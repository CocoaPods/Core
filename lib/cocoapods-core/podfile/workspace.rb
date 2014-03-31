module Pod
  class Podfile

    # Model class which describes a Workspace.
    # CocoaPods supports only one workspace per
    # Podfile.
    #
    class Workspace < BaseModel

      # The name of the workspace.
      #
      attr_accessor :name

      # @return [Array<Project>] The projects described in the workspace.
      #
      attr_reader :projects

      def initialize
        @projects = []
      end

      # Adds a project to the list of the projects described by this
      # workspace.
      #
      # @param  [Project] the project to add.
      #
      # @return [void]
      #
      def add_project(project)
        unless project.is_a?(Project)
          raise ArgumentError, 'Attempt to add a project which is not an' \
            'instance of Podfile::Project'
        end
        projects << project
      end


      public

      # Hash conversion
      #-----------------------------------------------------------------------#

      # @return [Array<String>] The keys used to serialize this model.
      #
      HASH_KEYS = %w(
        name
        projects
      )

      # @return [Hash] The serialized representation of the workspace.
      #
      def to_hash

      end

      # Configures a new target definition from the given hash.
      #
      # @param  [Hash] A hash containing a serialized workspace.
      #
      # @return [Workspace] A new workspace initialized with the given hash.
      #
      def self.from_hash(hash, parent)

      end
    end
  end
end
