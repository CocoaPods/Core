module Pod
  class Specification
    class Linter
      class Result

        # @return [Symbol] the type of result.
        #
        attr_reader :type

        # @return [String] the message associated with result.
        #
        attr_reader :message

        # @param [Symbol] type    @see type
        # @param [String] message @see message
        #
        def initialize(type, message)
          @type    = type
          @message = message
          @platforms = []
        end

        # @return [Array<Platform>] the platforms where this result was
        #         generated.
        #
        attr_reader :platforms

        # @return [String] a string representation suitable for UI output.
        #
        def to_s
          r = "[#{type.to_s.upcase}] #{message}"
          if platforms != Specification::PLATFORMS
            platforms_names = platforms.uniq.map do |p|
              Platform.string_name(p)
            end
            r << " [#{platforms_names * ' - '}]" unless platforms.empty?
          end
          r
        end
      end
    end
  end
end
