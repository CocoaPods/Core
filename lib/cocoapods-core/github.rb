module Pod

  # Allows to access information about the GitHub repos.
  #
  # This class is stored in Core because it might be used by web services.
  #
  module GitHub

    # Returns the information about a GitHub repo.
    #
    # @param  [String] The url of the repo.
    #
    # @return [Hash] The hash containing the data as reported by GtiHub.
    #
    def self.fetch_github_repo_data(url)
      require 'rest'
      require 'json'
      if repo_id = url[/github.com\/([^\/\.]*\/[^\/\.]*)\.*/, 1]
        url = "https://api.github.com/repos/#{repo_id}"
        response = REST.get(url)
        JSON.parse(response.body)
      end
    end

  end
end
