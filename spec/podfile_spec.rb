require File.expand_path('../spec_helper', __FILE__)

describe Pod::Podfile do
  describe "In general" do

    it "stores the path of the file it is loaded from" do
      podfile = Pod::Podfile.from_file(fixture('Podfile'))
      podfile.defined_in_file.should == fixture('Podfile')
    end

    before do
      @podfile = Pod::Podfile.new do
        pod 'ASIHTTPRequest'
        pod 'JSONKit'
        target "sub-target" do
          pod 'JSONKit'
          pod 'Reachability'
          pod 'SSZipArchive'
        end
      end
    end

    it "returns the target definitions" do
      @podfile.target_definitions.count.should == 2
      @podfile.target_definitions[:default].name.should == :default
      @podfile.target_definitions["sub-target"].name.should == "sub-target"
    end

    it "returns all dependencies of all targets combined" do
      @podfile.dependencies.map(&:name).sort.should == %w[ ASIHTTPRequest JSONKit Reachability SSZipArchive ]
    end

    it "returns the string representation" do
      @podfile.to_s.should == 'Podfile'
    end
  end

  #-----------------------------------------------------------------------------#

  describe "Nested target definitions" do

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

    it "leaves the name of the target, to link with, to be automatically resolved" do
      target = @podfile.target_definitions[:default]
      target.link_with.should == nil
    end

    it "returns the names of the explicit targets to link with" do
      target = @podfile.target_definitions[:test]
      target.link_with.should == ['TestRunner']
    end

    it "returns the platform of the target" do
      @podfile.target_definitions[:default].platform.should == :ios
      @podfile.target_definitions[:test].platform.should == :ios
      @podfile.target_definitions[:osx_target].platform.should == :osx
    end

    it "assigns a deployment target to the platforms if not specified" do
      @podfile.target_definitions[:default].platform.deployment_target.to_s.should == '4.3'
      @podfile.target_definitions[:test].platform.deployment_target.to_s.should == '4.3'
      @podfile.target_definitions[:osx_target].platform.deployment_target.to_s.should == '10.6'
    end

    it "automatically marks a target as exclusive if the parent platform doesn't match" do
      @podfile.target_definitions[:osx_target].should.be.exclusive
      @podfile.target_definitions[:nested_osx_target].should.not.be.exclusive
    end

    it "specifies that the inhibit all warnings flag should be added to the target's build settings" do
      @podfile.target_definitions[:default].should.not.inhibit_all_warnings
      @podfile.target_definitions[:test].should.inhibit_all_warnings
      @podfile.target_definitions[:subtarget].should.inhibit_all_warnings
    end

    it "returns the Xcode project that contains the target to link with" do
      [:default, :debug, :test, :subtarget].each do |target_name|
        target = @podfile.target_definitions[target_name]
        target.user_project_path.to_s.should == 'iOS Project.xcodeproj'
      end
      [:osx_target, :nested_osx_target].each do |target_name|
        target = @podfile.target_definitions[target_name]
        target.user_project_path.to_s.should == 'OSX Project.xcodeproj'
      end
    end
  end

  #-----------------------------------------------------------------------------#

  describe "DSL - Podfile attributes" do

    it "allows to specify a target definition" do
      podfile = Pod::Podfile.new do
        target :tests do
          pod 'OCMock'
        end
      end
      podfile.target_definitions[:tests].name.should == :tests
    end

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

    it "stores a block that will be called before integrating the targets" do
      yielded = nil
      Pod::Podfile.new do
        pre_install do |installer|
          yielded = installer
        end
      end.pre_install!(:an_installer)
      yielded.should == :an_installer
    end

    it "indicates if the pre install hook was executed" do
      Pod::Podfile.new {}.pre_install!(:an_installer).should.be == false
      result = Pod::Podfile.new { pre_install { |installer| } }.pre_install!(:an_installer)
      result.should.be == true
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

    it "indicates if the pod install hook was executed" do
      Pod::Podfile.new {}.post_install!(:an_installer).should.be == false
      result = Pod::Podfile.new { post_install { |installer| } }.post_install!(:an_installer)
      result.should.be == true
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

  #-----------------------------------------------------------------------------#

  describe "DSL - Target definition attributes" do

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


    it "adds dependencies" do
      podfile = Pod::Podfile.new do
        pod 'ASIHTTPRequest'; pod 'SSZipArchive', '>= 0.1'
      end
      podfile.dependencies.size.should == 2
      podfile.dependencies.find {|d| d.pod_name == 'ASIHTTPRequest'}.should == Pod::Dependency.new('ASIHTTPRequest')
      podfile.dependencies.find {|d| d.pod_name == 'SSZipArchive'}.should   == Pod::Dependency.new('SSZipArchive', '>= 0.1')
    end

    it "adds a dependency on a Pod repo outside of a spec repo (the repo is expected to contain a podspec)" do
      podfile = Pod::Podfile.new { pod 'SomeExternalPod', :git => 'GIT-URL', :commit => '1234' }
      dep = podfile.dependencies.find {|d| d.pod_name == 'SomeExternalPod'}
      dep.external_source.should == { :git => 'GIT-URL', :commit => '1234' }
    end

    it "adds a subspec dependency on a Pod repo outside of a spec repo (the repo is expected to contain a podspec)" do
      podfile = Pod::Podfile.new { pod 'MainSpec/FirstSubSpec', :git => 'GIT-URL', :commit => '1234' }
      dep = podfile.dependencies.find {|d| d.pod_name == 'MainSpec'}
      dep.name.should == 'MainSpec/FirstSubSpec'
      dep.external_source.should == { :git => 'GIT-URL', :commit => '1234' }
    end

    it "adds a dependency on a library outside of a spec repo (the repo does not need to contain a podspec)" do
      podfile = Pod::Podfile.new do
        pod 'SomeExternalPod', :podspec => 'http://gist/SomeExternalPod.podspec'
      end
      dep = podfile.dependencies.find {|d| d.pod_name == 'SomeExternalPod'}
      dep.external_source.should == { :podspec => 'http://gist/SomeExternalPod.podspec' }
    end

    it "returns whether a target definition it is empty" do
      Pod::Podfile.new do
      end.target_definitions[:default].should.be.empty
      Pod::Podfile.new do
        pod 'JSONKit'
      end.target_definitions[:default].should.not.be.empty
    end

    it "it can use use the dependencies of the first podspec in the directory of the podfile" do
      podfile = Pod::Podfile.new(fixture('banana-lib/Podfile')) do
        platform :ios
        podspec
      end
      podfile.dependencies.map(&:name).should == %w[ monkey ]
    end

    it "it can use use the dependencies of the podspec with the given path" do
      banalib_path = fixture('banana-lib/BananaLib.podspec').to_s
      podfile = Pod::Podfile.new do
        platform :ios
        podspec :path => banalib_path
      end
      podfile.dependencies.map(&:name).should == %w[ monkey ]
    end

    it "it can use use the dependencies of the podspec with the given name" do
      podfile = Pod::Podfile.new(fixture('banana-lib/Podfile')) do
        platform :ios
        podspec :name => 'BananaLib'
      end
      podfile.dependencies.map(&:name).should == %w[ monkey ]
    end
  end

  #-----------------------------------------------------------------------------#

  describe "Exceptions" do

    extend SpecHelper::TemporaryDirectory

    before do
      @podfile_file = temporary_directory + 'Podfile'
      @podfile_content = [ "platform :ios" ]
    end

    def write_podfile
      @podfile_content * "\n"
      File.open(@podfile_file, 'w') { |f| f.write(@podfile_content * "\n") }
    end

    it "includes the line of the podfile that generated the exception" do
      @podfile_content = [ "platform :windows", "pod 'libPusher'" ]
      write_podfile
      begin
        Pod::Podfile.from_file(@podfile_file)
      rescue Pod::Podfile::StandardError => e
        e.message.should.be =~ /from .*\/tmp\/Podfile:1/
        e.message.should.be =~ /platform :windows/
        e.message.should.be =~ /pod 'libPusher'/
      end
    end

    it "informs if a platform is unsupported" do
      @podfile_content = [ "platform :windows" ]
      write_podfile
      begin
        Pod::Podfile.from_file(@podfile_file)
      rescue Pod::Podfile::StandardError => e
        e.message.should.be =~ /Unsupported platform `windows`/
        e.message.should.be =~ /Podfile:1/
      end
    end

    it "informs that inline podspecs are deprecated" do
      @podfile_content << "pod do |s|" << "  s.name = 'mypod'" << "end"
      write_podfile
      begin
        Pod::Podfile.from_file(@podfile_file)
      rescue Pod::Podfile::StandardError => e
        e.message.should.be =~ /Inline specifications are deprecated/
        e.message.should.be =~ /Podfile:2/
      end
    end

    it "informs that a dependency needs a name" do
      @podfile_content << "pod"
      write_podfile
      begin
        Pod::Podfile.from_file(@podfile_file)
      rescue Pod::Podfile::StandardError => e
        e.message.should.be =~ /A dependency requires a name/
        e.message.should.be =~ /Podfile:2/
      end
    end
  end
end
