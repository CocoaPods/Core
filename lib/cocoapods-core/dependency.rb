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
    # @note This representation is used by the {Lockfile}.
    #
    # @example Output examples
    #
    #   "libPusher"
    #   "libPusher (= 1.0)"
    #   "libPusher (~> 1.0.1)"
    #   "libPusher (> 1.0, < 2.0)"
    #   "libPusher (HEAD)"
    #   "libPusher (from `www.example.com')"
    #   "libPusher (defined in Podfile)"
    #   "RestKit/JSON"
    #
    # @return [String] the representation of the dependency.
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
    # @note This representation is used by the {Lockfile}.
    #
    # @example Output examples
    #
    #   "from `www.example.com/libPusher.git', tag `v0.0.1'"
    #   "from `www.example.com/libPusher.podspec'"
    #   "from `~/path/to/libPusher'"
    #
    # @return [String] the description of the external source.
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

    # Taken from RubyGems 1.3.7
    #
    # TODO: REMOVE
    #
    unless public_method_defined?(:match?)

      # Checks if a dependency is compatible with a {Specification} that has
      # the given name and version.
      #
      # @param  [String] spec_name
      #         the name of the specification.
      #
      # @param  [String] spec_version
      #         the version of the specification.
      #
      # @return [Bool] whether the dependency matches the given name and
      #         version.
      #
      def match?(spec_name, spec_version)
        pattern = name

        if Regexp === pattern
          return false unless pattern =~ spec_name
        else
          return false unless pattern == spec_name
        end

        return true if requirement.to_s == ">= 0"

        requirement.satisfied_by? Gem::Version.new(spec_version)
      end
    end

    # Taken from RubyGems 1.6.0
    #
    # TODO: REMOVE and require RubyGems 1.6 in cocoapods-core.rb
    #
    unless public_method_defined?(:merge)

      # Merges the version requirements of the dependency with the ones of
      # another dependency.
      #
      # @param  [Dependency] other
      #         the dependency to merge with.
      #
      # @raise  If the other dependency has a different name.
      #
      def merge(other)
        unless name == other.name then
          raise StandardError, ArgumentError, "#{self} and #{other} have different names"
        end

        default = Gem::Requirement.default
        self_req  = self.requirement
        other_req = other.requirement

        return self.class.new name, self_req  if other_req == default
        return self.class.new name, other_req if self_req  == default

        self.class.new name, self_req.as_list.concat(other_req.as_list)
      end
    end

    # TODO port to Sandbox
    #
    # def specification_from_sandbox(sandbox, platform)
    #   @external_source.specification_from_sandbox(sandbox, platform)
    # end

    # TODO port to Sandbox
    #
    # require 'cocoapods/open_uri'
    # module ExternalSources
    #   def self.from_params(name, params)
    #     return unless name && params
    #     if params.key?(:git)
    #       GitSource.new(name, params)
    #     elsif params.key?(:podspec)
    #       PodspecSource.new(name, params)
    #     elsif params.key?(:local)
    #       LocalSource.new(name, params)
    #     else
    #       raise StandardError, "Unknown external source parameters for #{name}: #{params}"
    #     end
    #   end

    #   class AbstractExternalSource

    #     attr_reader :name, :params

    #     def initialize(name, params)
    #       @name, @params = name, params
    #     end

    #     def specification_from_sandbox(sandbox, platform)
    #       specification_from_local(sandbox, platform) || specification_from_external(sandbox, platform)
    #     end

    #     def specification_from_local(sandbox, platform)
    #       if local_pod = sandbox.installed_pod_named(name, platform)
    #         local_pod.top_specification
    #       end
    #     end

    #     def specification_from_external(sandbox, platform)
    #       podspec = copy_external_source_into_sandbox(sandbox, platform)
    #       spec = specification_from_local(sandbox, platform)
    #       raise StandardError, "No podspec found for `#{name}' in #{description}" unless spec
    #       spec
    #     end

    #     # Can store from a pathname or a string
    #     #
    #     def store_podspec(sandbox, podspec)
    #       output_path = sandbox.root + "Local Podspecs/#{name}.podspec"
    #       output_path.dirname.mkpath
    #       if podspec.is_a?(String)
    #         raise StandardError, "No podspec found for `#{name}' in #{description}" unless podspec.include?('Spec.new')
    #         output_path.open('w') { |f| f.puts(podspec) }
    #       else
    #         raise StandardError, "No podspec found for `#{name}' in #{description}" unless podspec.exist?
    #         FileUtils.copy(podspec, output_path)
    #       end
    #     end

    #     def ==(other)
    #       return if other.nil?
    #       name == other.name && params == other.params
    #     end
    #   end

    #   class GitSource < AbstractExternalSource
    #     def copy_external_source_into_sandbox(sandbox, platform)
    #       UI.info("->".green + " Pre-downloading: '#{name}'") do
    #         target = sandbox.root + name
    #         target.rmtree if target.exist?
    #         downloader = Downloader.for_target(sandbox.root + name, @params)
    #         downloader.download
    #         store_podspec(sandbox, target + "#{name}.podspec")
    #         if local_pod = sandbox.installed_pod_named(name, platform)
    #           local_pod.downloaded = true
    #         end
    #       end
    #     end

    #     def description
    #       "from `#{@params[:git]}'".tap do |description|
    #         description << ", commit `#{@params[:commit]}'" if @params[:commit]
    #         description << ", branch `#{@params[:branch]}'" if @params[:branch]
    #         description << ", tag `#{@params[:tag]}'" if @params[:tag]
    #       end
    #     end
    #   end

    #   # can be http, file, etc
    #   class PodspecSource < AbstractExternalSource
    #     def copy_external_source_into_sandbox(sandbox, _)
    #       UI.info("->".green + " Fetching podspec for `#{name}' from: #{@params[:podspec]}") do
    #         path = @params[:podspec]
    #         path = Pathname.new(path).expand_path if path.start_with?("~")
    #         open(path) { |io| store_podspec(sandbox, io.read) }
    #       end
    #     end

    #     def description
    #       "from `#{@params[:podspec]}'"
    #     end
    #   end

    #   class LocalSource < AbstractExternalSource
    #     def pod_spec_path
    #       path = Pathname.new(@params[:local]).expand_path
    #       path += "#{name}.podspec"# unless path.to_s.include?("#{name}.podspec")
    #       raise StandardError, "No podspec found for `#{name}' in `#{@params[:local]}'" unless path.exist?
    #       path
    #     end

    #     def copy_external_source_into_sandbox(sandbox, _)
    #       store_podspec(sandbox, pod_spec_path)
    #     end

    #     def specification_from_local(sandbox, platform)
    #       specification_from_external(sandbox, platform)
    #     end

    #     def specification_from_external(sandbox, platform)
    #       copy_external_source_into_sandbox(sandbox, platform)
    #       spec = Specification.from_file(pod_spec_path)
    #       spec.source = @params
    #       spec
    #     end

    #     def description
    #       "from `#{@params[:local]}'"
    #     end
    #   end
    # end
  end
end
