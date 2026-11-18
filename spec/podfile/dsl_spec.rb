require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Podfile::DSL do
    describe 'Dependencies' do
      it 'adds dependencies' do
        podfile = Podfile.new do
          pod 'ASIHTTPRequest'
          pod 'SSZipArchive', '>= 0.1'
        end
        expect(podfile.dependencies.size).to eq(2)
        expect(podfile.dependencies.find { |d| d.root_name == 'ASIHTTPRequest' }).to eq(Dependency.new('ASIHTTPRequest'))
        expect(podfile.dependencies.find { |d| d.root_name == 'SSZipArchive' }).to eq(Dependency.new('SSZipArchive', '>= 0.1'))
      end

      describe 'whitelisting pods per configuration' do
        it 'white-list dependencies on all build configuration by default' do
          podfile = Podfile.new do
            pod 'PonyDebugger'
          end

          target = podfile.target_definitions['Pods']
          expect(target.pod_whitelisted_for_configuration?('PonyDebugger', 'Release')).to be(true)
          expect(target.pod_whitelisted_for_configuration?('PonyDebugger', 'Debug')).to be(true)
        end

        it 'allows to white-list a dependency on multiple build configuration' do
          podfile = Podfile.new do
            pod 'PonyDebugger', :configurations => ['Release', 'App Store']
          end

          target = podfile.target_definitions['Pods']
          expect(target.pod_whitelisted_for_configuration?('PonyDebugger', 'Release')).to be(true)
          expect(target.pod_whitelisted_for_configuration?('PonyDebugger', 'App Store')).to be(true)
          expect(target.pod_whitelisted_for_configuration?('PonyDebugger', 'Debug')).to be(false)
        end

        it 'allows to white-list a dependency on a build configuration' do
          podfile = Podfile.new do
            pod 'PonyDebugger', :configuration => 'Release'
          end

          target = podfile.target_definitions['Pods']
          expect(target.pod_whitelisted_for_configuration?('PonyDebugger', 'Release')).to be(true)
          expect(target.pod_whitelisted_for_configuration?('PonyDebugger', 'Debug')).to be(false)
        end

        it 'allows to white-list a dependency on a build configuration in a target block' do
          podfile = Podfile.new do
            target 'App' do
              pod 'PonyDebugger', :configuration => 'Release'
            end
          end

          target = podfile.target_definitions['App']
          expect(target.pod_whitelisted_for_configuration?('PonyDebugger', 'Release')).to be(true)
          expect(target.pod_whitelisted_for_configuration?('PonyDebugger', 'Debug')).to be(false)
        end
      end

      describe 'inhibiting warnings' do
        it 'does not inhibit warnings on dependencies by default' do
          podfile = Podfile.new do
            pod 'PonyDebugger'
          end

          target = podfile.target_definitions['Pods']
          expect(target.inhibits_warnings_for_pod?('PonyDebugger')).to be(false)
        end

        it 'raises if :inhibit_warnings value is not a boolean' do
          expect do
            podfile = Podfile.new do
              pod 'PonyDebugger', :inhibit_warnings => 'true'
            end
            target = podfile.target_definitions['Pods']
            expect(target.inhibits_warnings_for_pod?('PonyDebugger')).to be(true)
          end.to raise_error(ArgumentError, /should be a boolean/)
        end

        it 'allows inhibiting warnings on a single dependency' do
          podfile = Podfile.new do
            pod 'PonyDebugger', :inhibit_warnings => true
          end

          target = podfile.target_definitions['Pods']
          expect(target.inhibits_warnings_for_pod?('PonyDebugger')).to be(true)
        end

        it 'allows not inhibiting warnings on a single dependency' do
          podfile = Podfile.new do
            inhibit_all_warnings!
            pod 'PonyDebugger', :inhibit_warnings => false
          end

          target = podfile.target_definitions['Pods']
          expect(target.inhibits_warnings_for_pod?('PonyDebugger')).to be(false)
        end

        it 'allows inhibiting warnings on a single dependency in a target block' do
          podfile = Podfile.new do
            target 'App' do
              pod 'PonyDebugger', :inhibit_warnings => true
            end
          end

          target = podfile.target_definitions['App']
          expect(target.inhibits_warnings_for_pod?('PonyDebugger')).to be(true)
        end

        it 'allows not inhibiting warnings on a single dependency in a target block' do
          podfile = Podfile.new do
            inhibit_all_warnings!
            target 'App' do
              pod 'PonyDebugger', :inhibit_warnings => false
            end
          end

          target = podfile.target_definitions['App']
          expect(target.inhibits_warnings_for_pod?('PonyDebugger')).to be(false)
        end

        it 'allows inhibiting warnings on a single dependency in a target block with inheritance' do
          podfile = Podfile.new do
            target 'App' do
              pod 'PonyDebugger', :inhibit_warnings => true
              target 'Inherited' do
                pod 'PonyDebugger', :inhibit_warnings => false
              end
            end
          end

          target = podfile.target_definitions['App']
          expect(target.inhibits_warnings_for_pod?('PonyDebugger')).to be(true)
        end

        it 'allows inhibiting in parent and not inhibiting in child on a single dependency' do
          podfile = Podfile.new do
            target 'App' do
              pod 'PonyDebugger', :inhibit_warnings => true
              target 'Inherited' do
                pod 'PonyDebugger', :inhibit_warnings => false
              end
            end
          end

          target = podfile.target_definitions['App']
          expect(target.inhibits_warnings_for_pod?('PonyDebugger')).to be(true)

          target = podfile.target_definitions['Inherited']
          expect(target.inhibits_warnings_for_pod?('PonyDebugger')).to be(false)
        end

        it 'allows not inhibiting in parent and inhibiting in child on a single dependency' do
          podfile = Podfile.new do
            target 'App' do
              pod 'PonyDebugger', :inhibit_warnings => false
              target 'Inherited' do
                pod 'PonyDebugger', :inhibit_warnings => true
              end
            end
          end

          target = podfile.target_definitions['App']
          expect(target.inhibits_warnings_for_pod?('PonyDebugger')).to be(false)

          target = podfile.target_definitions['Inherited']
          expect(target.inhibits_warnings_for_pod?('PonyDebugger')).to be(true)
        end

        it 'allows not inhibiting a single dependency in parent and inhibiting all dependencies in child' do
          podfile = Podfile.new do
            target 'App' do
              pod 'PonyDebugger', :inhibit_warnings => false
              target 'Inherited' do
                inhibit_all_warnings!
                pod 'PonyDebugger'
              end
            end
          end

          target = podfile.target_definitions['App']
          expect(target.inhibits_warnings_for_pod?('PonyDebugger')).to be(false)

          target = podfile.target_definitions['Inherited']
          expect(target.inhibits_warnings_for_pod?('PonyDebugger')).to be(true)
        end

        it 'allows not inhibiting a single dependency in grandparent and inhibiting all dependencies in grandchild' do
          podfile = Podfile.new do
            target 'App' do
              pod 'PonyDebugger', :inhibit_warnings => false
              target 'Inherited' do
                target 'InheritedLevelTwo' do
                  inhibit_all_warnings!
                  pod 'PonyDebugger'
                end
              end
            end
          end

          target = podfile.target_definitions['App']
          expect(target.inhibits_warnings_for_pod?('PonyDebugger')).to be(false)

          target = podfile.target_definitions['InheritedLevelTwo']
          expect(target.inhibits_warnings_for_pod?('PonyDebugger')).to be(true)
        end

        it 'allows inhibiting all warnings in parent and child scopes' do
          podfile = Podfile.new do
            inhibit_all_warnings!
            target 'App' do
              pod 'PonyDebugger'
              inhibit_all_warnings!
              target 'Inherited' do
                inhibit_all_warnings!
              end
            end
          end

          target = podfile.target_definitions['App']
          expect(target.inhibits_warnings_for_pod?('PonyDebugger')).to be(true)

          target = podfile.target_definitions['Inherited']
          expect(target.inhibits_warnings_for_pod?('PonyDebugger')).to be(true)
        end
      end

      describe 'project names' do
        it 'sets the project name for a given pod' do
          podfile = Podfile.new do
            pod 'PonyDebugger', :project_name => 'PonyProject'
          end

          target = podfile.target_definitions['Pods']
          expect(target.project_name_for_pod('PonyDebugger')).to eq('PonyProject')
        end
      end

      describe 'modular headers' do
        it 'does not have modular headers by default' do
          podfile = Podfile.new do
            pod 'PonyDebugger'
          end

          target = podfile.target_definitions['Pods']
          expect(target.build_pod_as_module?('PonyDebugger')).to be(false)
        end

        it 'raises if :modular_headers value is not a boolean' do
          expect do
            podfile = Podfile.new do
              pod 'PonyDebugger', :modular_headers => 'true'
            end
            target = podfile.target_definitions['Pods']
            expect(target.build_pod_as_module?('PonyDebugger')).to be(true)
          end.to raise_error(ArgumentError, /should be a boolean/)
        end

        it 'allows modular headers on a single dependency' do
          podfile = Podfile.new do
            pod 'PonyDebugger', :modular_headers => true
          end

          target = podfile.target_definitions['Pods']
          expect(target.build_pod_as_module?('PonyDebugger')).to be(true)
        end

        it 'allows not modular headers on a single dependency' do
          podfile = Podfile.new do
            use_modular_headers!
            pod 'PonyDebugger', :modular_headers => false
          end

          target = podfile.target_definitions['Pods']
          expect(target.build_pod_as_module?('PonyDebugger')).to be(false)
        end

        it 'allows modular headers on a single dependency in a target block' do
          podfile = Podfile.new do
            target 'App' do
              pod 'PonyDebugger', :modular_headers => true
            end
          end

          target = podfile.target_definitions['App']
          expect(target.build_pod_as_module?('PonyDebugger')).to be(true)
        end

        it 'allows not modular headers on a single dependency in a target block' do
          podfile = Podfile.new do
            use_modular_headers!
            target 'App' do
              pod 'PonyDebugger', :modular_headers => false
            end
          end

          target = podfile.target_definitions['App']
          expect(target.build_pod_as_module?('PonyDebugger')).to be(false)
        end

        it 'allows modular headers on a single dependency in a target block with inheritance' do
          podfile = Podfile.new do
            target 'App' do
              pod 'PonyDebugger', :modular_headers => true
              target 'Inherited' do
                pod 'PonyDebugger', :modular_headers => false
              end
            end
          end

          target = podfile.target_definitions['App']
          expect(target.build_pod_as_module?('PonyDebugger')).to be(true)
        end

        it 'allows modular headers in parent and not using them in child on a single dependency' do
          podfile = Podfile.new do
            target 'App' do
              pod 'PonyDebugger', :modular_headers => true
              target 'Inherited' do
                pod 'PonyDebugger', :modular_headers => false
              end
            end
          end

          target = podfile.target_definitions['App']
          expect(target.build_pod_as_module?('PonyDebugger')).to be(true)

          target = podfile.target_definitions['Inherited']
          expect(target.build_pod_as_module?('PonyDebugger')).to be(false)
        end

        it 'allows not using modular headers in parent and using modular headers in child on a single dependency' do
          podfile = Podfile.new do
            target 'App' do
              pod 'PonyDebugger', :modular_headers => false
              target 'Inherited' do
                pod 'PonyDebugger', :modular_headers => true
              end
            end
          end

          target = podfile.target_definitions['App']
          expect(target.build_pod_as_module?('PonyDebugger')).to be(false)

          target = podfile.target_definitions['Inherited']
          expect(target.build_pod_as_module?('PonyDebugger')).to be(true)
        end

        it 'allows not using modular headers a single dependency in parent and using modular headers all dependencies in child' do
          podfile = Podfile.new do
            target 'App' do
              pod 'PonyDebugger', :modular_headers => false
              target 'Inherited' do
                use_modular_headers!
                pod 'PonyDebugger'
              end
            end
          end

          target = podfile.target_definitions['App']
          expect(target.build_pod_as_module?('PonyDebugger')).to be(false)

          target = podfile.target_definitions['Inherited']
          expect(target.build_pod_as_module?('PonyDebugger')).to be(true)
        end

        it 'allows not using modular headers a single dependency in grandparent and using modular headers all dependencies in grandchild' do
          podfile = Podfile.new do
            target 'App' do
              pod 'PonyDebugger', :modular_headers => false
              target 'Inherited' do
                target 'InheritedLevelTwo' do
                  use_modular_headers!
                  pod 'PonyDebugger'
                end
              end
            end
          end

          target = podfile.target_definitions['App']
          expect(target.build_pod_as_module?('PonyDebugger')).to be(false)

          target = podfile.target_definitions['InheritedLevelTwo']
          expect(target.build_pod_as_module?('PonyDebugger')).to be(true)
        end
      end

      it 'allows specifying multiple subspecs' do
        podfile = Podfile.new do
          pod 'RestKit', '~> 0.24.0', :subspecs => %w(CoreData Networking), :configurations => %w(Release)
        end

        target = podfile.target_definitions['Pods']
        expected_dependencies = [
          Dependency.new('RestKit/CoreData', '~> 0.24.0'),
          Dependency.new('RestKit/Networking', '~> 0.24.0'),
        ]
        expect(target.dependencies.sort_by(&:name)).to eq(expected_dependencies)
        expect(target.pod_whitelisted_for_configuration?('RestKit', 'Release')).to be(true)

        podfile = Podfile.new do
          pod 'RestKit/Subspec', :subspecs => %w(CoreData Networking/Subspec), :git => 'https://github.com/RestKit/RestKit.git'
        end

        target = podfile.target_definitions['Pods']
        expected_dependencies = [
          Dependency.new('RestKit/Subspec/CoreData', :git => 'https://github.com/RestKit/RestKit.git'),
          Dependency.new('RestKit/Subspec/Networking/Subspec', :git => 'https://github.com/RestKit/RestKit.git'),
        ]
        expect(target.dependencies.sort_by(&:name)).to eq(expected_dependencies)
      end

      it 'implicitly reuses an external source' do
        podfile = Podfile.new do
          target 'A' do
            pod 'RestKit', :git => 'https://github.com/RestKit/RestKit.git'
          end

          target 'B' do
            pod 'RestKit'
          end
        end

        expected_dependencies = [
          Dependency.new('RestKit', :git => 'https://github.com/RestKit/RestKit.git'),
        ]
        podfile.target_definitions['A'].dependencies.sort_by(&:name).should == expected_dependencies
        podfile.target_definitions['B'].dependencies.sort_by(&:name).should == expected_dependencies
      end

      it 'raises if no name is specified for a Pod' do
        expect do
          Podfile.new do
            pod
          end
        end.to raise_error(Podfile::StandardError)
      end

      it 'raises if an inlide podspec is specified' do
        expect do
          Podfile.new do
            pod do |s|
              s.name = 'mypod'
            end
          end
        end.to raise_error(Podfile::StandardError)
      end

      it 'it can use use the dependencies of a podspec' do
        banalib_path = fixture('BananaLib.podspec').to_s
        podfile = Podfile.new(fixture('Podfile')) do
          platform :ios
          podspec :path => banalib_path
        end
        expect(podfile.dependencies.map(&:name)).to eq(%w(monkey AFNetworking SDWebImage))
      end

      it 'it can use use the dependencies of a podspec\'s subspec' do
        banalib_path = fixture('BananaLib.podspec').to_s
        podfile = Podfile.new(fixture('Podfile')) do
          platform :ios
          podspec :path => banalib_path, :subspec => 'GreenBanana'
        end
        expect(podfile.dependencies.map(&:name)).to eq(%w(monkey AFNetworking))
      end

      it 'allows specifying a child target definition' do
        podfile = Podfile.new do
          target :tests do
            pod 'OCMock'
          end
        end
        expect(podfile.target_definitions[:tests].name).to eq(:tests)
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Target configuration' do
      it 'allows specifying a platform' do
        podfile = Podfile.new do
          platform :ios, '6.0'
          target :osx_target do
            platform :osx, '10.8'
          end
        end
        expect(podfile.target_definitions['Pods'].platform).to eq(Platform.new(:ios, '6.0'))
        expect(podfile.target_definitions[:osx_target].platform).to eq(Platform.new(:osx, '10.8'))
      end

      it 'does not allow specifying a platform twice' do
        expect do
          Podfile.new do
            platform :ios, '6.0'
            platform :ios, '9.0'
          end
        end.to raise_error(Podfile::StandardError, 'The target `Pods` already has a platform set.')
      end

      it 'allows specifying whether the target is exclusive' do
        podfile = Podfile.new do
          target 'Pods' do
            inherit!(:none)
          end
        end
        expect(podfile.target_definitions['Pods']).to be_exclusive
      end

      it 'is not exclusive by default' do
        podfile = Podfile.new do
          target 'Pods' do
          end
        end
        expect(podfile.target_definitions['Pods']).not_to be_exclusive
      end

      it 'allows specifying whether the target is abstract' do
        podfile = Podfile.new do
          target 'App' do
            abstract!
          end
        end
        expect(podfile.target_definitions['App']).to be_abstract
      end

      it 'is not abstract by default' do
        podfile = Podfile.new do
          target 'App' do
          end
        end
        expect(podfile.target_definitions['App']).not_to be_abstract
      end

      it 'allows specifying an abstract target' do
        podfile = Podfile.new do
          abstract_target 'App' do
          end
        end
        expect(podfile.target_definitions['App']).to be_abstract
      end

      describe 'inheritance' do
        it 'allows specifying the inheritance mode for a target' do
          modes = %w(search_paths complete none)
          modes.each do |mode|
            podfile = Podfile.new do
              target 'App' do
                inherit! mode
              end
            end
            expect(podfile.target_definitions['App'].inheritance).to eq(mode)
          end
        end

        it 'raises when specifying an unknown mode' do
          expect do
            Podfile.new do
              target 'App' do
                inherit! 'foo'
              end
            end
          end.to raise_error(Informative, 'Unrecognized inheritance option `foo` specified for target `App`.')
        end
      end

      it 'raises if unrecognized keys are passed during the initialization of a target' do
        expect do
          Podfile.new do
            target 'Pods', :unrecognized => true do
            end
          end
        end.to raise_error(Informative)
      end

      it 'allows specifying the user Xcode project for a Target definition' do
        podfile = Podfile.new { project 'App.xcodeproj' }
        expect(podfile.target_definitions['Pods'].user_project_path).to eq('App.xcodeproj')
      end

      it 'allows specifying the build configurations of a user project' do
        podfile = Podfile.new do
          project 'App.xcodeproj', 'Mac App Store' => :release, 'Test' => :debug
        end
        expect(podfile.target_definitions['Pods'].build_configurations).to eq({
          'Mac App Store' => :release, 'Test' => :debug
        })
      end

      it 'allows to inhibit all the warnings of a Target definition' do
        podfile = Podfile.new do
          pod 'ObjectiveRecord'
          inhibit_all_warnings!
        end
        expect(podfile.target_definitions['Pods'].inhibits_warnings_for_pod?('ObjectiveRecord')).to be(true)
      end

      it 'defaults to not use frameworks for a Target definition' do
        podfile = Podfile.new { pod 'ObjectiveRecord' }
        expect(podfile.target_definitions['Pods'].uses_frameworks?).to be(false)
      end

      it 'allows to use frameworks for a Target definition' do
        podfile = Podfile.new do
          pod 'ObjectiveRecord'
          use_frameworks!
        end
        expect(podfile.target_definitions['Pods'].uses_frameworks?).to be(true)
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Workspace' do
      it 'specifies the Xcode workspace to use' do
        expect(Podfile.new do
          workspace 'MyWorkspace.xcworkspace'
        end.workspace_path).to eq('MyWorkspace.xcworkspace')
      end

      it 'specifies that BridgeSupport metadata should be generated' do
        expect(Podfile.new {}.generate_bridge_support?).to be_falsey
        expect(Podfile.new { generate_bridge_support! }.generate_bridge_support?).to be_truthy
      end

      it 'specifies that ARC compatibility flag should be generated' do
        expect(Podfile.new {}.set_arc_compatibility_flag?).to be_falsey
        expect(Podfile.new { set_arc_compatibility_flag! }.set_arc_compatibility_flag?).to be_truthy
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Hooks' do
      it 'stores a block that will be called before integrating the targets' do
        yielded = nil
        Podfile.new do
          pre_install do |installer|
            yielded = installer
          end
        end.pre_install!(:an_installer)
        expect(yielded).to eq(:an_installer)
      end

      it 'stores a block that will be called with the Installer instance once installation is finished' do
        yielded = nil
        Podfile.new do
          post_install do |installer|
            yielded = installer
          end
        end.post_install!(:an_installer)
        expect(yielded).to eq(:an_installer)
      end

      it 'raises when post_install is called multiple times' do
        expect do
          Podfile.new do
            target 'App' do
              post_install do |installer|
              end

              post_install do |installer|
              end
            end
          end
        end.to raise_error(Informative, 'Specifying multiple `post_install` hooks is unsupported.')
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Installation Method' do
      it 'allows specifying a custom installation method' do
        podfile = Podfile.new do
          install! 'method'
        end
        expect(podfile.installation_method).to eq(['method', {}])
      end

      it 'allows specifying a custom installation method with options' do
        podfile = Podfile.new do
          install! 'method', 'option' => 'value'
        end
        expect(podfile.installation_method).to eq(['method', { 'option' => 'value' }])
      end

      it 'raises when specifying an installation method outside of root' do
        expect do
          Podfile.new do
            target 'App' do
              install! 'method'
            end
          end
        end.to raise_error(Informative, 'The installation method can only be set at the root level of the Podfile.')
      end
    end

    #-------------------------------------------------------------------------#

    describe 'ensure_bundler!' do
      def stash_bundler_environment
        @stored_bundle_gemfile = ENV['BUNDLE_GEMFILE']
        @stored_bundle_bin_path = ENV['BUNDLE_BIN_PATH']
        @stored_bundle_version = ENV['BUNDLER_VERSION']
      end

      def restore_bundler_environment
        ENV['BUNDLE_BIN_PATH'] = @stored_bundle_bin_path
        ENV['BUNDLE_GEMFILE'] = @stored_bundle_gemfile
        ENV['BUNDLER_VERSION'] = @stored_bundle_version
      end

      it 'prints warning when bundler environment not found' do
        stash_bundler_environment
        ENV['BUNDLE_BIN_PATH'] = nil
        ENV['BUNDLE_GEMFILE'] = nil
        ENV['BUNDLER_VERSION'] = nil
        expect do
          Podfile.new do
            ensure_bundler!
          end
        end.to raise_error(Informative, "CocoaPods was invoked from Global Gemset.\nPlease re-run using: `bundle exec pod #{ARGV.join(' ')}`")
        restore_bundler_environment
      end

      it 'prints warning when a bundler env variable not found' do
        stash_bundler_environment
        ENV['BUNDLE_GEMFILE'] = nil
        expect do
          Podfile.new do
            ensure_bundler!
          end
        end.to raise_error(Informative, "CocoaPods was invoked from Global Gemset.\nPlease re-run using: `bundle exec pod #{ARGV.join(' ')}`")
        restore_bundler_environment
      end

      it 'has no warning with bundler environment' do
        stash_bundler_environment
        ENV['BUNDLE_GEMFILE'] = 'mock argument'
        ENV['BUNDLE_BIN_PATH'] = 'another mock argument'
        ENV['BUNDLER_VERSION'] = '1.17.1'
        Podfile.new do
          ensure_bundler!
        end
        restore_bundler_environment
        expect(CoreUI.warnings).to be_empty
      end

      it 'prints version warning when version argument fails match' do
        stash_bundler_environment
        ENV['BUNDLE_GEMFILE'] = 'mock argument'
        ENV['BUNDLE_BIN_PATH'] = 'another mock argument'
        ENV['BUNDLER_VERSION'] = '1.17.1'
        expect do
          Podfile.new do
            ensure_bundler! '2.0.0'
          end
        end.to raise_error(Informative, 'The installed Bundler version: 1.17.1 does not match the required version: 2.0.0')
        restore_bundler_environment
      end

      it 'has no warning with semantic version match' do
        stash_bundler_environment
        ENV['BUNDLE_GEMFILE'] = 'mock argument'
        ENV['BUNDLE_BIN_PATH'] = 'another mock argument'
        ENV['BUNDLER_VERSION'] = '2.0.9'
        Podfile.new do
          ensure_bundler! '~> 2.0.0'
        end
        restore_bundler_environment
        expect(CoreUI.warnings).to be_empty
      end

      it 'skips version check with missing bundle version (edge case)' do
        stash_bundler_environment
        ENV['BUNDLE_GEMFILE'] = 'mock argument'
        ENV['BUNDLE_BIN_PATH'] = 'another mock argument'
        ENV['BUNDLER_VERSION'] = nil
        Podfile.new do
          ensure_bundler! '2.0.0'
        end
        restore_bundler_environment
        expect(CoreUI.warnings).to be_empty
      end

      it 'raises with ensure_bundler! outside of root' do
        expect do
          Podfile.new do
            target 'App' do
              ensure_bundler!
            end
          end
        end.to raise_error(Informative, 'The Ensure Bundler check can only be set at the root level of the Podfile.')
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Deprecations' do
      it 'raises when using the #link_with method' do
        expect do
          Podfile.new do
            link_with 'App'
          end
        end.to raise_error(Informative, 'The specification of `link_with` in the Podfile is now unsupported, please use target blocks instead.')
      end

      it 'warns when using the #xcodeproj method' do
        podfile = Podfile.new { xcodeproj 'App.xcodeproj', 'Test' => :debug }
        expect(podfile.target_definitions['Pods'].user_project_path).to eq('App.xcodeproj')
        expect(podfile.target_definitions['Pods'].build_configurations).to eq({ 'Test' => :debug })
        expect(CoreUI.warnings).to eq('`xcodeproj` was renamed to `project`. Please update your Podfile accordingly.')
      end
    end

    describe 'script phases' do
      it 'raises when adding a script phase to the root target definition' do
        expect do
          Podfile.new do
            script_phase :name => 'PhaseName', :script => 'echo "Hello World"'
          end
        end.to raise_error(Informative, 'Script phases can only be added within target definitions.')
      end

      it 'raises when adding a script phase to an abstract target' do
        expect do
          Podfile.new do
            abstract_target 'AbstractTarget' do
              script_phase :name => 'PhaseName', :script => 'echo "Hello World"'
            end
          end
        end.to raise_error(Informative, 'Script phases cannot be added to abstract targets.')
      end
    end

    #-------------------------------------------------------------------------#
  end
end
