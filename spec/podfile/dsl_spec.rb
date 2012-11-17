require File.expand_path('../../spec_helper', __FILE__)

describe Pod::Podfile::DSL do

  describe "Dependencies" do
    it "adds dependencies" do
      podfile = Pod::Podfile.new do
        pod 'ASIHTTPRequest'; pod 'SSZipArchive', '>= 0.1'
      end
      podfile.dependencies.size.should == 2
      podfile.dependencies.find {|d| d.root_spec_name == 'ASIHTTPRequest'}.should == Pod::Dependency.new('ASIHTTPRequest')
      podfile.dependencies.find {|d| d.root_spec_name == 'SSZipArchive'}.should   == Pod::Dependency.new('SSZipArchive', '>= 0.1')
    end

    it "adds a dependency on a Pod repo outside of a spec repo (the repo is expected to contain a podspec)" do
      podfile = Pod::Podfile.new { pod 'SomeExternalPod', :git => 'GIT-URL', :commit => '1234' }
      dep = podfile.dependencies.find {|d| d.root_spec_name == 'SomeExternalPod'}
      dep.external_source.should == { :git => 'GIT-URL', :commit => '1234' }
    end

    it "adds a subspec dependency on a Pod repo outside of a spec repo (the repo is expected to contain a podspec)" do
      podfile = Pod::Podfile.new { pod 'MainSpec/FirstSubSpec', :git => 'GIT-URL', :commit => '1234' }
      dep = podfile.dependencies.find {|d| d.root_spec_name == 'MainSpec'}
      dep.name.should == 'MainSpec/FirstSubSpec'
      dep.external_source.should == { :git => 'GIT-URL', :commit => '1234' }
    end

    it "adds a dependency on a library outside of a spec repo (the repo does not need to contain a podspec)" do
      podfile = Pod::Podfile.new do
        pod 'SomeExternalPod', :podspec => 'http://gist/SomeExternalPod.podspec'
      end
      dep = podfile.dependencies.find {|d| d.root_spec_name == 'SomeExternalPod'}
      dep.external_source.should == { :podspec => 'http://gist/SomeExternalPod.podspec' }
    end

    it "allows to specify a target definition" do
      podfile = Pod::Podfile.new do
        target :tests do
          pod 'OCMock'
        end
      end
      podfile.target_definitions[:tests].name.should == :tests
    end

    it "it can use use the dependencies of the first podspec in the directory of the podfile" do
      podfile = Pod::Podfile.new(fixture('Podfile')) do
        platform :ios
        podspec
      end
      podfile.dependencies.map(&:name).should == %w[ monkey ]
    end

    it "it can use use the dependencies of the podspec with the given path" do
      banalib_path = fixture('BananaLib.podspec').to_s
      podfile = Pod::Podfile.new do
        platform :ios
        podspec :path => banalib_path
      end
      podfile.dependencies.map(&:name).should == %w[ monkey ]
    end

    it "it can use use the dependencies of the podspec with the given name" do
      podfile = Pod::Podfile.new(fixture('Podfile')) do
        platform :ios
        podspec :name => 'BananaLib'
      end
      podfile.dependencies.map(&:name).should == %w[ monkey ]
    end
  end

  #---------------------------------------------------------------------------#

  describe "Target configuration" do

    it "allows to specify a platform" do
      podfile = Pod::Podfile.new do
        platform :ios, "6.0"
        target :osx_target do
          platform :osx, "10.8"
        end
      end
      podfile.target_definitions[:default].platform.should == Pod::Platform.new(:ios, "6.0")
      podfile.target_definitions[:osx_target].platform.should == Pod::Platform.new(:osx, "10.8")
    end

    it "provides a default deployment target if not specified" do
      podfile = Pod::Podfile.new { platform :ios }
      podfile.target_definitions[:default].platform.deployment_target.should == Pod::Version.new('4.3')
      podfile = Pod::Podfile.new { platform :osx }
      podfile.target_definitions[:default].platform.deployment_target.should == Pod::Version.new('10.6')
    end

    it "allows to specify the user xcode project for a Target defintion" do
      podfile = Pod::Podfile.new { xcodeproj 'App.xcodeproj' }
      podfile.target_definitions[:default].user_project_path.should == 'App.xcodeproj'
    end


    it "allows to specify the build configurations of a user project" do
      podfile = Pod::Podfile.new do
        xcodeproj 'App.xcodeproj', 'Mac App Store' => :release, 'Test' => :debug
      end
      podfile.target_definitions[:default].build_configurations.should == {
        'Mac App Store' => :release, 'Test' => :debug
      }
    end

    it "appends the extension to a specified user project if needed" do
      podfile = Pod::Podfile.new { xcodeproj 'App' }
      podfile.target_definitions[:default].user_project_path.should == 'App.xcodeproj'
    end

    it "allows to specify the user targets a Target defintion should link with" do
      podfile = Pod::Podfile.new { link_with 'app_target' }
      podfile.target_definitions[:default].link_with.should == ['app_target']
    end


    it "allows to inhbit all the warnings of a Target defintion" do
      podfile = Pod::Podfile.new { inhibit_all_warnings! }
      podfile.target_definitions[:default].inhibit_all_warnings?.should.be.true
    end
  end

  #---------------------------------------------------------------------------#

  describe "Workspace" do

    it "specifies the Xcode workspace to use" do
      Pod::Podfile.new do
        workspace 'MyWorkspace.xcworkspace'
      end.workspace_path.should == 'MyWorkspace.xcworkspace'
    end

    it "appends the extension to the specified workspaces if needed" do
      Pod::Podfile.new do
        workspace 'MyWorkspace'
      end.workspace_path.should == 'MyWorkspace.xcworkspace'
    end

    it "specifies that BridgeSupport metadata should be generated" do
      Pod::Podfile.new {}.should.not.generate_bridge_support
      Pod::Podfile.new { generate_bridge_support! }.should.generate_bridge_support
    end

    it 'specifies that ARC compatibility flag should be generated' do
      Pod::Podfile.new {}.should.not.set_arc_compatibility_flag
      Pod::Podfile.new { set_arc_compatibility_flag! }.should.set_arc_compatibility_flag
    end
  end

  #---------------------------------------------------------------------------#

  describe "Hooks" do

    it "stores a block that will be called before integrating the targets" do
      yielded = nil
      Pod::Podfile.new do
        pre_install do |installer|
          yielded = installer
        end
      end.pre_install!(:an_installer)
      yielded.should == :an_installer
    end

    it "stores a block that will be called with the Installer instance once installation is finished" do
      yielded = nil
      Pod::Podfile.new do
        post_install do |installer|
          yielded = installer
        end
      end.post_install!(:an_installer)
      yielded.should == :an_installer
    end
  end
end

