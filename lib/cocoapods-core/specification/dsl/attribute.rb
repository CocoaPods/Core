module Pod
  class Specification
    module DSL

      # @return [Array<Attribute>] The attributes of the class.
      #
      def self.attributes
        @attributes
      end

      # Checks that specification has been activated for platform as it is
      # necessary to read multi-platform attributes.
      #
      # @raise It the specification has not been activated for a platform.
      #
      def active_plaform_check
        unless active_platform
          raise StandardError, "#{self.inspect} not activated for a platform before consumption."
        end
      end

      #-----------------------------------------------------------------------#

      # A Specification attribute stores the information of an attribute. It
      # also provides logic to implement any required logic.
      #
      class Attribute

        require 'active_support/inflector/inflections'

        # @return [Symbol] the name of the attribute.
        #
        attr_reader :name

        # @param    [Symbol] name @see name
        #
        # @option  options [String] :description
        #
        def initialize(name, options)
          @name = name

          @root_only        = options.delete(:root_only) { false }
          @multi_platform   = options.delete(:multi_platform) { true }
          @required         = options.delete(:required)
          @singularize      = options.delete(:singularize)
          @inheritance      = options.delete(:inheritance)
          @defined_as = options.delete(:defined_as)

          @default_value    = options.delete(:default_value)
          @ios_default      = options.delete(:ios_default)
          @osx_default      = options.delete(:osx_default)
          @keys             = options.delete(:keys)

          @wrapper = options.delete(:wrapper)
          @types = options.delete(:types) {[]}
          @types << type if type = options.delete(:type)

          @file_patterns = options.delete(:file_patterns) {false}
          if @file_patterns
            @multi_platform ||= true
            @inheritance ||= :merge
            @wrapper ||= Array
          end

          @types << String if @types.empty?
          @types << @wrapper if @wrapper
          @types << Rake::FileList if @file_patterns && defined?(Rake)

          raise StandardError, "Unrecognized options for specification attribute: #{options}" unless options.empty?
        end

        # @return [String]
        #
        def to_s
          "Attribute for `#{name}`"
        end

        #-------------------#

        # @!group Options

        # @return [Array<Class>] the list of the classes of the values
        #   supported by the attribute writer. If not specified defaults
        #   to #{String} and the class of the #{#wrapper}.
        #
        attr_reader :types

        # @return [Class] if defined it can be #{Array} or #{Hash}. It is used
        #   as default initialization value and to automatically wrap other
        #   values to arrays.
        #
        attr_reader :wrapper

        # @return [Symbol] defines the behaviour of the reader, if defined it
        #   can be either:
        #
        #   - first_defined: represents attributes that should be looked in
        #     the parent if nil.
        #   - merge: represents attributes that have a #{wrapper} and whose
        #     values should be merged with the parents.
        #
        attr_reader :inheritance

        # @return [Array] the list of the accepted keys for an attribute
        #   wrapped by a Hash.
        #
        attr_reader :keys

        # @return [Object] if the attribute follows configuration over
        #   convention it can specify a default value.
        #
        attr_reader :default_value

        # @return [Object] similar to #{default_value} but for iOS.
        #
        attr_reader :ios_default

        # @return [Object] similar to #{default_value} but for OS X.
        #
        attr_reader :osx_default

        # @return [Bool] whether the specification should be considered invalid
        #   if a value for the attribute is not specified.
        #
        def required?; @required; end

        # @return [Bool] whether the attribute should be specified only on the
        #   root specification.
        #
        def root_only?; @root_only; end

        # @return [Bool] whether the attribute is multi-platform and should
        #   work in conjunction with #{PlatformProxy}.
        #
        def multi_platform?; @multi_platform; end

        # @return [Bool] whether there should be a singular alias for the
        #   attribute writer.
        #
        def singularize?; @singularize; end

        # @return [Bool] whether an implementation for the writers and the
        # setters is provided and thus the definition should be skipped.
        #
        # Multi-platform attributes can use it to be Picked up by the platform
        # proxy and by the documentation.
        #
        # TODO: this is used only by the `dependency` attribute.
        #
        def skip_definitions?
          !@defined_as.nil?
        end

        #-------------------#

        # @!group Specification helpers

        # @return [Object] the value that should be used initialize the ivar.
        #
        def initialization_value
          default_value || (wrapper.new if wrapper)
        end

        # Initializes the ivar for the given specification.
        #
        # @return [void]
        #
        def initialize_on(spec)
          if multi_platform?
            value = {}
            Spec::PLATFORMS.each { |platform| value[platform] = initialization_value }
            value[:ios] = ios_default if ios_default
            value[:osx] = osx_default if osx_default
            spec.instance_variable_set(ivar, value)
          end
        end

        # @return [String] the instance variable associated with the attribute.
        #
        def ivar
          "@#{name}"
        end


        #-------------------#

        # @!group Reader method support

        # @return [Symbol] the name of the getter method for the attribute.
        #
        def reader_name
          name
        end

        # @return [Object] Returns the value for the attribute taking into
        #         account the inheritance policy.
        #
        def value_with_inheritance(spec, value)
          return value if spec.root_spec?
          if inheritance == :first_defined
            value ||= spec.parent.send(reader_name)
          elsif inheritance == :merge
            parent_value = spec.parent.send(reader_name)
            case parent_value
            when Array
              value = (parent_value || []) + value
            when Hash
              value = (parent_value || {}).merge(value) do |_, oldval, newval|
                if newval.is_a?(Array)
                  oldval + newval
                else
                  oldval + ' ' + newval
                end
              end
            end
          end
          value
        end

        #-------------------#

        # @!group Writer method support

        # @return [String] the name of the setter method for the attribute.
        #
        def writer_name
           @defined_as || "#{name}="
        end

        # @return [String] an aliased attribute writer offered for convenience
        #         on the DSL.
        #
        def writer_alias
          "#{name.to_s.singularize}=" if singularize?
        end


        # @return [String] the name of the prepare hook for this attribute.
        #
        def prepare_hook_name
          "_prepare_#{name}"
        end

        # Calls the prepare hook to allow further customization of a value
        # before storing it in the instance variable.
        #
        # @return [Object] the customized value of the original one if no
        #         prepare hook was defined.
        #
        def prepare_ivar(spec, value)
          if wrapper
            if wrapper ==  Array
              value = [ value ] unless value.is_a?(Array)
            end
          end

          if spec.respond_to?(prepare_hook_name)
            value = spec.send(prepare_hook_name, value)
          else
            value
          end
        end

        # Validates the value for an attribute. This validation should be
        # performed before the value is prepared or wrapped.
        #
        # @raise if the type is not in the allowed ones.
        #
        # @return [void]
        #
        def validate_type(spec, value)
          unless types.any? { |klass| value.class == klass }
            raise StandardError, "Non acceptable type `#{value.class}` for "\
              "attribute `#{name}`. Allowed values: `#{types.inspect}`"
          end

          # Validates a value before storing.
          #
          # @raise If a root only attribute is set in a subspec.
          #
          # @raise If a unknown key is added to a hash.
          #
          # @return [void]
          #
          def validate_value(spec, value)
            if root_only? && !spec.root_spec
              raise StandardError, "#{spec.inspect} Can't set `#{name}' for subspecs."
            end
            if keys
              allowed_keys = keys.is_a?(Hash) ? (keys.keys.concat(keys.values.flatten.compact)) : keys
              value.keys.each do |key|
                unless allowed_keys.include?(key)
                  raise StandardError, "Unknown key `#{key}` for attribute "\
                    "`#{name}`. Allowed keys: `#{allowed_keys.inspect}`"
                end
              end
            end
          end
        end
      end

      #-----------------------------------------------------------------------#

      # This module provides support for creating the {Specification} DSL. In
      # practice it provides the DSL for the creation of the DSL (Yup! You've
      # read it right).
      #
      module Attributes

        # Defines an attribute for the extended class.
        #
        # The attribute is stored by the class
        #
        def attribute(name, options = {})
          attr = Attribute.new(name, options)
          @attributes ||= []
          @attributes << attr
          unless attr.skip_definitions?
            define_attr_reader(attr)
            define_attr_writer(attr)
            define_attr_writer_alias(attr)
          end
        end

        #-------------------#

        # @!group Private methods

        # Defines the attribute reader instance method for the class extended
        # by this module.
        #
        # @visibility private
        #
        # @return     [void]
        #
        def define_attr_reader(attr)
          define_method(attr.reader_name) do
            value = instance_variable_get(attr.ivar)
            if attr.multi_platform?
              active_plaform_check
              value = value[active_platform]
            end
            attr.value_with_inheritance(self, value)
          end
        end

        # Defines the attribute writer instance method for the class extended
        # by this module.
        #
        # The defined method, prepares the value according to the
        # {Attribute#wrapper} and to the optional prepare hook. Then it
        # performs validations and stores the attribute in the corresponding
        # ivar.
        #
        # @note       Multi-platform attributes use a hash to store the value
        #             for each platform.
        #
        # @raise      If the value is not valid for the attribute.
        #
        # @visibility private
        #
        # @return     [void]
        #
        def define_attr_writer(attr)

          define_method(attr.writer_name) do |value|
            attr.validate_type(self, value)
            value = attr.prepare_ivar(self, value)
            attr.validate_value(self, value)

            if attr.multi_platform?
              ivar_value = instance_variable_get(attr.ivar)
              @define_for_platforms.each do |platform|
                ivar_value[platform] = value
              end
            else
              instance_variable_set(attr.ivar, value);
            end
          end
        end

        # Defines the attribute writer instance method for the class extended
        # by this module.
        #
        # @visibility private
        #
        # @return     [void]
        #
        def define_attr_writer_alias(attr)
          alias_method(attr.writer_alias, attr.writer_name) if attr.writer_alias
        end

      end
    end
  end
end
