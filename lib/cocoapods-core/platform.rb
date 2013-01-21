module Pod

  # A Platform describes an SDK name and deployment target.
  #
  class Platform

    # @return [Symbol, String] the name of the SDK represented by the platform.
    #
    def name
      @symbolic_name
    end

    # @return [Version] the deployment target of the platform.
    #
    attr_reader :deployment_target

    # Constructs a platform from either another platform or by
    # specifying the symbolic name and optionally the deployment target.
    #
    # @overload   initialize(name, deployment_target)
    #
    #   @param    [Symbol, String] name
    #             the name of platform.
    #
    #   @param    [String, Version] deployment_target
    #             the optional deployment.
    #
    #   @note     If the deployment target is not provided a default deployment
    #             target will not be assigned.
    #
    #   @example  Initialization with symbol
    #
    #             Platform.new(:ios)
    #             Platform.new(:ios, '4.3')
    #
    # @overload   initialize(platform)
    #
    #   @param    [Platform] platform
    #             Another {Platform}.
    #
    #   @example  Initialization with another platform
    #
    #             platform = Platform.new(:ios)
    #             Platform.new(platform)
    #
    def initialize(input, target = nil)
      if input.is_a? Platform
        @symbolic_name = input.name
        @deployment_target = input.deployment_target
      else
        @symbolic_name = input.to_sym
        target = target[:deployment_target] if target.is_a?(Hash)
        @deployment_target = Version.create(target)
      end
    end

    # Convenience method to initialize an iOS platform.
    #
    # @return [Platform] an iOS platform.
    #
    def self.ios
      new :ios
    end

    # Convenience method to initialize an OS X platform.
    #
    # @return [Platform] an OS X platform.
    #
    def self.osx
      new :osx
    end

    # Checks if a platform is equivalent to another one or to a symbol
    # representation.
    #
    # @param  [Platform, Symbol] other
    #         the other platform to check.
    #
    # @note   If a symbol is passed the comparison does not take into account
    #         the deployment target.
    #
    # @return [Boolean] whether two platforms are the equivalent.
    #
    def ==(other)
      if other.is_a?(Symbol)
        @symbolic_name == other
      else
        (name == other.name) && (deployment_target == other.deployment_target)
      end
    end

    # Checks whether a platform supports another one.
    #
    # In the context of operating system SDKs, a platform supports another
    # one if they have the same name and the other platform has a minor or
    # equal deployment target.
    #
    # @return [Bool] whether the platform supports another platform.
    #
    def supports?(other)
      other = Platform.new(other)
      if other.deployment_target && deployment_target
      (other.name == name) && (other.deployment_target <= deployment_target)
      else
        other.name == name
      end
    end

    # @return [String] a string representation that includes the deployment
    #         target.
    #
    def to_s
      s = self.class.string_name(@symbolic_name)
      s << " #{deployment_target}" if deployment_target
      s
    end

    # @return [String] the debug representation.
    #
    def inspect
      "#<#{self.class.name} name=#{name.inspect} " \
      "deployment_target=#{deployment_target.inspect}>"
    end

    # @return [Symbol] a symbol representing the name of the platform.
    #
    def to_sym
      name
    end

    # Compares the platform first by name and the by deployment_target for
    # sorting.
    #
    # @param  [Platform] other
    #         The other platform to compare.
    #
    # @return [Fixnum] -1, 0, or +1 depending on whether the receiver is less
    #         than, equal to, or greater than other.
    #
    def <=> other
      name_sort = self.name.to_s <=> other.name.to_s
      if name_sort.zero?
        self.deployment_target <=> other.deployment_target
      else
        name_sort
      end
    end

    # @return [Bool] whether the platform requires legacy architectures for
    #         iOS.
    #
    def requires_legacy_ios_archs?
      (name == :ios) && deployment_target && (deployment_target < Version.new("4.3"))
    end

    # Converts the symbolic name of a platform to a string name suitable to be
    # presented to the user.
    #
    # @param  [Symbol] symbolic_name
    #         the symbolic name of a platform.
    #
    # @return [String] The string that describes the name of the given symbol.
    #
    def self.string_name(symbolic_name)
      case symbolic_name
      when :ios then 'iOS'
      when :osx then 'OS X'
      else symbolic_name end
    end
  end
end
