module Pod
  class Specification
    module DSL

      # @return [Array<Attribute>] The attributes of the class.
      #
      def self.attributes
        @attributes
      end

      # TODO: temporary support for Rake::FileList
      module ::Rake; class FileList; end; end

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
          @file_patterns  = options.delete(:file_patterns)  { false     }
          @container      = options.delete(:container)      { nil       }
          @keys           = options.delete(:keys)           { nil       }
          @default_value  = options.delete(:default_value)  { nil       }
          @ios_default    = options.delete(:ios_default)    { nil       }
          @osx_default    = options.delete(:osx_default)    { nil       }
          @defined_as     = options.delete(:defined_as)     { nil       }
          @types          = options.delete(:types)          { [String ] }

          # temporary support for Rake::FileList
          @types << Rake::FileList if defined?(Rake) && @file_patterns

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

        # @return [String] A string representation suitable for debugging.
        #
        def inspect
          "<#{self.class} name=#{self.name} types=#{types} multi_platform=#{multi_platform?}>"
        end

        #--------------------------------------#

        # @!group Options

        # @return [Array<Class>] the list of the classes of the values
        #         supported by the attribute writer. If not specified defaults
        #         to #{String}.
        #
        attr_reader :types

        # @return [Array<Class>] the list of the classes of the values
        #         supported by the attribute, including the container.
        #
        def supported_types
          @supported_types ||= @types.dup.push(container).compact
        end

        # @return [Class] if defined it can be #{Array} or #{Hash}. It is used
        #         as default initialization value and to automatically wrap
        #         other values to arrays.
        #
        attr_reader :container

        # @return [Array, Hash] the list of the accepted keys for an attribute
        #         wrapped by a Hash.
        #
        # @note   A hash is accepted to group the keys associated only with
        #         certain keys (see the source attribute of a Spec).
        #
        attr_reader :keys

        # @return [Object] if the attribute follows configuration over
        #         convention it can specify a default value.
        #
        # @note   The default value is not automatically wrapped and should be
        #         specified within the container if any.
        #
        attr_reader :default_value

        # @return [Object] similar to #{default_value} but for iOS.
        #
        attr_reader :ios_default

        # @return [Object] similar to #{default_value} but for OS X.
        #
        attr_reader :osx_default

        # @return [Bool] whether the specification should be considered invalid
        #         if a value for the attribute is not specified.
        #
        def required?; @required; end

        # @return [Bool] whether the attribute should be specified only on the
        #         root specification.
        #
        def root_only?; @root_only; end

        # @return [Bool] whether the attribute is multi-platform and should
        #         work in conjunction with #{PlatformProxy}.
        #
        def multi_platform?; @multi_platform; end

        # @return [Bool] whether there should be a singular alias for the
        #         attribute writer.
        #
        def singularize?; @singularize; end

        # @return [Bool] whether the attribute describes file patterns.
        #
        # @note   This is mostly used by the linter.
        #
        def file_patterns?; @file_patterns; end

        # @return [Bool] whether an implementation for the writers and the
        #         setters is provided and thus the definition should be
        #         skipped.
        #
        # @note   Multi-platform attributes can use it to be Picked up by the
        #         platform proxy (currently used only by the `dependency`
        #         attribute).
        #
        def skip_definitions?
          !@defined_as.nil?
        end

        #--------------------------------------#

        # @!group Specification helpers

        # @return [String] the instance variable associated with the attribute.
        #
        def ivar
          "@#{name}"
        end

        # Initializes the ivar for the given specification.
        #
        # @note   The default value is not stored in the ivar but returned by
        #         the getter, to preserve to possibility to detect if the
        #         specifications has a value for the attribute.
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

        # Checks if a value for the attribute has been defined for the given
        # specification.
        #
        # @param  [Specification] spec
        #         the specification to check.
        #
        # @return [Bolean] whether a value has been specified for this
        #         attribute.
        #
        def empty?(spec)
          if multi_platform?
            spec.instance_variable_get(ivar) == {:osx=>{}, :ios=>{}}
          else
            spec.instance_variable_get(ivar).nil?
          end
        end

        #--------------------------------------#

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
        # @note   If attributes described by a string need to be concatenated
        #         they should be contained in an array.
        #
        # @return [Object] the value for the attribute.
        #
        def value_with_inheritance(spec, value)
          return value if spec.root? || !inherited?
          parent_value = spec.parent.send(reader_name)

          if container == Array
            (parent_value || []) + (value || [])
          elsif container == Hash
            (parent_value || {}).merge(value || {}) do |_, old, new|
              if new.is_a?(Array)
                old + new
              else
                old + ' ' + new
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

        #--------------------------------------#

        # @!group Writer method support

        # @return [String] the name of the setter method for the attribute.
        #
        def writer_name
           @defined_as || "#{name}="
        end

        # @return [String] an aliased attribute writer offered for convenience
        #         on the DSL.
        #
        def writer_singular_form
          "#{name.to_s.singularize}=" if singularize?
        end


        # @return [String] the name of the prepare hook for this attribute.
        #
        # @note   The hook is called after the value has been wrapped in an
        #         array (if needed according to the container) but before
        #         validation.
        #
        def prepare_hook_name
          "_prepare_#{name}"
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
        def prepare_value(spec, value)
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
        # @note   The this is called before preparing the value.
        #
        # @raise  If the type is not in the allowed list.
        #
        # @return [void]
        #
        def validate_type(value)
          return if value.nil?
          unless supported_types.any? { |klass| value.class == klass }
            raise StandardError, "Non acceptable type `#{value.class}` for "\
              "#{to_s}. Allowed values: `#{types.inspect}`"
          end
        end

        # Validates a value before storing.
        #
        # @raise If a root only attribute is set in a subspec.
        #
        # @raise If a unknown key is added to a hash.
        #
        # @return [void]
        #
        def validate_for_writing(spec, value)
          if root_only? && !spec.root?
            raise StandardError, "Can't set `#{name}` attribute for subspecs (in `#{spec.name}`)."
          end

          if keys
            value.keys.each do |key|
              unless allowed_keys.include?(key)
                raise StandardError, "Unknown key `#{key}` for "\
                  "#{to_s}. Allowed keys: `#{allowed_keys.inspect}`"
              end
            end

            if defined?(Rake) && value.is_a?(Rake::FileList)
              # UI.warn "Rake::FileList is deprecated, use `exclude_files` (#{attrb.name})."
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
            define_attr_writer_singular_form(attr)
          end
        end

        #--------------------------------------#

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
            if attr.root_only? && subspec?
              return root.send(attr.reader_name)
            end
            value = instance_variable_get(attr.ivar)
            if attr.multi_platform?
              __active_plaform_check
              value = value[active_platform]
              value = attr.value_with_inheritance(self, value)
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
        # @note       To properly support multi platform attributes their
        #             values are merged/concatenated with the value of the
        #             ivar.
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
            attr.validate_type(value)
            value = attr.prepare_value(self, value)
            attr.validate_for_writing(self, value)

            if attr.multi_platform?
              ivar_value = instance_variable_get(attr.ivar)
              @define_for_platforms.each do |platform|
                current = ivar_value[platform]
                if current && attr.container == Array
                  ivar_value[platform] = current + value
                elsif current && attr.container == Hash
                  ivar_value[platform] = __deep_merge_hash(current, value)
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
        def define_attr_writer_singular_form(attr)
          if attr.writer_singular_form
            alias_method(attr.writer_singular_form, attr.writer_name)
          end
        end
      end

      #-----------------------------------------------------------------------#

      # This module provides support for creating the {Specification} DSL. In
      # practice it provides the DSL for the creation of the DSL (Yup! You've
      # read it right).
      #
      module AttributeSupport

        private

        # Checks that specification has been activated for platform as it is
        # necessary to read multi-platform attributes.
        #
        # @raise It the specification has not been activated for a platform.
        #
        def __active_plaform_check
          unless active_platform
            raise StandardError, "#{self.inspect} not activated for a " \
              "platform before consumption."
          end
        end

        # @return [Hash] merges the keys of the given hashes concatenating them
        # if needed.
        #
        def __deep_merge_hash(hash1, hash2)
          hash1.merge(hash2) do |_, old, new|
            if old.is_a?(Array)
              old + new
            else
              old + ' ' + new
            end
          end
        end
      end
    end
  end
end
