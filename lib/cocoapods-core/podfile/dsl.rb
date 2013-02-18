module Pod
  class Podfile

    # The of the methods defined in this file and the order of the methods is
    # relevant for the documentation generated on CocoaPods/cocoapods.github.com.

    # The Podfile is a specification that describes the dependencies of the
    # targets of one or more Xcode projects. The Podfile always creates an
    # implicit target, named `default`, which links to the first target of the
    # user project.
    #
    # A podfile can be very simple:
    #
    #     pod 'AFNetworking', '~> 1.0'
    #
    # An example of a more complex podfile can be:
    #
    #     platform :ios, '6.0'
    #     inhibit_all_warnings!
    #
    #     xcodeproj `MyProject`
    #
    #     pod 'ObjectiveSugar', '~> 0.5'
    #
    #     target :test do
    #       pod 'OCMock', '~> 2.0.1'
    #     end
    #
    #     post_install do |installer|
    #       installer.project.targets.each do |target|
    #         puts "#{target.name}"
    #       end
    #     end
    #
    module DSL

      # @!group Dependencies
      #   The Podfile specifies the dependencies of each user target.

      #-----------------------------------------------------------------------#

      # Specifies a dependency of the project.
      #
      # A dependency requirement is defined by the name of the Pod and
      # optionally a list of version requirements.
      #
      # ------
      #
      # When starting out with a project it is likely that you will want to use
      # the latest version of a Pod. If this is the case, simply omit the
      # version requirements.
      #
      #     pod 'SSZipArchive'
      #
      #
      # Later on in the project you may want to freeze to a specific version of
      # a Pod, in which case you can specify that version number.
      #
      #     pod 'Objection', '0.9'
      #
      #
      # Besides no version, or a specific one, it is also possible to use
      # operators:
      #
      # * `> 0.1`    Any version higher than 0.1
      # * `>= 0.1`   Version 0.1 and any higher version
      # * `< 0.1`    Any version lower than 0.1
      # * `<= 0.1`   Version 0.1 and any lower version
      # * `~> 0.1.2` Version 0.1.2 and the versions up to 0.2, not including 0.2
      #
      # A list of version requirements can be specified for even more fine
      # grained control.
      #
      # For more information, regarding versioning policy, see:
      #
      # * [Semantic Versioning](http://semver.org)
      # * [RubyGems Versioning Policies](http://docs.rubygems.org/read/chapter/7)
      #
      # Finally, instead of a version, you can specify the `:head` flag. This
      # will use the pod’s latest version spec version, but force the download
      # of the ‘bleeding edge’ version. Use this with caution, as the spec
      # might not be compatible anymore.
      #
      #     pod 'Objection', :head
      #
      # ------
      #
      # Dependencies can be obtained also from external sources.
      #
      # ### From a podspec in the root of a library repo.
      #
      # Sometimes you may want to use the bleeding edge version of a Pod. Or a
      # specific revision. If this is the case, you can specify that with your
      # pod declaration.
      #
      # To use the `master` branch of the repo:
      #
      #     pod 'AFNetworking', :git => 'https://github.com/gowalla/AFNetworking.git'
      #
      #
      # Or specify a commit:
      #
      #     pod 'AFNetworking', :git => 'https://github.com/gowalla/AFNetworking.git', :commit => '082f8319af'
      #
      #
      # Or specify a local folder in the machine:
      #
      #     pod 'AFNetworking', :local => '~/Documents/AFNetworking'
      #
      #
      # It is important to note, though, that this means that the version will
      # have to satisfy any other dependencies on the Pod by other Pods.
      #
      #
      # The `podspec` file is expected to be in the root of the repo, if this
      # library does not have a `podspec` file in its repo yet, you will have
      # to use one of the approaches outlined in the sections below.
      #
      #
      # ### From a podspec outside a spec repo, for a library without podspec.
      #
      # If a podspec is available from another source outside of the library’s
      # repo. Consider, for instance, a podspec available via HTTP:
      #
      #     pod 'JSONKit', :podspec => 'https://raw.github.com/gist/1346394/1d26570f68ca27377a27430c65841a0880395d72/JSONKit.podspec'
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
          raise StandardError, "Inline specifications are deprecated. Please store the specification in a `podspec` file."
        end

        unless name
          raise StandardError, "A dependency requires a name."
        end

        @target_definition.target_dependencies << Dependency.new(name, *requirements)
      end

      # Use the dependencies of a Pod defined in the given podspec file. If no
      # arguments are passed the first podspec in the root of the Podfile is
      # used. It is intended to be used by the project of a library.
      #
      # @example
      #   podspec
      #
      # @example
      #   podspec :name => 'QuickDialog'
      #
      # @example
      #   podspec :path => '/Documents/PrettyKit/PrettyKit.podspec'
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
        all_specs = [spec, *spec.recursive_subspecs]
        deps = all_specs.map{ |s| s.dependencies(@target_definition.platform) }
        deps = deps.flatten.uniq
        @target_definition.target_dependencies.concat(deps)
      end

      # Defines a new static library target and scopes dependencies defined from
      # the given block. The target will by default include the dependencies
      # defined outside of the block, unless the `:exclusive => true` option is
      # given.
      #
      # ---
      #
      # The Podfile creates a global target named `:default` which produces the
      # `libPods.a` file. This target is linked with the first target of user
      # project if not value is specified for the `link_with` attribute.
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
      #           target :ZipApp do
      #             pod 'SSZipArchive'
      #           end
      #
      # @example  Defining an exclusive target
      #
      #           target :ZipApp do
      #             pod 'SSZipArchive'
      #             target :test, :exclusive => true do
      #               pod 'JSONKit'
      #             end
      #           end
      #
      # @return   [void]
      #
      def target(name, options = {})
        parent = @target_definition
        @target_definitions[name] = @target_definition = TargetDefinition.new(name, parent, self, options)
        yield
      ensure
        @target_definition = parent
      end

      #---------------------------------------------------------------------------#

      # @!group Target configuration
      #   This group list the options to configure a target.

      #---------------------------------------------------------------------------#

      # Specifies the platform for which a static library should be build.
      #
      # -----
      #
      # CocoaPods provides a default deployment target if one is not specified.
      # The current default values are `4.3` for iOS and `10.6` for OS X.
      #
      # -----
      #
      # If the deployment target requires it (iOS < `4.3`), `armv6`
      # architecture will be added to `ARCHS`.
      #
      # @param    [Symbol] name
      #           the name of platform, can be either `:osx` for OS X or `:ios`
      #           for iOS.
      #
      # @param    [String, Version] target
      #           The optional deployment.  If not provided a default value
      #           according to the platform name will be assigned.
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
          raise StandardError, "Unsupported platform `#{name}`. Platform must be `:ios` or `:osx`."
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
      # -----
      #
      # If no explicit project is specified, it will use the Xcode project of
      # the parent target. If none of the target definitions specify an
      # explicit project and there is only **one** project in the same
      # directory as the Podfile then that project will be used.
      #
      # @param    [String] path
      #           the path of the project to link with
      #
      # @param    [Hash{String => symbol}] build_configurations
      #           a hash where the keys are the name of the build configurations
      #           in your Xcode project and the values are Symbols that specify
      #           if the configuration should be based on the `:debug` or
      #           `:release` configuration. If no explicit mapping is specified
      #           for a configuration in your project, it will default to
      #           `:release`.
      #
      # @example  Specifying the user project
      #
      #           # Look for target to link with in an Xcode project called
      #           # `MyProject.xcodeproj`.
      #           xcodeproj `MyProject`
      #
      #           target :test do
      #             # This Pods library links with a target in another project.
      #             xcodeproj `TestProject`
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
      # -----
      #
      # If no explicit target is specified, then the Pods target will be linked
      # with the first target in your project. So if you only have one target
      # you do not need to specify the target to link with.
      #
      # @param    [String, Array<String>] targets
      #           the target or the targets to link with.
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
      # ------
      #
      # This attribute is inherited by child target definitions.
      #
      def inhibit_all_warnings!
        @target_definition.inhibit_all_warnings = true
      end

      #---------------------------------------------------------------------------#

      # @!group Workspace
      #   This group list the options to configure workspace and to set global settings.

      #---------------------------------------------------------------------------#

      # Specifies the Xcode workspace that should contain all the projects.
      #
      # -----
      #
      # If no explicit Xcode workspace is specified and only **one** project
      # exists in the same directory as the Podfile, then the name of that
      # project is used as the workspace’s name.
      #
      # @param    [String] path
      #           path of the workspace.
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

      # Specifies that a BridgeSupport metadata document should be generated from
      # the headers of all installed Pods.
      #
      # -----
      #
      # This is for scripting languages such as [MacRuby](http://macruby.org),
      # [Nu](http://programming.nu/index), and
      # [JSCocoa](http://inexdo.com/JSCocoa), which use it to bridge types,
      # functions, etc.
      #
      # @return   [void]
      #
      def generate_bridge_support!
        @generate_bridge_support = true
      end

      # Specifies that the -fobjc-arc flag should be added to the `OTHER_LD_FLAGS`.
      #
      # -----
      #
      # This is used as a workaround for a compiler bug with non-ARC projects
      # (see #142). This was originally done automatically but libtool as of
      # Xcode 4.3.2 no longer seems to support the `-fobjc-arc` flag. Therefore
      # it now has to be enabled explicitly using this method.
      #
      # Support for this method might be dropped in CocoaPods `1.0`.
      #
      # @return   [void]
      #
      def set_arc_compatibility_flag!
        @set_arc_compatibility_flag = true
      end

      #---------------------------------------------------------------------------#

      # @!group Hooks
      #   The Podfile provides hooks that will be called during the
      #   installation process.
      #
      #   Hooks are __global__ and not stored per target definition.

      #---------------------------------------------------------------------------#

      # This hook allows you to make any changes to the Pods after they have been
      # downloaded but before they are installed.
      #
      # @example  Defining a pre install hook in a Podfile.
      #
      #           pre_install do |installer|
      #             # Do something fancy!
      #           end
      #
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
      # @return   [void]
      #
      def post_install(&block)
        @post_install_callback = block
      end
    end
  end
end

