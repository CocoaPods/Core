module Pod
  class Specification
    module YAMLSupport

      # @return [String] the yaml representation of the specification.
      #
      def to_yaml
        to_hash.to_yaml
      end

      # @return [Hash] the hash representation of the specification including
      #         subspecs.
      #
      def to_hash
        hash = attributes_hash.dup
        hash["subspecs"] = subspecs.map { |spec| spec.to_hash } unless subspecs.empty?
        hash
      end

      # @return [Bool] Whether the specification can be converted to a hash
      #         without loss of information.
      #
      def safe_to_hash?
        !has_file_list(self) && pre_install_callback.nil? && post_install_callback.nil?
      end

      # @return [Bool] If any of the specs uses the FileList class.
      #
      def has_file_list(spec)
        result = false
        all_specs = [ spec, *spec.recursive_subspecs ]
        all_specs.each do |current_spec|
          current_spec.available_platforms.each do |platform|
            consumer = Specification::Consumer.new(current_spec, platform)
            attributes = DSL.attributes.values.select(&:file_patterns?)
            attributes.each do |attrb|
              patterns = consumer.send(attrb.name)
              if patterns.is_a?(Hash)
                patterns = patterns.values.flatten(1)
              end
              patterns.each do |pattern|
                if pattern.is_a?(Rake::FileList)
                  result = true
                end
              end
            end
          end
        end
        result
      end
    end

    # Configures a new specification from the given hash.
    #
    # @param  [Hash] the hash which contains the information of the
    #         specification.
    #
    # @return [Specification] the specification
    #
    def self.from_hash(hash)
      spec = Spec.new
      attributes_hash = hash.dup
      subspecs = attributes_hash.delete('subspecs')
      spec.attributes_hash = attributes_hash
      if subspecs
        spec.subspecs = subspecs.map { |s_hash| Specification.from_hash(s_hash) }
      end
      spec
    end

    # Configures a new specification from the given YAML representation.
    #
    # @param  [String] the YAML encoded hash which contains the information of
    #         the specification.
    #
    #
    # @return [Specification] the specification
    #
    def self.from_yaml(yaml)
      hash = YAML.load(yaml)
      from_hash(hash)
    end
  end
end
