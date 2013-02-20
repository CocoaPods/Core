require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Podfile::DSL do

    describe "Dependencies" do
      it "adds dependencies" do
        podfile = Podfile.new do
          pod 'ASIHTTPRequest'; pod 'SSZipArchive', '>= 0.1'
        end
        podfile.dependencies.size.should == 2
        podfile.dependencies.find {|d| d.root_name == 'ASIHTTPRequest'}.should == Dependency.new('ASIHTTPRequest')
        podfile.dependencies.find {|d| d.root_name == 'SSZipArchive'}.should   == Dependency.new('SSZipArchive', '>= 0.1')
      end

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

      it "raises if no name is specified for a podspec" do
        lambda { Podfile.new do
          pod
        end }.should.raise Podfile::StandardError
      end

      it "raises if an inlide podspec is specified" do
        lambda { Podfile.new do
          pod do |s|
            s.name = 'mypod'
          end
        end }.should.raise Podfile::StandardError
      end

      it "allows to specify a target definition" do
        podfile = Podfile.new do
          target :tests do
            pod 'OCMock'
          end
        end
        podfile.target_definitions[:tests].name.should == :tests
      end

      #--------------------------------------#

      describe "Podspec" do

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
          home_dir = File.expand_path("~")
          expanded = Pathname.new("#{home_dir}/BananaLib.podspec")
          Pod::Specification.expects(:from_file).with(expanded).returns(stub_spec)
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

        it "raises if unrecognized options are provided" do
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

    describe "Target configuration" do

      it "allows to specify a platform" do
        podfile = Podfile.new do
          platform :ios, "6.0"
          target :osx_target do
            platform :osx, "10.8"
          end
        end
        podfile.target_definitions[:default].platform.should == Platform.new(:ios, "6.0")
        podfile.target_definitions[:osx_target].platform.should == Platform.new(:osx, "10.8")
      end

      it "provides a default deployment target if not specified" do
        podfile = Podfile.new { platform :ios }
        podfile.target_definitions[:default].platform.deployment_target.should == Version.new('4.3')
        podfile = Podfile.new { platform :osx }
        podfile.target_definitions[:default].platform.deployment_target.should == Version.new('10.6')
      end

      it "raises if the specified platform is unsupported" do
        lambda { Podfile.new do
          platform :windows
        end }.should.raise Podfile::StandardError
      end



      it "allows to specify the user xcode project for a Target defintion" do
        podfile = Podfile.new { xcodeproj 'App.xcodeproj' }
        podfile.target_definitions[:default].user_project_path.should == 'App.xcodeproj'
      end


      it "allows to specify the build configurations of a user project" do
        podfile = Podfile.new do
          xcodeproj 'App.xcodeproj', 'Mac App Store' => :release, 'Test' => :debug
        end
        podfile.target_definitions[:default].build_configurations.should == {
          'Mac App Store' => :release, 'Test' => :debug
        }
      end

      it "appends the extension to a specified user project if needed" do
        podfile = Podfile.new { xcodeproj 'App' }
        podfile.target_definitions[:default].user_project_path.should == 'App.xcodeproj'
      end

      it "allows to specify the user targets a Target defintion should link with" do
        podfile = Podfile.new { link_with 'app_target' }
        podfile.target_definitions[:default].link_with.should == ['app_target']
      end


      it "allows to inhbit all the warnings of a Target defintion" do
        podfile = Podfile.new { inhibit_all_warnings! }
        podfile.target_definitions[:default].inhibit_all_warnings?.should.be.true
      end
    end

    #-------------------------------------------------------------------------#

    describe "Workspace" do

      it "specifies the Xcode workspace to use" do
        Podfile.new do
          workspace 'MyWorkspace.xcworkspace'
        end.workspace_path.should == 'MyWorkspace.xcworkspace'
      end

      it "appends the extension to the specified workspaces if needed" do
        Podfile.new do
          workspace 'MyWorkspace'
        end.workspace_path.should == 'MyWorkspace.xcworkspace'
      end

      it "specifies that BridgeSupport metadata should be generated" do
        Podfile.new {}.should.not.generate_bridge_support
        Podfile.new { generate_bridge_support! }.should.generate_bridge_support
      end

      it 'specifies that ARC compatibility flag should be generated' do
        Podfile.new {}.should.not.set_arc_compatibility_flag
        Podfile.new { set_arc_compatibility_flag! }.should.set_arc_compatibility_flag
      end
    end

    #-------------------------------------------------------------------------#

    describe "Hooks" do
      it "stores a block that will be called before integrating the targets" do
        yielded = nil
        Podfile.new do
          pre_install do |installer|
            yielded = installer
          end
        end.pre_install!(:an_installer)
        yielded.should == :an_installer
      end

      it "stores a block that will be called with the Installer instance once installation is finished" do
        yielded = nil
        Podfile.new do
          post_install do |installer|
            yielded = installer
          end
        end.post_install!(:an_installer)
        yielded.should == :an_installer
      end
    end
  end
end
