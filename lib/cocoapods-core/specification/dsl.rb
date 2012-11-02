module Pod

  # For readability the DSL is stored in this file.

  class Specification

    # !@group DSL: Root specification attributes

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
      :root_only      => false,
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
      :root_only      => false,
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
      :type           => [ String, Hash ],
      :is_required    => true,
      :multi_platform => false,
      :root_only      => false,
      :singularize    => true,
    }

    # @return [Hash] a hash containing the authors as the keys and their email
    #         address as the values.
    #
    def authors
      list = @authors.flatten
      unless list.first.is_a?(Hash)
        @authors = list.last.is_a?(Hash) ? list.pop : {}
        list.each { |name| @authors[name] = nil }
      end
      @authors || list.first
    end

    #------------------#

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
      :root_only      => false,
    }

    # @return [Hash] a hash containing information about the license of the
    #         Pod.
    #
    def license
      license = ( @license.kind_of? String ) ? { :type => @license } : @license
      license[:text] = license[:text].strip_heredoc if license[:text]
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
      :root_only      => false,
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
      :type           => String,
      :keys           => SOURCE_KEYS,
      :is_required    => true,
      :root_only      => false,
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
      :root_only      => false,
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
      :root_only      => false,
    }

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
      :root_only      => false,
      :multi_platform => false,
    }

    #---------------------------------------------------------------------------#

    # !@group DSL: Platform attributes

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
    # @param  [Symbol] name
    #         The name of the platform, either `:ios` or `:osx`.
    #
    # @param  [String] deployment_target
    #         The deployment target of platform.
    #
    def platform=(name, deployment_target = nil)
      unless PLATFORMS.include?(name)
        raise StandardError, "Unsupported platform `#{name}` the available values are `#{PLATFORMS}`"
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

    # @return [Array<Platform>] the platforms where the module of code
    #         described by the specification is supported on.
    #
    # @note   If no platform is specified this method returns all the known
    #         platforms.
    #
    def available_platforms
      if platform
        [ platform ]
      else
        PLATFORMS.map { |name| Platform.new(name, deployment_target[name]) }
      end
    end

    #---------------------------------------------------------------------------#

    # !@group DSL: Regular attributes

    # TODO
    attr_accessor :preferred_dependency

    #---------------------------------------------------------------------------#

    # !@group DSL: File patterns attributes

    def self.pattern_list(patterns)
      if patterns.is_a?(Array) && (!defined?(Rake) || !patterns.is_a?(Rake::FileList))
        patterns
      else
        [patterns]
      end
    end

    def pattern_list(patterns)
      if patterns.is_a?(Array) && (!defined?(Rake) || !patterns.is_a?(Rake::FileList))
        patterns
      else
        [patterns]
      end
    end

    #------------------#

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
      :inheritance => :merge,
      :type        => String,
      # :default     => 'Classes/**/*.{h,m}',
    }

    def set_source_files(pattern)
      @source_files = pattern_list(pattern)
    end

    #------------------#

    # @!method exclude_source_files=(exclude_source_files)
    #
    #   The pattern to ignore source files.
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
    #   @return [Array<String>, FileList]
    #
    attribute :exclude_source_files, {
      :inheritance => :merge,
      :type        => String,
      # :description          => 'A patter of files that should be excluded from the source files.',
      :example        => '"Classes/**/unused.{h,m}"',
      # :ios_default    => 'Classes/osx',
      # :osx_default    => 'Classes/ios',
      :multi_platform => true,
    }

    def set_exclude_source_files(pattern)
      @set_exclude_source_files = pattern_list(pattern)
    end

    #------------------#

    attribute :public_header_files, {
      :inheritance          => :merge,
      :type                 => String,
      # :description          => 'A pattern of files that should be used as public headers.',
      :example              => '"Classes/{public_header,other_public_header}.h"',
      :multi_platform       => true,
    }

    def set_public_header_files(pattern)
      @public_header_files = pattern_list(pattern)
    end

    #------------------#

    # @todo allow for subspecs?
    #
    pltf_chained_attr_accessor  :resources,                   lambda {|value, current| pattern_list(value) }
    pltf_chained_attr_accessor  :preserve_paths,              lambda {|value, current| pattern_list(value) } # Paths that should not be cleaned
    pltf_chained_attr_accessor  :exclude_header_search_paths, lambda {|value, current| pattern_list(value) } # Headers to be excluded from being added to search paths (RestKit)
    pltf_chained_attr_accessor  :frameworks,                  lambda {|value, current| (current << value).flatten }
    pltf_chained_attr_accessor  :weak_frameworks,             lambda {|value, current| (current << value).flatten }
    pltf_chained_attr_accessor  :libraries,                   lambda {|value, current| (current << value).flatten }

    alias_method :resource=,        :resources=
    alias_method :preserve_path=,   :preserve_paths=
    alias_method :framework=,       :frameworks=
    alias_method :weak_framework=,  :weak_frameworks=
    alias_method :library=,         :libraries=

    top_attr_accessor :prefix_header_file,  lambda { |file| Pathname.new(file) }
    top_attr_accessor :prefix_header_contents


    # @!method requires_arc=
    #
    # @abstract Wether the `-fobjc-arc' flag should be added to the compiler
    #   flags.
    #
    # @param [Bool] Wether the source files require ARC.
    #
    platform_attr_writer :requires_arc
    pltf_first_defined_attr_reader :requires_arc

    # @!method header_dir=
    #
    # @abstract The directory where to name space the headers files of
    #   the specification.
    #
    # @param [String] The headers directory.
    #
    platform_attr_writer           :header_dir, lambda { |dir, _| Pathname.new(dir) }
    pltf_first_defined_attr_reader :header_dir

    # If not provided the headers files are flattened
    #
    platform_attr_writer           :header_mappings_dir, lambda { |file, _| Pathname.new(file) }
    pltf_first_defined_attr_reader :header_mappings_dir

    # @!method xcconfig=
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

    attribute :dependency, {
      :inheritance          => :merge,
      :type                 => [ String, Array ],
      :multi_platform       => true,
    }

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

    # !@group Hooks

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

    # !@group Subspecs

    #
    #
    def subspec(name, &block)
      subspec = Specification.new(self, name, &block)
      @subspecs << subspec
      subspec
    end

    #
    #
    attr_reader :subspecs

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


