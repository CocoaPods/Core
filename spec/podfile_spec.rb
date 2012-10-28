require File.expand_path('../spec_helper', __FILE__)

describe Pod::Podfile do
  describe "In general" do

    it "loads from a file" do
      podfile = Pod::Podfile.from_file(fixture('Podfile'))
      podfile.defined_in_file.should == fixture('Podfile')
    end

    it "assigns the platform attribute to the current target" do
      podfile = Pod::Podfile.new { platform :ios }
      podfile.target_definitions[:default].platform.should == :ios
    end

    it "provides a default deployment target if not specified" do
      podfile = Pod::Podfile.new { platform :ios }
      podfile.target_definitions[:default].platform.deployment_target.should == Pod::Version.new('4.3')
    end

    xit "raise error if unsupported platform is supplied" do
      lambda {
        Pod::Podfile.new { platform :iOS }
      }.should.raise Pod::Podfile::StandardError

      begin
        Pod::Podfile.new { platform :iOS }
      rescue Pod::Podfile::StandardError => e
        e.stubs(:podfile_line).returns("./podfile_spec.rb:1")
        e.message.should.be =~ /podfile_spec\.rb:1/
      end
    end

    it "adds dependencies" do
      podfile = Pod::Podfile.new { pod 'ASIHTTPRequest'; pod 'SSZipArchive', '>= 0.1' }
      podfile.dependencies.size.should == 2
      podfile.dependency_by_top_level_spec_name('ASIHTTPRequest').should == Pod::Dependency.new('ASIHTTPRequest')
      podfile.dependency_by_top_level_spec_name('SSZipArchive').should == Pod::Dependency.new('SSZipArchive', '>= 0.1')
    end

    it "adds a dependency on a Pod repo outside of a spec repo (the repo is expected to contain a podspec)" do
      podfile = Pod::Podfile.new do
        pod 'SomeExternalPod', :git => 'GIT-URL', :commit => '1234'
      end
      dep = podfile.dependency_by_top_level_spec_name('SomeExternalPod')
      dep.external_source.should == { :git => 'GIT-URL', :commit => '1234' }
    end

    it "adds a subspec dependency on a Pod repo outside of a spec repo (the repo is expected to contain a podspec)" do
      podfile = Pod::Podfile.new do
        pod 'MainSpec/FirstSubSpec', :git => 'GIT-URL', :commit => '1234'
      end
      dep = podfile.dependency_by_top_level_spec_name('MainSpec')
      dep.external_source.should == { :git => 'GIT-URL', :commit => '1234' }
    end

    it "adds a dependency on a library outside of a spec repo (the repo does not need to contain a podspec)" do
      podfile = Pod::Podfile.new do
        pod 'SomeExternalPod', :podspec => 'http://gist/SomeExternalPod.podspec'
      end
      dep = podfile.dependency_by_top_level_spec_name('SomeExternalPod')
      dep.external_source.should == { :podspec => 'http://gist/SomeExternalPod.podspec' }
    end

    it "specifies that BridgeSupport metadata should be generated" do
      Pod::Podfile.new {}.should.not.generate_bridge_support
      Pod::Podfile.new { generate_bridge_support! }.should.generate_bridge_support
    end

    it 'specifies that ARC compatibility flag should be generated' do
      Pod::Podfile.new { set_arc_compatibility_flag! }.should.set_arc_compatibility_flag
    end

    it "stores a block that will be called with the Installer before the target integration" do
      yielded = nil
      Pod::Podfile.new do
        pre_install do |installer|
          yielded = installer
        end
      end.pre_install!(:an_installer)
      yielded.should == :an_installer
    end

    it "stores a block that will be called with the Installer instance once installation is finished (but the project is not written to disk yet)" do
      yielded = nil
      Pod::Podfile.new do
        post_install do |installer|
          yielded = installer
        end
      end.post_install!(:an_installer)
      yielded.should == :an_installer
    end

    # TODO: Move to target installer, UserProjectIntegrator or Installer.
    xit "assumes the xcode project is the only existing project in the root" do
      podfile = Pod::Podfile.new do
        target(:another_target) {}
      end

      path = config.project_root + 'MyProject.xcodeproj'
      Pathname.expects(:glob).with(config.project_root + '*.xcodeproj').returns([path])

      podfile.target_definitions[:default].user_project.path.should == path
      podfile.target_definitions[:another_target].user_project.path.should == path
    end

    # TODO: Move to target installer, UserProjectIntegrator or Installer.
    xit "assumes the basename of the workspace is the same as the default target's project basename" do
      path = config.project_root + 'MyProject.xcodeproj'
      Pathname.expects(:glob).with(config.project_root + '*.xcodeproj').returns([path])
      Pod::Podfile.new {}.workspace.should == config.project_root + 'MyProject.xcworkspace'

      Pod::Podfile.new do
        xcodeproj 'AnotherProject.xcodeproj'
      end.workspace.should == config.project_root + 'AnotherProject.xcworkspace'
    end

    xit "does not base the workspace name on the default target's project if there are multiple projects specified" do
      Pod::Podfile.new do
        xcodeproj 'MyProject'
        target :another_target do
          xcodeproj 'AnotherProject'
        end
      end.workspace.should == nil
    end

    it "specifies the Xcode workspace to use" do
      Pod::Podfile.new do
        xcodeproj 'AnotherProject'
        workspace 'MyWorkspace'
      end.workspace.should == 'MyWorkspace.xcworkspace'
      Pod::Podfile.new do
        xcodeproj 'AnotherProject'
        workspace 'MyWorkspace.xcworkspace'
      end.workspace.should == 'MyWorkspace.xcworkspace'
    end
  end

  describe "Podspec method" do
    xit "it can use use the dependencies of a podspec" do

    end

    xit "it allows to specify the name of a podspec" do

    end

    xit "it allows to specify the path of a podspec" do

    end
  end

  describe "Validation" do

    # TODO: This should be moved
    xit "raises if it should integrate and can't find an xcodeproj" do
      config.integrate_targets = true
      target_definition = Pod::Podfile.new {}.target_definitions[:default]
      target_definition.user_project.stubs(:path).returns(nil)
      exception = lambda {
        target_definition.relative_pods_root
      }.should.raise Pod::StandardError
      exception.message.should.include "Xcode project"
    end
  end
end
