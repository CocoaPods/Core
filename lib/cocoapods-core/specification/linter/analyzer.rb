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
          validate_file_patterns
          check_if_spec_is_empty
        end

        private

        attr_reader :consumer

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
