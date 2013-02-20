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

      # @return [TargetDefinition] the parent target definition.
      #
      attr_reader :parent

      # @return [Array<TargetDefinition>]
      #
      attr_reader :children

      # @return [Podfile] the podfile that contains the specification for this
      # target definition.
      #
      attr_reader :podfile

      # @param  [String, Symbol]
      #         name @see name
      #
      # @param  [TargetDefinition] parent
      #         @see parent
      #
      # @option options [Bool] :exclusive
      #         @see exclusive?
      #
      def initialize(name, parent, podfile, options = {})
        @internal_hash = {}
        @name      = name
        @parent    = parent
        @podfile   = podfile
        @exclusive = options[:exclusive]
        @children = []
      end

      # @return [Bool]
      #
      def root?
        name == :default
        # parent.is_a?(Podfile)
      end

      #-----------------------------------------------------------------------#

      # @!group Attributes

      # @return [Array] the list of the dependencies of the target definition,
      #         excluding inherited ones.
      #
      def target_dependencies
        pod_dependencies.concat(podspec_dependencies)
      end

      # @return [Bool] whether the target definition has at least one
      #         dependency, excluding inherited ones.
      #
      def empty?
        target_dependencies.empty?
      end

      # @return [Array<Dependency>] the list of the dependencies of the target
      #         definition including the inherited ones.
      #
      def dependencies
        target_dependencies + ((exclusive? || parent.nil?) ? [] : parent.dependencies)
      end



      # @return [String] the label of the target definition according to its
      #         name.
      #
      def label
        if root?
          "Pods"
        elsif exclusive? || parent.nil?
          "Pods-#{name}"
        else
          "#{parent.label}-#{name}"
        end
      end

      # @return [String]
      #
      def to_s
        "`#{label}` target definition"
      end

      # @return [String]
      #
      def inspect
        "#<#{self.class} label=#{label}>"
      end

      #-----------------------------------------------------------------------#

      public

      # @!group Attributes

      # Sets if the target definition is exclusive.
      #
      attr_writer :exclusive

      # @return [Bool] whether the target definition should inherit the
      #         dependencies of the parent.
      #
      # @note   A target is automatically `exclusive` if the `platform` does
      #         not match the parent's `platform`.
      #
      def exclusive?
        @exclusive || ( platform && parent && parent.platform != platform )
      end

      def store_pod(name, requirements = nil)
        internal_hash['dependencies'] ||= []
        if requirements && !requirements.empty?
          internal_hash['dependencies'] << { name => requirements }
        else
          internal_hash['dependencies'] << name
        end
      end

      def store_podspec(options)
        internal_hash['Podspecs'] ||= []
        internal_hash['Podspecs'] << options || { :autodetect => true }
      end

      # @return [String] the path of the project this target definition should
      #         link with.
      #
      def user_project_path=(path)
        set_hash_value('user_project_path', path)
      end

      # Sets the path of the user project this target definition should link
      # with.
      #
      def user_project_path
        path = internal_hash['user_project_path'] || (parent.user_project_path if parent)
        if path
         File.extname(path) == '.xcodeproj' ? path : "#{path}.xcodeproj"
        end
      end

      def build_configurations=(hash)
        set_hash_value('build_configurations', hash) unless hash.empty?
      end

      # @return [Hash{String => symbol}] a hash where the keys are the name of
      #         the build configurations and the values a symbol that
      #         represents their type (`:debug` or `:release`).
      #
      def build_configurations
        internal_hash['build_configurations']
      end

      # @return [Array] the list of the names of the Xcode targets with which
      #         this target definition should be linked with.
      #
      def link_with
        internal_hash['link_with']
      end

      # @return [void]
      #
      def link_with=(targets)
        set_hash_value('link_with', Array(targets).map(&:to_s))
      end

      # @return [Bool] whether the target definition should silence all the
      #         warnings with a compiler flag.
      #
      def inhibit_all_warnings?
        internal_hash['inhibit_all_warnings'] || (parent.inhibit_all_warnings? if parent)
      end

      # Sets whether the target definition should inhibit the warnings during
      # compilation.
      #
      # @return [void]
      #
      def inhibit_all_warnings=(flag)
        set_hash_value('inhibit_all_warnings', flag)
      end

      # Sets the {Platform} of the target definition.
      #
      # @param [Symbol, Array] platform
      #
      def set_platform(name, target = nil)
        if target
          value = {name => target}
        else
          value = name
        end
        set_hash_value('platform', value)
      end

      # @return [Platform] the platform of the target definition.
      #
      def platform
        name_or_hash = get_hash_value('platform')
        if name_or_hash
          if name_or_hash.is_a?(Hash)
            name = name_or_hash.keys.first
            target = name_or_hash.values.first
          else
            name = name_or_hash
          end
          target ||= (name == :ios ? '4.3' : '10.6')
          unless [:ios, :osx].include?(name)
            raise StandardError, "Unsupported platform `#{name}`. Platform must be `:ios` or `:osx`."
          end
          Platform.new(name, target)
        else
          parent.platform if parent
        end
      end

      #-----------------------------------------------------------------------#

      public

      # @!group Representations

      # @return [Array] The keys used by the hash representation of the Podfile.
      #
      HASH_KEYS = [
        'platform',
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
          hash['children'] = children.map { |child| child.to_hash }
        end
        { name => hash }
      end

      # Configures a new target definition from the given hash.
      #
      # @param  [Hash] the hash which contains the information of the
      #         Podfile.
      #
      # @return [TargetDefinition] the new target definition
      #
      def self.from_hash(hash, parent, podfile)
        name = hash.keys.first
        data = hash.values.first
        definition = TargetDefinition.new(name, parent, podfile)
        internal_hash = data.dup
        children_hashes = internal_hash.delete('children')
        definition.send(:internal_hash=, internal_hash)
        if children_hashes
          children = children_hashes.map do |child_hash|
            TargetDefinition.from_hash(child_hash, definition, podfile)
          end
          definition.send(:children=, children)
        end
        definition
      end

      #-----------------------------------------------------------------------#

      private

      # @!group Private helpers

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
      # @raise  If the key is not recognized.
      #
      # @return [Object] The value for the key.
      #
      def get_hash_value(key)
        raise StandardError, "Unsupported hash key `#{key}`" unless HASH_KEYS.include?(key)
        internal_hash[key]
      end


      # @return [Array<TargetDefinition>]
      #
      attr_writer :children

      # @return [Array<Dependency>]
      #
      def pod_dependencies
        pods = internal_hash['dependencies']
        if pods
          pods.map do |name_or_hash|
            if name_or_hash.is_a?(Hash)
              name = name_or_hash.keys.first
              requirements = name_or_hash.values.first
              Dependency.new(name, *requirements)
            else
              Dependency.new(name_or_hash)
            end
          end
        else
          []
        end
      end

      # @return [Array<Dependency>]
      #
      def podspec_dependencies
        podspecs = internal_hash['Podspecs'] || []
        podspecs.map do |options|
          if options && path = options[:path]
            path_with_ext = File.extname(path) == '.podspec' ? path : "#{path}.podspec"
            path_without_tilde = path_with_ext.gsub('~', ENV['HOME'])
            file = podfile.defined_in_file.dirname + path_without_tilde
          elsif options && name = options[:name]
            name = File.extname(name) == '.podspec' ? name : "#{name}.podspec"
            file = podfile.defined_in_file.dirname + name
          elsif options.nil?
            file = Pathname.glob(podfile.defined_in_file.dirname + '*.podspec').first
          else
            raise StandardError, "Unrecognized options for the podspec method `#{options}`"
          end

          spec = Specification.from_file(file)
          all_specs = [spec, *spec.recursive_subspecs]
          deps = all_specs.map{ |s| s.dependencies(platform) }
          deps = deps.flatten.uniq
        end
      end

      #-----------------------------------------------------------------------#

    end
  end
end
