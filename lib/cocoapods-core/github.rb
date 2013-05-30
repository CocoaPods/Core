module Pod

  # Allows to access information about the GitHub repos.
  #
  # This class is stored in Core because it might be used by web services.
  #
  module GitHub

    # Returns the information of a user.
    #
    # @param  [String] login
    #         The name of the user.
    #
    # @return [Hash] The data of user.
    #
    def self.user(login)
      peform_request("https://api.github.com/users/#{login}")
    end

    # Returns the information of a repo.
    #
    # @param  [String] url
    #         The URL of the repo.
    #
    # @return [Hash] The hash containing the data as reported by GitHub.
    #
    def self.repo(url)
      if repo_id = repo_id_from_url(url)
        peform_request("https://api.github.com/repos/#{repo_id}")
      end
    end

    # Returns the tags of a repo.
    #
    # @param  [String] url @see #repo
    #
    # @return [Array] The list of the tags.
    #
    def self.tags(url)
      if repo_id = repo_id_from_url(url)
        peform_request("https://api.github.com/repos/#{repo_id}/tags")
      end
    end

    # Returns the branches of a repo.
    #
    # @param  [String] url @see #repo
    #
    # @return [Array] The list of the branches.
    #
    def self.branches(url)
      if repo_id = repo_id_from_url(url)
        peform_request("https://api.github.com/repos/#{repo_id}/branches")
      end
    end

    private

    #-------------------------------------------------------------------------#

    # @!group Private helpers

    # Returns the repo ID given it's URL.
    #
    # @param [String] url
    #        The URL of the repo.
    #
    # @return [String] the repo ID.
    #
    def self.repo_id_from_url(url)
      url[/github.com\/([^\/\.]*\/[^\/\.]*)\.*/, 1]
    end

    # Performs a get request with the given URL.
    #
    # @param [String] url
    #        The URL of the resource.
    #
    # @return [Array, Hash] The information of the resource as Ruby objects.
    #
    def self.peform_request(url)
      require 'rest'
      require 'json'
      response = REST.get(url)
      JSON.parse(response.body)
    end

    #-------------------------------------------------------------------------#

  end
end
