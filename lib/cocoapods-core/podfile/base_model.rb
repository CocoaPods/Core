module Pod
  class Podfile

    # The base model class of any Podfile model. Features for the object and
    # whole subtree descending from it the specification of:
    #
    # - Dependencies
    # - Warning inhibition
    #
    class BaseModel

      # TODO: port
      #-----------------------------------------------------------------------#

      def store_podspec(options = nil)
        if options
          unless options.keys.all? { |key| [:name, :path].include?(key) }
            raise StandardError, "Unrecognized options for the podspec " \
              "method `#{options}`"
          end
          get_hash_value('podspecs', []) << options
        else
          get_hash_value('podspecs', []) << { :autodetect => true }
        end
      end

      #-----------------------------------------------------------------------#

    end
  end
end
