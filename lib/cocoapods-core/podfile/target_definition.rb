module Pod
  class Podfile

    # The TargetDefinition stores the information of a CocoaPods static
    # library. The target definition can be linked with one or more targets of
    # the user project.
    #
    # Target definitions can be nested and by default inherit the dependencies
    # of the parent.
    #
    class TargetDefinition

      # @return [String, Symbol] the name of the target definition.
      #
      attr_reader :name

      # @return [TargetDefinition, Podfile] the parent target definition or the
      #         Podfile if the receiver is root.
      #
      attr_reader :parent

      # @param  [String, Symbol]
      #         name @see name
      #
      # @param  [TargetDefinition] parent
      #         @see parent
      #
      # @option options [Bool] :exclusive
      #         @see exclusive?
      #
      def initialize(name, parent, internal_hash = {})
        @name = name
        @parent = parent
        @internal_hash = internal_hash
        @children = []

        if parent.is_a?(TargetDefinition)
          parent.children << self
        end
      end

      # @return [Array<TargetDefinition>] the children target definitions.
      #
      attr_reader :children

      # @return [Array<TargetDefinition>] the targets definition descending
      #         from this one.
      #
      def recursive_children
        (children + children.map(&:recursive_children)).flatten
      end

      # @return [Bool] Whether the target definition is root.
      #
      def root?
        parent.is_a?(Podfile) || parent.nil?
      end

      # @return [TargetDefinition] The root target definition.
      #
      def root
        if root?
          self
        else
          parent.root
        end
      end

      # @return [Podfile] The podfile that contains the specification for this
      #         target definition.
      #
      def podfile
        root.parent
      end

      # @return [Array<Dependency>] The list of the dependencies of the target
      #         definition including the inherited ones.
      #
      def dependencies
        non_inherited_dependencies + ((exclusive? || parent.nil?) ? [] : parent.dependencies)
      end

      # @return [Array] The list of the dependencies of the target definition,
      #         excluding inherited ones.
      #
      def non_inherited_dependencies
        pod_dependencies.concat(podspec_dependencies)
      end

      # @return [Bool] Whether the target definition has at least one
      #         dependency, excluding inherited ones.
      #
      def empty?
        non_inherited_dependencies.empty?
      end

      # @return [String] The label of the target definition according to its
      #         name.
      #
      def label
        if root? && name == :default
          "Pods"
        elsif exclusive? || parent.nil?
          "Pods-#{name}"
        else
          "#{parent.label}-#{name}"
        end
      end

      # @return [String] A string representation suitable for UI.
      #
      def to_s
        "`#{label}` target definition"
      end

      # @return [String] A string representation suitable for debug.
      #
      def inspect
        "#<#{self.class} label=#{label}>"
      end

      #-----------------------------------------------------------------------#

      public

      # @!group Attributes

      # Returns whether the target definition should inherit the dependencies
      # of the parent.
      #
      # @note   A target is always `exclusive` if it is root.
      #
      # @note   A target is always `exclusive` if the `platform` does
      #         not match the parent's `platform`.
      #
      # @return [Bool] whether is exclusive.
      #
      def exclusive?
        if root?
          true
        else
          get_hash_value('exclusive') || ( platform && parent && parent.platform != platform )
        end
      end

      # Sets whether the target definition is exclusive.
      #
      # @param  [Bool] flag
      #         Whether the definition is exclusive.
      #
      # @return [void]
      #
      def exclusive=(flag)
        set_hash_value('exclusive', flag)
      end

      #--------------------------------------#

      # @return [Array<String>] the list of the names of the Xcode targets with
      #         which this target definition should be linked with.
      #
      def link_with
        get_hash_value('link_with')
      end

      # Sets the client targets that should be integrated by this definition.
      #
      # @param  [Array<String>] targets
      #         The list of the targets names.
      #
      # @return [void]
      #
      def link_with=(targets)
        set_hash_value('link_with', Array(targets).map(&:to_s))
      end

      #--------------------------------------#

      # @return [String] the path of the project this target definition should
      #         link with.
      #
      def user_project_path
        path = get_hash_value('user_project_path')
        if path
          File.extname(path) == '.xcodeproj' ? path : "#{path}.xcodeproj"
        else
          parent.user_project_path unless root?
        end
      end

      # Sets the path of the user project this target definition should link
      # with.
      #
      # @param  [String] path
      #         The path of the project.
      #
      # @return [void]
      #
      def user_project_path=(path)
        set_hash_value('user_project_path', path)
      end

      #--------------------------------------#

      # @return [Hash{String => symbol}] A hash where the keys are the name of
      #         the build configurations and the values a symbol that
      #         represents their type (`:debug` or `:release`).
      #
      def build_configurations
        get_hash_value('build_configurations') || (parent.build_configurations unless root?)
      end

      # Sets the build configurations for this target.
      #
      # @return [Hash{String => Symbol}] hash
      #         A hash where the keys are the name of the build configurations
      #         and the values the type.
      #
      # @return [void]
      #
      def build_configurations=(hash)
        set_hash_value('build_configurations', hash) unless hash.empty?
      end

      #--------------------------------------#

      # @return [Bool] whether the target definition should silence all the
      #         warnings with a compiler flag.
      #
      def inhibit_all_warnings?
        get_hash_value('inhibit_all_warnings') || (parent.inhibit_all_warnings? unless root?)
      end

      # Sets whether the target definition should inhibit the warnings during
      # compilation.
      #
      # @param  [Bool] flag
      #         Whether the warnings should be suppressed.
      #
      # @return [void]
      #
      def inhibit_all_warnings=(flag)
        set_hash_value('inhibit_all_warnings', flag)
      end

      #--------------------------------------#

      # @return [Platform] the platform of the target definition.
      #
      # @note   If no deployment target has been specified a default value is
      #         provided.
      #
      def platform
        name_or_hash = get_hash_value('platform')
        if name_or_hash
          if name_or_hash.is_a?(Hash)
            name = name_or_hash.keys.first.to_sym
            target = name_or_hash.values.first
          else
            name = name_or_hash.to_sym
          end
          target ||= (name == :ios ? '4.3' : '10.6')
          Platform.new(name, target)
        else
          parent.platform unless root?
        end
      end

      # Sets the platform of the target definition.
      #
      # @param  [Symbol] name
      #         The name of the platform.
      #
      # @param  [String] target
      #         The deployment target of the platform.
      #
      # @raise  When the name of the platform is unsupported.
      #
      # @return [void]
      #
      def set_platform(name, target = nil)
        unless [:ios, :osx].include?(name)
          raise StandardError, "Unsupported platform `#{name}`. Platform must be `:ios` or `:osx`."
        end

        if target
          value = {name.to_s => target}
        else
          value = name.to_s
        end
        set_hash_value('platform', value)
      end

      #--------------------------------------#

      # Stores the dependency for a Pod with the given name.
      #
      # @param  [String] name
      #         The name of the Pod
      #
      # @param  [Array<String, Hash>] requirements
      #         The requirements and the options of the dependency.
      #
      # @note   The dependencies are stored as an array. To simplify the YAML
      #         representation if they have requirements they are represented
      #         as a Hash, otherwise only the String of the name is added to
      #         the array.
      #
      # @todo   This needs urgently a rename.
      #
      # @return [void]
      #
      def store_pod(name, *requirements)
        if requirements && !requirements.empty?
          pod = { name => requirements }
        else
          pod = name
        end
        get_hash_value('dependencies', []) << pod
      end

      #--------------------------------------#

      # Stores the podspec whose dependencies should be included by the
      # target.
      #
      # @param  [Hash] options
      #         The options used to find the podspec (either by name or by
      #         path). If nil the podspec is auto-detected (i.e. the first one
      #         in the folder of the Podfile)
      #
      # @note   The storage of this information is optimized for YAML
      #         readability.
      #
      # @todo   This needs urgently a rename.
      #
      # @return [void]
      #
      def store_podspec(options = nil)
        if options
          unless options.keys.all? { |key| [:name, :path].include?(key) }
            raise StandardError, "Unrecognized options for the podspec method `#{options}`"
          end
          get_hash_value('podspecs', []) << options
        else
          get_hash_value('podspecs', []) << { :autodetect => true }
        end
      end

      #-----------------------------------------------------------------------#

      public

      # @!group Representations

      # @return [Array] The keys used by the hash representation of the
      #         target definition.
      #
      HASH_KEYS = [
        'platform',
        'podspecs',
        'exclusive',
        'link_with',
        'inhibit_all_warnings',
        'user_project_path',
        'build_configurations',
        'dependencies',
        'children'
      ].freeze

      # @return [Hash] The hash representation of the target definition.
      #
      def to_hash
        hash = internal_hash.dup
        unless children.empty?
          hash['children'] = Hash[children.map { |child| [child.name, child.to_hash] }]
        end
        hash
      end

      # Configures a new target definition from the given hash.
      #
      # @param  [Hash] the hash which contains the information of the
      #         Podfile.
      #
      # @return [TargetDefinition] the new target definition
      #
      def self.from_hash(name, hash, parent)
        internal_hash = hash.dup
        children_hashes = internal_hash.delete('children') || {}
        definition = TargetDefinition.new(name, parent, internal_hash)
        children_hashes.each do |child_name, child_hash|
          TargetDefinition.from_hash(child_name, child_hash, definition)
        end
        definition
      end

      #-----------------------------------------------------------------------#

      private

      # @!group Private helpers

      # @return [Array<TargetDefinition>]
      #
      attr_writer :children

      # @return [Hash] The hash which store the attributes of the target
      #         definition.
      #
      attr_accessor :internal_hash

      # Set a value in the internal hash of the target definition for the given
      # key.
      #
      # @param  [String] key
      #         The key for which to store the value.
      #
      # @param  [Object] value
      #         The value to store.
      #
      # @raise  If the key is not recognized.
      #
      # @return [void]
      #
      def set_hash_value(key, value)
        raise StandardError, "Unsupported hash key `#{key}`" unless HASH_KEYS.include?(key)
        internal_hash[key] = value
      end

      # Returns the value for the given key in the internal hash of the target
      # definition.
      #
      # @param  [String] key
      #         The key for which the value is needed.
      #
      # @param  [Object] base_value
      #         The value to set if they key is nil. Useful for collections.
      #
      # @raise  If the key is not recognized.
      #
      # @return [Object] The value for the key.
      #
      def get_hash_value(key, base_value = nil)
        raise StandardError, "Unsupported hash key `#{key}`" unless HASH_KEYS.include?(key)
        internal_hash[key] ||= base_value
      end

      # @return [Array<Dependency>] The dependencies specified by the user for
      #         this target definition.
      #
      def pod_dependencies
        pods = get_hash_value('dependencies') || []
        pods.map do |name_or_hash|
          if name_or_hash.is_a?(Hash)
            name = name_or_hash.keys.first
            requirements = name_or_hash.values.first
            Dependency.new(name, *requirements)
          else
            Dependency.new(name_or_hash)
          end
        end
      end

      # @return [Array<Dependency>] The dependencies inherited by the podspecs.
      #
      def podspec_dependencies
        podspecs = get_hash_value('podspecs') || []
        podspecs.map do |options|
          file = podspec_path_from_options(options)
          spec = Specification.from_file(file)
          all_specs = [spec, *spec.recursive_subspecs]
          all_specs.map{ |s| s.dependencies(platform) }

        end.flatten.uniq
      end

      # The path of the podspec with the given options.
      #
      # @param  [Hash] options
      #         The options to use for finding the podspec. The supported keys
      #         are: `:name`, `:path`, `:autodetect`.
      #
      # @return [Pathname] The path.
      #
      def podspec_path_from_options(options)
        if path = options[:path]
          path_with_ext = File.extname(path) == '.podspec' ? path : "#{path}.podspec"
          path_without_tilde = path_with_ext.gsub('~', ENV['HOME'])
          file = podfile.defined_in_file.dirname + path_without_tilde
        elsif name = options[:name]
          name = File.extname(name) == '.podspec' ? name : "#{name}.podspec"
          file = podfile.defined_in_file.dirname + name
        elsif options[:autodetect]
          file = Pathname.glob(podfile.defined_in_file.dirname + '*.podspec').first
        end
      end

      #-----------------------------------------------------------------------#

    end
  end
end
