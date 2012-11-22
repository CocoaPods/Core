module Pod
  class Specification

    module YAMLSupport

      # No support for hooks
      # No support for regular expressions
      # Needs to store the encoder version

      def to_hash
        hash = {}
        attributes = Specification::DSL.attributes

        attributes.each do |attrb|
          value = instance_variable_get(attrb.ivar)
          next if is_empty?(value)
          value = prepare_value(value)
          hash[attrb.name.to_s] = value
        end

        if subspecs && !subspecs.empty?
          hash['subspecs'] = subspecs.map { |s| s.to_hash }
        end

        available_platforms.each do |platform|
          activate_platform(platform)
          dependencies = external_dependencies.map(&:to_s)
          unless dependencies.empty?
            hash['dependencies'] ||= {}
            hash['dependencies'][platform.name] = dependencies
          end
        end

        hash
      end

      def is_empty?(value)
        return true unless value
        case value
        when Hash  then is_empty?(value.values)
        when Array then value.compact.all?{|v| is_empty?(v)}
        else false end
      end

      def prepare_value(value)
        case value
        when Version then value.version
        when Platform
          [value.name, value.deployment_target ? value.deployment_target.version : nil]
        else value end
      end

      def to_yaml
        to_hash.to_yaml
      end

      def self.from_hash(hash)
        spec = Spec.new
        spec
      end

    end
  end
end
