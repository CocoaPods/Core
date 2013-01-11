require 'active_support/core_ext/string/strip.rb'

module Pod
  class Specification

    # Allows to conveniently access a Specification programmatically.
    #
    # It takes care of:
    #
    # - standardizing the attributes
    # - handling multi-platform values
    # - handle default values
    # - handle inherited values
    #
    # This class allows to store the values of the attributes in the
    # Specification as specified in the DSL. The benefits is reduced reliance
    # on meta programming to access the attributes and the possibility of
    # serializing a specification back exactly as defined in a file.
    #
    class Consumer

      # @return [Specification] The specification to consume.
      #
      attr_reader :spec

      # @return [Symbol] The platform for which the specification should be
      #         consumed.
      #
      attr_reader :consumer_platform

      # @param  [Specification] spec @see spec
      # @param  [Symbol] platform @see platform
      #
      def initialize(spec, platform)
        @spec = spec
        @consumer_platform = platform

        # unless spec.supported_on_platform?(platform)
        #   raise StandardError, "#{to_s} is not compatible with #{platform.to_s}."
        # end
      end

      # Creates a method to access the contents of the attribute.
      #
      # @param  [Symbol] name
      #         the name of the attribute.
      #
      # @macro  [attach]
      #         @!method $1
      #
      def self.spec_attr_accessor(name)
        define_method(name) do
          value_for_attribute(name)
        end
      end

      #-----------------------------------------------------------------------#

      # @!group Platform


      # TODO
      # @return [Platform] The platform of the specification.
      #
      def platform
        spec.platform
      end


      # TODO
      # @return [Version] The deployment target of each supported platform.
      #
      def deployment_target

      end

      #-----------------------------------------------------------------------#

      # @!group Regular attributes

      # @return [Bool] Whether the source files of the specification require to
      #         be compiled with ARC.
      #
      spec_attr_accessor :requires_arc
      alias_method :requires_arc?, :requires_arc

      # @return [Array<String>] A list of frameworks that the user’s target
      #         needs to link against
      #
      spec_attr_accessor :frameworks

      # @return [Array<String>] A list of frameworks that the user’s target
      #         needs to **weakly** link against
      #
      spec_attr_accessor :weak_frameworks

      # @return [Array<String>] A list of libraries that the user’s target
      #         needs to link against
      #
      spec_attr_accessor :libraries

      # @return [Array<String>] the list of compiler flags needed by the
      #         specification files.
      #
      spec_attr_accessor :compiler_flags

      # @return [Hash{String => String}] the xcconfig flags for the current
      #         specification.
      #
      spec_attr_accessor :xcconfig

      # @return [String] The contents of the prefix header.
      #
      spec_attr_accessor :prefix_header_contents

      # @return [String] The path of the prefix header file.
      #
      spec_attr_accessor :prefix_header_file

      # @return [String] the headers directory.
      #
      spec_attr_accessor :header_dir

      # @return [String] the directory from where to preserve the headers
      #         namespacing.
      #
      spec_attr_accessor :header_mappings_dir

      #-----------------------------------------------------------------------#

      # @!group File patterns

      # @return [Array<String>] the source files of the Pod.
      #
      spec_attr_accessor :source_files

      # @return [Array<String>] the public headers of the Pod.
      #
      spec_attr_accessor :public_header_files

      # @return [Array<String>] A hash where the key represents the
      #         paths of the resources to copy and the values the paths of
      #         the resources that should be copied.
      #
      spec_attr_accessor :resources

      # @return [Array<String>] The file patterns that the
      #         Pod should ignore.
      #
      spec_attr_accessor :exclude_files

      # @return [Array<String>] The paths that should be not
      #         cleaned.
      #
      spec_attr_accessor :preserve_paths

      #-----------------------------------------------------------------------#

      # @!group Dependencies

      # @return [Array<Dependency>] the dependencies on other Pods.
      #
      def dependencies
        value = value_for_attribute(:dependencies)
        value.map do |name, requirements|
          Dependency.new(name, requirements)
        end
      end

      #-----------------------------------------------------------------------#

      private

      # Returns the value for the attribute with the given name for the
      # specification. It takes into account inheritance, multi-platform
      # attributes and default values.
      #
      # @param  [Symbol] attr_name
      #         The name of the attribute.
      #
      # @return [String, Array, Hash] the value for the attribute.
      #
      def value_for_attribute(attr_name)
        attr = Specification::DSL.attributes[attr_name]
        value = value_with_inheritance(spec, attr)
        value || attr.default_value_for_platform(consumer_platform)
      end

      #
      #
      def value_with_inheritance(evaluated_spec, attr)
        value = raw_value_for_attribute(evaluated_spec, attr)
        if evaluated_spec.root? || !attr.inherited?
          return value
        end

        parent_value = value_with_inheritance(evaluated_spec.parent, attr)
        merge_values(attr, parent_value, value)
      end

      # @return [String, Array, Hash] The value for an attribute as stored in
      #         the specification taking into account the current platform.
      #
      def raw_value_for_attribute(spec, attr)
        value = spec.attributes_hash[attr.name]
        value = prepare_value(attr, value)
        if attr.multi_platform? && spec.attributes_hash[consumer_platform]
          platform_value = spec.attributes_hash[consumer_platform][attr.name]
          platform_value = prepare_value(attr, platform_value)
          value = merge_values(attr, value, platform_value)
        end
        value
      end

      # @return [String, Array, Hash] Merges two values of an attribute, either
      #         because the attribute is multi platform or because it is inherited.
      #
      def merge_values(attr, value, value_to_merge)
        return value unless value_to_merge
        return value_to_merge unless value

        if attr.container == Array
          value + value_to_merge
        elsif attr.container == Hash
          value = value.merge(value_to_merge) do |_, old, new|
            if new.is_a?(Array)
              old + new
            else
              old + ' ' + new
            end
          end
        else
          value
        end
      end

      # Wraps a value in an Array if needed and calls the prepare hook to
      # allow further customization of a value before storing it in the
      # instance variable.
      #
      # @note   Only array containers are wrapped. To automatically wrap
      #         values for attributes with hash containers a prepare hook
      #         should be used.
      #
      # @return [Object] the customized value of the original one if no
      #         prepare hook was defined.
      #
      def prepare_value(attr, value)
        return nil unless value
        if attr.container ==  Array
          value = [*value ]
        end

        hook_name = prepare_hook_name(attr)
        if self.respond_to?(hook_name, true)
          value = self.send(hook_name, value)
        else
          value
        end
      end

      #-----------------------------------------------------------------------#

      private

      # @return [String] the name of the prepare hook for this attribute.
      #
      # @note   The hook is called after the value has been wrapped in an
      #         array (if needed according to the container) but before
      #         validation.
      #
      def prepare_hook_name(attr)
        "_prepare_#{attr.name}"
      end

      # @!group Preparing Values
      #
      # Raw values need to be prepared as soon as they are read so they can be
      # safely merged to support multi platform attributes and inheritance

      #
      #
      def _prepare_prefix_header_contents(value)
        value.is_a?(Array) ? value * "\n" : value
      end

      #
      #
      def _prepare_resources(value)
        value = { :resources => value } unless value.is_a?(Hash)
        result = {}
        value.each do |key, patterns|
          patterns = [ patterns ] if patterns.is_a?(String)
          result[key] = patterns
        end
        result
      end

      #
      #
      def _prepare_deployment_target(deployment_target)
        unless @define_for_platforms.count == 1
          raise StandardError, "The deployment target must be defined per platform like `s.ios.deployment_target = '5.0'`."
        end
        Version.new(deployment_target)
      end

      #
      #
      def _prepare_platform(name_and_deployment_target)
        return nil if name_and_deployment_target.nil?
        if name_and_deployment_target.is_a?(Array)
          name = name_and_deployment_target.first
          deployment_target = name_and_deployment_target.last
        else
          name = name_and_deployment_target
          deployment_target = nil
        end
        unless PLATFORMS.include?(name)
          raise StandardError, "Unsupported platform `#{name}`. The available " \
            "names are `#{PLATFORMS.inspect}`"
        end
        Platform.new(name, deployment_target)
      end

      #-----------------------------------------------------------------------#

    end
  end
end
