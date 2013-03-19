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

      #-----------------------------------------------------------------------#

    end
  end
end
