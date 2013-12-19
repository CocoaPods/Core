require 'cocoapods-core/source/acceptor'
require 'cocoapods-core/source/aggregate'
require 'cocoapods-core/source/health_reporter'

module Pod

  # The Source class is responsible to manage a collection of podspecs.
  #
  # The backing store of the podspecs collection is an implementation detail
  # abstracted from the rest of CocoaPods.
  #
  # The default implementation uses a git repo as a backing store, where the
  # podspecs are namespaced as:
  #
  #     "#{SPEC_NAME}/#{VERSION}/#{SPEC_NAME}.podspec"
  #
  class Source

    # @return [Pathname] the location of the repo of the source.
    #
    attr_reader :repo

    # @param  [Pathname, String] repo @see #repo.
    #
    def initialize(repo)
      @repo = Pathname.new(repo)
    end

    # @return [String] the name of the source.
    #
    def name
      repo.basename.to_s
    end

    alias_method :to_s, :name

    # @return [Integer] compares a source with another one for sorting
    #         purposes.
    #
    # @note   Source are compared by the alphabetical order of their name, and
    #         this convention should be used in any case where sources need to
    #         be disambiguated.
    #
    def <=>(other)
      name <=> other.name
    end

    #-------------------------------------------------------------------------#

    # @!group Queering the source

    # @return [Array<String>] the list of the name of all the Pods.
    #
    # @note   Using Pathname#children is sensibly slower.
    #
    def pods
      specs_dir_as_string = specs_dir.to_s
      Dir.entries(specs_dir).select do |entry|
        valid_name = !(entry == '.' || entry == '..' || entry == '.git')
        valid_name && File.directory?(File.join(specs_dir_as_string, entry))
      end
    end

    # Returns the set for the Pod with the given name.
    #
    # @param  [String] pod_name
    #         The name of the Pod.
    #
    # @return [Sets] the set.
    #
    def set(pod_name)
      Specification::Set.new(pod_name, self)
    end

    # @return [Array<Sets>] the sets of all the Pods.
    #
    def pod_sets
      pods.map { |pod_name| set(pod_name) }
    end

    # @return [Array<Version>] all the available versions for the Pod, sorted
    #         from highest to lowest.
    #
    # @param  [String] name
    #         the name of the Pod.
    #
    def versions(name)
      pod_dir = specs_dir + name
      return unless pod_dir.exist?
      pod_dir.children.map do |v|
        basename = v.basename.to_s
        Version.new(basename) if v.directory? && basename[0, 1] != '.'
      end.compact.sort.reverse
    end

    # @return [Specification] the specification for a given version of Pod.
    #
    # @param  @see specification_path
    #
    def specification(name, version)
      Specification.from_file(specification_path(name, version))
    end

    # Returns the path of the specification with the given name and version.
    #
    # @param  [String] name
    #         the name of the Pod.
    #
    # @param  [Version,String] version
    #         the version for the specification.
    #
    # @return [Pathname] The path of the specification.
    #
    def specification_path(name, version)
      path = specs_dir + name + version.to_s
      specification_path = path + "#{name}.podspec.json"
      unless specification_path.exist?
        specification_path = path + "#{name}.podspec"
      end
      unless specification_path.exist?
        raise StandardError, "Unable to find the specification #{name} " \
          "(#{version}) in the #{name} source."
      end
      specification_path
    end

    # @return [Array<Specification>] all the specifications contained by the
    #         source.
    #
    def all_specs
      specs = pods.map do |name|
        begin
          versions(name).map { |version| specification(name, version) }
        rescue
          CoreUI.warn "Skipping `#{name}` because the podspec contains errors."
          next
        end
      end
      specs.flatten.compact
    end

    #-------------------------------------------------------------------------#

    # @!group Searching the source

    # @return [Set] a set for a given dependency. The set is identified by the
    #               name of the dependency and takes into account subspecs.
    #
    # @todo   Rename to #load_set
    #
    def search(query)
      if query.is_a?(Dependency)
        name = query.root_name
      else
        name = query
      end
      pod_sets.find do |set|
        set.name == name
      end
    end

    # @return [Array<Set>] The list of the sets that contain the search term.
    #
    # @param  [String] query
    #         the search term. Can be a regular expression.
    #
    # @param  [Bool] full_text_search
    #         whether the search should be limited to the name of the Pod or
    #         should include also the author, the summary, and the description.
    #
    # @note   full text search requires to load the specification for each pod,
    #         hence is considerably slower.
    #
    def search_by_name(query, full_text_search = false)
      regexp_query = /#{query}/i
      if full_text_search
        pod_sets.reject do |set|
          texts = []
          begin
            s = set.specification
            texts << s.name
            texts += s.authors.keys
            texts << s.summary
            texts << s.description
          rescue
            CoreUI.warn "Skipping `#{set.name}` because the podspec " \
              "contains errors."
          end
          texts.grep(regexp_query).empty?
        end
      else
        names = pods.grep(regexp_query)
        names.map { |pod_name| set(pod_name) }
      end
    end

    # Returns the set of the Pod whose name fuzzily matches the given query.
    #
    # @param  [String] query
    #         The query to search for.
    #
    # @return [Set] The name of the Pod.
    # @return [Nil] If no Pod with a suitable name was found.
    #
    def fuzzy_search(query)
      require 'fuzzy_match'
      pod_name = FuzzyMatch.new(pods).find(query)
      if pod_name
        search(pod_name)
      end
    end

    #-------------------------------------------------------------------------#

    # @!group Representations

    # @return [Hash{String=>{String=>Specification}}] the static representation
    #         of all the specifications grouped first by name and then by
    #         version.
    #
    def to_hash
      hash = {}
      all_specs.each do |spec|
        hash[spec.name] ||= {}
        hash[spec.name][spec.version.version] = spec.to_hash
      end
      hash
    end

    # @return [String] the YAML encoded {to_hash} representation.
    #
    def to_yaml
      require 'yaml'
      to_hash.to_yaml
    end

    private

    #-------------------------------------------------------------------------#

    # @group Private Helpers

    # @return [Pathname] The directory where the specs are stored.
    #
    # @note   In previous versions of CocoaPods they used to be stored in
    #         the root of the repo. This lead to issues, especially with
    #         the GitHub interface and now the are stored in a dedicated
    #         folder.
    #
    def specs_dir
      unless @specs_dir
        specs_sub_dir = repo + 'Specs'
        if specs_sub_dir.exist?
          @specs_dir = specs_sub_dir
        elsif repo.exist?
          @specs_dir = repo
        else
          raise Informative, "Unable to find a source named: `#{name}`"
        end
      end
      @specs_dir
    end

    #-------------------------------------------------------------------------#

  end
end
