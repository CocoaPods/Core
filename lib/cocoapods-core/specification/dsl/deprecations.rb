module Pod
  class Specification
    module DSL
      # Provides warning and errors for the deprecated attributes of the DSL.
      #
      module Deprecations
        def preferred_dependency=(name)
          self.default_subspecs = [name]
          CoreUI.warn "[#{self}] `preferred_dependency` has been renamed "\
            'to `default_subspecs`.'
        end

        def singleton_method_added(method)
          if method == :header_mappings
            raise Informative, "[#{self}] The use of the `header_mappings` " \
              "hook has been deprecated.\n Use the `header_dir` and the " \
                '`header_mappings_dir` attributes.'

          elsif method == :copy_header_mapping
            raise Informative, "[#{self}] The use of the " \
              "`copy_header_mapping` hook has been deprecated.\nUse" \
                'the `header_dir` and the `header_mappings_dir` attributes.'
          end
        end

        def documentation=(value)
          CoreUI.warn "[#{self}] The `documentation` DSL directive of the " \
            'podspec format has been deprecated.'
        end

        def clean_paths=(value)
          raise Informative, "[#{self}] Clean paths are deprecated. " \
            'CocoaPods now cleans unused files by default. Use the ' \
              '`preserve_paths` attribute if needed.'
        end

        DEPRECATED_METHODS = [
          :part_of_dependency=,
          :part_of=,
          :exclude_header_search_paths=,
        ]

        DEPRECATED_METHODS.each do |method|
          define_method method do |value|
            raise Informative, "[#{self}] Attribute "\
              "`#{method.to_s[0..-2]}` has been deprecated."
          end
        end
      end
    end
  end
end
