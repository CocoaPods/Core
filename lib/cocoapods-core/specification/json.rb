module Pod
  class Specification
    module JSONSupport
      # @return [String] the json representation of the specification.
      #
      def to_json(*a)
        require 'json'
        to_hash.to_json(*a) << "\n"
      end

      # @return [String] the pretty json representation of the specification.
      #
      def to_pretty_json(*a)
        require 'json'
        JSON.pretty_generate(to_hash, *a) << "\n"
      end

      #-----------------------------------------------------------------------#

      # @return [Hash] the hash representation of the specification including
      #         subspecs.
      #
      def to_hash
        hash = attributes_hash.dup
        if root? || available_platforms != parent.available_platforms
          platforms = Hash[available_platforms.map { |p| [p.name.to_s, p.deployment_target && p.deployment_target.to_s] }]
          hash['platforms'] = platforms
        end
        unless subspecs.empty?
          hash['subspecs'] = subspecs.map(&:to_hash)
        end
        hash
      end
    end

    # Configures a new specification from the given JSON representation.
    #
    # @param  [String] the JSON encoded hash which contains the information of
    #         the specification.
    #
    #
    # @return [Specification] the specification
    #
    def self.from_json(json)
      require 'json'
      hash = JSON.parse(json)
      from_hash(hash)
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

    #-----------------------------------------------------------------------#
  end
end
