require 'cocoapods-core/specification/linter/result'

module Pod
  class Specification
    class Linter
      class Analyzer
        include Linter::ResultHelpers

        def initialize(consumer)
          @consumer = consumer
          @results = []
        end

        def analyze
          check_for_unknown_keys
          validate_file_patterns
          check_if_spec_is_empty
        end

        private

        attr_reader :consumer

        # Checks the attributes hash for any unknown key which might be the
        # result of a misspell in JSON file.
        #
        # @note Sub-keys are not checked per-platform as
        #       there is no attribute supporting this combination.
        #
        # @note The keys of sub-keys are not checked as they are only used by 
        #       the `source` attribute and they are subject
        #       to change according the support in the
        #       `cocoapods-downloader` gem.
        #
        def check_for_unknown_keys
          Pod::Specification::DSL.attributes
          attributes_keys = Pod::Specification::DSL.attributes.keys.map(&:to_s)
          platform_keys = Specification::DSL::PLATFORMS.map(&:to_s)
          valid_keys = attributes_keys + platform_keys
          keys = consumer.spec.attributes_hash.keys
          unknown_keys = keys - valid_keys

          unknown_keys.each do |key|
            warning "Unrecognized `#{key}` key"
          end

         Pod::Specification::DSL.attributes.each do |key, attribute|
           if attribute.keys
             value = consumer.spec.attributes_hash[key.to_s]
             if value
               if attribute.keys.is_a?(Array)
                 unknown_keys = value.keys - attribute.keys.map(&:to_s)
                 unknown_keys.each do |key|
                   warning "Unrecognized `#{key}` key for " \
                     "`#{attribute.name}` attribute"
                 end
               end
             end
           end
         end
        end

        # Checks the attributes that represent file patterns.
        #
        # @todo Check the attributes hash directly.
        #
        def validate_file_patterns
          attributes = DSL.attributes.values.select(&:file_patterns?)
          attributes.each do |attrb|
            patterns = consumer.send(attrb.name)
            if patterns.is_a?(Hash)
              patterns = patterns.values.flatten(1)
            end
            patterns.each do |pattern|
              if pattern.start_with?('/')
                error '[File Patterns] File patterns must be relative ' \
                "and cannot start with a slash (#{attrb.name})."
              end
            end
          end
        end

        # Check empty subspec attributes
        #
        def check_if_spec_is_empty
          methods = %w( source_files resources resource_bundles preserve_paths dependencies
                        vendored_libraries vendored_frameworks )
          empty_patterns = methods.all? { |m| consumer.send(m).empty? }
          empty = empty_patterns && consumer.spec.subspecs.empty?
          if empty
            error "[File Patterns] The #{consumer.spec} spec is empty"
            '(no source files, ' \
            'resources, resource_bundles, preserve paths,' \
            'vendored_libraries, vendored_frameworks dependencies' \
            'or subspecs).'
          end
        end
      end
    end
  end
end
