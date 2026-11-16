require 'rspec/expectations'

# Transitional shim that implements bacon's `should` assertion chain on top of
# RSpec, so the existing specs run unchanged under RSpec.
#
# RSpec's own `should` syntax is not a drop-in replacement: it only supports
# the operator forms (`should ==`, `should =~`, …), rejects `should !=`, and has
# no `.not`, `.be`, predicate, or `.raise` chaining.
#
# New specs should use `expect` syntax. Once the existing specs have been
# converted, this file should be deleted.
#
# Supported forms (all may be prefixed with `.not`, and `.be`/`.a`/`.an` are
# no-op connectors):
#
#   obj.should == other            obj.should.equal other     # ==
#   obj.should != other                                       # !=
#   obj.should =~ other            obj.should.match other     # obj =~ other
#   obj.should.be < other                                     # < > <= >=
#   obj.should.be.identical_to o   obj.should.be.same_as o    # equal?
#   obj.should.be.true             obj.should.be.false        # strict
#   obj.should.satisfy { |o| … }
#   obj.should.be.nil              obj.should.include x       # any predicate:
#                                                             # calls `nil?`,
#                                                             # `include?(x)`
#   lambda { … }.should.raise(Klass)                          # returns the
#   should.raise(Klass) { … }                                 # exception
#   should.not.raise { … }
#   should.flunk 'reason'
#
module BaconCompat
  class Should < BasicObject
    def initialize(object)
      @object = object
      @negated = false
    end

    def not(*args, &block)
      @negated = !@negated
      args.empty? ? self : be(*args, &block)
    end

    def be(*args, &block)
      return self if args.empty?
      satisfy(*args, &block)
    end
    alias a be
    alias an be

    def satisfy(description = '')
      result = yield(@object)
      ::RSpec::Expectations.fail_with(description) unless @negated ^ result
      result
    end

    def ==(other)
      check(::RSpec::Matchers::BuiltIn::Eq.new(other))
    end
    alias equal ==

    def !=(other)
      @negated = !@negated
      self == other
    end

    # Bacon calls the receiver's own `=~` (e.g. `Requirement#=~` checks whether
    # a version satisfies it), which RSpec's `match` matcher does not.
    def =~(other)
      satisfy("#{negation}#{@object.inspect} =~ #{other.inspect} failed") { |o| o =~ other }
    end
    alias match =~

    def identical_to(other)
      check(::RSpec::Matchers::BuiltIn::Equal.new(other))
    end
    alias same_as identical_to
    alias equal? identical_to

    [:<, :>, :<=, :>=].each do |operator|
      define_method(operator) do |other|
        check(::RSpec::Matchers::BuiltIn::BeComparedTo.new(other, operator))
      end
    end

    def true
      check(::RSpec::Matchers::BuiltIn::Equal.new(true))
    end

    def false
      check(::RSpec::Matchers::BuiltIn::Equal.new(false))
    end

    # Like bacon, defaults to RuntimeError, does not rescue other exceptions,
    # and returns the raised exception so callers can inspect it.
    def raise(*exceptions, &block)
      callable = block || @object
      if @negated
        check(::RSpec::Matchers::BuiltIn::RaiseError.new(nil, nil), callable)
        return false
      end

      exceptions = [::RuntimeError] if exceptions.empty?
      begin
        callable.call
      rescue *exceptions => e
        return e
      end
      ::RSpec::Expectations.fail_with("expected #{exceptions.inspect} to be raised, but nothing was raised")
    end

    def flunk(reason = 'Flunked')
      ::RSpec::Expectations.fail_with(reason)
    end

    # Anything else is a predicate: `should.be.empty` calls `empty?`.
    def method_missing(name, *args, &block)
      name = "#{name}?" if name.to_s =~ /\w[^?]\z/
      description = "#{negation}#{@object.inspect}.#{name}(#{args.map(&:inspect).join(', ')}) failed"
      satisfy(description) { |o| o.__send__(name, *args, &block) }
    end

    private

    def negation
      @negated ? 'not ' : ''
    end

    def check(matcher, actual = @object)
      target = ::RSpec::Expectations::ExpectationTarget.for(actual, nil)
      @negated ? target.not_to(matcher) : target.to(matcher)
      true
    end
  end

  module ObjectExtensions
    def should
      Should.new(self)
    end
  end

  # Inside examples, rspec-core's one-liner `should` (MemoizedHelpers) takes
  # precedence over Object#should, which breaks bare `should.raise { … }`.
  module ExampleExtensions
    def should
      Should.new(self)
    end
  end

  def self.shared_blocks
    @shared_blocks ||= {}
  end

  # `behaves_like` evaluates a `shared` block in the current group, like bacon.
  module GroupExtensions
    def behaves_like(*names)
      names.each { |name| class_exec(&BaconCompat.shared_blocks.fetch(name)) }
    end
  end
end

Object.include(BaconCompat::ObjectExtensions)

module Kernel
  private

  def shared(name, &block)
    BaconCompat.shared_blocks[name] = block
  end
end
