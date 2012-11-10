module Pod
  class Command
    class Linter

      # TODO: Add check to ensure that attributes inherited by subspecs are not duplicated ?

      attr_accessor :quick, :no_clean, :repo_path

      # @return [Bool] Wether the lint should be performed against the root of
      #   the podspec instead to its original source. Uses the `:local` option
      #   of the Podfile.
      #
      attr_accessor :local
      alias :local? :local

      attr_reader   :spec, :file
      attr_reader   :errors, :warnings, :notes

      def initialize(podspec)
        @file = podspec
      end

      def spec_name
        name = file.basename('.*').to_s
        if @spec
          name << " (#{spec.version})"
        elsif @repo_path
          name << " (#{file.dirname.basename})"
        end
        name
      end

      # Takes an array of podspec files and lints them all
      #
      # It returns true if the spec passed validation
      #
      def lint
        @errors, @warnings, @notes = [], [], []
        @platform_errors, @platform_warnings, @platform_notes = {}, {}, {}

        if !deprecation_errors.empty?
          @errors = deprecation_errors
          @errors << "#{spec_name} [!] Fatal errors found skipping the rest of the validation"
        else
          @spec = Specification.from_file(file)
          platforms = spec.available_platforms

          if @repo_path
            expected_path = "#{@spec.name}/#{@spec.version}/#{@spec.name}.podspec"
            path = file.relative_path_from(@repo_path).to_s
            @errors << "Incorrect path, the path is `#{file}` and should be `#{expected_path}`" unless path.end_with?(expected_path)
          end

          platforms.each do |platform|
            @platform_errors[platform], @platform_warnings[platform], @platform_notes[platform] = [], [], []

            spec.activate_platform(platform)
            @platform = platform
            puts "\n\n#{spec} - Analyzing on #{platform} platform.".green.reversed if config.verbose? && !@quick

            # Skip validation if there are errors in the podspec as it would result in a crash
            if !podspec_errors.empty?
              @platform_errors[platform]   += podspec_errors
              @platform_notes[platform]    << "#{platform.name} [!] Fatal errors found skipping the rest of the validation"
            else
              @platform_warnings[platform] += podspec_warnings
              peform_extensive_analysis unless quick
            end
          end

          # Get common messages
          @errors   += @platform_errors.values.reduce(:&)
          @warnings += @platform_warnings.values.reduce(:&)
          @notes    += @platform_notes.values.reduce(:&)

          platforms.each do |platform|
            # Mark platform specific messages
            @errors   += (@platform_errors[platform] - @errors).map {|m| "[#{platform}] #{m}"}
            @warnings += (@platform_warnings[platform] - @warnings).map {|m| "[#{platform}] #{m}"}
            @notes    += (@platform_notes[platform] - @notes).map {|m| "[#{platform}] #{m}"}
          end
        end
      end

      def result_type
        return :error   unless errors.empty?
        return :warning unless warnings.empty?
        return :note    unless notes.empty?
        :success
      end


      # It reads a podspec file and checks for strings corresponding
      # to features that are or will be deprecated
      #
      # @return [Array<String>]
      #
      def deprecation_errors
        text = @file.read
        deprecations = []
        deprecations << "`config.ios?' and `config.osx?' are deprecated"              if text. =~ /config\..?os.?/
        deprecations << "clean_paths are deprecated and ignored (use preserve_paths)" if text. =~ /clean_paths/
        deprecations
      end

      # @return [Array<String>] List of the fatal defects detected in a podspec
      def podspec_errors
        messages = []
        messages << "The name of the spec should match the name of the file" unless names_match?
        messages << "The summary should be short use `description` (max 140 characters)." if spec.summary && spec.summary.length > 140
        messages << "The spec appears to be empty (no source files, resources, or preserve paths)" if spec.source_files.empty? && spec.subspecs.empty? && spec.resources.empty? && spec.preserve_paths.empty?
        messages += paths_starting_with_a_slash_errors
        messages += deprecation_errors
        messages
      end

      def names_match?
        return true unless spec.name
        root_name = spec.name.match(/[^\/]*/)[0]
        file.basename.to_s == root_name + '.podspec'
      end

      def source_valid?
        spec.source && !(spec.source =~ /http:\/\/EXAMPLE/)
      end

      def paths_starting_with_a_slash_errors
        messages = []
        %w[source_files public_header_files resources clean_paths].each do |accessor|
          patterns = spec.send(accessor.to_sym)
          # Some values are multiplaform
          patterns = patterns.is_a?(Hash) ? patterns.values.flatten(1) : patterns
          patterns = patterns.compact # some patterns may be nil (public_header_files, for instance)
          patterns.each do |pattern|
            # Skip FileList that would otherwise be resolved from the working directory resulting
            # in a potentially very expensi operation
            next if pattern.is_a?(FileList)
            invalid = pattern.is_a?(Array) ? pattern.any? { |path| path.start_with?('/') } : pattern.start_with?('/')
            if invalid
              messages << "Paths cannot start with a slash (#{accessor})"
              break
            end
          end
        end
        messages
      end

      # @return [Array<String>] List of the **non** fatal defects detected in a podspec
      def podspec_warnings
        text     = @file.read
        messages = []
        messages << "Missing license type"                                  unless license[:type]
        messages << "Sample license type"                                   if license[:type] && license[:type] =~ /\(example\)/
        messages << "Invalid license type"                                  if license[:type] && license[:type] =~ /\n/
        messages << "The summary is not meaningful"                         if spec.summary =~ /A short description of/
        messages << "The description is not meaningful"                     if spec.description && spec.description =~ /An optional longer description of/
        messages << "The summary should end with a dot"                     if spec.summary !~ /.*\./
        messages << "The description should end with a dot"                 if spec.description !~ /.*\./ && spec.description != spec.summary
        messages << "The summary should end with a dot"                     if spec.summary !~ /.*\./
        messages << "Comments must be deleted"                              if text.scan(/^\s*#/).length > 24
        messages << "Warnings must not be disabled (`-Wno' compiler flags)" if spec.compiler_flags.split(' ').any? {|flag| flag.start_with?('-Wno') }

        if (git_source = source[:git])
          messages << "Git sources should specify either a tag or a commit" unless source[:commit] || source[:tag]
          if spec.version.to_s != '0.0.1'
          messages << "The version of the spec should be part of the git tag (not always applicable)" if source[:tag] && !source[:tag].include?(spec.version.to_s)
          messages << "Git sources without tag should be marked as 0.0.1 (not always applicable)" if !source[:tag]
          end
          if git_source.include?('github.com')
            messages << "Github repositories should end in `.git'"          unless git_source.end_with?('.git')
            messages << "Github repositories should use `https' link"       unless git_source.start_with?('https://github.com') || git_source.start_with?('git://gist.github.com')
          end
        end

        messages
      end

    end
  end
end
