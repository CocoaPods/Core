module Pod

  # A Requirement is a set of one or more version restrictions of a
  # {Dependency}.
  #
  # It is based on the RubyGems class adapted to support CocoaPods specific
  # information.
  #
  # @todo Move support about external sources and head information here from
  #       the Dependency class.
  #
  class Requirement < Pod::Vendor::Gem::Requirement

    quoted_operators = OPS.keys.map { |k| Regexp.quote k }.join '|'

    # @return [Regexp] The regular expression used to validate input strings.
    #
    PATTERN = /\A\s*(#{quoted_operators})?\s*(#{Version::VERSION_PATTERN})\s*\z/

    #-------------------------------------------------------------------------#

    # Factory method to create a new requirement.
    #
    # @param  [Requirement, Version, Array<Version>, String, Nil] input
    #         The input used to create the requirement.
    #
    # @return [Requirement] A new requirement.
    #
    def self.create(input)
      case input
      when Requirement
        input
      when Version, Array
        new(input)
      else
        if input.respond_to? :to_str
          new([input.to_str])
        else
          default
        end
      end
    end

    # @return [Requirement] The default requirement.
    #
    def self.default
      new('>= 0')
    end

    # Parses the given object returning an tuple where the first entry is an
    # operator and the second a version. If not operator is provided it
    # defaults to `=`.
    #
    # @param  [String, Version] input
    #         The input passed to create the requirement.
    #
    # @return [Array] A tuple representing the requirement.
    #
    def self.parse(input)
      return ['=', input] if input.is_a?(Version)

      unless PATTERN =~ input.to_s
        raise ArgumentError, "Illformed requirement `#{input.inspect}`"
      end

      operator = Regexp.last_match[1] || '='
      version = Version.new(Regexp.last_match[2])
      [operator, version]
    end

    #-------------------------------------------------------------------------#

  end

end
