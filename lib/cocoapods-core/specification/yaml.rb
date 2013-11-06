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
        unless subspecs.empty?
          hash["subspecs"] = subspecs.map { |spec| spec.to_hash }
        end
        hash
      end

      # @return [Bool] Whether the specification can be converted to a hash
      #         without loss of information.
      #
      def safe_to_hash?
        pre_install_callback.nil? && post_install_callback.nil?
      end

    end

    # Configures a new specification from the given hash.
    #
    # @param  [Hash] the hash which contains the information of the
    #         specification.
    #
    # @return [Specification] the specification
    #
    def self.from_hash(hash, parent = nil)
      spec = Spec.new(parent)
      attributes_hash = hash.dup
      subspecs = attributes_hash.delete('subspecs')
      spec.attributes_hash = attributes_hash
      if subspecs
        spec.subspecs = subspecs.map do |s_hash|
          Specification.from_hash(s_hash, spec)
        end
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
