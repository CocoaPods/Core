module Pod
  class Specification
    # This class validates and represents swift package manager dependecy requirements
    class SpmRequirement
      REQUIRED_KEYS = {
        :upToNextMajorVersion => [:minimumVersion],
        :upToNextMinorVersion => [:minimumVersion],
        :exactVersion => [:version],
        :versionRange => %i[minimumVersion maximumVersion],
      }.freeze

      def initialize(requirement_hash)
        @requirement = requirement_hash
        validate
      end

      def kind
        @requirement[:kind]
      end

      def ==(other)
        @requirement == other.instance_variable_get(:@requirement)
      end

      def validate
        raise 'Kind should be string' unless kind.is_a?(String)
        raise "Unknown requirement kind #{kind}" if REQUIRED_KEYS[kind.to_sym].nil?
    
        REQUIRED_KEYS[kind.to_sym].each do |key|
          raise "Missing key #{key} for requirement #{@requirement}" unless @requirement[key]
        end
      end

      def to_h
        @requirement.map { |k,v| [k.to_s, v.to_s] }.to_h
      end

      def self.validate(requirement_hash)
        if (requirement_hash.is_a? SpmRequirement)
          requirement_hash.validate
          nil
        else
          new(requirement_hash)
          nil
        end
      rescue => e
        e.message
      end
    end
  end
end