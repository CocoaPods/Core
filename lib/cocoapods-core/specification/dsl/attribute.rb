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
          raise StandardError, "#{self.inspect} not activated for a " \
            "platform before consumption."
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

        # Returns a new attribute initialized with the given options.
        #
        # Attributes by default are:
        #
        # - inherited
        # - multi-platform
        #
        # @param    [Symbol] name @see name
        #
        # @param    [Hash{Symbol=>Object}] options
        #           The options for configuring the attribute (see Options
        #           group).
        #
        # @raise    If there are unrecognized options.
        #
        def initialize(name, options)
          @name = name

          @multi_platform = options.delete(:multi_platform) { true      }
          @inherited      = options.delete(:inherited)      { true      }
          @root_only      = options.delete(:root_only)      { false     }
          @required       = options.delete(:required)       { false     }
          @singularize    = options.delete(:singularize)    { false     }
          @container      = options.delete(:container)      { nil       }
          @keys           = options.delete(:keys)           { nil       }
          @default_value  = options.delete(:default_value)  { nil       }
          @ios_default    = options.delete(:ios_default)    { nil       }
          @osx_default    = options.delete(:osx_default)    { nil       }
          @defined_as     = options.delete(:defined_as)     { nil       } # TODO used only by dependency
          @types          = options.delete(:types)          { [String ] }

          # temporary support for Rake::FileList
          @types << Rake::FileList if defined?(Rake)

          if @root_only
            @multi_platform = false
            @inherited = false
          end

          unless options.empty?
            raise StandardError, "Unrecognized options: #{options} for #{to_s}"
          end
        end

        # @return [String] A string representation suitable for UI.
        #
        def to_s
          "Specification attribute `#{name}`"
        end

        #-------------------#

        # @!group Options

        # @return [Array<Class>] the list of the classes of the values
        #   supported by the attribute writer. If not specified defaults
        #   to #{String} and the class of the #{#container}.
        #
        attr_reader :types

        # @return [Class] if defined it can be #{Array} or #{Hash}. It is used
        #   as default initialization value and to automatically wrap other
        #   values to arrays.
        #
        attr_reader :container

        # @return [Array, Hash] the list of the accepted keys for an attribute
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

        # Initializes the ivar for the given specification.
        #
        # @return [void]
        #
        def initialize_spec_ivar(spec)
          if multi_platform?
            value = {}
            PLATFORMS.each { |p| value[p] = container ? container.new : nil }
            spec.instance_variable_set(ivar, value)
          else
            spec.instance_variable_set(ivar, container.new) if container
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

        # @return [Bool] defines whether the attribute reader should join the
        # values with the parent.
        #
        # @note   Attributes stored in wrappers are always inherited.
        #
        def inherited?; @inherited; end

        # Returns the value of the attribute of the given specification taking
        # into account whether it should inherit the values of the parents.
        #
        # If the attribute is a collection it is concatenated with the value of
        # the parent. If the value is stored in a String the values are joined
        # by an empty space. Finally if it is stored in a hash the values are
        # merged according to the above defined rules.
        #
        # @param  [Specification] spec
        #         the specification whose value is required.
        #
        # @param  [Object] value
        #         the value stored in the instance variable of the attribute.
        #
        # @return [Object] the value for the attribute.
        #
        def value_with_inheritance(spec, value)
          return value if spec.root_spec? || !inherited?
          parent_value = spec.parent.send(reader_name)

          if container == Array
            (parent_value || []) + value
          elsif container == Hash
            (parent_value || {}).merge(value) do |_, oldval, newval|
              if newval.is_a?(Array)
                oldval + newval
              else
                oldval + ' ' + newval
              end
            end
          else
            value || parent_value
          end
        end

        def default_value
          if multi_platform?
            value = {}
            PLATFORMS.each { |p| value[p] = @default_value }
            value[:ios] = ios_default if @ios_default
            value[:osx] = osx_default if @osx_default
            value
          else
            @default_value
          end
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
          if container
            if container ==  Array
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
          unless supported_types.any? { |klass| value.class == klass }
            raise StandardError, "Non acceptable type `#{value.class}` for "\
              "#{to_s}. Allowed values: `#{types.inspect}`"
          end
        end

        def supported_types
          types.dup.push(container).compact
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
            value.keys.each do |key|
              unless allowed_keys.include?(key)
                raise StandardError, "Unknown key `#{key}` for "\
                  "#{to_s}. Allowed keys: `#{allowed_keys.inspect}`"
              end
            end
          end

          # @return [Array] the flattened list of the allowed keys for the
          # hash of a given specification.
          #
          def allowed_keys
            if keys.is_a?(Hash)
              keys.keys.concat(keys.values.flatten.compact)
            else
              keys
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
              value = attr.value_with_inheritance(self, value)
              # TODO: clean up
              if attr.default_value[active_platform] && ( !value || (value.respond_to?(:empty?) && value.empty?) )
                attr.default_value[active_platform]
              else
                value
              end
            else
              attr.value_with_inheritance(self, value) || attr.default_value
            end
          end
        end

        # Defines the attribute writer instance method for the class extended
        # by this module.
        #
        # The defined method, prepares the value according to the
        # {Attribute#container} and to the optional prepare hook. Then it
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
                current = ivar_value[platform]
                if current && current.is_a?(Array)
                  ivar_value[platform] = current + value
                  # TODO: clean up
                elsif current && current.is_a?(Hash)
                  ivar_value[platform] = current.merge(value) do |_, old, new|
                    if old.is_a?(Array)
                      old + new
                    else
                      old + ' ' + new
                    end
                  end
                else
                  ivar_value[platform] = value
                end
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
          if attr.writer_alias
            alias_method(attr.writer_alias, attr.writer_name)
          end
        end

      end
    end
  end
end
