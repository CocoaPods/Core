module Pod
  class Source

    # The Aggregate manages a directory of sources repositories.
    #
    class Aggregate

      # @return [Pathname] the directory were the repositories are stored.
      #
      attr_reader :repos_dir

      # @param [Pathname] repos_dir @see repos_dir.
      #
      def initialize(repos_dir)
        @repos_dir = repos_dir
      end

      # @return [Array<Source>] all the sources.
      #
      def all
        @sources ||= dirs.map { |repo| Source.new(repo) }.sort_by(&:name)
      end

      # @return [Array<String>] the names of all the pods available.
      #
      def all_pods
        all.map(&:pods).flatten.uniq
      end

      # @return [Array<Set>] the sets for all the pods available.
      #
      # @note   Implementation detail: The sources don't cache their values
      #         because they might change in response to an update. Therefore
      #         this method to prevent slowness caches the values before
      #         processing them.
      #
      def all_sets
        pods_by_source = {}
        all.each do |source|
          pods_by_source[source] = source.pods
        end
        sources = pods_by_source.keys
        pods = pods_by_source.values.flatten.uniq

        pods.map do |pod|
          pod_sources = sources.select{ |s| pods_by_source[s].include?(pod) }.compact
          Specification::Set.new(pod, pod_sources)
        end
      end

      # @return [Array<Pathname>] the directories where the sources are stored.
      #
      # @note   If the repos dir doesn't exits this will return an empty array.
      #
      # @raise  If the repos dir doesn't exits.
      #
      def dirs
        if repos_dir.exist?
          repos_dir.children.select(&:directory?)
        else
          []
        end
      end

      # Returns a set configured with the source which contains the highest
      # version in the aggregate.
      #
      # @param  [String] name
      #         The name of the Pod.
      #
      # @return [Set] The most representative set for the Pod with the given
      #         name.
      #
      def represenative_set(name)
        representative_source = nil
        highest_version = nil
        all.each do |source|
          source_versions = source.versions(name)
          if source_versions
            source_version = source_versions.first
            if highest_version.nil? || (highest_version < source_version)
              highest_version = source_version
              representative_source = source
            end
          end
        end
        Specification::Set.new(name, representative_source)
      end

      public

      # @!group Search
      #-----------------------------------------------------------------------#

      # @return [Set, nil] a set for a given dependency including all the
      #         {Source} that contain the Pod. If no sources containing the
      #         Pod where found it returns nil.
      #
      # @raise  If no source including the set can be found.
      #
      # @see    Source#search
      #
      def search(dependency)
        sources = all.select { |s| !s.search(dependency).nil? }
        Specification::Set.new(dependency.root_name, sources) unless sources.empty?
      end

      # @return [Array<Set>]  the sets that contain the search term.
      #
      # @raise  If no source including the set can be found.
      #
      # @todo   Clients should raise not this method.
      #
      # @see    Source#search_by_name
      #
      def search_by_name(query, full_text_search = false)
        pods_by_source = {}
        result = []
        all.each { |s| pods_by_source[s] = s.search_by_name(query, full_text_search).map(&:name) }
        root_spec_names = pods_by_source.values.flatten.uniq
        root_spec_names.each do |pod|
          sources = []
          pods_by_source.each{ |source, pods| sources << source if pods.include?(pod) }
          result << Specification::Set.new(pod, sources)
        end
        if result.empty?
          extra = ", author, summary, or description" if full_text_search
          raise(Informative, "Unable to find a pod with name" \
                "#{extra} matching `#{query}'")
        end
        result
      end

      public

      # @!group Search Index
      #-----------------------------------------------------------------------#

      # Generates from scratch the search data for all the sources of the
      # aggregate. This operation can take a considerable amount of time
      # (seconds) as it needs to evaluate the most representative podspec
      # for each Pod.
      #
      # @return [Hash{String=>Hash}] The search data of every set grouped by
      #         name.
      #
      def generate_search_index
        result = {}
        all_sets.each do |set|
          result[set.name] = search_data_from_set(set)
        end
        result
      end

      # Updates inline the given search data with the information stored in all
      # the sources. The update skips the Pods for which the version of the
      # search data is the same of the highest version known to the aggregate.
      # This can lead to updates in podspecs being skipped until a new version
      # is released.
      #
      # @note   This procedure is considerably faster as it only needs to
      #         load the most representative spec of the new or updated Pods.
      #
      # @return [Hash{String=>Hash}] The search data of every set grouped by
      #         name.
      #
      def update_search_index(search_data)
        enumerated_names = []
        all_sets.each do |set|
          enumerated_names << set.name
          set_data = search_data[set.name]
          has_data = set_data && set_data['version']
          needs_update = !has_data || Version.new(set_data['version']) < set.required_version
          if needs_update
            search_data[set.name] = search_data_from_set(set)
          end
        end

        stored_names = search_data.keys
        delted_names = stored_names - enumerated_names
        delted_names.each do |name|
          search_data.delete(name)
        end

        search_data
      end

      private

      # @!group Private helpers
      #-----------------------------------------------------------------------#

      # Returns the search related information from the most representative
      # specification of the set following keys:
      #
      #   - version
      #   - summary
      #   - description
      #   - authors
      #
      # @param  [Set] set
      #         The set for which the information is needed.
      #
      # @note   If the specification can't load an empty hash is returned and
      #         a warning is printed.
      #
      # @note   For compatibility with non Ruby clients a strings are used
      #         instead of symbols for the keys.
      #
      # @return [Hash{String=>String}] A hash with the search information.
      #
      def search_data_from_set(set)
        result = {}
        spec = set.specification
        result['version'] = spec.version.to_s
        result['summary'] = spec.summary
        result['description'] = spec.description
        result['authors'] = spec.authors.keys.sort * ', '
        result
      rescue
        CoreUI.warn "Skipping `#{set.name}` because the podspec contains errors."
        result
      end

      #-----------------------------------------------------------------------#

    end
  end
end
