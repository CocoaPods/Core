module Pod
  class Source
    # Defines the required and the optional methods of a data provider.
    #
    class AbstractDataProvider
      public

      # @group Required methods
      #-----------------------------------------------------------------------#

      # @return [String] The name of the source.
      #
      def name
        raise StandardError, 'Abstract method.'
      end

      # @return [String] The URL of the source.
      #
      def url
        raise StandardError, 'Abstract method.'
      end

      # @return [String] The user friendly type of the source.
      #
      def type
        raise StandardError, 'Abstract method.'
      end

      # @return [Array<String>] The list of the name of all the Pods known to
      #         the Source.
      #
      def pods
        raise StandardError, 'Abstract method.'
      end

      # @return [Array<String>] All the available versions of a given Pod,
      #         sorted from highest to lowest.
      #
      # @param  [String] name
      #         The name of the Pod.
      #
      def versions(_name)
        raise StandardError, 'Abstract method.'
      end

      # @return [Specification] The specification for a given version of a Pod.
      #
      # @param  [String] name
      #         The name of the Pod.
      #
      # @param  [String] version
      #         The version of the Pod.
      #
      def specification(_name, _version)
        raise StandardError, 'Abstract method.'
      end

      # @return [Specification] The contents of the specification for a given
      #         version of a Pod.
      #
      # @param  [String] name
      #         the name of the Pod.
      #
      # @param  [String] version
      #         the version of the Pod.
      #
      def specification_contents(_name, _version)
        raise StandardError, 'Abstract method.'
      end

      #-----------------------------------------------------------------------#
    end
  end
end
