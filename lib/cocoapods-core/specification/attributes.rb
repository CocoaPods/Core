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

    module Attributes

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
          ivar_value = instance_variable_get("@#{attr}")[active_platform]
          @parent ? @parent.send(attr) + ivar_value : ( ivar_value )
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
