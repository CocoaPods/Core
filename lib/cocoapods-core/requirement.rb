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
  class Requirement < VersionKit::Requirement

    #-------------------------------------------------------------------------#

    def initialize(input)
      case input
      when String
        super(input)
      when Version
        super(input.canonical_version)
      when Requirement
        super(input.to_s)
      when nil
        super('>= 0')
      end
    end

    # Factory method to create a new requirement.
    #
    # @param  [Requirement, Version, Array<Version>, String, Nil] input
    #         The input used to create the requirement.
    #
    # @return [Requirement] A new requirement.
    #
    def self.create(input)
      new(input)
    end

    # @return [Requirement] The default requirement.
    #
    def self.default
      new('>= 0')
    end

    #-------------------------------------------------------------------------#
  end
end
