module Pod

  # For readability the DSL is stored in this file.

  class Specification

    # @!group DSL: Root specification attributes
    #
    #   A ‘root’ specification is a specification that holds other
    #   ‘sub-specifications’.
    #
    #   These attributes can only be written to on the ‘root’ specification,
    #   **not** on the ‘sub-specifications’.
    #

    # @!method name=(name)
    #
    #   The name of the Pod.
    #
    #   @example
    #     'MyPod'
    #
    #   @param [String] name
    #
    attribute :name, {
      :type           => String,
      :is_required    => true,
      :multi_platform => false,
      :root_only      => true,
    }

    # @return [String] the name of the specification including the names of the
    #         parents for subspecs.
    #
    def name
      @parent ? "#{@parent.name}/#{@name}" : @name
    end

    #------------------#

    # @!method version=(version)
    #
    #   The version of the Pod (see [Semver](http://semver.org)).
    #
    #   @example
    #     '0.0.1'
    #
    #   @param [String] version
    #
    attribute :version, {
      :type           => String,
      :is_required    => true,
      :multi_platform => false,
      :root_only      => true,
    }

    # @return [Version] the version of the Pod.
    #
    def version
      Version.new(@version)
    end

    #------------------#

    # @!method authors=(authors)
    #
    #   The email and the name of the authors of the library.
    #
    #   @example
    #     'Darth Vader'
    #
    #   @example
    #     'Darth Vader', 'Wookiee'
    #
    #   @example
    #     { 'Darth Vader' => 'darthvader@darkside.com',
    #       'Wookiee' => 'wookiee@aggrrttaaggrrt.com' }
    #
    #   @param [String, Hash{String=>String}] authors
    #
    attribute :authors, {
      :type           => [ String, Array, Hash ],
      :is_required    => true,
      :multi_platform => false,
      :root_only      => true,
      :singularize    => true,
    }

    # @return [Hash] a hash containing the authors as the keys and their email
    #         address as the values.
    #
    def authors
      if @authors.is_a?(Hash)
        @authors
      elsif @authors.is_a?(Array)
        result = {}
        @authors.each { |name| result[name] = nil }
        result
      elsif @authors.is_a?(String)
        { @authors => nil }
      end
    end

    #------------------#

    # The keys accepted by the license attribute.
    #
    LICENSE_KEYS = [ :type, :file, :text ]

    # @!method license=(license)
    #
    #   The license of the Pod, unless the source contains a file named
    #   `LICENSE.*` or `LICENCE.*` the path of the file containing the license
    #   or the text of the license should be specified.
    #
    #   @example
    #     'MIT'
    #
    #   @example
    #     { :type => 'MIT', :file => 'MIT-LICENSE.txt' }
    #
    #   @example
    #     { :type => 'MIT', :text => <<-LICENSE
    #         Copyright 2012
    #         Permission is granted to...
    #       LICENSE
    #     }
    #
    #   @param [String, Hash{Symbol=>String}] license
    #
    attribute :license, {
      :type           => [ String, Hash ],
      :keys           => LICENSE_KEYS,
      :is_required    => true,
      :multi_platform => false,
      :root_only      => true,
    }

    # @return [Hash] a hash containing information about the license of the
    #         Pod.
    #
    def license
      license = ( @license.kind_of? String ) ? { :type => @license } : @license
      license[:text] = license[:text].strip_heredoc.gsub(/\n$/, '') if license[:text]
      license
    end

    #------------------#

    # @!method homepage=(homepage)
    #
    #   The URL of the homepage of the Pod.
    #
    #   @example
    #     'www.example.com'
    #
    #   @param  [String] homepage
    #
    # @!method homepage
    #
    #   @return [String] a string containing the URL of the homepage of the Pod.
    #
    attribute :homepage, {
      :type           => String,
      :is_required    => true,
      :multi_platform => false,
      :root_only      => true,
    }

    #------------------#

    # The keys accepted by the hash of the source attribute.
    #
    SOURCE_KEYS = {
      :git  => [:tag, :branch, :commit, :submodules],
      :svn  => [:folder, :tag, :revision],
      :hg   => [:revision],
      :http => nil
    }

    # @!method source=(source)
    #
    #   The location from where the library should be retrieved.
    #
    #   @example
    #     :git => www.example.com/repo.git
    #
    #   @example
    #     :git => www.example.com/repo.git, :tag => 'v0.0.1'
    #
    #   @example
    #     :git => www.example.com/repo.git, :tag => "v#{s.version}"
    #
    #   @param  [Hash{Symbol=>String}] source
    #
    # @!method source
    #
    #   @return [Hash{Symbol=>String}]
    #
    attribute :source, {
      :type           => Hash,
      :keys           => SOURCE_KEYS,
      :is_required    => true,
      :root_only      => true,
      :multi_platform => false,
    }

    #------------------#

    # @!method summary=(summary)
    #
    #   A short description (max 140 characters).
    #
    #   @example
    #     'A library that computes the meaning of life.'
    #
    #   @param  [String] summary
    #
    # @!method summary
    #
    #   @return [String] a short description for the library.
    #
    attribute :summary, {
      :type           => String,
      :is_required    => true,
      :multi_platform => false,
      :root_only      => true,
    }

    #------------------#

    # @!method description=(description)
    #
    #   An optional longer description that can be used in place of the summary.
    #
    #   @example
    #     <<-DESC
    #       A library that computes the meaning of life. Features:
    #       1. Is self aware
    #       ...
    #       42. Likes candies.
    #     DESC
    #
    #   @param  [String] description
    #
    # @!method description
    #
    #   @return [String] a short description for the library.
    #
    attribute :description, {
      :type           => String,
      :multi_platform => false,
      :root_only      => true,
    }

    def description
      @description.strip_heredoc
    end

    #------------------#

    # @!method documentation=(documentation)
    #
    #   Any additional option to pass to the
    #   [appledoc](http://gentlebytes.com/appledoc/) tool.
    #
    #   @example
    #     :appledoc => ['--no-repeat-first-par',
    #                   '--no-warn-invalid-crossref']
    #
    #   @param  [Hash{Symbol=>Array<String>}] documentation
    #
    # @!method documentation
    #
    #   @return [Hash{Symbol=>Array<String>}]
    #
    attribute :documentation, {
      :type           => Hash,
      :root_only      => true,
      :multi_platform => false,
    }

    #---------------------------------------------------------------------------#

    # @!group DSL: Platform attributes

    # The name of the platforms supported by the specification class.
    #
    PLATFORMS = [:osx, :ios].freeze

    # @!method platform
    #
    #   @return [Platform] the platform of the specification.
    #
    attribute :platform, {
      :type           => Array,
      :inheritance    => :first_defined,
      :multi_platform => false,
    }

    # The platform where this specification is supported.
    #
    # @example
    #   :ios
    #
    # @example
    #   :osx
    #
    # @example
    #   :osx, "10.8"
    #
    # @param  [Array<Symbol, String>] name_and_deployment_target
    #         A tuple where the first value is the name of the platform,
    #         (either `:ios` or `:osx`) and the second is deployment target.
    #
    def platform=(name_and_deployment_target)
      name = name_and_deployment_target.first
      deployment_target = name_and_deployment_target.last
      unless PLATFORMS.include?(name)
        raise StandardError, "Unsupported platform `#{name}` the available names are `#{PLATFORMS}`"
      end
      @platform = Platform.new(name, deployment_target)
    end

    # @!method deployment_target
    #
    #   @return [String] the deployment target of each platform.
    #
    attribute :deployment_target, {
      :type        => String,
      :inheritance => :first_defined,
      :initial_value => nil,
    }

    # The deployment targets for the platforms of the specification.
    #
    # @example  iOS
    #           "6.0"
    #
    # @example  OS X
    #           "10.8"
    #
    # @param    [String] version
    #           The deployment target of the platform.
    #
    # @raise    If the there is an attempt to set the deployment target for
    #           more than one platform.
    #
    def deployment_target=(version)
      unless @define_for_platforms.count == 1
        raise StandardError, "The deployment target must be defined per platform like `s.ios.deployment_target = '5.0'`."
      end
      @deployment_target[@define_for_platforms.first] = version
    end

    # @return [Hash{Symbol=>String}] the deployment targets for each available
    #         platform.
    #
    # @note   If a platform is specified for the subspec it takes the
    #         precedence over any other values. If not platform is specified,
    #         first is checked if any deployment target is specified by the
    #         spec, and if needed the call is forwarded to the parent.
    #
    def deployment_targets
      targets = { @platform.name => @platform.deployment_target } if @platform && @platform.deployment_target
      targets ||= @deployment_target unless @deployment_target == { :osx=>nil, :ios=>nil }
      targets || (parent.deployment_targets if parent) || {}
    end

    # @return [Array<Platform>] the platforms where the module of code
    #         described by the specification is supported on.
    #
    # @note   If no platform is specified this method returns all the known
    #         platforms.
    #
    def available_platforms
      names = platform ? [ platform.name ] : PLATFORMS
      names.map { |name| Platform.new(name, deployment_targets[name]) }
    end

    #---------------------------------------------------------------------------#

    # @!group DSL: Regular attributes


    # A list of frameworks that the client application needs to link against.
    #
    attribute :frameworks, {
      :inheritance => :merge,
      :singularize => true
    }

    #------------------#

    # A list of frameworks that the client application needs to weakly link against.
    #
    attribute :weak_frameworks, {
      :inheritance => :merge,
      :singularize => true
    }

    #------------------#

    # A list of libraries that the client application needs to link against.
    #
    attribute :libraries, {
      :inheritance => :merge,
      :singularize => true
    }

    #------------------#

    # @!method xcconfig=
    #
    # Any flag to add to final xcconfig file.
    #
    platform_attr_writer :xcconfig, lambda {|value, current| current.tap { |c| c.merge!(value) } }
    pltf_first_defined_attr_reader :xcconfig

    # TODO: use meta-programming
    def xcconfig
      if @parent
        @parent.xcconfig.merge(@xcconfig[active_platform]) do |_, parent_val, self_val|
          parent_val + ' ' + self_val
        end
      else
        @xcconfig[active_platform]
      end
    end

    # TODO: This will be handled by the LocalPod
    #
    # def xcconfig
    #   result = raw_xconfig.dup
    #   result.libraries.merge(libraries)
    #   result.frameworks.merge(frameworks)
    #   result.weak_frameworks.merge(weak_frameworks)
    #   result
    # end

    def recursive_compiler_flags
      @parent ? @parent.recursive_compiler_flags | @compiler_flags[active_platform] : @compiler_flags[active_platform]
    end

    def compiler_flags
      flags = recursive_compiler_flags.dup
      flags << '-fobjc-arc' if requires_arc
      flags.join(' ')
    end

    platform_attr_writer :compiler_flags, lambda {|value, current| current << value }

    #------------------#

    # TODO allow for subspecs
    top_attr_accessor :prefix_header_file,  lambda { |file| Pathname.new(file) }
    top_attr_accessor :prefix_header_contents

    #------------------#

    # @!method requires_arc=
    #
    # @abstract Wether the `-fobjc-arc' flag should be added to the compiler
    #   flags.
    #
    # @param [Bool] Wether the source files require ARC.
    #
    platform_attr_writer :requires_arc
    pltf_first_defined_attr_reader :requires_arc

    #------------------#

    # @!method header_dir=
    #
    # @abstract The directory where to name space the headers files of
    #   the specification.
    #
    # @param [String] The headers directory.
    #
    platform_attr_writer           :header_dir, lambda { |dir, _| Pathname.new(dir) }
    pltf_first_defined_attr_reader :header_dir

    #------------------#

    # If not provided the headers files are flattened
    #
    platform_attr_writer           :header_mappings_dir, lambda { |file, _| Pathname.new(file) }
    pltf_first_defined_attr_reader :header_mappings_dir

    #---------------------------------------------------------------------------#

    # @!group DSL: File pattern attributes

    # @!method source_files=(source_files)
    #
    #   The source files of the specification.
    #
    #   @example
    #     "Classes/**/*.{h,m}"
    #
    #   @example
    #     "Classes/**/*.{h,m}", "More_Classes/**/*.{h,m}"
    #
    #   @param  [String, Array<String>] source_files
    #
    # @!method source_files
    #
    #   @return [Array<String>, FileList]
    #
    attribute :source_files, {
      :file_patterns => true,
      :default_value => 'Classes/**/*.{h,m}',
    }

    #------------------#

    # @!method exclude_source_files=(exclude_source_files)
    #
    #   A pattern of files that should be excluded from the source files.
    #
    #   @example iOS
    #     "Classes/osx"
    #
    #   @example
    #     "Classes/**/unused.{h,m}"
    #
    #   @param  [String, Array<String>] exclude_source_files
    #
    # @!method exclude_source_files
    #
    #   @return [Array<String>, Rake::FileList]
    #
    attribute :exclude_source_files, {
      :file_patterns => true,
      :ios_default   => 'Classes/osx',
      :osx_default   => 'Classes/ios',
    }

    #------------------#

    # @!method public_header_files=(public_header_files)
    #
    #   A pattern of files that should be used as public headers.
    #
    #   @example
    #     "Resources/*.png"
    #
    #   @param  [String, Array<String>] public_header_files
    #
    # @!method public_header_files
    #
    #   @return [Array<String>, FileList]
    #
    attribute :public_header_files, {
      :file_patterns => true,
    }

    #------------------#

    # @!method resources=(resources)
    #
    #   A list of resources. These are copied into the target bundle with a
    #   build phase script.
    #
    #   @example
    #     "Resources/*.png"
    #
    #   @param  [String, Array<String>] resources
    #
    # @!method resources
    #
    #   @return [Array<String>, FileList]
    #
    attribute :resources, {
      :file_patterns => true,
      :default_value => 'Resources/**/*',
      :singularize   => true
    }

    #------------------#

    # @!method preserve_paths=(preserve_paths)
    #
    #   Any file that should not be cleaned (CocoaPods cleans all the unused
    #   files by default).
    #
    #   @example
    #     "IMPORTANT.txt"
    #
    #   @param  [String, Array<String>] preserve_paths
    #
    # @!method preserve_paths
    #
    #   @return [Array<String>, FileList]
    #
    attribute :preserve_paths, {
      :file_patterns => true,
      :singularize   => true
    }

    #------------------#

    # Headers that should not be visible to the Pods project.
    #
    # TODO: should this be called exclude headers?
    #
    attribute :exclude_header_search_paths, {
      :file_patterns => true,
    }

    #---------------------------------------------------------------------------#

    # @!group DSL: Hooks

    # TODO: hooks should appear in the documentation as well.

    # This method takes a header path and returns the location it should have
    # in the pod's header dir.
    #
    # By default all headers are copied to the pod's header dir without any
    # namespacing. However if the top level attribute accessor header_mappings_dir
    # is specified the namespacing will be preserved from that directory.
    #
    def copy_header_mapping(from)
      header_mappings_dir ? from.relative_path_from(header_mappings_dir) : from.basename
    end

    # This is a convenience method which gets called after all pods have been
    # downloaded but before they have been installed, and the Xcode project and
    # related files have been generated. (It receives the Pod::LocalPod
    # instance generated form the specification and the #
    # Pod::Podfile::TargetDefinition instance for the current target.) Override
    # this to, for instance, to run any build script:
    #
    # @example
    #
    #   Pod::Spec.new do |s|
    #     def s.pre_install(pod, target_definition)
    #       Dir.chdir(pod.root){ `sh make.sh` }
    #     end
    #   end
    #
    def pre_install(pod, target_definition)
      FALSE
    end

    # This is a convenience method which gets called after all pods have been
    # downloaded, installed, and the Xcode project and related files have been
    # generated. (It receives the Pod::Installer::TargetInstaller instance for
    # the current target.) Override this to, for instance, add to the prefix
    # header:
    #
    # @example
    #
    #   Pod::Spec.new do |s|
    #     def s.post_install(target_installer)
    #       prefix_header = config.project_pods_root + target_installer.prefix_header_filename
    #       prefix_header.open('a') do |file|
    #         file.puts(%{#ifdef __OBJC__\n#import "SSToolkitDefines.h"\n#endif})
    #       end
    #     end
    #   end
    #
    def post_install(target_installer)
      FALSE
    end

    #---------------------------------------------------------------------------#

    # @!group DSL: Dependencies & Subspecs

    # @!method subspecs
    #
    #   @return [Array<Specification>] the list of the children subspecs of the
    #           Specification.
    #
    attribute :subspec, {
      :inheritance    => :merge,
      :type           => String,
      :writer_name    => :subspec,
      :reader_name    => :subspecs,
      :ivar_name      => "@subspecs"
    }

    # Specification for a module of the Pod. A specification automaically
    # iherits as a dependency all it children subspecs.
    #
    # Subspec also inherits values from their parents so common values for
    # attributes can be specified in the ancestors.
    #
    # @example
    #
    #   subspec "core" do |sp|
    #     sp.source_files = "Classes/Core"
    #   end
    #
    #   subspec "optional" do |sp|
    #     sp.source_files = "Classes/BloatedClassesThatNobodyUses"
    #   end
    #
    # @example
    #
    #   subspec "Subspec" do |sp|
    #     sp.subspec "resources" do |ssp|
    #     end
    #   end
    #
    def subspec(name, &block)
      subspec = Specification.new(self, name, &block)
      @subspecs << subspec
      subspec
    end

    # @!method preferred_dependency=(subspec_name)
    #
    #   The name of the subspec that should be used as preferred dependency.
    #   This is useful in case there are incompatible subspecs or a subspec
    #   provides components that are rarely used.
    #
    #   @example
    #     'Pod/default_subspec'
    #
    #   @param  [String] subspec_name
    #
    # @!method preferred_dependency
    #
    #   @return [String] the name of the subspec that should be inherited as
    #           dependency.
    #
    attribute :preferred_dependency, {
      :type => String,
      :initial_value => nil,
    }

    #------------------#

    # @!method dependency
    #
    attribute :dependency, {
      :inheritance    => :merge,
      :type           => [ String, Array ],
      :writer_name    => :dependency,
      :reader_name    => :dependencies,
      :ivar_name      => "@dependencies"
    }

    #
    #
    def dependency(*name_and_version_requirements)
      name, *version_requirements = name_and_version_requirements.flatten
      raise StandardError, "A specification can't require self as a subspec" if name == self.name
      raise StandardError, "A subspec can't require one of its parents specifications" if @parent && @parent.name.include?(name)
      dep = Dependency.new(name, *version_requirements)
      @define_for_platforms.each do |platform|
        @dependencies[platform] << dep
      end
      dep
    end

    #---------------------------------------------------------------------------#

    # @!group DSL: Multi-Platform support

    # Provides support for specifying iOS attributes.
    #
    # @return [PlatformProxy] the proxy that will set the attributes.
    #
    def ios
      PlatformProxy.new(self, :ios)
    end

    # Provides support for specifying OS X attributes.
    #
    # @return [PlatformProxy] the proxy that will set the attributes.
    #
    def osx
      PlatformProxy.new(self, :osx)
    end
  end
end


