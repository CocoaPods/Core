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
      if requires_update?
        super
      else
        []
      end
    end

    private

    # Returns whether a source requires updating.
    #
    # @param [Source] source
    #        The source to check.
    #
    # @return [Bool] Whether the given source should be updated.
    #
    def requires_update?
      commit_hash = git_commit_hash
      GitHub.modified_since_commit('CocoaPods/Specs', commit_hash)
    end
  end
end
