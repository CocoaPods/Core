require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe Podfile do
    describe "In general" do

      it "stores the path of the file it is loaded from" do
        podfile = Podfile.from_file(fixture('Podfile'))
        podfile.defined_in_file.should == fixture('Podfile')
      end

      it "returns the string representation" do
        Podfile.new {}.to_s.should == 'Podfile'
      end

      it "creates a default target definition if a block is provided" do
        podfile = Podfile.new {}
        podfile.root_target_definitions.count.should == 1
        podfile.root_target_definitions.first.name.should == 'Pods'
      end

      it "names the default target definition as Pods" do
        podfile = Podfile.new {}
        podfile.root_target_definitions.first.name.should == 'Pods'
      end

      it "specifies that the default target definition should link with the first target of the project" do
        podfile = Podfile.new {}
        podfile.root_target_definitions.first.should.link_with_first_target
      end

      extend SpecHelper::TemporaryDirectory

      it "includes the line of the podfile that generated an exception" do
        podfile_content = "\n# Comment\npod "
        podfile_file = temporary_directory + 'Podfile'
        File.open(podfile_file, 'w') { |f| f.write(podfile_content) }
        raised = false
        begin
          Podfile.from_file(podfile_file)
        rescue DSLError => e
          raised = true
          e.message.should.match /from .*\/tmp\/Podfile:3/
          e.message.should.match /requires a name/
          e.message.should.match /# Comment/
        end
        raised.should.be.true
      end
    end

    #-------------------------------------------------------------------------#

    describe "Working with a Podfile" do
      before do
        @podfile = Podfile.new do
          pod 'ASIHTTPRequest'
          pod 'JSONKit'
          target "sub-target" do
            pod 'JSONKit'
            pod 'Reachability'
            pod 'SSZipArchive'
          end
        end
      end

      it "returns the string representation" do
        @podfile.to_s.should == 'Podfile'
      end

      it "returns the target definitions" do
        @podfile.target_definitions.count.should == 2
        @podfile.target_definitions["Pods"].name.should == "Pods"
        @podfile.target_definitions["sub-target"].name.should == "sub-target"
      end

      it "indicates if the pre install hook was executed" do
        Podfile.new {}.pre_install!(:an_installer).should.be == false
        result = Podfile.new { pre_install { |installer| } }.pre_install!(:an_installer)
        result.should.be == true
      end

      it "returns all dependencies of all targets combined" do
        @podfile.dependencies.map(&:name).sort.should == %w[ ASIHTTPRequest JSONKit Reachability SSZipArchive ]
      end


      it "indicates if the pod install hook was executed" do
        Podfile.new {}.post_install!(:an_installer).should.be == false
        result = Podfile.new { post_install { |installer| } }.post_install!(:an_installer)
        result.should.be == true
      end

    end

    #-------------------------------------------------------------------------#

    describe "Attributes" do

      it "returns the workspace" do
        Podfile.new do
          workspace 'MyWorkspace.xcworkspace'
        end.workspace_path.should == 'MyWorkspace.xcworkspace'
      end

      it "appends the extension to the specified workspaces if needed" do
        Podfile.new do
          workspace 'MyWorkspace'
        end.workspace_path.should == 'MyWorkspace.xcworkspace'
      end

      it "returns whether the BridgeSupport metadata should be generated" do
        Podfile.new {}.should.not.generate_bridge_support
        Podfile.new { generate_bridge_support! }.should.generate_bridge_support
      end

      it 'returns whether the ARC compatibility flag should be set' do
        Podfile.new {}.should.not.set_arc_compatibility_flag
        Podfile.new { set_arc_compatibility_flag! }.should.set_arc_compatibility_flag
      end

    end

    #-------------------------------------------------------------------------#

    describe "Representation" do

      it "returns the hash representation" do
        podfile = Podfile.new do
          pod 'ASIHTTPRequest'
        end
        podfile.to_hash.should == {
          "target_definitions"=> [
            "name" => "Pods",
            "link_with_first_target"=>true,
            "dependencies"=>["ASIHTTPRequest"]
          ]
        }
      end

      it "includes the podfile wide settings in the hash representation" do
        podfile = Podfile.new do
          workspace('MyApp.xcworkspace')
          generate_bridge_support!
          set_arc_compatibility_flag!
        end
        podfile.to_hash.should == {
          "target_definitions"=>[{ "name" => "Pods", "link_with_first_target"=>true }],
          "workspace"=>"MyApp.xcworkspace",
          "generate_bridge_support"=>true,
          "set_arc_compatibility_flag"=>true
        }
      end

      it "includes the targets definitions tree in the hash representation" do
        podfile = Podfile.new do
          pod 'ASIHTTPRequest'
          target "sub-target" do
            pod 'JSONKit'
          end
        end
        podfile.to_hash.should == {
          "target_definitions"=>[
            {
              "name" => "Pods",
              "link_with_first_target"=>true,
              "dependencies"=>["ASIHTTPRequest"],
              "children"=> [
                {
                  "name" => "sub-target",
                  "dependencies"=> ["JSONKit"]
                }
              ]
            }
          ]
        }
      end

      it "returns the yaml representation" do
        podfile = Podfile.new do
          pod 'ASIHTTPRequest'
          pod 'JSONKit', '> 1.0', :inhibit_warnings => true
          generate_bridge_support!
          set_arc_compatibility_flag!
        end
        expected = <<-EOF.strip_heredoc
          ---
          target_definitions:
          - name: Pods
            link_with_first_target: true
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
        YAML::load(podfile.to_yaml).should == YAML::load(expected)
      end

      it "includes inhibit warnings per pod" do
        podfile = Podfile.new do
          pod 'ASIHTTPRequest', :inhibit_warnings => true
          pod 'ObjectiveSugar'
        end
        podfile.to_hash.should == {
          "target_definitions" => [
            "name" => "Pods",
            "link_with_first_target" => true,
            "inhibit_warnings" => {
              "for_pods" => [ "ASIHTTPRequest" ]
            },
            "dependencies" => ["ASIHTTPRequest", "ObjectiveSugar"]
          ]
        }
      end

      it "includes inhibit all warnings" do
        podfile = Podfile.new do
          pod 'ObjectiveSugar'
          inhibit_all_warnings!
        end
        podfile.to_hash.should == {
          "target_definitions" => [
            "name" => "Pods",
            "link_with_first_target" => true,
            "dependencies" => ["ObjectiveSugar"],
            "inhibit_warnings" => {
              "all" => true
            }
          ]
        }
      end

    end

    #-------------------------------------------------------------------------#

    describe "Class methods" do

      it "can be initialized from a ruby DSL file" do
        ruby_podfile = Podfile.from_file(fixture('Podfile'))
        ruby_podfile.target_definitions.keys.should == ["Pods"]
        ruby_podfile.dependencies.map(&:name).should == [
          "SSZipArchive",
          "ASIHTTPRequest",
          "Reachability",
          "ASIWebPageRequest"
        ]
      end

      it "can be initialized from a YAML file" do
        ruby_podfile = Podfile.from_file(fixture('Podfile'))
        yaml_podfile = Podfile.from_file(fixture('Podfile.yaml'))
        ruby_podfile.to_hash.should == yaml_podfile.to_hash
      end

      it "raises if the given initialization file doesn't exists" do
        should.raise Informative do
          Podfile.from_file('Missing-file')
        end.message.should.match /No Podfile exists/
      end

      it "raises if the given initialization file has an unsupported extension" do
        Pathname.any_instance.stubs(:exist?).returns(true)
        File.stubs(:open).returns('')
        should.raise Informative do
          Podfile.from_file('Podfile.json')
        end.message.should.match /Unsupported Podfile format/
      end

      it "can be initialized from a hash" do
        fixture_podfile = Podfile.from_file(fixture('Podfile'))
        hash = fixture_podfile.to_hash
        podfile = Podfile.from_hash(hash)
        podfile.to_hash.should == fixture_podfile.to_hash
      end

    end

    #-------------------------------------------------------------------------#

    describe "Private helpers" do

      it "sets and retrieves a value in the internal hash" do
        podfile = Podfile.new
        podfile.send(:set_hash_value, 'generate_bridge_support', true)
        podfile.send(:get_hash_value, 'generate_bridge_support').should.be.true
      end

      it "raises if there is an attempt to access or set an unknown key in the internal hash" do
        podfile = Podfile.new
        lambda { podfile.send(:set_hash_value, 'unknown', true) }.should.raise Pod::Podfile::StandardError
        lambda { podfile.send(:get_hash_value, 'unknown') }.should.raise Pod::Podfile::StandardError
      end

    end

    #-------------------------------------------------------------------------#

    describe "Deprecations" do
      it "Warns about the deprecated dependency DSL directive" do
        podfile = Podfile.new
        podfile.expects(:pod).with('My-Pod')
        podfile.dependency 'My-Pod'
        CoreUI.warnings.should.match /DEPRECATED/
      end
    end

    #-------------------------------------------------------------------------#

    describe "Nested target definitions" do
      before do
        @podfile = Podfile.new do
          platform :ios
          xcodeproj 'iOS Project', 'iOS App Store' => :release, 'Test' => :debug

          target :debug do
            pod 'SSZipArchive'
          end

          target :test, :exclusive => true do
            link_with 'TestRunner'
            inhibit_all_warnings!
            pod 'JSONKit'
            target :subtarget do
              pod 'Reachability'
            end
          end

          target :osx_target do
            platform :osx
            xcodeproj 'OSX Project.xcodeproj', 'Mac App Store' => :release, 'Test' => :debug
            link_with 'OSXTarget'
            pod 'ASIHTTPRequest'
            target :nested_osx_target do
            end
          end

          pod 'ASIHTTPRequest'
        end
      end

      it "adds dependencies outside of any explicit target block to the default target" do
        target = @podfile.target_definitions["Pods"]
        target.label.should == 'Pods'
        target.dependencies.should == [Dependency.new('ASIHTTPRequest')]
      end

      it "adds dependencies of the outer target to non-exclusive targets" do
        target = @podfile.target_definitions[:debug]
        target.label.should == 'Pods-debug'
        target.dependencies.sort_by(&:name).should == [
          Dependency.new('ASIHTTPRequest'),
          Dependency.new('SSZipArchive')
        ]
      end

      it "does not add dependencies of the outer target to exclusive targets" do
        target = @podfile.target_definitions[:test]
        target.label.should == 'Pods-test'
        target.dependencies.should == [Dependency.new('JSONKit')]
      end

      it "adds dependencies of the outer target to nested targets" do
        target = @podfile.target_definitions[:subtarget]
        target.label.should == 'Pods-test-subtarget'
        target.dependencies.should == [Dependency.new('Reachability'), Dependency.new('JSONKit')]
      end

      it "leaves the name of the target, to link with, to be automatically resolved" do
        target = @podfile.target_definitions["Pods"]
        target.link_with.should == nil
      end

      it "returns the names of the explicit targets to link with" do
        target = @podfile.target_definitions[:test]
        target.link_with.should == ['TestRunner']
      end

      it "returns the platform of the target" do
        @podfile.target_definitions["Pods"].platform.should == :ios
        @podfile.target_definitions[:test].platform.should == :ios
        @podfile.target_definitions[:osx_target].platform.should == :osx
      end

      it "assigns a deployment target to the platforms if not specified" do
        @podfile.target_definitions["Pods"].platform.deployment_target.to_s.should == '4.3'
        @podfile.target_definitions[:test].platform.deployment_target.to_s.should == '4.3'
        @podfile.target_definitions[:osx_target].platform.deployment_target.to_s.should == '10.6'
      end

      it "automatically marks a target as exclusive if the parent platform doesn't match" do
        @podfile.target_definitions[:osx_target].should.be.exclusive
        @podfile.target_definitions[:nested_osx_target].should.not.be.exclusive
      end

      it "specifies that the inhibit all warnings flag should be added to the target's build settings" do
        @podfile.target_definitions["Pods"].should.not.inhibit_all_warnings
        @podfile.target_definitions[:test].should.inhibit_all_warnings
        @podfile.target_definitions[:subtarget].should.inhibit_all_warnings
      end

      it "returns the Xcode project that contains the target to link with" do
        ["Pods", :debug, :test, :subtarget].each do |target_name|
          target = @podfile.target_definitions[target_name]
          target.user_project_path.to_s.should == 'iOS Project.xcodeproj'
        end
        [:osx_target, :nested_osx_target].each do |target_name|
          target = @podfile.target_definitions[target_name]
          target.user_project_path.to_s.should == 'OSX Project.xcodeproj'
        end
      end
    end

    #-------------------------------------------------------------------------#

  end
end
