module Pod
  class MasterSource < Source
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
      if requires_update
        super
      else
        []
      end
    end

    # Returns whether a source requires updating.
    #
    # @param [Source] source
    #        The source to check.
    #
    # @return [Bool] Whether the given source should be updated.
    #
    def requires_update
      current_commit_hash = '""'
      Dir.chdir(repo) do
        current_commit_hash = "\"#{(`git rev-parse HEAD`).strip}\""
      end

      url = 'https://github.com/cocoapods/specs'
      GitHub.modified_since_commit(url, current_commit_hash)
    end
  end
end
