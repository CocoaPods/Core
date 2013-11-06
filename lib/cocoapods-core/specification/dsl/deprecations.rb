module Pod
  class Specification
    module DSL

      # Provides warning and errors for the deprecated attributes of the DSL.
      #
      module Deprecations

        def preferred_dependency=(name)
          self.default_subspec = name
          CoreUI.warn "[#{to_s}] `preferred_dependency` has been renamed "\
            "to `default_subspec`."
        end

        def singleton_method_added(method)
          if method == :pre_install
            CoreUI.warn "[#{to_s}] The use of `#{method}` by overriding " \
              "the method is deprecated."
            @pre_install_callback = Proc.new do |pod, target_definition|
              pre_install(pod, target_definition)
            end

          elsif method == :post_install
            CoreUI.warn "[#{to_s}] The use of `#{method}` by overriding the " \
              "method is deprecated."
            @post_install_callback = Proc.new do |target_installer|
              post_install(target_installer)
            end

          elsif method == :header_mappings
            raise Informative, "[#{to_s}] The use of the `header_mappings` " \
              "hook has been deprecated.\n Use the `header_dir` and the " \
                "`header_mappings_dir` attributes."

          elsif method == :copy_header_mapping
            raise Informative, "[#{to_s}] The use of the " \
              "`copy_header_mapping` hook has been deprecated.\nUse" \
                "the `header_dir` and the `header_mappings_dir` attributes."
          end
        end

        def documentation=(value)
          CoreUI.warn "[#{to_s}] The `documentation` DSL directive of the " \
            "podspec format has been deprecated."
        end

        def clean_paths=(value)
          raise Informative, "[#{to_s}] Clean paths are deprecated. " \
            "CocoaPods now cleans unused files by default. Use the " \
              "`preserve_paths` attribute if needed."
        end

        DEPRECATED_METHODS = [
          :part_of_dependency=,
          :part_of=,
          :exclude_header_search_paths=
        ]

        DEPRECATED_METHODS.each do |method|
          define_method method do |value|
            raise Informative, "[#{to_s}] Attribute "\
              "`#{method.to_s[0..-2]}` has been deprecated."
          end
        end

        # @!group Hooks
        #
        #   The specification class provides hooks which are called by
        #   CocoaPods when a Pod is installed.

        #-----------------------------------------------------------------------#

        # This is a convenience method which gets called after all pods have
        # been downloaded but before they have been installed, and the Xcode
        # project and related files have been generated. Note that this hook is
        # called for each Pods library and only for installations where the Pod
        # is installed.
        #
        # This hook should be used to generate and modify the files of the Pod.
        #
        # It receives the
        # [`Pod::Hooks::PodRepresentation`](http://docs.cocoapods.org/cocoapods/pod/hooks/podrepresentation/)
        # and the
        # [`Pod::Hooks::LibraryRepresentation`](http://docs.cocoapods.org/cocoapods/pod/hooks/libraryrepresentation/)
        # instances.
        #
        # Override this to, for instance, to run any build script.
        #
        # @example
        #
        #   spec.pre_install do |pod, target_definition|
        #     Dir.chdir(pod.root){ `sh make.sh` }
        #   end
        #
        def pre_install(&block)
          CoreUI.warn "[#{to_s}] The pre install hook of the specification " \
            "DSL has been deprecated, use the `resource_bundles` or the " \
              "`prepare_command` attributes."
            @pre_install_callback = block
        end

        # This is a convenience method which gets called after all pods have been
        # downloaded, installed, and the Xcode project and related files have
        # been generated. Note that this hook is called for each Pods library and
        # only for installations where the Pod is installed.
        #
        # To modify and generate files for the Pod the pre install hook should be
        # used instead of this one.
        #
        # It receives a
        # [`Pod::Hooks::LibraryRepresentation`](http://docs.cocoapods.org/cocoapods/pod/hooks/libraryrepresentation/)
        # instance for the current target.
        #
        # Override this to, for instance, add to the prefix header.
        #
        # @example
        #
        #   spec.post_install do |library_representation|
        #     prefix_header = library_representation.prefix_header_path
        #     prefix_header.open('a') do |file|
        #       file.puts('#ifdef __OBJC__\n#import "SSToolkitDefines.h"\n#endif')
        #     end
        #   end
        #
        def post_install(&block)
          CoreUI.warn "[#{to_s}] The post install hook of the specification " \
            "DSL has been deprecated, use the `resource_bundles` or the " \
              "`prepare_command` attributes."
            @post_install_callback = block
        end

        #-----------------------------------------------------------------------#

      end
    end
  end
end
