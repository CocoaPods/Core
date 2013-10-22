require 'active_support/core_ext/array/conversions'
require 'cocoapods-core/specification/set/presenter'
require 'cocoapods-core/specification/set/statistics'


module Pod
  class Specification

    # A Specification::Set is responsible of handling all the specifications of
    # a Pod. This class stores the information of the dependencies that required
    # a Pod in the resolution process.
    #
    # @note   The alphabetical order of the sets is used to select a
    #         specification if multiple are available for a given version.
    #
    # @note   The set class is not and should be not aware of the backing store
    #         of a Source.
    #
    class Set

      # @return [String] the name of the Pod.
      #
      attr_reader :name

      # @return [Array<Source>] the sources that contain the specifications for
      #         the available versions of a Pod.
      #
      attr_reader :sources

      # @param  [String] name
      #         the name of the Pod.
      #
      # @param  [Array<Source>,Source] sources
      #         the sources that contain a Pod.
      #
      def initialize(name, sources = [])
        @name    = name
        sources  = sources.is_a?(Array) ? sources : [sources]
        @sources = sources.sort_by(&:name)
        @required_by  = []
        @dependencies = []
      end

      # Stores a dependency on the Pod.
      #
      # @param  [Dependency] dependency
      #         a dependency that requires the Pod.
      #
      # @param  [String] dependent_name
      #         the name of the owner of the dependency.  It is used only to
      #         display the Pod::Informative.
      #
      # @raise  If the versions requirement of the dependency are not
      #         compatible with the previously stored dependencies.
      #
      # @todo   This should simply return a boolean. Is CocoaPods that should
      #         raise.
      #
      # @return [void]
      #
      def required_by(dependency, dependent_name)
        # TODO
        unless @required_by.empty? || dependency.requirement.satisfied_by?(required_version)
          raise Informative, "#{dependent_name} tries to activate " \
            "`#{dependency}', but already activated version " \
              "`#{required_version}' by #{@required_by.to_sentence}."
        end
        @specification = nil
        @required_by  << dependent_name
        @dependencies << dependency
      end

      # @return [Dependency] A dependency that includes all the versions
      #         requirements of the stored dependencies.
      #
      def dependency
        @dependencies.inject(Dependency.new(name)) do |previous, dependency|
          previous.merge(dependency.to_root_dependency)
        end
      end

      # @return [Specification] the top level specification of the Pod for the
      #         {#required_version}.
      #
      # @note   If multiple sources have a specification for the
      #         {#required_version} The alphabetical order of their names is
      #         used to disambiguate.
      #
      def specification
        path = specification_path_for_version(required_version)
        @specification ||= Specification.from_file(path)
      end

      # TODO
      #
      def specification_path_for_version(version)
        sources = []
        versions_by_source.each do |source, source_versions|
          sources << source if source_versions.include?(required_version)
        end
        source = sources.sort_by(&:name).first
        source.specification_path(name, required_version)
      end

      # @return [Version] the highest version that satisfies the stored
      #         dependencies.
      #
      # @todo   This should simply return nil. CocoaPods should raise instead.
      #
      def required_version
        version = versions.find { |v| dependency.match?(name, v) }
        unless version
          raise Informative, "Required version (#{dependency}) not found " \
            "for `#{name}`.\nAvailable versions: #{versions.join(', ')}"
        end
        version
      end

      # @return [Array<Version>] all the available versions for the Pod, sorted
      #         from highest to lowest.
      #
      def versions
        versions_by_source.values.flatten.uniq.sort.reverse
      end

      # @return [Version] The highest version known of the specification.
      #
      def highest_version
        versions.first
      end

      # @return [Pathname] The path of the highest version.
      #
      def highest_version_spec_path
        specification_path_for_version(highest_version)
      end

      # @return [Hash{Source => Version}] all the available versions for the
      #         Pod grouped by source.
      #
      def versions_by_source
        result = {}
        sources.each do |source|
          result[source] = source.versions(name)
        end
        result
      end

      def ==(other)
        self.class === other &&
          @name == other.name &&
          @sources.map(&:name) == other.sources.map(&:name)
      end

      def to_s
        "#<#{self.class.name} for `#{name}' with required version " \
          "`#{required_version}' available at `#{sources.map(&:name) * ', '}'>"
      end
      alias_method :inspect, :to_s

      # Returns a hash representation of the set composed by dumb data types.
      #
      # @example
      #
      #   "name" => "CocoaLumberjack",
      #   "versions" => { "master" => [ "1.6", "1.3.3"] },
      #   "highest_version" => "1.6",
      #   "highest_version_spec" => 'REPO/CocoaLumberjack/1.6/CocoaLumberjack.podspec'
      #
      # @return [Hash] The hash representation.
      #
      def to_hash
        versions = versions_by_source.inject({}) do |memo, (source, version)|
          memo[source.name] = version.map(&:to_s); memo
        end
        {
          'name' => name,
          'versions' => versions,
          'highest_version' => highest_version.to_s,
          'highest_version_spec' => highest_version_spec_path.to_s
        }
      end

      #-----------------------------------------------------------------------#

      # The Set::External class handles Pods from external sources. Pods from
      # external sources don't use the {Source} and are initialized by a given
      # specification.
      #
      # @note External sources *don't* support subspecs.
      #
      class External < Set

        attr_reader :specification

        def initialize(spec)
          @specification = spec.root
          super(@specification.name)
        end

        def ==(other)
          self.class === other && @specification == other.specification
        end

        def required_by(dependency, dependent_name)
          before = @specification
          super(dependency, dependent_name)
        ensure
          @specification = before
        end

        def specification_path
          raise StandardError, "specification_path"
        end

        def versions
          [@specification.version]
        end
      end
    end
  end
end
