module Pod

  # The {Source} class is responsible to manage a collection of podspecs.
  #
  # @note The backing store of the podspecs collection is an implementation detail
  # abstracted from the rest of CocoaPods.
  #
  # @note The default implementation uses a git repo as a backing store, where the
  # podspecs are namespaced as:
  #
  #     #{POD_NAME}/#{VERSION}/#{POD_NAME}.podspec
  #
  class Source

    # @return [Pathname] the location of the repo of the source.
    #
    attr_reader :repo

    # @param  [Pathname] repo @see #repo.
    #
    def initialize(repo)
      @repo = repo
    end

    # @return [String] the name of the source.
    #
    def name
      @repo.basename.to_s
    end

    #---------------------------------------------------------------------------#

    # @!group Queering the source

    # @return [Array<String>] the list of the name of all the Pods.
    #
    def pods
      @repo.children.map do |child|
        child.basename.to_s if child.directory? && child.basename.to_s != '.git'
      end.compact
    end

    # @return [Array<Sets>] the sets of all the Pods.
    #
    def pod_sets
      pods.map { |pod| Specification::Set.new(pod, self) }
    end

    # @return [Array<Version>] all the available versions for the Pod, sorted
    #         from highest to lowest.
    #
    # @param  [String] name
    #         the name of the Pod.
    #
    def versions(name)
      pod_dir = repo + name
      pod_dir.children.map do |v|
        basename = v.basename.to_s
        Version.new(basename) if v.directory? && basename[0,1] != '.'
      end.compact.sort.reverse
    end

    # @return [Specification] the specification for a given version of Pod.
    #
    # @param  [String] name
    #         the name of the Pod.
    #
    # @param  [Version,String] version
    #         the version for the specification.
    #
    def specification(name, version)
      specification_path = repo + name + version.to_s + "#{name}.podspec"
      Specification.from_file(specification_path)
    end

    #---------------------------------------------------------------------------#

    # @!group Searching the source

    # @return [Set] a set for a given dependency. The set is identified by the
    #               name of the dependency and takes into account subspecs.
    #
    def search(dependency)
      pod_sets.find do |set|
        # First match the (top level) name, which does not yet load the spec from disk
        set.name == dependency.pod_name &&
          # Now either check if it's a dependency on the top level spec, or if it's not
          # check if the requested subspec exists in the top level spec.
          set.specification.subspec_by_name(dependency.name)
      end
    end

    # @return [Array<Set>] The list of the sets that contain the search term.
    #
    # @param  [String] query
    #         the search term.
    #
    # @param  [Bool] full_text_search
    #         whether the search should be limited to the name of the Pod or
    #         should include also the author, the summary, and the description.
    #
    # @note   full text search requires to load the specification for each pod,
    #         hence is considerably slower.
    #
    def search_by_name(query, full_text_search = false)
      pod_sets.map do |set|
        text = if full_text_search
          s = set.specification
          "#{s.name} #{s.authors} #{s.summary} #{s.description}"
        else
          set.name
        end
        set if text.downcase.include?(query.downcase)
      end.compact
    end

    #---------------------------------------------------------------------------#

    # The {Aggregate} manages a directory of sources repositories.
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
      #         {Sources} that contain the Pod. If no sources containing the
      #         Pod where found it returns nil.
      #
      # @raise  If no source including the set can be found.
      #
      # @see    Source#search
      #
      def search(dependency)
        sources = all.select { |s| !s.search(dependency).nil? }
        Specification::Set.new(dependency.pod_name, sources) unless sources.empty?
      end

      # @return [Array<Set>]  the sets that contain the search term.
      #
      # @raise  If no source including the set can be found.
      #
      # @see    Source#search_by_name
      #
      def search_by_name(query, full_text_search = false)
        pods_by_source = {}
        result = []
        all.each { |s| pods_by_source[s] = s.search_by_name(query, full_text_search).map(&:name) }
        pod_names = pods_by_source.values.flatten.uniq
        pod_names.each do |pod|
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
      # @raise  If the repos dir doesn't exits.
      #
      def dirs
        repos_dir.children.select(&:directory?)
      end
    end
  end
end
