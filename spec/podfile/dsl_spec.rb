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

      it "raises if no name is specified for a Pod" do
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

      it "it can use use the dependencies of a podspec" do
        banalib_path = fixture('BananaLib.podspec').to_s
        podfile = Podfile.new(fixture('Podfile')) do
          platform :ios
          podspec :path => banalib_path
        end
        podfile.dependencies.map(&:name).should == %w[ monkey ]
      end

      it "allows to specify a child target definition" do
        podfile = Podfile.new do
          target :tests do
            pod 'OCMock'
          end
        end
        podfile.target_definitions[:tests].name.should == :tests
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
        podfile.target_definitions["Pods"].platform.should == Platform.new(:ios, "6.0")
        podfile.target_definitions[:osx_target].platform.should == Platform.new(:osx, "10.8")
      end

      it "allows to specify whether the target is exclusive" do
        podfile = Podfile.new do
          target 'Pods', :exclusive => true do
          end
        end
        podfile.target_definitions["Pods"].should.be.exclusive
      end

      it "is not exclusive by default" do
        podfile = Podfile.new do
          target 'Pods' do
          end
        end
        podfile.target_definitions["Pods"].should.not.be.exclusive
      end

      it "raises if unrecognized keys are passed during the initialization of a target" do
        should.raise Informative do
          podfile = Podfile.new do
            target 'Pods', :unrecognized => true do
            end
          end
        end
      end

      it "allows to specify the user xcode project for a Target definition" do
        podfile = Podfile.new { xcodeproj 'App.xcodeproj' }
        podfile.target_definitions["Pods"].user_project_path.should == 'App.xcodeproj'
      end

      it "allows to specify the build configurations of a user project" do
        podfile = Podfile.new do
          xcodeproj 'App.xcodeproj', 'Mac App Store' => :release, 'Test' => :debug
        end
        podfile.target_definitions["Pods"].build_configurations.should == {
          'Mac App Store' => :release, 'Test' => :debug
        }
      end

      it "allows to specify the user targets a Target definition should link with" do
        podfile = Podfile.new { link_with 'app_target' }
        podfile.target_definitions["Pods"].link_with.should == ['app_target']
      end

      it "allows to inhibit all the warnings of a Target definition" do
        podfile = Podfile.new { pod 'ObjectiveRecord'; inhibit_all_warnings! }
        podfile.target_definitions["Pods"].inhibits_warnings_for_pod?('ObjectiveRecord').should.be.true
      end
    end

    #-------------------------------------------------------------------------#

    describe "Workspace" do

      it "specifies the Xcode workspace to use" do
        Podfile.new do
          workspace 'MyWorkspace.xcworkspace'
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

    #-------------------------------------------------------------------------#

  end
end
