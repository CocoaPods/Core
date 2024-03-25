require 'cocoapods-core/source/acceptor'
require 'cocoapods-core/source/aggregate'
require 'cocoapods-core/source/health_reporter'
require 'cocoapods-core/source/manager'
require 'cocoapods-core/source/metadata'

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
  class SingleSource < Source
    # @param  [Pathname, String] repo @see #repo.
    #
    def initialize(repo)
      super(repo)
      spec_paths
    end

    private 

    def raw_versions
      @version_tags ||= repo_git(%w(tag)).split(/\s+/).map do |v|
        version = Version.new(v) 
      rescue ArgumentError
      end.compact
    end

    def process_podspec(path, output_path)
      spec = Specification.from_file(path)
      File.open(output_path, 'w') { |f| f.write(spec.to_pretty_json) }
      output_path
    end

    def preload_podspecs_at_version(version)
      version_dir = repo.join('.git', '.specs', version.to_s)
      if version_dir.exist?
        Pathname.glob(version_dir.join('*'))
      else
        repo_git(['checkout', version.to_s])
        version_dir.mkpath
        Pathname.glob(repo.join('*.podspec')).map do |podspec_path|
          name = podspec_path.basename('.podspec')
          process_podspec(podspec_path, version_dir.join("#{name}.podspec.json"))
        end.compact
      end
    end

    def spec_paths
      raw_versions.map do |version|
        preload_podspecs_at_version(version)
      end.flatten
    end
  
    public

    # @!group Querying the source
    #-------------------------------------------------------------------------#

    # @return [Array<String>] the list of the name of all the Pods.
    #
    #
    def pods
      spec_paths.map do |spec_path|
        spec_path.basename('.podspec.json').to_s
      end.flatten.uniq.sort
    end

    # @return [Array<Version>] all the available versions for the Pod, sorted
    #         from highest to lowest.
    #
    # @param  [String] name
    #         the name of the Pod.
    #
    def versions(name)
      return nil unless pods.include?(name)
      @versions_by_name[name] ||= raw_versions.map do |version|
        if specification_path(name, version) 
          version 
        else 
          nil
        end
      end.compact.sort.reverse
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
      raise ArgumentError, 'No name' unless name
      raise ArgumentError, 'No version' unless version

      preload_podspecs_at_version(version)

      path = repo.join('.git', '.specs', version.to_s, "#{name}.podspec.json")

      return nil unless path.exist?

      path
    end

    # @return [Array<Specification>] all the specifications contained by the
    #         source.
    #
    def all_specs
      specs = spec_paths.map do |path|
        begin
          Specification.from_file(path)
        rescue
          CoreUI.warn "Skipping `#{path.relative_path_from(repo)}` because the " \
                      'podspec contains errors.'
          next
        end
      end
      specs.compact
    end
 

    # @!group Searching the source
    #-------------------------------------------------------------------------#

    # @return [Set] a set for a given dependency. The set is identified by the
    #               name of the dependency and takes into account subspecs.
    #
    # @note   This method is optimized for fast lookups by name, i.e. it does
    #         *not* require iterating through {#pod_sets}
    #
    # @todo   Rename to #load_set
    #
    def search(query)
      if query.is_a?(Dependency)
        query = query.root_name
      end

      if (versions = versions(query)) && !versions.empty?
        set = set(query)
        return set if set.specification_name == query
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
    # @todo   Rename to #search
    #
    def search_by_name(query, full_text_search = false)
      regexp_query = /#{query}/i
      
      names = pods.grep(regexp_query)
      names.map { |pod_name| set(pod_name) }
    end

    # @!group Updating the source
    #-------------------------------------------------------------------------#

    # Updates the local clone of the source repo.
    #
    # @param  [Bool] show_output
    #
    # @return  [Array<String>] changed_spec_paths
    #          Returns the list of changed spec paths.
    #
    def update(show_output)
      result = super(show_output)
      repo.join('.git', '.specs').rmtree if repo.join('.git', '.specs').exist?
      all_specs
      result
    end

    def verify_compatibility!
    end

  end
end
