module Pod

  # Allows to access information about the GitHub repos.
  #
  # This class is stored in Core because it might be used by web services.
  #
  module GitHub

    # @return [Hash]
    #
    def self.user(name)
      peform_request("https://api.github.com/users/#{name}")
    end

    # Returns the information about a GitHub repo.
    #
    # @param  [String] The URL of the repo.
    #
    # @return [Hash] The hash containing the data as reported by GitHub.
    #
    def self.fetch_github_repo_data(url)
      if repo_id = repo_id_from_url(url)
        peform_request("https://api.github.com/repos/#{repo_id}")
      end
    end

    # @return [Array]
    #
    def self.tags(url)
      if repo_id = repo_id_from_url(url)
        peform_request("https://api.github.com/repos/#{repo_id}/tags")
      end
    end

    # @return [Array]
    #
    def self.branches(url)
      if repo_id = repo_id_from_url(url)
        peform_request("https://api.github.com/repos/#{repo_id}/branches")
      end
    end

    private

    #-------------------------------------------------------------------------#

    # @!group Private helpers

    # @return [String]
    #
    def self.repo_id_from_url(url)
      url[/github.com\/([^\/\.]*\/[^\/\.]*)\.*/, 1]
    end

    def self.peform_request(url)
      require 'rest'
      require 'json'
      response = REST.get(url)
      JSON.parse(response.body)
    end

    #-------------------------------------------------------------------------#

  end
end
