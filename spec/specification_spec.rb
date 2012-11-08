require File.expand_path('../spec_helper', __FILE__)

describe Pod::Specification do

  describe "In general" do
    before do
      @spec = Pod::Spec.new do |s|
        s.name = "Pod"
        s.version = "1.0"
        s.subspec 'Subspec' do |sp|
        end
      end
      @subspec = @spec.subspecs.first
    end

    it "returns the parent" do
      @subspec.parent.should == @spec
    end

    it "produces a string representation suitable for UI output." do
      @spec.to_s.should == "Pod (1.0)"
    end

    it "returns that it's equal to another specification if the name and version are equal" do
      @spec.should == Pod::Spec.new { |s| s.name = 'Pod'; s.version = '1.0' }
      @spec.should.not == Pod::Spec.new { |s| s.name = 'Seed'; s.version = '1.0' }
      @spec.should.not == Pod::Spec.new { |s| s.name = 'Pod'; s.version = '1.1' }
      @spec.should.not == Pod::Spec.new
    end
  end

  #-----------------------------------------------------------------------------#

  describe "Initialization from a file" do
    before do
      @path = fixture('BananaLib.podspec')
      @spec = Pod::Spec.from_file(@path)
    end

    it "can be initialized from a file" do
      @spec.class.should == Pod::Spec
    end

    it "reports the file from which it was initialized" do
      @spec.defined_in_file.should == @path
    end
  end

  #-----------------------------------------------------------------------------#

  describe "Hierarchy" do
    before do
      @spec = Pod::Spec.new do |s|
        s.name = "Pod"
        s.subspec 'Subspec' do |sp|
        end
      end
      @subspec = @spec.subspecs.first
    end

    it "returns the root spec" do
      @spec.root_spec.should == @spec
      @subspec.root_spec.should == @spec
    end

    it "returns the name of the root spec" do
      @spec.root_spec_name.should == 'Pod'
      @subspec.root_spec_name.should == 'Pod'
    end

    it "returns whether it is a root spec" do
      @spec.root_spec?.should.be.true
      @subspec.root_spec?.should.be.false
    end

    it "returns whether it is a subspec" do
      @spec.subspec?.should.be.false
      @subspec.subspec?.should.be.true
    end
  end

  #-----------------------------------------------------------------------------#

  describe "Dependencies" do
    before do
      @spec = Pod::Spec.new do |s|
        s.name = "Pod"
        s.version = '1.0'
        s.dependency 'AFNetworking'
        s.osx.dependency 'MagicalRecord'
        s.subspec 'Subspec' do |sp|
          sp.dependency 'libPusher'
          sp.subspec 'Subsubspec' do |ssp|
          end
        end
        s.subspec 'SubspecOSX' do |sp|
          sp.platform = :osx
        end
      end
      @subspec = @spec.subspecs[0]
      @subspec_osx = @spec.subspecs[1]
      @subsubspec = @subspec.subspecs.first
    end

    it "returns the child subspecs" do
      @spec.subspecs.sort_by(&:name).should == [@subspec, @subspec_osx]
    end

    it "returns the recursive subspecs" do
      @spec.recursive_subspecs.sort_by(&:name).should == [@subspec, @subsubspec, @subspec_osx]
    end

    it "returns a subspec with the given name" do
      @spec.subspec_by_name('Pod/Subspec').should == @subspec
      @spec.subspec_by_name('Pod/Subspec/Subsubspec').should == @subsubspec
    end

    it "raises if it can't find a subspec with the given name" do
      lambda { @spec.subspec_by_name('Pod/Nonexistent') }.should.raise Pod::StandardError
    end

    it "returns the dependencies on other Pods for the activated platform" do
      @spec.activate_platform(:ios)
      @spec.external_dependencies.should == [ Pod::Dependency.new('AFNetworking') ]
    end

    it "inherits the dependencies of the parent" do
      @spec.activate_platform(:ios)
      @subsubspec.external_dependencies.should == [ Pod::Dependency.new('AFNetworking'), Pod::Dependency.new('libPusher') ]
    end

    it "returns all the dependencies on specification of other Pods" do
      @spec.activate_platform(:ios)
      @spec.external_dependencies(true).should == [
        Pod::Dependency.new('AFNetworking'),
        Pod::Dependency.new('MagicalRecord') ]
    end

    it "returns dependencies on its subspecs" do
      @spec.activate_platform(:osx)
      @spec.subspec_dependencies.should == [
        Pod::Dependency.new('Pod/Subspec', '1.0'),
        Pod::Dependency.new('Pod/SubspecOSX', '1.0') ]
    end

    it "returns dependencies of only the subspecs that are supported for the active platform" do
      @spec.activate_platform(:ios)
      @spec.subspec_dependencies.should == [ Pod::Dependency.new('Pod/Subspec', '1.0') ]
    end

    it "returns a dependency on a default subspec if it is specified" do
      @spec.activate_platform(:osx)
      @spec.default_subspec = 'SubspecOSX'
      @spec.subspec_dependencies.should == [ Pod::Dependency.new('Pod/SubspecOSX', '1.0') ]
    end

    it "returns all the dependencies" do
      @spec.activate_platform(:osx)
      @spec.dependencies.sort_by(&:name).should == [
        Pod::Dependency.new('AFNetworking'),
        Pod::Dependency.new('MagicalRecord'),
        Pod::Dependency.new('Pod/Subspec', '1.0'),
        Pod::Dependency.new('Pod/SubspecOSX', '1.0') ]
    end
  end

  #-----------------------------------------------------------------------------#

  describe "DSL Helpers" do
    before do
      @spec = Pod::Spec.new do |s|
        s.name = "Pod"
        s.version = "1.0"
        s.subspec 'Subspec' do |sp| end
      end
      @subspec = @spec.subspecs.first
    end

    it "it reports if it is locally sourced" do
      @spec.activate_platform(:ios)
      @spec.source = {:local => '/tmp/local/path'}
      @spec.local?.should.be.true
    end

    it "returns whether it is supported on a given platform" do
      @spec.platform = :ios, '4.0'
      @spec.supported_on_platform?(:ios).should.be.true
      @spec.supported_on_platform?(:ios, '4.0').should.be.true
      @spec.supported_on_platform?(:ios, '3.0').should.be.false
      @spec.supported_on_platform?(:osx).should.be.false
      @spec.supported_on_platform?(:osx, '10.5').should.be.false
    end

    it "returns the available platforms for which the pod is supported" do
      @spec.platform = :ios, '4.0'
      @spec.available_platforms.count.should == 1
      @spec.available_platforms.first.should == :ios
      @spec.available_platforms.first.deployment_target.should == Pod::Version.new('4.0')
    end

    it "returns the deployment target for the given platform" do
      @spec.platform = :ios, '4.0'
      @spec.deployment_target(:ios).should == Pod::Version.new('4.0')
    end

    it "returns the deployment target specified the `deployment_target` attribute the spec has no `platform`" do
      @spec.platform = :ios, '4.0'
      @subspec.ios.deployment_target = '5.0'
      @subspec.deployment_target(:ios).should == Pod::Version.new('5.0')
    end

    it "inherits the deployment target from the parent" do
      @spec.platform = :ios, '4.0'
      @subspec.deployment_target(:ios).should == Pod::Version.new('4.0')
    end

    it "returns nil if not deployment target is available for the given platfrom" do
      @spec.osx.deployment_target = '10.6'
      @subspec.platform = :ios, '4.0'
      @subspec.deployment_target(:osx).should.be.nil
    end
  end

  #-----------------------------------------------------------------------------#

  describe "Multi-platform support" do
    before do
      @spec = Pod::Spec.new do |s|
        s.platform = :ios, '4.3'
        s.subspec 'Subspec' do |sp| end
      end
      @subspec = @spec.subspecs.first
    end

    it "can be activated for a supported platform" do
      @spec.platform = :ios
      lambda {@spec.activate_platform(:ios)}.should.not.raise Pod::StandardError
    end

    it "raises if a platform with another name is activated" do
      lambda {@spec.activate_platform(:osx)}.should.raise Pod::StandardError
    end

    it "raises if a platform with an unsupported deployment target is activated" do
      lambda {@spec.activate_platform(:ios, '4.0')}.should.raise Pod::StandardError
    end

    it "inherits the active platform of the root specification" do
      @spec.activate_platform(:ios)
      @subspec.active_platform.should == :ios
    end

    it "activates a platform at the root level" do
      @subspec.activate_platform(:ios)
      @spec.active_platform.should == :ios
    end

    it "provides support for the platform proxy" do
      @spec._on_platform(:ios) do
        @spec.instance_variable_get('@define_for_platforms').should == [ :ios ]
      end
      @spec.instance_variable_get('@define_for_platforms').should == Pod::Specification::PLATFORMS
    end
  end
end

#-------------------------------------------------------------------------------#

describe Pod::Specification::PlatformProxy do
  describe "In general" do
    before do
      @spec =  Pod::Spec.new
      @proxy = Pod::Specification::PlatformProxy.new(@spec, :ios)
    end

    it "declares the writer methods of the multi-platform attributes" do
      attributes = Pod::Specification.attributes.select(&:multi_platform?)
      attributes.each do |attr|
        @proxy.should.respond_to?(attr.writer_name)
      end
    end

    it "forwards multi-platform attributes to the specification" do
      @spec.expects(:source_files=).once
      @proxy.source_files = 'SomeFile'
    end

    it "configures the specificatin `@define_for_platforms` instance variable while setting an attribute" do
      @spec.expects(:_on_platform).with(:ios)
      @proxy.source_files = 'SomeFile'
    end

    it "works correctly with the specification multi platform attributes" do
      @proxy.preserve_paths = ['SomeFile']
      @spec.instance_variable_get('@preserve_paths').should == {
        :osx => [],
        :ios => ['SomeFile']
      }
    end
  end
end
