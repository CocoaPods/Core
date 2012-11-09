module Pod
  class Specification
    module DSL

      # Checks that specification has been activated for platform as it is
      # necessary to read multi-platform attributes.
      #
      # @raise It the specification has not been activated for a platform.
      #
      def active_plaform_check
        raise StandardError, "#{self.inspect} not activated for a platform before consumption." unless active_platform
      end

      def transform_value_to_file_patterns(patterns)
        if patterns.is_a?(Array) && (!defined?(Rake) || !patterns.is_a?(Rake::FileList))
          patterns
        else
          [ patterns ]
        end
      end

      # A Specification attribute stores the information of an attribute. It also
      # provides logic to implement any required logic.
      #
      class Attribute

        require 'active_support/inflector/inflections'

        # @return [Symbol] the name of the attribute.
        #
        attr_reader :name

        # @param    [Symbol] name @see name
        #
        # @option  options [String] :description
        # @option  options [String] :type
        # @option  options [String] :required
        # @option  options [String] :root_only
        # @option  options [String] :multi_platform
        # @option  options [String] :singularize
        # @option  options [String] :inheritance
        # @option  options [String] :example
        # @option  options [String] :examples
        #
        def initialize(name, options)
          @name = name

          @types                = [ options.delete(:type) ]
          @types                = options.delete(:types)
          @wrapper              = options.delete(:wrapper)

          @required             = options.delete(:required)
          @singularize          = options.delete(:singularize)
          @inheritance          = options.delete(:inheritance)
          @keys                 = options.delete(:keys)

          @default_value        = options.delete(:default_value)
          @ios_default          = options.delete(:ios_default)
          @osx_default          = options.delete(:osx_default)
          @initial_value        = options.delete(:initial_value) {[]}

          @skip_definitions     = options.delete(:skip_definitions)
          @reader_name          = options.delete(:reader_name)
          @writer_name          = options.delete(:writer_name)
          @ivar_name            = options.delete(:ivar_name)


          @root_only            = options.delete(:root_only) { false }
          @multi_platform       = options.delete(:multi_platform) { true }

          @file_patterns = options.delete(:file_patterns) {false}
          if @file_patterns
            @multi_platform ||= true
            @inheritance ||= :merge
            @wrapper ||= Array
          end

          raise StandardError, "Unrecognized options for specification attribute: #{options}" unless options.empty?
        end

        attr_reader :type
        attr_reader :wrapper
        attr_reader :inheritance
        attr_reader :keys
        attr_reader :initial_value
        attr_reader :default_value
        attr_reader :ios_default
        attr_reader :osx_default

        %w{ required root_only multi_platform singularize skip_definitions }.each do |attr|
          define_method("#{attr}?") do
            instance_variable_get("@#{attr}")
          end
        end

        def file_patterns?
          @file_patterns
        end

        # Initializes the attribute with the initial value or the defaul in the
        # given specification.
        #
        def initialize_on(spec)
          if multi_platform?
            initialization_value = default_value || initial_value
            initial_value_per_platform = Spec::PLATFORMS.inject(Hash.new) { | memo, platform | memo[platform] = initialization_value; memo }
            initial_value_per_platform[:ios] = ios_default if ios_default
            initial_value_per_platform[:osx] = osx_default if osx_default
            spec.instance_variable_set(ivar, initial_value_per_platform)
          end
        end

        # @return [String] the instance variable associated with the attribute.
        #
        def ivar
          @ivar_name || "@#{name}"
        end

        # @return [Symbol] the name of the getter method for the attribute.
        #
        def reader_name
          @reader_name || name
        end

        # @return [String] the name of the setter method for the attribute.
        #
        def writer_name
          @writer_name || "#{name}="
        end

        # @return [String] an alised attribute writer offered for convenience on
        # the DSL.
        #
        def writer_alias
          "#{name.to_s.singularize}=" if singularize?
        end

        def prepare_hook_name
          "_prepare_#{name}"
        end
      end


      # @return [Array<Attribute>] The attributes of the class.
      #
      def self.attributes
        @attributes
      end

      @attributes = []

      module Attributes

        #
        #
        def attribute(name, options)
          attr = Attribute.new(name, options)
          @attributes << attr

          unless attr.skip_definitions?
            # reader
            define_method(attr.reader_name) do
              if attr.multi_platform?
                active_plaform_check
                if attr.inheritance == :first_defined
                  ivar_value = instance_variable_get(attr.ivar)[active_platform]
                  ivar_value || (@parent.send(attr.reader_name) if @parent)
                elsif attr.inheritance == :merge
                  value = instance_variable_get(attr.ivar)[active_platform]
                  if parent
                    parent_value = @parent.send(attr.reader_name)
                    value = case parent_value
                            when Array
                              (parent_value || []) + value
                            when Hash
                            end
                  end
                  value
                else
                  instance_variable_get(attr.ivar)[active_platform]
                end
              else
                if attr.inheritance == :first_defined
                  ivar_value = instance_variable_get(attr.ivar)
                  ivar_value || (@parent.send(attr.reader_name) if @parent)
                else
                  instance_variable_get(attr.ivar)
                end
              end
            end

            # writer
            define_method(attr.writer_name) do |value|
              raise StandardError, "#{self.inspect} Can't set `#{name}' for subspecs." if attr.root_only? && !root_spec

              if attr.wrapper
                if attr.wrapper ==  Array
                  value = [ value ] unless value.is_a?(Array)
                end
              end

              if respond_to?(attr.prepare_hook_name)
                value = self.send(attr.prepare_hook_name, value)
              end

              if attr.keys
                value.keys.each do |key|
                  attr_keys = attr.keys.is_a?(Hash) ? (attr.keys.keys.concat(attr.keys.values.flatten.compact)) : attr.keys
                  raise StandardError, "Unknown key `#{key}` for attribute `#{attr.name}`. Allowed keys: `#{attr_keys}`" unless attr_keys.include?(key)
                end
              end

              if attr.multi_platform?
                ivar_value = instance_variable_get(attr.ivar)
                @define_for_platforms.each do |platform|
                  ivar_value[platform] = value
                end
              else
                instance_variable_set(attr.ivar, value);
              end
            end

            alias_method(attr.writer_alias, attr.writer_name) if attr.writer_alias
          end
        end
      end
    end
  end
end
