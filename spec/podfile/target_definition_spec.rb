require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Podfile::TargetDefinition do
    describe "In general" do

      before do
        @app_def = Podfile::TargetDefinition.new("MyApp", nil, Podfile.new {})
        @app_def.store_pod('BlocksKit')
        @app_def.set_platform(:ios, '6.0')
        @test_def = Podfile::TargetDefinition.new(:MyAppTests, @app_def, nil)
        @test_def.store_pod('OCMockito')
      end

      it "returns its name" do
        @app_def.name.should == "MyApp"
        @test_def.name.should == :MyAppTests
      end

      it "returns its app_def" do
        @app_def.parent.should.be.nil
        @test_def.parent.should == @app_def
      end

      it "returns the podfile that specifies it" do
        @app_def.podfile.class.should == Podfile
      end

      it "returns its target dependencies" do
        @app_def.target_dependencies.map(&:name).should == %w[ BlocksKit ]
        @test_def.target_dependencies.map(&:name).should == %w[ OCMockito ]
      end

      it "returns whether it is empty" do
        @app_def.should.not.be.empty
        empty_def = Podfile::TargetDefinition.new(:empty, nil, nil)
        empty_def.should.be.empty
      end

      it "returns dependencies" do
        @app_def.dependencies.map(&:name).should  == %w[ BlocksKit ]
        @test_def.dependencies.map(&:name).should == %w[ OCMockito BlocksKit ]
      end

      it "returns if it is exclusive" do
        @app_def.should.not.be.exclusive
        @app_def.exclusive = true
        @app_def.should.be.exclusive
      end

      it "doesn't inherit dependencies if it is exclusive" do
        @test_def.exclusive = true
        @test_def.dependencies.map(&:name).should == %w[ OCMockito ]
      end

      it "returns the names of the targets that it should link with" do
        @app_def.link_with.should.be.nil
        @app_def.link_with = ['appTarget1, appTarget2']
        @app_def.link_with.should.be == ['appTarget1, appTarget2']
      end

      it "returns its platform" do
        @app_def.platform.should == Pod::Platform.new(:ios, '6.0')
      end

      it "returns its parent platform if none was specified" do
        @test_def.platform.should == Pod::Platform.new(:ios, '6.0')
      end

      it "returns if it should inhibit all warnings" do
        @app_def.inhibit_all_warnings?.should == nil
        @app_def.inhibit_all_warnings = true
        @app_def.inhibit_all_warnings?.should == true
      end

      it "inherits the option to inhibit all warnings from the parent" do
        @test_def.inhibit_all_warnings?.should == nil
        @app_def.inhibit_all_warnings = true
        @test_def.inhibit_all_warnings?.should == true
      end

      it "returns the user project path if specified" do
        @app_def.user_project_path.should.be.nil
        @app_def.user_project_path = 'some/path/project.xcodeproj'
        @app_def.user_project_path.should == 'some/path/project.xcodeproj'
      end

      it "returns the project build configurations" do
        @app_def.build_configurations.should.be.nil
        @app_def.build_configurations = { 'Debug' => :debug, 'Release' => :release }
        @app_def.build_configurations.should == { 'Debug' => :debug, 'Release' => :release }
      end

      it "returns its label" do
        @app_def.label.should == 'Pods-MyApp'
      end

      it "returns `Pods` as the label if its name is default" do
        target_def = Podfile::TargetDefinition.new(:default, nil, nil)
        target_def.label.should == 'Pods'
      end

      it "includes the name of the parent in the label if any" do
        @test_def.label.should == 'Pods-MyApp-MyAppTests'
      end

      it "doesn't include the name of the parent in the label if it is exclusive" do
        @test_def.exclusive = true
        @test_def.label.should == 'Pods-MyAppTests'
      end
    end

    #-------------------------------------------------------------------------#

    describe "Attributes accessors" do

      xit "provides a default deployment target if not specified" do
        podfile = Podfile.new { platform :ios }
        podfile.target_definitions[:default].platform.deployment_target.should == Version.new('4.3')
        podfile = Podfile.new { platform :osx }
        podfile.target_definitions[:default].platform.deployment_target.should == Version.new('10.6')
      end

      xit "raises if the specified platform is unsupported" do
        lambda { Podfile.new do
          platform :windows
        end }.should.raise Podfile::StandardError
      end

      xit "appends the extension to a specified user project if needed" do
        podfile = Podfile.new { xcodeproj 'App' }
        podfile.target_definitions[:default].user_project_path.should == 'App.xcodeproj'
      end

    end

    #-------------------------------------------------------------------------#

    describe "Hash representation" do

      it "returns the hash representation" do
        definition = Podfile::TargetDefinition.new("MyApp", nil, Podfile.new {})
        definition.store_pod('BlocksKit')
        definition.set_platform(:ios, '6.0')
        definition.to_hash.should == {
          "MyApp"=>{
            "dependencies"=>["BlocksKit"],
            "platform"=>{:ios=>"6.0"}
          }
        }
      end

      it "stores the children in the hash representation" do
        parent = Podfile::TargetDefinition.new("Parent", nil, Podfile.new {})
        parent.store_pod('BlocksKit')
        child = Podfile::TargetDefinition.new("Child", parent, Podfile.new {})
        child.store_pod('RestKit')
        parent.children << child
        parent.to_hash.should == {
          "Parent"=>{
            "dependencies"=> ["BlocksKit"],
            "children"=> [
              {
                "Child"=>{
                  "dependencies"=> [ "RestKit"]
                }
              }
            ]
          }
        }
      end

      it "can be initialized from a hash" do
        parent = Podfile::TargetDefinition.new("Parent", nil, Podfile.new {})
        parent.store_pod('BlocksKit')
        child = Podfile::TargetDefinition.new("Child", parent, Podfile.new {})
        child.store_pod('RestKit')
        parent.children << child
        converted = Podfile::TargetDefinition.from_hash(parent.to_hash, nil, Podfile.new)
        converted.to_hash.should == parent.to_hash
      end


      xit "" do
        podfile = Podfile.new do
          pod 'ASIHTTPRequest'
          podspec :name => 'Pod.podspec'
          platform(:ios, '10.6')
          inhibit_all_warnings!
          link_with('MyApp')
          xcodeproj('MyApp.xcodeproj', 'Mac App Store' => :release, 'Test' => :debug)    # TODO test build configurations
          target "sub-target" do          # TODO test options
            pod 'JSONKit'
          end
        end
      end

    end

    #-------------------------------------------------------------------------#

    describe "Private helpers" do

      it "sets and retrieves a value in the internal hash" do
        definition = Podfile::TargetDefinition.new("Name", nil, Podfile.new {})
        definition.send(:set_hash_value, 'inhibit_all_warnings', true)
        definition.send(:get_hash_value, 'inhibit_all_warnings').should.be.true
      end

      it "raises if there is an attempt to access or set an unknown key in the internal hash" do
        definition = Podfile::TargetDefinition.new("Name", nil, Podfile.new {})
        -> { definition.send(:set_hash_value, 'unknown', true) }.should.raise Pod::Podfile::StandardError
        -> { definition.send(:get_hash_value, 'unknown') }.should.raise Pod::Podfile::StandardError
      end

      it "returns the dependencies specified by the user" do
        definition = Podfile::TargetDefinition.new("Name", nil, Podfile.new {})
        definition.store_pod('BlocksKit')
        definition.store_pod('AFNetworking', '1.0')
        dependencies = definition.send(:pod_dependencies)
        dependencies.map(&:to_s).should == ["BlocksKit", "AFNetworking (= 1.0)"]
      end

      #--------------------------------------#

      describe "#pod_dependencies" do
      it "adds a dependency on a Pod repo outside of a spec repo (the repo is expected to contain a podspec)" do
        podfile = Podfile.new { pod 'SomeExternalPod', :git => 'GIT-URL', :commit => '1234' }
        dep = podfile.dependencies.find {|d| d.root_name == 'SomeExternalPod'}
        dep.external_source.should == { :git => 'GIT-URL', :commit => '1234' }
      end

      it "adds a subspec dependency on a Pod repo outside of a spec repo (the repo is expected to contain a podspec)" do
        podfile = Podfile.new { pod 'MainSpec/FirstSubSpec', :git => 'GIT-URL', :commit => '1234' }
        dep = podfile.dependencies.find {|d| d.root_name == 'MainSpec'}
        dep.name.should == 'MainSpec/FirstSubSpec'
        dep.external_source.should == { :git => 'GIT-URL', :commit => '1234' }
      end

      it "adds a dependency on a library outside of a spec repo (the repo does not need to contain a podspec)" do
        podfile = Podfile.new do
          pod 'SomeExternalPod', :podspec => 'http://gist/SomeExternalPod.podspec'
        end
        dep = podfile.dependencies.find {|d| d.root_name == 'SomeExternalPod'}
        dep.external_source.should == { :podspec => 'http://gist/SomeExternalPod.podspec' }
      end


      end

      #--------------------------------------#

      describe "#podspec_dependencies" do

        it "it can use use the dependencies of the first podspec in the directory of the podfile" do
          podfile = Podfile.new(fixture('Podfile')) do
            platform :ios
            podspec
          end
          podfile.dependencies.map(&:name).should == %w[ monkey ]
        end

        it "it can use use the dependencies of the podspec with the given absolute path" do
          banalib_path = fixture('BananaLib.podspec').to_s
          podfile = Podfile.new(fixture('Podfile')) do
            platform :ios
            podspec :path => banalib_path
          end
          podfile.dependencies.map(&:name).should == %w[ monkey ]
        end

        it "it can use use the dependencies of the podspec with the given relative path respect to the Podfile" do
          podfile = Podfile.new(fixture('Podfile')) do
            platform :ios
            podspec :path => 'BananaLib.podspec'
          end
          podfile.dependencies.map(&:name).should == %w[ monkey ]
        end

        it "it expands the tilde in the provided path" do
          stub_spec = Spec.new do |s|
            s.dependency 'monkey'
          end
          expaded = Pathname.new("/Users/fabio/BananaLib.podspec")
          Pod::Specification.expects(:from_file).with(expaded).returns(stub_spec)
          podfile = Podfile.new(fixture('Podfile')) do
            platform :ios
            podspec :path => '~/BananaLib.podspec'
          end
          podfile.dependencies.map(&:name).should == %w[ monkey ]
        end

        it "it can use use the dependencies of the podspec with the given path without the extension" do
          banalib_path = fixture('BananaLib').to_s
          podfile = Podfile.new(fixture('Podfile')) do
            platform :ios
            podspec :path => banalib_path
          end
          podfile.dependencies.map(&:name).should == %w[ monkey ]
        end

        it "it can use use the dependencies of the podspec with the given name without the extension" do
          podfile = Podfile.new(fixture('Podfile')) do
            platform :ios
            podspec :name => 'BananaLib'
          end
          podfile.dependencies.map(&:name).should == %w[ monkey ]
        end

        it "it can use use the dependencies of the podspec with the given name with the extension" do
          podfile = Podfile.new(fixture('Podfile')) do
            platform :ios
            podspec :name => 'BananaLib.podspec'
          end
          podfile.dependencies.map(&:name).should == %w[ monkey ]
        end

        xit "raises if unrecognized options are provided" do
          e = lambda {
            Podfile.new(fixture('Podfile')) do
              platform :ios
              podspec :unrecognized => 'BananaLib.podspec'
            end
          }.should.raise Podfile::StandardError
          e.message.should.match /Unrecognized options/
        end

      end

    end

    #-------------------------------------------------------------------------#

  end
end
