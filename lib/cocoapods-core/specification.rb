require 'active_support/core_ext/string/strip.rb'
require 'cocoapods-core/specification/set'
require 'cocoapods-core/specification/dsl'
require 'cocoapods-core/specification/linter'

module Pod

  # The {Specification} provides a DSL to describe a Pod. A pod is defined as a
  # library originating from a source. A specification can support detailed
  # attributes for modules of code  through subspecs.
  #
  # Usually it is stored in files with `podspec` extension.
  #
  class Specification

    include Pod::Specification::DSL

    # @return [Specification] parent the parent of the specification unless the
    #         specification is a root.
    #
    attr_accessor :parent

    # @param  [Specification] parent @see parent
    #
    # @param  [String] name
    #         the name of the specification.
    #
    def initialize(parent = nil, name = nil)
      DSL.attributes.each { |a| a.initialize_spec_ivar(self) }
      @subspecs = []
      @define_for_platforms = PLATFORMS
      @deployment_target = {}
      @dependencies = {}
      PLATFORMS.each do |platform|
        @dependencies[platform] = []
      end

      @parent = parent
      @name   = name

      yield self if block_given?
    end

    # Loads a specification form the given path.
    #
    # @param  [Pathname, String] path
    #         the path of the `podspec` file.
    #
    # @param  [String] subspec_name
    #         the name of the specification that should be returned. If nil
    #         returns the root specification.
    #
    # @raise  If the file doesn't return a Pods::Specification after
    #         evaluation.
    #
    # @return [Specification]
    #
    def self.from_file(path, subspec_name = nil)
      path = Pathname.new(path)
      unless path.exist?
        raise StandardError, "No podspec exists at path `#{path}`."
      end
      spec = ::Pod._eval_podspec(path)
      unless spec.is_a?(Specification)
        raise StandardError, "Invalid podspec file at path `#{path}`."
      end
      spec.defined_in_file = path
      spec.subspec_by_name(subspec_name)
    end

    # @return [String] the path where the specification is defined, if loaded
    #         from a file.
    #
    def defined_in_file
      root? ? @defined_in_file : root.defined_in_file
    end

    # Sets the path of the `podspec` file used to load the specification.
    #
    # @param  [String] file
    #         the `podspec` file.
    #
    # @return [void]
    #
    def defined_in_file=(file)
      unless root?
        raise StandardError, "Defined in file can be set only for root specs."
      end
      @defined_in_file = file
    end


    # Compares a specification to another. The comparison is based only on the
    # name and the version of the specification.
    #
    # @return [Bool] whether the specifications represent the same version of
    #         the same Pod.
    #
    def ==(other)
      object_id == other.object_id ||
        (self.class === other &&
         name == other.name &&
         version == other.version)
    end

    #-------------------------------------------------------------------------#

    # @!group Working with a hierarchy of specifications

    # @return [Specification] The root specification or itself if it is root.
    #
    def root
      @parent ? @parent.root : self
    end

    # @return [Bool] whether the specification is root.
    #
    def root?
      parent.nil?
    end

    # @return [Bool] whether the specification is a subspec.
    #
    def subspec?
      !parent.nil?
    end

    #-------------------------------------------------------------------------#

    # @!group Working with dependencies

    attr_reader :subspecs

    # @return [Array<Specifications>] the recursive list of all the subspecs of
    #         a specification.
    #
    def recursive_subspecs
      @recursive_subspecs ||= begin
        mapper = lambda do |spec|
          spec.subspecs.map do |subspec|
            [subspec, *mapper.call(subspec)]
          end.flatten
        end
        mapper.call(self)
      end
    end

    # Returns the subspec with the given name or the receiver if the name is
    # nil or equal to the name of the receiver.
    #
    # @param    [String] relative_name
    #           the relative name of the subspecs starting from the receiver
    #           including the name of the receiver.
    #
    # @example  Retrieving a subspec
    #
    #           s.subspec_by_name('Pod/subspec').name #=> 'subspec'
    #
    # @return   [Specification] the subspec with the given name or self.
    #
    def subspec_by_name(relative_name)
      # TODO: the implementation of this method should be cleaner.
      if relative_name.nil? || relative_name == @name
        self
      else
        remainder = relative_name[@name.size+1..-1]
        subspec_name = remainder.split('/').shift
        subspec = subspecs.find { |s| s.name == "#{self.name}/#{subspec_name}" }
        unless subspec
          raise StandardError, "Unable to find a specification named " \
            "`#{relative_name}` in `#{self.name}`."
        end
        subspec.subspec_by_name(remainder)
      end
    end

    # Returns the dependencies on other Pods or subspecs of other Pods.
    #
    # @param  [Bool] all_platforms
    #         whether the dependencies should be returned for all platforms
    #         instead of the active one.
    #
    # @note   External dependencies are inherited by subspecs
    #
    # @return [Array<Dependency>] the dependencies on other Pods.
    #
    def external_dependencies(all_platforms = false)
      active_plaform_check unless all_platforms
      result = if all_platforms then @dependencies.values.flatten
               else @dependencies[active_platform] end
      result = parent.external_dependencies + result if parent
      result.uniq
    end

    # Returns the dependencies on subspecs.
    #
    # @note   A specification has a dependency on either the
    #         {#default_subspec} or each of its children subspecs that are
    #         compatible with its platform.
    #
    # @return [Array<Dependency>] the dependencies on subspecs.
    #
    def subspec_dependencies
      active_plaform_check
      specs = if default_subspec then [subspec_by_name("#{name}/#{default_subspec}")]
              else subspecs end
      specs = specs.compact
      specs = specs.select { |s| s.supported_on_platform?(active_platform) }
      specs = specs.map { |s| Dependency.new(s.name, version) }
    end

    # @return [Array<Dependency>] all the dependencies of the specification.
    #
    def dependencies
      external_dependencies + subspec_dependencies
    end

    # @note   This is used by the specification set
    #
    # @return [Dependency]
    # TODO :delete
    # def dependency_by_top_level_spec_name(name)
    #   external_dependencies(true).each do |dep|
    #     return dep if dep.top_level_spec_name == name
    #   end
    # end

    #-------------------------------------------------------------------------#

    # @!group DSL helpers

    # TODO: Convert master repo.
    #
    alias :preferred_dependency= :default_subspec=

    # @return [Bool] whether the specification should use a directory as it
    #         source.
    #
    def local?
      !source.nil? && !source[:local].nil?
    end

    # @return     [Bool] whether the specification is supported in the given
    #             platform.
    #
    # @overload   supported_on_platform?(platform)
    #
    #   @param    [Platform] platform
    #             the platform which is checked for support.
    #
    # @overload   supported_on_platform?(symbolic_name, deployment_target)
    #
    #   @param    [Symbol] symbolic_name
    #             the name of the platform which is checked for support.
    #
    #   @param    [String] deployment_target
    #             the deployment target which is checked for support.
    #
    def supported_on_platform?(*platform)
      platform = Platform.new(*platform)
      available_platforms.any? { |p| platform.supports?(p) }
    end

    # @return [Array<Platform>] The platforms that the Pod is supported on.
    #
    # @note   If no platform is specified, this method returns all known
    #         platforms.
    #
    def available_platforms
      names = platform ? [ platform.name ] : PLATFORMS
      names.map { |name| Platform.new(name, deployment_target(name)) }
    end

    # Returns the deployment target for the specified platform.
    #
    # @param  [String] the symbolic name of the platform.
    #
    # @return [Version] the version of the deployment target or nil if not
    #         specified or the platform is not supported.
    #
    def deployment_target(platform_name)
      if @platform
        platform.deployment_target if platform.name == platform_name
      elsif target = @deployment_target[platform_name]
        target
      elsif parent
        parent.deployment_target(platform_name)
      end
    end

    #-------------------------------------------------------------------------#

    # @!group DSL deprecations

    # TODO: Convert master repo.
    # TODO: Review implementations.
    # TODO: exclude_header_search_paths

    # Preferred dependency rename.
    #
    def preferred_dependency=(args)
      # puts "`preferred_dependency` has been renamed to `default_subspec`."
      self.default_subspec = args
    end

    # Clean paths warnings.
    #
    def clean_paths
      raise StandardError, "Clean paths are deprecated. CocoaPods now " \
        "cleans unused files by default. Use preserver paths if needed."
    end

    def part_of_dependency=
      raise StandardError, "Deprecated attribute"
    end

    def part_of=
      raise StandardError, "Deprecated attribute"
    end

    # Checks the specification for deprecations and changes.
    #
    def peform_post_initialization_checks
      # TODO: check that the post install hook has not been overridden.
      # TODO: check that the headers hook has not been set.
    end

    #-------------------------------------------------------------------------#

    # The PlatformProxy works in conjunction with Specification#_on_platform.
    # It provides support for a syntax like `spec.ios.source_files = 'file'`.
    #
    class PlatformProxy

      # @param  [Specification] specification
      #         the specification whose syntax attribute should be set.
      #
      # @param  [Symbol] platform
      #
      def initialize(specification, platform)
        @specification, @platform = specification, platform
      end

      # Defines a setter method for each attribute of the specification class,
      # that forwards the message to the {#specification} using the
      # {Specification#on_platform} method.
      #
      DSL.attributes.select { |a| a.multi_platform? }.each do |a|
        define_method(a.writer_name) do |args|
          @specification._on_platform(@platform) do
            @specification.send(a.writer_name, args)
          end
        end

        alias_method(a.writer_alias, a.writer_name) if a.writer_alias
      end
    end

    #-------------------------------------------------------------------------#

    # @!group Support for Multi-platform attributes

    # Defines the active platform for consumption of the specification.
    #
    # This method is provided as a convenience so there is no need to specify
    # the symbolic name of a platform while accessing the multi-platform
    # attributes.
    #
    # @overload   activate_platform(platform)
    #
    #   @param    [Platform] platform
    #             the platform to activate.
    #
    # @overload   activate_platform(symbolic_name, deployment_target)
    #
    #   @param    [Symbol] symbolic_name
    #             the name of the platform to activate.
    #
    #   @param    [String] deployment_target
    #             the deployment target to activate.
    #
    # @note       To simplify the interface a specification needs to be
    #             activated for a platform before accessing multi-platform
    #             attributes.
    #
    # @raise      If the platform is not supported by the specification.
    #
    # @return     [void]
    #
    def activate_platform(*platform)
      platform = Platform.new(*platform)
      unless supported_on_platform?(platform)
        raise StandardError, "#{to_s} is not compatible with #{platform.to_s}."
      end
      set_active_platform(platform)
    end

    def set_active_platform(platform)
      if root?
        @active_platform = platform.to_sym
      else
        root.set_active_platform(*platform)
      end
    end

    # @return [Symbol] The name of the platform this specification was
    #         activated for.
    #
    def active_platform
      root? ? @active_platform : root.active_platform
    end

    # Alters the `@define_for_platforms` instance variable to point to the
    # given platform during the execution of the given block.
    #
    # @visibility private
    #
    # @note   Multi-platform attribute writers should use the
    #         `@define_for_platforms` instance variable to infer the platforms
    #         for which the attribute should be defined.
    #
    # @note   This is used by PlatformProxy to assign attributes for the scoped
    #         platform.
    #
    # @return [void]
    #
    def _on_platform(platform)
      before, @define_for_platforms = @define_for_platforms, [platform]
      yield
    ensure
      @define_for_platforms = before
    end

    #-------------------------------------------------------------------------#

    # @!group String representation

    # @return [String] A string suitable for representing the specification in
    #         clients.
    #
    def to_s
      "#{name} (#{version})"
    end

    # @param    [String] string
    #           the string that describes a {Specification} generated from
    #           {Specification#to_s}.
    #
    # @example  Input examples
    #
    #           "libPusher"
    #           "libPusher (1.0)"
    #           "libPusher (HEAD based on 1.0)"
    #           "RestKit/JSON"
    #
    # @return   [Array<String, Version>] the name and the version of a
    #           pod.
    #
    def self.name_and_version_from_string(string_reppresenation)
      match_data = string_reppresenation.match(/(\S*) \((.*)\)/)
      name = match_data[1]
      vers = Version.from_string(match_data[2])
      [name, vers]
    end

    # @return [String] A string suitable for debugging.
    #
    def inspect
      "#<#{self.class.name} for `#{to_s}`>"
    end
  end

  Spec = Specification

  # Evaluates the file at the given path in the namespace of the Pod module.
  #
  # @return [Object] it can return any object but, is expected to be called on
  #         `podspec` files that should return a #{Specification}.
  #
  def self._eval_podspec(path)
    string = File.open(path, 'r:utf-8')  { |f| f.read }
    # Work around for Rubinius incomplete encoding in 1.9 mode
    if string.respond_to?(:encoding) && string.encoding.name != "UTF-8"
      string.encode!('UTF-8')
    end

    begin
      eval(string, nil, path.to_s)
    rescue Exception => e
      raise DSLError.new("Invalid `#{path.basename}` file: #{e.message}",
                         path, e.backtrace)
    end
  end
end
