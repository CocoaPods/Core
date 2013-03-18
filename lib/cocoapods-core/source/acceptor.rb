module Pod
  class Source

    # Checks whether a podspec can be accepted by a source. The check takes
    # into account the introduction of 0.0.1 version if there are already
    # tagged ones or whether there is change in the source.
    #
    class Acceptor

      # @return [Source] the source where the podspec should be added.
      #
      attr_reader :source

      # @param  [Pathname] repo @see Source#repo.
      #
      def initialize(repo)
        @source = Source.new(repo)
      end

      public

      # @!group Actions
      #-----------------------------------------------------------------------#

      # Checks whether the given specification can be accepted.
      #
      # @return [Array<String>] A list of errors. If the list is empty the
      #         specification should be accepted.
      #
      def analyze(spec, previous_spec = nil)
        errors = []
        check_spec_source_change(spec, errors)
        check_if_untagged_version_is_acceptable(spec, errors)
        check_commit_change_for_untagged_version(spec, previous_spec, errors)
        check_dependencies(spec, errors)
        errors
      end

      # Checks whether the specification at the given path can be accepted.
      #
      # @return [Array<String>] A list of errors. If the list is empty the
      #         specification should be accepted.
      #
      def analyze_path(spec_path)
        spec = Specification.from_file(spec_path)
        analyze(spec)
      rescue
        ["Unable to load the specification."]
      end

      private

      # @!group Private helpers
      #-----------------------------------------------------------------------#

      # Checks whether the source of the proposed specification is different
      # from the one of the reference specification.
      #
      # @return [void]
      #
      def check_spec_source_change(spec, errors)
        return unless spec
        return unless reference_spec(spec)
        keys = Spec::DSL::SOURCE_KEYS.keys
        source = spec.source.values_at(*keys).compact.first
        old_source = reference_spec(spec).source.values_at(*keys).compact.first
        unless source == old_source
          errors << "The source of the spec doesn't match with the recorded ones." \
            "Source: `#{source}`. Previous: `#{old_source}`.\n " \
            "Please contact the specs repo maintainers if the library changed " \
            "location."
        end
      end

      # Checks there are already tagged specifications if the specification has
      # a git source and doesn't specify a tag (i.e. rejects 0.0.1 specs if
      # they are not admissible anymore).
      #
      # @return [void]
      #
      def check_if_untagged_version_is_acceptable(spec, errors)
        return if !spec.source[:git] || spec.source[:tag]
        return unless related_specifications(spec)
        has_tagged_spec = related_specifications(spec).any? { |s| s.version != '0.0.1' }
        if has_tagged_spec
          errors << "There is already at least one versioned specification so " \
            "untagged versions cannot be accepted."
        end
      end

      # If the previous specification for the given file is passed it is
      # checked for any attempt to update the commit of a 0.0.1 version.
      #
      # @return [void]
      #
      def check_commit_change_for_untagged_version(spec, previous_spec, errors)
        return unless previous_spec
        return unless spec.version == Version.new('0.0.1')
        unless spec.source[:commit] == previous_spec.source[:commit]
          errors << "Attempt to rewrite the commit of a 0.0.1 version."
        end
      end

      # Checks that there is a specification available for the dependencies of
      # the given specification.
      #
      # @return [void]
      #
      def check_dependencies(spec, errors)
        spec.dependencies.each do |dep|
          set = source.search(dep)
          unless set && set.specification
            errors << "Unable to find a specification for the `#{dep}` dependency."
          end
        end
      end

      private

      # @!group Source helpers
      #-----------------------------------------------------------------------#

      # Returns the specifications related to the given spec.
      #
      # @param  [Specification] spec
      #         The specification for which the siblings specs are needed.
      #
      # @return [Array<Specification>] The other specifications of the Pod.
      #
      # @return [Nil] If there are no other specifications stored.
      #
      def related_specifications(spec)
        versions = source.versions(spec.name)
        return unless versions
        specs = versions.sort.map { |v| source.specification(spec.name, v) }
        specs.delete(spec)
        specs
      end

      # Returns the most representative specification for the Pod of the given
      # spec.
      #
      # @param  [Specification] spec
      #         The specification for which the representative spec is needed.
      #
      # @return [Specification] The specification with the highest version.
      #
      # @return [Nil] If there are no other specifications stored.
      #
      def reference_spec(spec)
        specs = related_specifications(spec)
        specs.last if specs
      end

      #-----------------------------------------------------------------------#

    end
  end
end
