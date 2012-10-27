module Pod

  # The {Dependency} allows to specify dependencies of a {Podfile} or a
  # {Specification} on a Pod. It stores the name of the dependency, version
  # requirements and external sources information.
  #
  # This class leverages the RubyGems dependency class
  # (http://rubygems.rubyforge.org/rubygems-update/Gem/Dependency.html) with
  # minor extension to support CocoaPods specific features.
  #
  # The Dependency class provides support for subspecs.
  #
  class Dependency < Gem::Dependency

    # @return [Hash{Symbol=>String}] a hash describing the external source
    #         where the pod should be fetched. The external source has to
    #         provide its own {Specification} file.
    #
    attr_accessor :external_source

    # @return [Bool] whether the dependency should use the podspec with the
    #         highest know version but force the downloader to checkout the
    #         `head` of the source repository.
    #
    attr_reader :head
    alias :head? :head

    # @return [Specification] the specification loaded for the dependency.
    #
    attr_accessor :specification

    # TODO: Inline podspecs will be deprecated
    #
    # TODO: External Sources should be handled by the Sandbox
    #
    def initialize(*name_and_version_requirements, &block)
      if name_and_version_requirements.empty? && block
        @inline_podspec = true
        @specification  = Specification.new(&block)
        super(@specification.name, @specification.version)

      elsif !name_and_version_requirements.empty? && block.nil?
        version = name_and_version_requirements.last
        if name_and_version_requirements.last.is_a?(Hash)
          @external_source = name_and_version_requirements.pop
          # @external_source = ExternalSources.from_params(name_and_version_requirements[0].split('/').first, name_and_version_requirements.pop)
        elsif version.is_a?(Symbol) && version == :head || version.is_a?(Version) && version.head?
          name_and_version_requirements.pop
          @head = true
        end

        super(*name_and_version_requirements)

        if head? && !latest_version?
          raise StandardError, "A `:head' dependency may not specify version requirements."
        end

      else
        raise StandardError, "A dependency needs either a name and version requirements, " \
          "a source hash, or a block which defines a podspec."
      end
    end

    # TODO: Inline podspecs will be deprecated
    #
    def inline?
      @inline_podspec
    end

    # @return [Bool] whether the dependency wants the latest version of a Pod.
    #
    def latest_version?
      versions = @version_requirements.requirements.map(&:last)
      versions == [Gem::Version.new('0')]
    end

    # @return [Bool] whether the dependency points to a subspec.
    #
    def subspec_dependency?
      @name.include?('/')
    end

    # @return [Bool] whether the dependency points to an external source.
    #
    def external?
      !@external_source.nil?
    end

    # Creates a new dependency with the name of the top level spec and the same
    # version requirements.
    #
    # This is used by the {Set} class to merge dependencies and resolve the
    # required version of a Pod regardless what particular specification
    # (subspecs or top level) is required.
    #
    # @return [Dependency] a dependency with the same versions requirements
    #         that is guaranteed to point to a top level specification.
    #
    def to_top_level_spec_dependency
      dep = dup
      dep.name = top_level_spec_name
      dep
    end

    # Returns the name of the Pod that the dependency is pointing to.
    #
    # In case this is a dependency for a subspec, e.g. 'RestKit/Networking',
    # this returns 'RestKit', which is what the Pod::Source needs to know to
    # retrieve the correct Set from disk.
    #
    # @return [String] the name of the Pod.
    #
    # TODO: this should be handled by the specification class.
    #
    def top_level_spec_name
      subspec_dependency? ? @name.split('/').first : @name
    end

    # Checks if a dependency would be satisfied by the given {Version} of a
    # {Specification} with the same name.
    #
    # @param  [String] version
    #         the version to check.
    #
    # @return [Bool] whether the dependency matches the given version.
    #
    def match_version?(version)
      match?(name, version) && (version.head? == head?)
    end

    # @return [Bool] whether the dependency is equal to another taking into
    #                account the loaded specification, the head options and the
    #                external source.
    #
    def ==(other)
      super &&
        (head? == other.head?) &&
        # TODO: Inline podspecs will be deprecated so the comparison with the
        #       external sources should suffice.
        (@specification ? @specification == other.specification : @external_source == other.external_source)
    end

    # Creates a string representation of the dependency suitable for
    # serialization and de-serialization without loss of information.
    #
    # @note     This representation is used by the {Lockfile}.
    #
    # @example  Output examples
    #
    #           "libPusher"
    #           "libPusher (= 1.0)"
    #           "libPusher (~> 1.0.1)"
    #           "libPusher (> 1.0, < 2.0)"
    #           "libPusher (HEAD)"
    #           "libPusher (from `www.example.com')"
    #           "libPusher (defined in Podfile)"
    #           "RestKit/JSON"
    #
    # @return   [String] the representation of the dependency.
    #
    def to_s
      version = ''
      if external?
        version << external_source_description
      elsif inline?
        version << 'defined in Podfile'
      elsif head?
        version << 'HEAD'
      elsif @version_requirements != Gem::Requirement.default
        version << @version_requirements.to_s
      end
      result = @name.dup
      result << " (#{version})" unless version.empty?
      result
    end

    # Creates a string representation of the external source.
    #
    # @note     This representation is used by the {Lockfile}.
    #
    # @example  Output examples
    #
    #           "from `www.example.com/libPusher.git', tag `v0.0.1'"
    #           "from `www.example.com/libPusher.podspec'"
    #           "from `~/path/to/libPusher'"
    #
    # @return   [String] the description of the external source.
    #
    def external_source_description
      source = external_source
      if source.key?(:git)
        desc =  "`#{source[:git]}'"
        desc << ", commit `#{source[:commit]}'" if source[:commit]
        desc << ", branch `#{source[:branch]}'" if source[:branch]
        desc << ", tag `#{source[:tag]}'"       if source[:tag]
      elsif source.key?(:podspec)
        desc = "`#{source[:podspec]}'"
      elsif source.key?(:local)
        desc = "`#{source[:local]}'"
      else
        desc = "`#{source.to_s}'"
      end
      "from #{desc}"
    end
  end
end
