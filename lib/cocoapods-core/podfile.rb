require 'cocoapods-core/podfile/target_definition'

module Pod

  # The {Podfile} is a specification that describes the dependencies of the
  # targets of an Xcode project.
  #
  # It supports its own DSL and generally is stored in files named
  # `CocoaPods.podfile` or `Podfile`.
  #
  # The Podfile creates a hierarchy of target definitions that that store the
  # information of necessary to generate the CocoaPods libraries.
  #
  class Podfile

    # @return [Pathname] the path where the podfile was loaded from. It is nil
    #         if the podfile was generated programmatically.
    #
    attr_accessor :defined_in_file

    # @param    [Pathname] defined_in_file
    #           the path of the podfile.
    #
    # @param    [Proc] block
    #           a block that configures the podfile through its DSL.
    #
    # @example  Creating a Podfile.
    #
    #           platform :ios, "6.0"
    #           target :my_app do
    #             pod "AFNetworking", "~> 1.0"
    #           end
    #
    def initialize(defined_in_file = nil, &block)
      self.defined_in_file = defined_in_file
      @target_definition = TargetDefinition.new(:default, nil, :exclusive => true)
      @target_definitions = { :default => @target_definition }
      instance_eval(&block)
    end

    # Initializes a podfile from the file with the given path.
    #
    # @param  [Pathname] path
    #         the path from where the podfile should be loaded.
    #
    # @return [Podfile] the generated podfile.
    #
    def self.from_file(path)
      podfile = Podfile.new(path) do
        string = File.open(path, 'r:utf-8')  { |f| f.read }
        # Work around for Rubinius incomplete encoding in 1.9 mode
        string.encode!('UTF-8') if string.respond_to?(:encoding) && string.encoding.name != "UTF-8"
        eval(string, nil, path.to_s)
      end
      podfile.validate!
      podfile
    end

    class Pod::Podfile::StandardError < StandardError; end

    # Raises a {Podfile::StandardError} exception with the given message. If
    # the Podfile is defined in a file, the line that caused the exception is
    # included in the message.
    #
    # @param    [String] message
    #           the message of the exception.
    #
    # @example  Output example
    #
    #           Pod::Podfile::StandardError: Inline specifications are deprecated.
    #           Please store the specification in a `podspec` file.
    #
    #               from CocoaPods/tmp/Podfile:2
    #
    #               pod do |s|
    #            >    s.name = 'mypod'
    #               end
    #
    # @return   [void]
    #
    def raise(message)
      if defined_in_file
        podfile_file_trace_line = caller.find { |l| l =~ /#{defined_in_file.basename}/ }
        line_numer    = podfile_file_trace_line.split(':')[1].to_i - 1
        podfile_lines = File.readlines(defined_in_file)
        indent        = "    "
        indicator     = indent.dup.insert(1, ">")[0..-2]

        message << "\n\n#{indent}from #{podfile_file_trace_line.gsub(/:in.*$/,'')}\n\n"
        (message << indent    << podfile_lines[line_numer - 1 ]) unless line_numer == 0
        (message << indicator << podfile_lines[line_numer])
        (message << indent    << podfile_lines[line_numer + 1 ]) unless line_numer == (podfile_lines.count - 1)
        message << "\n"
      end
      super StandardError, message
    end

    #---------------------------------------------------------------------------#

    # @!group Working with a podfile

    # @return [Hash{Symbol,String => TargetDefinition}] the target definitions
    #         of the podfile stored by their name.
    #
    attr_reader :target_definitions


    # @return [Array<Dependency>] the dependencies of the all the target
    #         definitions.
    #
    def dependencies
      @target_definitions.values.map(&:target_dependencies).flatten.uniq
    end

    # Validates the podfile.
    #
    # @note   Currently this method does nothing.
    #
    # @return [void]
    #
    def validate!
      # TODO: raise if not platform is specified for the target definition ?
    end

    # @return [String] a string useful to represent the Podfile in a message
    #         presented to the user.
    #
    def to_s
      "Podfile"
    end

    # @return [String] the path of the workspace if specified by the user.
    #
    attr_reader :workspace_path

    # @return [Bool] whether the podfile should generate a BridgeSupport
    #         metadata document.
    #
    def generate_bridge_support?
      @generate_bridge_support
    end

    # @return [Bool] whether the -fobjc-arc flag should be added to the
    #         OTHER_LD_FLAGS.
    #
    def set_arc_compatibility_flag?
      @set_arc_compatibility_flag
    end

    # Calls the pre install callback if defined.
    #
    # @param  [Pod::Installer] installer
    #         the installer that is performing the installation.
    #
    # @return [Bool] whether a pre install callback was specified and it was
    #         called.
    #
    def pre_install!(installer)
      if @pre_install_callback
        @pre_install_callback.call(installer)
        true
      else
        false
      end
    end

    # Calls the post install callback if defined.
    #
    # @param  [Pod::Installer] installer
    #         the installer that is performing the installation.
    #
    # @return [Bool] whether a post install callback was specified and it was
    #         called.
    #
    def post_install!(installer)
      if @post_install_callback
        @post_install_callback.call(installer)
        true
      else
        false
      end
    end

    #---------------------------------------------------------------------------#

    # @!group DSL - Podfile

    # Defines a new static library target and scopes dependencies defined from
    # the given block. The target will by default include the dependencies
    # defined outside of the block, unless the `:exclusive => true` option is
    # given.
    #
    # @param    [Symbol, String] name
    #           the name of the target definition.
    #
    # @option   options [Bool] :exclusive
    #           whether the target should inherit the dependencies of its
    #           parent. by default targets are inclusive.
    #
    # @example  Defining a target
    #
    #           target :debug do
    #             pod 'SSZipArchive'
    #           end
    #
    # @example  Defining an exclusive target
    #
    #           target :test, :exclusive => true do
    #             pod 'JSONKit'
    #           end
    #
    # @note     The Podfile creates a global target named `:default` which
    #           produces the `libPods.a` file. This target is linked with the
    #           first target of user project if not value is specified for the
    #           {#link_with} attribute.
    #
    # @return   [void]
    #
    def target(name, options = {})
      parent = @target_definition
      @target_definitions[name] = @target_definition = TargetDefinition.new(name, parent, options)
      yield
    ensure
      @target_definition = parent
    end

    # Specifies the Xcode workspace that should contain all the projects.
    #
    # @param    [String] path
    #           path of the workspace.
    #
    # @note     If no explicit Xcode workspace is specified and only **one**
    #           project exists in the same directory as the Podfile, then the
    #           name of that project is used as the workspace’s name.
    #
    # @example  Specifying a workspace
    #
    #           workspace 'MyWorkspace'
    #
    # @return   [void]
    #
    def workspace(path)
      @workspace_path = (File.extname(path) == '.xcworkspace' ? path : "#{path}.xcworkspace")
    end

    # This hook allows you to make any changes to the Pods after they have been
    # downloaded but before they are installed.
    #
    # @example  Defining a pre install hook in a Podfile.
    #
    #           pre_install do |installer|
    #             # Do something fancy!
    #           end
    #
    # @note     Hooks are global and not stored per target definition.
    #
    # @return   [void]
    #
    def pre_install(&block)
      @pre_install_callback = block
    end

    # This hook allows you to make any last changes to the generated Xcode project
    # before it is written to disk, or any other tasks you might want to perform.
    #
    # @example  Customizing the `OTHER_LDFLAGS` of all targets
    #
    #           post_install do |installer|
    #             installer.project.targets.each do |target|
    #               target.build_configurations.each do |config|
    #                 config.build_settings['GCC_ENABLE_OBJC_GC'] = 'supported'
    #               end
    #             end
    #           end
    #
    # @note     Hooks are global and not stored per target definition.
    #
    # @return   [void]
    #
    def post_install(&block)
      @post_install_callback = block
    end

    # Specifies that a BridgeSupport metadata document should be generated from
    # the headers of all installed Pods.
    #
    # @note     This is for scripting languages such as MacRuby, Nu, and
    #           JSCocoa, which use it to bridge types, functions, etc better.
    #
    # @return   [void]
    #
    def generate_bridge_support!
      @generate_bridge_support = true
    end

    # Specifies that the -fobjc-arc flag should be added to the OTHER_LD_FLAGS.
    #
    # @note     This is used as a workaround for a compiler bug with non-ARC
    #           projects (see #142). This was originally done automatically
    #           but libtool as of Xcode 4.3.2 no longer seems to support the
    #           -fobjc-arc flag. Therefore it now has to be enabled explicitly
    #           using this method.
    #
    # @note     This may be removed in a future release.
    #
    # @return   [void]
    #
    def set_arc_compatibility_flag!
      @set_arc_compatibility_flag = true
    end

    #---------------------------------------------------------------------------#

    # @!group DSL - Target definitions

    # Specifies the platform for which a static library should be build.
    #
    # @param    [Symbol] name
    #           the name of platform, can be either `:osx` for OS X or `:ios`
    #           for iOS.
    #
    # @param    [String, Version] target
    #           The optional deployment.  If not provided a default value
    #           according to the platform name will be assigned.
    #
    # @note     If the deployment target requires it (iOS < 4.3), armv6 will be
    #           added to ARCHS.
    #
    # @example  Specifying the platform
    #
    #           platform :ios, "4.0"
    #           platform :ios
    #
    # @return   [void]
    #
    def platform(name, target = nil)
      unless [:ios, :osx].include?(name)
        raise "Unsupported platform `#{name}`. Platform must be `:ios` or `:osx`."
      end

      # Support for deprecated options parameter
      target = target[:deployment_target] if target.is_a?(Hash)

      unless target
        target = (name == :ios ? '4.3' : '10.6')
      end
      @target_definition.platform = Platform.new(name, target)
    end

    # Specifies the Xcode project that contains the target that the Pods library
    # should be linked with.
    #
    # @param    [String] path
    #           the path of the project to link with
    #
    # @param    [Hash{String => symbol}] build_configurations
    #           a hash where the keys are the name of the build configurations
    #           and the values a symbol that represents their type (`:debug` or
    #           `:release`).
    #
    # @note     If no explicit project is specified, it will use the Xcode
    #           project of the parent target. If none of the target definitions
    #           specify an explicit project and there is only **one** project
    #           in the same directory as the Podfile then that project will be
    #           used.
    #
    # @example  Specifying the user project
    #
    #           # Look for target to link with in an Xcode project called
    #           # ‘MyProject.xcodeproj’.
    #           xcodeproj 'MyProject'
    #
    #           target :test do
    #             # This Pods library links with a target in another project.
    #             xcodeproj 'TestProject'
    #           end
    #
    # @return   [void]
    #
    def xcodeproj(path, build_configurations = {})
      path = File.extname(path) == '.xcodeproj' ? path : "#{path}.xcodeproj"
      @target_definition.user_project_path = path
      @target_definition.build_configurations = build_configurations
    end

    # Specifies the target(s) in the user’s project that this Pods library
    # should be linked in.
    #
    # @param    [String, Array<String>] targets
    #           the target or the targets to link with.
    #
    # @note     If no explicit target is specified, then the Pods target will
    #           be linked with the first target in your project. So if you only
    #           have one target you do not need to specify the target to link
    #           with.
    #
    # @example  Link with an user project target
    #
    #           link_with 'MyApp'
    #
    # @example  Link with a more user project targets
    #
    #           link_with ['MyApp', 'MyOtherApp']
    #
    # @return   [void]
    #
    def link_with(targets)
      targets = [targets] unless targets.is_a?(Array)
      @target_definition.link_with = targets
    end

    # Inhibits **all** the warnings from the CocoaPods libraries.
    #
    # @note this attribute is inherited by child target definitions.
    #
    # @return   [void]
    #
    def inhibit_all_warnings!
      @target_definition.inhibit_all_warnings = true
    end

    # Use the dependencies of a Pod defined in the given podspec file.
    #
    # @param    [Hash {Symbol=>String}] options
    #           the path where to load the {Specification}. If not provided the
    #           first podspec in the directory of the podfile is used.
    #
    # @option   options [String] :path
    #           the path of the podspec file
    #
    # @option   options [String] :name
    #
    # @note     This method requires that the Podfile has a non nil value for
    #           {#defined_in_file} unless the path option is used.
    #
    # @return   [void]
    #
    def podspec(options = nil)
      if options && path = options[:path]
        path = File.extname(path) == '.podspec' ? path : "#{path}.podspec"
        file = Pathname.new(File.expand_path(path))
      elsif options && name = options[:name]
        name = File.extname(name) == '.podspec' ? name : "#{name}.podspec"
        file = defined_in_file.dirname + name
      else
        file = Pathname.glob(defined_in_file.dirname + '*.podspec').first
      end

      spec = Specification.from_file(file)
      spec.activate_platform(@target_definition.platform)
      all_specs = spec.recursive_subspecs.push(spec)
      deps = all_specs.map {|specification| specification.external_dependencies }
      deps = deps.flatten.uniq
      @target_definition.target_dependencies.concat(deps)
    end

    # Specifies a dependency of the project.
    #
    # A dependency requirement is defined by the name of the Pod and _optionally_
    # a list of version requirements.
    #
    # @example    Defining a dependency
    #
    #             pod 'SSZipArchive'
    #
    # @overload   pod(name, requirements)
    #
    #   @param    [String] name
    #             the name of the Pod.
    #
    #   @param    [Array] requirements
    #             an array specifying the version requirements of the
    #             dependency.
    #
    #   @example  Initialization with version requirements.
    #
    #             pod 'Objection', '>  0.9'
    #             pod 'Objection', '~> 0.9'
    #             pod 'Objection', '>= 0.5', '< 0.9'
    #
    # @overload   pod(name, external_source)
    #
    #   @param    [String] name
    #             the name of the Pod.
    #
    #   @param    [Hash] external_source
    #             a hash describing the external source.
    #
    #   @example  Initialization with an external source.
    #
    #             pod 'TTTFormatterKit', :git => 'https://github.com/gowalla/AFNetworking.git'
    #             pod 'TTTFormatterKit', :git => 'https://github.com/gowalla/AFNetworking.git', :commit => '082f8319af'
    #             pod 'JSONKit', :podspec => 'https://raw.github.com/gist/1346394/1d26570f68ca27377a27430c65841a0880395d72/JSONKit.podspec'
    #             pod 'JSONKit', :local => 'path/to/JSONKit'
    #
    #   @note     External sources (except `:podspec`) require a podspec in the
    #             root of the library.
    #
    # @overload   initialize(name, is_head)
    #
    #   @param    [String] name
    #             the name of the Pod.
    #
    #   @param    [Symbol] is_head
    #             a symbol that can be `:head` or nil.
    #
    #   @example  Initialization with the head option
    #
    #             pod 'TTTFormatterKit', :head
    #
    # @note       This method allow a nil name and the raises to be more
    #             informative.
    #
    # @note       Support for inline podspecs has been deprecated.
    #
    # @return     [void]
    #
    def pod(name = nil, *requirements, &block)
      if block
        raise "Inline specifications are deprecated. Please store the specification in a `podspec` file."
      end

      unless name
        raise "A dependency requires a name."
      end

      @target_definition.target_dependencies << Dependency.new(name, *requirements)
    end

    # @deprecated Deprecated in favour of the more succinct {#pod}
    #
    # @see        pod
    #
    # @todo       Remove for CocoaPods 1.0.
    #
    # @return     [void]
    #
    def dependency(name = nil, *requirements, &block)
      warn "[DEPRECATED] `dependency' is deprecated (use `pod')"
      pod(name, *requirements, &block)
    end

  end
end
