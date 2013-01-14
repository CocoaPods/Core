module Pod
  class Specification
    module DSL

      # Provides warning and errors for the deprecated attributes of the DSL.
      #
      module Deprecations

        def preferred_dependency=(args)
          CoreUI.warn "[#{to_s}] `preferred_dependency` has been renamed to `default_subspec`."
          attributes_hash[:default_subspec] = args
        end

        def singleton_method_added(method)
          if [:pre_install, :post_install ].include?(method)
            CoreUI.warn "[#{to_s}] The use of `#{method}` by overriding the method is deprecated."
          elsif method == :header_mappings
            raise StandardError, "[#{to_s}] The use of the `header_mappings` hook has been deprecated."
          end
        end

        def clean_paths=(value)
          raise StandardError, "[#{to_s}] Clean paths are deprecated. CocoaPods now " \
            "cleans unused files by default. Use preserver paths if needed."
        end

        [ :part_of_dependency=, :part_of=, :exclude_header_search_paths= ].each do |method|
          define_method method do |value|
            raise StandardError, "[#{to_s}] Attribute `#{method.to_s[0..-2]}` has been deprecated."
          end
        end

      end

    end
  end
end
