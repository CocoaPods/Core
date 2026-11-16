require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe Podfile do
    describe 'In general' do
      it 'stores the path of the file it is loaded from' do
        podfile = Podfile.from_file(fixture('Podfile'))
        expect(podfile.defined_in_file).to eq(fixture('Podfile'))
      end

      it 'returns the string representation' do
        expect(Podfile.new {}.to_s).to eq('Podfile')
      end

      it 'creates a default target definition if a block is provided' do
        podfile = Podfile.new {}
        expect(podfile.root_target_definitions.count).to eq(1)
        expect(podfile.root_target_definitions.first.name).to eq('Pods')
      end

      it 'names the default target definition as Pods' do
        podfile = Podfile.new {}
        expect(podfile.root_target_definitions.first.name).to eq('Pods')
      end

      it 'is equatable' do
        expect(Podfile.new).to eq(Podfile.new)

        expect(Podfile.from_file(fixture('Podfile'))).to eq(Podfile.from_file(fixture('Podfile')))
        expect(Podfile.from_file(fixture('Podfile'))).to eq(Podfile.from_file(fixture('Podfile')).tap { |pf| pf.defined_in_file = Pathname('foo') })
        expect(Podfile.from_file(fixture('Podfile'))).to eq(Podfile.from_file(fixture('Podfile.yaml')))

        expect(Podfile.from_file(fixture('Podfile'))).not_to eq(Podfile.new)
        expect(Podfile.from_file(fixture('Podfile'))).not_to eq(Podfile.from_ruby(fixture('Podfile'), fixture('Podfile').read.gsub(/pod '/, "pod 'A_")))
      end

      extend SpecHelper::TemporaryDirectory

      it 'includes the line of the podfile that generated an exception' do
        podfile_content = "\n# Comment\npod "
        podfile_file = temporary_directory + 'Podfile'
        File.open(podfile_file, 'w') { |f| f.write(podfile_content) }
        raised = false
        begin
          Podfile.from_file(podfile_file)
        rescue DSLError => e
          raised = true
          expect(e.message).to match(%r{from .*/tmp/Podfile:3})
          expect(e.message).to match(/requires a name/)
          expect(e.message).to match(/# Comment/)
        end
        expect(raised).to be(true)
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Working with a Podfile' do
      before do
        @podfile = Podfile.new do
          pod 'ASIHTTPRequest'
          pod 'JSONKit'
          target 'sub-target' do
            pod 'JSONKit'
            pod 'Reachability'
            pod 'SSZipArchive'
          end
        end
      end

      it 'returns the string representation' do
        expect(@podfile.to_s).to eq('Podfile')
      end

      it 'returns the target definitions' do
        expect(@podfile.target_definitions.count).to eq(2)
        expect(@podfile.target_definitions['Pods'].name).to eq('Pods')
        expect(@podfile.target_definitions['sub-target'].name).to eq('sub-target')
      end

      it 'indicates if the pre install hook was executed' do
        expect(Podfile.new {}.pre_install!(:an_installer)).to eq(false)
        result = Podfile.new { pre_install { |_installer| } }.pre_install!(:an_installer)
        expect(result).to eq(true)
      end

      it 'indicates if the pre integrate hook was executed' do
        expect(Podfile.new {}.pre_integrate!(:an_installer)).to eq(false)
        result = Podfile.new { pre_integrate { |_installer| } }.pre_integrate!(:an_installer)
        expect(result).to eq(true)
      end

      it 'returns all dependencies of all targets combined' do
        expect(@podfile.dependencies.map(&:name).sort).to eq(%w(ASIHTTPRequest JSONKit Reachability SSZipArchive))
      end

      it 'indicates if the post install hook was executed' do
        expect(Podfile.new {}.post_install!(:an_installer)).to eq(false)
        result = Podfile.new { post_install { |_installer| } }.post_install!(:an_installer)
        expect(result).to eq(true)
      end

      it 'indicates if the post integrate hook was executed' do
        expect(Podfile.new {}.post_integrate!(:an_installer)).to eq(false)
        result = Podfile.new { post_integrate { |_installer| } }.post_integrate!(:an_installer)
        expect(result).to eq(true)
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Attributes' do
      it 'returns the workspace' do
        podfile = Podfile.new do
          workspace 'MyWorkspace.xcworkspace'
        end
        expect(podfile.workspace_path).to eq('MyWorkspace.xcworkspace')
      end

      it 'appends the extension to the specified workspaces if needed' do
        podfile = Podfile.new do
          workspace 'MyWorkspace'
        end
        expect(podfile.workspace_path).to eq('MyWorkspace.xcworkspace')
      end

      it 'returns whether the BridgeSupport metadata should be generated' do
        expect(Podfile.new {}.generate_bridge_support?).to be_falsey
        expect(Podfile.new { generate_bridge_support! }.generate_bridge_support?).to be_truthy
      end

      it 'returns whether the ARC compatibility flag should be set' do
        expect(Podfile.new {}.set_arc_compatibility_flag?).to be_falsey
        expect(Podfile.new { set_arc_compatibility_flag! }.set_arc_compatibility_flag?).to be_truthy
      end

      it 'returns the installation method' do
        name, options = Podfile.new {}.installation_method
        expect(name).to eq('cocoapods')
        expect(options).to eq({})

        name, options = Podfile.new { install! 'install-method', :option1 => 'value1', 'option2' => false }.installation_method
        expect(name).to eq('install-method')
        expect(options).to eq({ :option1 => 'value1', 'option2' => false })
      end

      describe 'source' do
        it 'can have multiple sources' do
          podfile = Podfile.new do
            source 'new_repo_1'
            source 'new_repo_2'
          end
          expect(podfile.sources.size).to eq(2)

          podfile = Podfile.new do
            source 'new_repo_1'
            source 'new_repo_2'
            source 'master'
          end
          expect(podfile.sources.size).to eq(3)
        end
      end

      describe 'plugin' do
        it 'can have mutiple plugins' do
          podfile = Podfile.new do
            plugin 'slather'
            plugin 'cocoapods-keys', :keyring => 'Eidolon'
          end
          expect(podfile.plugins).to eq({
            'slather' => {},
            'cocoapods-keys' => {
              'keyring' => 'Eidolon',
            },
          })
        end
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Representation' do
      it 'returns the hash representation' do
        podfile = Podfile.new do
          pod 'ASIHTTPRequest'
          target 'App' do
          end
        end
        expect(podfile.to_hash).to eq({
          'target_definitions' => [
            'name' => 'Pods',
            'abstract' => true,
            'dependencies' => ['ASIHTTPRequest'],
            'children' => [
              {
                'name' => 'App',
              },
            ],
          ],
        })
      end

      it 'includes the podfile wide settings in the hash representation' do
        podfile = Podfile.new do
          workspace('MyApp.xcworkspace')
          generate_bridge_support!
          set_arc_compatibility_flag!
          install! 'install-method', :option1 => 'value1', 'option2' => false
        end
        expect(podfile.to_hash).to eq({
          'target_definitions' => [{ 'name' => 'Pods', 'abstract' => true }],
          'workspace' => 'MyApp.xcworkspace',
          'generate_bridge_support' => true,
          'set_arc_compatibility_flag' => true,
          'installation_method' => {
            'name' => 'install-method',
            'options' => {
              :option1 => 'value1',
              'option2' => false,
            },
          },
        })
      end

      it 'includes the targets definitions tree in the hash representation' do
        podfile = Podfile.new do
          pod 'ASIHTTPRequest'
          target 'sub-target' do
            pod 'JSONKit'
            target 'test_target' do
              inherit!(:search_paths)
            end
          end
        end
        expect(podfile.to_hash).to eq({
          'target_definitions' => [
            {
              'name' => 'Pods',
              'abstract' => true,
              'dependencies' => ['ASIHTTPRequest'],
              'children' => [
                {
                  'name' => 'sub-target',
                  'dependencies' => ['JSONKit'],
                  'children' => [
                    {
                      'name' => 'test_target',
                      'abstract' => false,
                      'inheritance' => 'search_paths',
                    },
                  ],
                },
              ],
            },
          ],
        })
      end

      it 'returns the yaml representation' do
        podfile = Podfile.new do
          pod 'ASIHTTPRequest'
          pod 'JSONKit', '> 1.0', :inhibit_warnings => true
          generate_bridge_support!
          set_arc_compatibility_flag!
          install! 'install-method', :option1 => 'value1', 'option2' => false
        end
        expected = <<-EOF.strip_heredoc
          ---
          installation_method:
            name: install-method
            options:
              :option1: value1
              option2: false
          target_definitions:
          - name: Pods
            abstract: true
            dependencies:
            - ASIHTTPRequest
            - JSONKit:
              - '> 1.0'
            inhibit_warnings:
              for_pods:
                - 'JSONKit'
          generate_bridge_support: true
          set_arc_compatibility_flag: true
        EOF
        expect(YAMLHelper.load_string(podfile.to_yaml)).to eq(YAMLHelper.load_string(expected))
      end

      describe '#checksum' do
        it 'returns the checksum of the file in which it is defined' do
          podfile = Podfile.from_file(fixture('Podfile'))
          expect(podfile.checksum).to eq('c140d332c2d286f26b6439dc3570be477d1897b8')
        end

        it 'returns a nil checksum if the podfile is not defined in a file' do
          podfile = Podfile.new
          expect(podfile.checksum).to be_nil
        end
      end

      it 'includes inhibit warnings per pod' do
        podfile = Podfile.new do
          pod 'ASIHTTPRequest', :inhibit_warnings => true
          pod 'ObjectiveSugar'
        end
        expect(podfile.to_hash).to eq({
          'target_definitions' => [
            'name' => 'Pods',
            'abstract' => true,
            'inhibit_warnings' => {
              'for_pods' => ['ASIHTTPRequest'],
            },
            'dependencies' => %w(ASIHTTPRequest ObjectiveSugar),
          ],
        })
      end

      it 'excludes inhibit warnings per pod' do
        podfile = Podfile.new do
          pod 'ASIHTTPRequest', :inhibit_warnings => false
          pod 'ObjectiveSugar'
        end
        expect(podfile.to_hash).to eq({
          'target_definitions' => [
            'name' => 'Pods',
            'abstract' => true,
            'inhibit_warnings' => {
              'not_for_pods' => ['ASIHTTPRequest'],
            },
            'dependencies' => %w(ASIHTTPRequest ObjectiveSugar),
          ],
        })
      end

      it 'includes inhibit all warnings' do
        podfile = Podfile.new do
          pod 'ObjectiveSugar'
          inhibit_all_warnings!
        end
        expect(podfile.to_hash).to eq({
          'target_definitions' => [
            'name' => 'Pods',
            'abstract' => true,
            'dependencies' => ['ObjectiveSugar'],
            'inhibit_warnings' => {
              'all' => true,
            },
          ],
        })
      end

      it 'includes build type' do
        podfile = Podfile.new do
          pod 'ObjectiveSugar'
          use_frameworks!
        end
        expect(podfile.to_hash).to eq({
          'target_definitions' => [
            'name' => 'Pods',
            'abstract' => true,
            'dependencies' => ['ObjectiveSugar'],
            'uses_frameworks' => { :linkage => :dynamic, :packaging => :framework },
          ],
        })
      end

      it 'includes the specified sources in the hash representation' do
        podfile = Podfile.new do
          source 'new_ASIHTTPRequest_source'
          pod 'ASIHTTPRequest'
        end
        expect(podfile.to_hash).to eq({
          'sources' => %w(new_ASIHTTPRequest_source),
          'target_definitions' => [
            {
              'name' => 'Pods',
              'abstract' => true,
              'dependencies' => %w(ASIHTTPRequest),
            },
          ],
        })
      end

      it 'includes the specified plugins in the hash representation' do
        podfile = Podfile.new do
          plugin 'slather'
          plugin 'cocoapods-keys', :keyring => 'Eidolon'
          pod 'ASIHTTPRequest'
        end
        expect(podfile.to_hash).to eq({
          'plugins' => {
            'slather' => {},
            'cocoapods-keys' => {
              'keyring' => 'Eidolon',
            },
          },
          'target_definitions' => [
            {
              'name' => 'Pods',
              'abstract' => true,
              'dependencies' => %w(ASIHTTPRequest),
            },
          ],
        })
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Class methods' do
      it 'can be initialized from a ruby DSL file' do
        ruby_podfile = Podfile.from_file(fixture('Podfile'))
        expect(ruby_podfile.target_definitions.keys).to eq(['Pods'])
        expect(ruby_podfile.dependencies.map(&:name)).to eq(%w(SSZipArchive ASIHTTPRequest Reachability ASIWebPageRequest))
      end

      it 'can handle smartquotes in a ruby DSL file' do
        dsl = <<-DSL
          pod “AFNetworking”, ‘~> 2.0’
        DSL
        podfile = Podfile.from_ruby(fixture('Podfile'), dsl)
        expect(podfile.dependencies).to eq([Dependency.new('AFNetworking', '~> 2.0')])
        expect(CoreUI.warnings).to match(/smart quotes/)
      end

      it 'handles the `podfile` extension' do
        path = fixture('CocoaPods.podfile')
        Pathname.any_instance.stubs(:exist?).returns(true)
        Podfile.expects(:from_ruby)
        Podfile.from_file(path)
      end

      it 'handles the `rb` extension' do
        path = fixture('Podfile.rb')
        Pathname.any_instance.stubs(:exist?).returns(true)
        Podfile.expects(:from_ruby)
        Podfile.from_file(path)
      end

      it 'can be initialized from a YAML file' do
        ruby_podfile = Podfile.from_file(fixture('Podfile'))
        yaml_podfile = Podfile.from_file(fixture('Podfile.yaml'))
        expect(ruby_podfile.to_hash).to eq(yaml_podfile.to_hash)
      end

      it 'can properly parse a boolean uses_frameworks value from a YAML file' do
        podfile = Podfile.from_file(fixture('Podfile_UsesFrameworksBoolean.yaml'))
        target_definition = podfile.target_definitions['SampleApp']
        expect(target_definition.uses_frameworks?).to be(true)
        expect(target_definition.build_type).to eq(BuildType.dynamic_framework)
      end

      it 'can properly parse a hash uses_frameworks value from a YAML file' do
        podfile = Podfile.from_file(fixture('Podfile_UsesFrameworksHash.yaml'))
        target_definition = podfile.target_definitions['SampleApp']
        expect(target_definition.uses_frameworks?).to be(true)
        expect(target_definition.build_type).to eq(BuildType.dynamic_framework)
      end

      it "raises if the given initialization file doesn't exists" do
        expect do
          Podfile.from_file('Missing-file')
        end.to raise_error(Informative, /No Podfile exists/)
      end

      it 'raises if the given initialization file has an unsupported extension' do
        Pathname.any_instance.stubs(:exist?).returns(true)
        File.stubs(:open).returns('')
        expect do
          Podfile.from_file('Podfile.json')
        end.to raise_error(Informative, /Unsupported Podfile format/)
      end

      it 'can be initialized from a hash' do
        fixture_podfile = Podfile.from_file(fixture('Podfile'))
        hash = fixture_podfile.to_hash
        podfile = Podfile.from_hash(hash)
        expect(podfile.to_hash).to eq(fixture_podfile.to_hash)
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Private helpers' do
      it 'sets and retrieves a value in the internal hash' do
        podfile = Podfile.new
        podfile.send(:set_hash_value, 'generate_bridge_support', true)
        expect(podfile.send(:get_hash_value, 'generate_bridge_support')).to be(true)
      end

      it 'allows specifying a default value when fetching from the hash' do
        podfile = Podfile.new

        expect(podfile.send(:get_hash_value, 'generate_bridge_support', 'default')).to eq('default')

        podfile.send(:set_hash_value, 'generate_bridge_support', true)
        expect(podfile.send(:get_hash_value, 'generate_bridge_support', 'default')).to be(true)
      end

      it 'raises if there is an attempt to access or set an unknown key in the internal hash' do
        podfile = Podfile.new
        expect { podfile.send(:set_hash_value, 'unknown', true) }.to raise_error(Pod::Podfile::StandardError)
        expect { podfile.send(:get_hash_value, 'unknown') }.to raise_error(Pod::Podfile::StandardError)
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Nested target definitions' do
      before do
        @podfile = Podfile.new do
          platform :ios
          project 'iOS Project', 'iOS App Store' => :release, 'Test' => :debug

          target :debug do
            pod 'SSZipArchive'
          end

          target :test do
            inherit! :search_paths
            inhibit_all_warnings!
            use_frameworks!
            pod 'JSONKit'
            target :subtarget do
              pod 'Reachability'
            end
          end

          target :osx_target do
            platform :osx
            project 'OSX Project.xcodeproj', 'Mac App Store' => :release, 'Test' => :debug
            pod 'ASIHTTPRequest'
            target :nested_osx_target do
            end
          end

          pod 'ASIHTTPRequest'
        end
      end

      it 'adds dependencies outside of any explicit target block to the default target' do
        target = @podfile.target_definitions['Pods']
        expect(target.label).to eq('Pods')
        expect(target.dependencies).to eq([Dependency.new('ASIHTTPRequest')])
      end

      it 'adds dependencies of the outer target to non-exclusive targets' do
        target = @podfile.target_definitions[:debug]
        expect(target.label).to eq('Pods-debug')
        expect(target.dependencies.sort_by(&:name)).to eq([
          Dependency.new('ASIHTTPRequest'),
          Dependency.new('SSZipArchive'),
        ])
      end

      it 'does not add dependencies of the outer target to exclusive targets' do
        target = @podfile.target_definitions[:test]
        expect(target.label).to eq('Pods-test')
        expect(target.dependencies).to eq([Dependency.new('JSONKit')])
      end

      it 'adds dependencies of the outer target to nested targets' do
        target = @podfile.target_definitions[:subtarget]
        expect(target.label).to eq('Pods-test-subtarget')
        expect(target.dependencies).to eq([Dependency.new('Reachability'), Dependency.new('JSONKit')])
      end

      it 'returns the platform of the target' do
        expect(@podfile.target_definitions['Pods'].platform).to eq(:ios)
        expect(@podfile.target_definitions[:test].platform).to eq(:ios)
        expect(@podfile.target_definitions[:osx_target].platform).to eq(:osx)
      end

      it 'assigns a deployment target to the platforms if not specified' do
        expect(@podfile.target_definitions['Pods'].platform.deployment_target.to_s).to eq('4.3')
        expect(@podfile.target_definitions[:test].platform.deployment_target.to_s).to eq('4.3')
        expect(@podfile.target_definitions[:osx_target].platform.deployment_target.to_s).to eq('10.6')
      end

      it "automatically marks a target as exclusive if the parent platform doesn't match" do
        expect(@podfile.target_definitions[:osx_target]).to be_exclusive
        expect(@podfile.target_definitions[:nested_osx_target]).not_to be_exclusive
      end

      it 'inhibits warnings for any asked pod if inhibit_all_warnings! is called' do
        expect(@podfile.target_definitions['Pods'].inhibits_warnings_for_pod?('SSZipArchive')).not_to be(true)
        expect(@podfile.target_definitions[:test].inhibits_warnings_for_pod?('JSONKit')).to be(true)
        expect(@podfile.target_definitions[:subtarget].inhibits_warnings_for_pod?('Reachability')).to be(true)
      end

      it 'uses frameworks for any target if use_frameworks! is called' do
        expect(@podfile.target_definitions['Pods'].uses_frameworks?).not_to be(true)
        expect(@podfile.target_definitions[:test].uses_frameworks?).to be(true)
        expect(@podfile.target_definitions[:subtarget].uses_frameworks?).to be(true)
      end

      it 'returns the Xcode project that contains the target to link with' do
        ['Pods', :debug, :test, :subtarget].each do |target_name|
          target = @podfile.target_definitions[target_name]
          expect(target.user_project_path.to_s).to eq('iOS Project.xcodeproj')
        end
        [:osx_target, :nested_osx_target].each do |target_name|
          target = @podfile.target_definitions[target_name]
          expect(target.user_project_path.to_s).to eq('OSX Project.xcodeproj')
        end
      end
    end

    #-------------------------------------------------------------------------#
  end
end
