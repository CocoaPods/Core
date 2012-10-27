require File.expand_path('../../spec_helper', __FILE__)

describe Pod::Podfile::TargetDefinition do
  it "returns wether or not a target has any dependencies" do
    Pod::Podfile.new do
    end.target_definitions[:default].should.be.empty
    Pod::Podfile.new do
      pod 'JSONKit'
    end.target_definitions[:default].should.not.be.empty
  end

  before do
    @podfile = Pod::Podfile.new do
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

  it "returns all dependencies of all targets combined, which is used during resolving to ensure compatible dependencies" do
    @podfile.dependencies.map(&:name).sort.should == %w{ ASIHTTPRequest JSONKit Reachability SSZipArchive }
  end

  it "adds dependencies outside of any explicit target block to the default target" do
    target = @podfile.target_definitions[:default]
    target.label.should == 'Pods'
    target.dependencies.should == [Pod::Dependency.new('ASIHTTPRequest')]
  end

  it "adds dependencies of the outer target to non-exclusive targets" do
    target = @podfile.target_definitions[:debug]
    target.label.should == 'Pods-debug'
    target.dependencies.sort_by(&:name).should == [
      Pod::Dependency.new('ASIHTTPRequest'),
      Pod::Dependency.new('SSZipArchive')
    ]
  end

  it "does not add dependencies of the outer target to exclusive targets" do
    target = @podfile.target_definitions[:test]
    target.label.should == 'Pods-test'
    target.dependencies.should == [Pod::Dependency.new('JSONKit')]
  end

  it "adds dependencies of the outer target to nested targets" do
    target = @podfile.target_definitions[:subtarget]
    target.label.should == 'Pods-test-subtarget'
    target.dependencies.should == [Pod::Dependency.new('Reachability'), Pod::Dependency.new('JSONKit')]
  end

  xit "returns the Xcode project that contains the target to link with" do
    [:default, :debug, :test, :subtarget].each do |target_name|
      target = @podfile.target_definitions[target_name]
      target.user_project.path.to_s.should == 'iOS Project.xcodeproj'
    end
    [:osx_target, :nested_osx_target].each do |target_name|
      target = @podfile.target_definitions[target_name]
      target.user_project.path.to_s.should == 'OSX Project.xcodeproj'
    end
  end

  # TODO: Move to target installer, UserProjectIntegrator or Installer.
  xit "returns a Xcode project found in the working dir when no explicit project is specified" do
    xcodeproj1 = config.project_root + '1.xcodeproj'
    Pathname.expects(:glob).with(config.project_root + '*.xcodeproj').returns([xcodeproj1])
    Pod::Podfile::UserProject.new.path.should == xcodeproj1
  end

  # TODO: Move to target installer, UserProjectIntegrator or Installer.
  xit "returns `nil' if more than one Xcode project was found in the working when no explicit project is specified" do
    xcodeproj1, xcodeproj2 = config.project_root + '1.xcodeproj', config.project_root + '2.xcodeproj'
    Pathname.expects(:glob).with(config.project_root + '*.xcodeproj').returns([xcodeproj1, xcodeproj2])
    Pod::Podfile::UserProject.new.path.should == nil
  end

  it "leaves the name of the target, to link with, to be automatically resolved" do
    target = @podfile.target_definitions[:default]
    target.link_with.should == nil
  end

  it "returns the names of the explicit targets to link with" do
    target = @podfile.target_definitions[:test]
    target.link_with.should == ['TestRunner']
  end

  xit "returns the name of the Pods static library" do
    @podfile.target_definitions[:default].lib_name.should == 'libPods.a'
    @podfile.target_definitions[:test].lib_name.should == 'libPods-test.a'
  end

  xit "returns the name of the xcconfig file for the target" do
    @podfile.target_definitions[:default].xcconfig_name.should == 'Pods.xcconfig'
    @podfile.target_definitions[:default].xcconfig_path.should == 'Pods/Pods.xcconfig'
    @podfile.target_definitions[:test].xcconfig_name.should == 'Pods-test.xcconfig'
    @podfile.target_definitions[:test].xcconfig_path.should == 'Pods/Pods-test.xcconfig'
  end

  xit "returns the name of the 'copy resources script' file for the target" do
    @podfile.target_definitions[:default].copy_resources_script_name.should == 'Pods-resources.sh'
    @podfile.target_definitions[:default].copy_resources_script_path.should == 'Pods/Pods-resources.sh'
    @podfile.target_definitions[:test].copy_resources_script_name.should == 'Pods-test-resources.sh'
    @podfile.target_definitions[:test].copy_resources_script_path.should == 'Pods/Pods-test-resources.sh'
  end

  xit "returns the name of the 'prefix header' file for the target" do
    @podfile.target_definitions[:default].prefix_header_name.should == 'Pods-prefix.pch'
    @podfile.target_definitions[:test].prefix_header_name.should == 'Pods-test-prefix.pch'
  end

  xit "returns the name of the BridgeSupport file for the target" do
    @podfile.target_definitions[:default].bridge_support_name.should == 'Pods.bridgesupport'
    @podfile.target_definitions[:test].bridge_support_name.should == 'Pods-test.bridgesupport'
  end

  it "returns the platform of the target" do
    @podfile.target_definitions[:default].platform.should == :ios
    @podfile.target_definitions[:test].platform.should == :ios
    @podfile.target_definitions[:osx_target].platform.should == :osx
  end

  it "assigs a deployment target to the platforms if not specified" do
    @podfile.target_definitions[:default].platform.deployment_target.to_s.should == '4.3'
    @podfile.target_definitions[:test].platform.deployment_target.to_s.should == '4.3'
    @podfile.target_definitions[:osx_target].platform.deployment_target.to_s.should == '10.6'
  end

  it "autmatically marks a target as exclusive if the parent platform doesn't match" do
    @podfile.target_definitions[:osx_target].should.be.exclusive
    @podfile.target_definitions[:nested_osx_target].should.not.be.exclusive
  end

  xit "returns the specified configurations and wether it should be based on a debug or a release build" do
    Pod::Podfile::UserProject.any_instance.stubs(:project)
    all = { 'Release' => :release, 'Debug' => :debug, 'Test' => :debug }
    @podfile.target_definitions[:default].user_project.build_configurations.should == all.merge('iOS App Store' => :release)
    @podfile.target_definitions[:test].user_project.build_configurations.should == all.merge('iOS App Store' => :release)
    @podfile.target_definitions[:osx_target].user_project.build_configurations.should == all.merge('Mac App Store' => :release)
    @podfile.target_definitions[:nested_osx_target].user_project.build_configurations.should == all.merge('Mac App Store' => :release)
    @podfile.user_build_configurations.should == all.merge('iOS App Store' => :release, 'Mac App Store' => :release)
  end

  # TODO: this check should not be here
  xit "defaults, for unspecified configurations, to a release build" do
    project = Pod::Podfile::UserProject.new(fixture('SampleProject/SampleProject.xcodeproj'), 'Test' => :debug)
    project.build_configurations.should == { 'Release' => :release, 'Debug' => :debug, 'Test' => :debug, 'App Store' => :release }
  end

  it "specifies that the inhibit all warnings flag should be added to the target's build settings" do
    @podfile.target_definitions[:default].should.not.inhibit_all_warnings
    @podfile.target_definitions[:test].should.inhibit_all_warnings
    @podfile.target_definitions[:subtarget].should.inhibit_all_warnings
  end

  describe "with an Xcode project that's not in the project_root" do
    before do
      @target_definition = @podfile.target_definitions[:default]
      @target_definition.user_project.stubs(:path).returns('subdir/iOS Project.xcodeproj')
    end

    # TODO: This should be moved
    xit "returns the $(PODS_ROOT) relative to the project's $(SRCROOT)" do
      @target_definition.pods_root.should == 'Pods'
    end

    # TODO: This should be moved
    xit "simply returns the $(PODS_ROOT) path if no xcodeproj file is available and doesn't needs to integrate" do
      # config.integrate_targets.should.equal true
      # config.integrate_targets = false
      @target_definition.pods_root.should == 'Pods'
      @target_definition.user_project.stubs(:path).returns(nil)
      @target_definition.pods_root.should == 'Pods'
      # config.integrate_targets = true
    end

    # TODO: This should be moved
    xit "returns the xcconfig file path relative to the project's $(SRCROOT)" do
      @target_definition.xcconfig_relative_path.should == '../Pods/Pods.xcconfig'
    end

    # TODO: This should be moved
    xit "returns the 'copy resources script' path relative to the project's $(SRCROOT)" do
      @target_definition.copy_resources_script_relative_path.should == '${SRCROOT}/../Pods/Pods-resources.sh'
    end
  end
end
