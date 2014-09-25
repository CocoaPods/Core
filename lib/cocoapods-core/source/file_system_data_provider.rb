module Pod
  class Source
    # Data provider for a `Pod::Source` backed by a repository hosted in the
    # file system.
    #
    class FileSystemDataProvider < AbstractDataProvider
      # @return [Pathname] The path where the source is stored.
      #
      attr_reader :repo

      # @param  [Pathname, String] repo @see #repo.
      #
      def initialize(repo)
        @repo = Pathname.new(repo)
      end

      public

      # @group Required methods
      #-----------------------------------------------------------------------#

      # @return [String] The name of the source.
      #
      def name
        repo.basename.to_s
      end

      # @return [String] The URL of the source.
      #
      def url
        Dir.chdir(repo) do
          remote = `git ls-remote --get-url`.chomp
          remote if $?.success?
        end
      end

      # @return [String] The user friendly type of the source.
      #
      def type
        'file system'
      end

      # @return [Array<String>] The list of the name of all the Pods known to
      #         the Source.
      #
      # @note   Using Pathname#children is sensibly slower.
      #
      def pods
        return nil unless specs_dir
        specs_dir_as_string = specs_dir.to_s
        Dir.entries(specs_dir).select do |entry|
          valid_name = entry[0, 1] != '.'
          valid_name && File.directory?(File.join(specs_dir_as_string, entry))
        end.sort
      end

      # @return [Array<String>] All the available versions of a given Pod,
      #         sorted from highest to lowest.
      #
      # @param  [String] name
      #         The name of the Pod.
      #
      def versions(name)
        return nil unless specs_dir
        raise ArgumentError, 'No name' unless name
        pod_dir = specs_dir + name
        return unless pod_dir.exist?
        pod_dir.children.map do |v|
          basename = v.basename.to_s
          begin
            Version.new(basename) if v.directory? && basename[0, 1] != '.'
          rescue ArgumentError => e
            raise Informative, 'An unexpected version directory ' \
             "`#{basename}` was encountered for the " \
             "`#{pod_dir}` Pod in the `#{name}` repository."
          end
        end.compact.sort.reverse.map(&:to_s)
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
        path = specification_path(name, version)
        Pod::Specification.from_file(path) if path && path.exist?
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
        path = specification_path(name, version)
        File.open(path, 'r:utf-8') { |f| f.read } if path && path.exist?
      end

      public

      # @group Other methods
      #-----------------------------------------------------------------------#

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
        return nil unless specs_dir
        path = specs_dir + name + version.to_s
        specification_path = path + "#{name}.podspec.json"
        specification_path.exist?
        unless specification_path.exist?
          specification_path = path + "#{name}.podspec"
        end
        specification_path
      end

      private

      # @group Private Helpers
      #-----------------------------------------------------------------------#

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
          end
        end
        @specs_dir
      end

      #-----------------------------------------------------------------------#
    end
  end
end
