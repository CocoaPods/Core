module Pod
  class Podfile

    # Model class which describes a Workspace.
    # CocoaPods supports only one workspace per
    # Podfile.
    #
    class Project

      # The name of the workspace.
      #
      attr_accessor :name

      # @return [Array<Target>] The targets described in the project.
      #
      attr_reader :targets

      def initialize
        @projects = []
      end

      def add_target(target)
        target << target
      end


      public

      # Hash conversion
      #-----------------------------------------------------------------------#

      HASH_KEYS = %w(
        name
        target
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

