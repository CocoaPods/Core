module Pod
  class Specification

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
      # @option  options [String] :is_required
      # @option  options [String] :root_only
      # @option  options [String] :multi_platform
      # @option  options [String] :singularize
      # @option  options [String] :inheritance
      # @option  options [String] :example
      # @option  options [String] :examples
      #
      def initialize(name, options)
        @name = name
        @type                 = options.delete(:type)
        @required             = options.delete(:is_required)
        @singularize          = options.delete(:singularize)
        @inheritance          = options.delete(:inheritance)
        @keys                 = options.delete(:keys)

        @default_value        = options.delete(:default_value)
        @ios_default          = options.delete(:ios_default)
        @osx_default          = options.delete(:osx_default)
        @initial_value        = options.delete(:initial_value) {[]}

        @reader_name          = options.delete(:reader_name)
        @writer_name          = options.delete(:writer_name)
        @ivar_name            = options.delete(:ivar_name)

        @file_patterns         = options.delete(:file_patterns) {false}

        @root_only            = options.delete(:root_only) { false }
        @multi_platform       = options.delete(:multi_platform) { true }

        raise StandardError, "Unrecognized options for specification attribute: #{options}" unless options.empty?
      end

      attr_reader :type
      attr_reader :required
      attr_reader :root_only
      attr_reader :multi_platform
      attr_reader :singularize
      attr_reader :inheritance
      attr_reader :keys
      attr_reader :initial_value
      attr_reader :default_value

      def file_patterns?
        @file_patterns
      end

      # Initializes the attribute with the initial value or the defaul in the
      # given specification.
      #
      def initialize_on(spec)
        if multi_platform
          default_value = default_value || initial_value
          initial_value_per_platform = Spec::PLATFORMS.inject(Hash.new) { | memo, platform | memo[platform] = default_value; memo }
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
        "#{name.to_s.singularize}=" if singularize
      end

    end


    def self.attributes
      @attributes
    end

    @attributes = []

    module Attributes

      #
      #
      def attribute(name, options)
        attrb = Attribute.new(name, options)
        @attributes << attrb

        # reader
        define_method(attrb.reader_name) do
          if attrb.multi_platform
            active_plaform_check
            if attrb.inheritance == :first_defined
              ivar_value = instance_variable_get(attrb.ivar)[active_platform]
              ivar_value || (@parent.send(attrb.reader_name) if @parent)
            elsif attrb.inheritance == :merge
              ivar_value = instance_variable_get(attrb.ivar)[active_platform]
              ivar_value.nil? ? (@parent.send(attr) if @parent) : ivar_value
            else
              instance_variable_get(attrb.ivar)[active_platform]
            end
          else
            if attrb.inheritance == :first_defined
              ivar_value = instance_variable_get(attrb.ivar)
              ivar_value || (@parent.send(attrb.reader_name) if @parent)
            else
              instance_variable_get(attrb.ivar)
            end
          end
        end

        # writer
        define_method(attrb.writer_name) do |value|
          raise StandardError, "#{self.inspect} Can't set `#{name}' for subspecs." if attrb.root_only && !root_spec
          if attrb.multi_platform
            ivar_value = instance_variable_get(attrb.ivar)
            @define_for_platforms.each do |platform|
              ivar_value[platform] = value
            end
          else
            instance_variable_set(attrb.ivar, value);
          end
        end

        alias_method(attrb.writer_alias, attrb.writer_name) if attrb.writer_alias
      end

      # Creates a top level attribute reader. A lambda can be passed to process
      # the ivar before returning it
      #
      def top_attr_reader(attr, read_lambda = nil)
        define_method(attr) do
          ivar = instance_variable_get("@#{attr}")
          @parent ? top_level_parent.send(attr) : ( read_lambda ? read_lambda.call(self, ivar) : ivar )
        end
      end

      # Creates a top level attribute writer. A lambda can be passed to
      # initialize the value
      #
      def top_attr_writer(attr, init_lambda = nil)
        define_method("#{attr}=") do |value|
          raise StandardError, "#{self.inspect} Can't set `#{attr}' for subspecs." if @parent
          instance_variable_set("@#{attr}",  init_lambda ? init_lambda.call(value) : value);
        end
      end

      # Creates a top level attribute accessor. A lambda can be passed to
      # initialize the value in the attribute writer.
      #
      def top_attr_accessor(attr, writer_labmda = nil)
        top_attr_reader attr
        top_attr_writer attr, writer_labmda
      end

      # Returns the value of the attribute for the active platform chained with
      # the upstream specifications. The ivar must store the platform specific
      # values as an array.
      #
      def pltf_chained_attr_reader(attr)
        define_method(attr) do
          active_plaform_check
        end
      end

      # Returns the first value defined of the attribute traversing the chain
      # upwards.
      #
      def pltf_first_defined_attr_reader(attr)
        define_method(attr) do
          active_plaform_check
          ivar_value = instance_variable_get("@#{attr}")[active_platform]
          ivar_value.nil? ? (@parent.send(attr) if @parent) : ivar_value
        end
      end


      # Attribute writer that works in conjunction with the PlatformProxy.
      #
      def platform_attr_writer(attr, block = nil)
        define_method("#{attr}=") do |value|
          current = instance_variable_get("@#{attr}")
          @define_for_platforms.each do |platform|
            block ?  current[platform] = block.call(value, current[platform]) : current[platform] = value
          end
        end
      end

      def pltf_chained_attr_accessor(attr, block = nil)
        pltf_chained_attr_reader(attr)
        platform_attr_writer(attr, block)
      end

    end
  end
end
