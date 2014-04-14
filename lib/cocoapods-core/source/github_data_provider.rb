module Pod
  class Source
    # Data provider for a `Pod::Source` backed by a repository hosted on GitHub
    # and accessed via the HTTP API. Only pure JSON repos using the `Specs`
    # subdir to store the specifications are supported.
    #
    class GitHubDataProvider < AbstractDataProvider
      # @return [String] The identifier of the repository (user name and repo
      #         name) or the full URL of the repo.
      #
      attr_reader :repo_id

      # @return [String] The branch of the repo if the default one shouldn't be
      #         used.
      #
      attr_reader :branch

      # @param [String] repo_id @see repo_id
      # @param [String] branch @see branch
      #
      def initialize(repo_id, branch = nil)
        @repo_id = repo_id
        @branch = branch
      end

      public

      # @group Data Source
      #-----------------------------------------------------------------------#

      # @return [String] The name of the Source. User name and repo.
      #
      def name
        GitHub.normalized_repo_id(repo_id)
      end

      # @return [String] The user friendly type of the source.
      #
      def type
        'GitHub API'
      end

      # @return [Array<String>] The list of the name of all the Pods known to
      #         the Source.
      #
      def pods
        root_contents = get_github_contents('Specs')
        pods = dir_names(root_contents)
        pods.sort if pods
      end

      # @return [Array<String>] All the available versions of a given Pod,
      #         sorted from highest to lowest.
      #
      # @param  [String] name
      #         The name of the Pod.
      #
      def versions(name)
        raise ArgumentError, 'No name' unless name
        contents = get_github_contents("Specs/#{name}")
        pre_vers = dir_names(contents)
        return nil if pre_vers.nil?
        pre_vers.each do |v|
          Version.new(v)
        end.sort.reverse.map(&:to_s)
      end

      # @return [Specification] The specification for a given version of a Pod.
      #
      # @param  [String] name
      #         The name of the Pod.
      #
      # @param  [String] version
      #         The version of the Pod.
      #
      def specification(name, version)
        raise ArgumentError, 'No name' unless name
        raise ArgumentError, 'No version' unless version
        spec_content = specification_contents(name, version)
        if spec_content
          Pod::Specification.from_json(spec_content)
        end
      end

      # @return [Specification] The contents of the specification for a given
      #         version of a Pod.
      #
      # @param  [String] name
      #         the name of the Pod.
      #
      # @param  [String] version
      #         the version of the Pod.
      #
      def specification_contents(name, version)
        raise ArgumentError, 'No name' unless name
        raise ArgumentError, 'No version' unless version
        path = "Specs/#{name}/#{version}/#{name}.podspec.json"
        file_contents = get_github_contents(path)
        if file_contents
          if file_contents['encoding'] == 'base64'
            require 'base64'
            Base64.decode64(file_contents['content'])
          end
        end
      end

      private

      # @group Private Helpers
      #-----------------------------------------------------------------------#

      # Performs a get request with the given URL.
      #
      # @param [String] url
      #        The URL of the resource.
      #
      # @return [Array, Hash] The information of the resource as Ruby objects.
      #
      def get_github_contents(path = nil)
        Pod::GitHub.contents(repo_id, path, branch)
      end

      # @param  [Array] [Array<Hash>] The contents of a directory.
      #
      # @return [Array<String>] Returns the list of the directories given the
      #         contents returned for the API of a directory.
      #
      # @return [Nil] If the directory was not found or the contents is not an
      #         array.
      #
      def dir_names(contents)
        if contents.is_a?(Array)
          contents.map do |entry|
            if entry['type'] == 'dir'
              entry['name']
            end
          end.compact
        end
      end

      #-----------------------------------------------------------------------#
    end
  end
end
