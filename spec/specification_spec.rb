require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe Specification do

    describe "In general" do
      before do
        @spec = Spec.new do |s|
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
        @spec.should == Spec.new { |s| s.name = 'Pod'; s.version = '1.0' }
        @spec.should.not == Spec.new { |s| s.name = 'Seed'; s.version = '1.0' }
        @spec.should.not == Spec.new { |s| s.name = 'Pod'; s.version = '1.1' }
        @spec.should.not == Spec.new
      end

      it "returns the checksum of the file in which it is defined" do
        @path = fixture('BananaLib.podspec')
        @spec = Spec.from_file(@path)
        @spec.checksum.should == '439d9f683377ecf4a27de43e8cf3bce6be4df97b'
      end

      it "returns a nil checksum if the specification is not defined in a file" do
        @spec.checksum.should.be.nil
      end

      it "returns the root name of a given specification name" do
        Specification.root_name('Pod').should == 'Pod'
        Specification.root_name('Pod/Subspec').should == 'Pod'
      end
    end

    #-------------------------------------------------------------------------#

    describe "Initialization from a file" do
      before do
        @path = fixture('BananaLib.podspec')
        @spec = Spec.from_file(@path)
      end

      it "can be initialized from a file" do
        @spec.class.should == Spec
      end

      it "reports the file from which it was initialized" do
        @spec.defined_in_file.should == @path
      end
    end

    #-------------------------------------------------------------------------#

    describe "Hierarchy" do
      before do
        @spec = Spec.new do |s|
          s.name = "Pod"
          s.subspec 'Subspec' do |sp|
          end
        end
        @subspec = @spec.subspecs.first
      end

      it "returns the root spec" do
        @spec.root.should == @spec
        @subspec.root.should == @spec
      end

      it "returns whether it is a root spec" do
        @spec.root?.should.be.true
        @subspec.root?.should.be.false
      end

      it "returns whether it is a subspec" do
        @spec.subspec?.should.be.false
        @subspec.subspec?.should.be.true
      end
    end

    #-------------------------------------------------------------------------#

    describe "Dependencies" do
      before do
        @spec = Spec.new do |s|
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
        @subspec.subspec_by_name('Subspec/Subsubspec').should == @subsubspec
      end

      it "raises if it can't find a subspec with the given name" do
        lambda { @spec.subspec_by_name('Pod/Nonexistent') }.should.raise StandardError
        lambda { @spec.subspec_by_name('Pod/Subspeca') }.should.raise StandardError
      end

      it "returns the dependencies on other Pods for the activated platform" do
        @spec.activate_platform(:ios)
        @spec.external_dependencies.should == [ Dependency.new('AFNetworking') ]
      end

      it "inherits the dependencies of the parent" do
        @spec.activate_platform(:ios)
        @subsubspec.external_dependencies.should == [ Dependency.new('AFNetworking'), Dependency.new('libPusher') ]
      end

      it "returns all the dependencies on specification of other Pods" do
        @spec.activate_platform(:ios)
        @spec.external_dependencies(true).should == [
          Dependency.new('AFNetworking'),
          Dependency.new('MagicalRecord') ]
      end

      it "returns dependencies on its subspecs" do
        @spec.activate_platform(:osx)
        @spec.subspec_dependencies.should == [
          Dependency.new('Pod/Subspec', '1.0'),
          Dependency.new('Pod/SubspecOSX', '1.0') ]
      end

      it "returns dependencies of only the subspecs that are supported for the active platform" do
        @spec.activate_platform(:ios)
        @spec.subspec_dependencies.should == [ Dependency.new('Pod/Subspec', '1.0') ]
      end

      it "returns a dependency on a default subspec if it is specified" do
        @spec.activate_platform(:osx)
        @spec.default_subspec = 'SubspecOSX'
        @spec.subspec_dependencies.should == [ Dependency.new('Pod/SubspecOSX', '1.0') ]
      end

      it "returns all the dependencies" do
        @spec.activate_platform(:osx)
        @spec.dependencies.sort_by(&:name).should == [
          Dependency.new('AFNetworking'),
          Dependency.new('MagicalRecord'),
          Dependency.new('Pod/Subspec', '1.0'),
          Dependency.new('Pod/SubspecOSX', '1.0') ]
      end
    end

    #-------------------------------------------------------------------------#

    describe "DSL Helpers" do
      before do
        @spec = Spec.new do |s|
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
        @spec.available_platforms.first.deployment_target.should == Version.new('4.0')
      end

      it "returns the deployment target for the given platform" do
        @spec.platform = :ios, '4.0'
        @spec.deployment_target(:ios).should == Version.new('4.0')
      end

      it "returns the deployment target specified the `deployment_target` attribute the spec has no `platform`" do
        @spec.platform = :ios, '4.0'
        @subspec.ios.deployment_target = '5.0'
        @subspec.deployment_target(:ios).should == Version.new('5.0')
      end

      it "inherits the deployment target from the parent" do
        @spec.platform = :ios, '4.0'
        @subspec.deployment_target(:ios).should == Version.new('4.0')
      end

      it "returns nil if not deployment target is available for the given platfrom" do
        @spec.osx.deployment_target = '10.6'
        @subspec.platform = :ios, '4.0'
        @subspec.deployment_target(:osx).should.be.nil
      end
    end

    #-------------------------------------------------------------------------#

    describe "Multi-platform support" do
      before do
        @spec = Spec.new do |s|
          s.platform = :ios, '4.3'
          s.subspec 'Subspec' do |sp| end
        end
        @subspec = @spec.subspecs.first
      end

      it "can be activated for a supported platform" do
        @spec.platform = :ios
        lambda {@spec.activate_platform(:ios)}.should.not.raise StandardError
      end

      it "raises if a platform with another name is activated" do
        lambda {@spec.activate_platform(:osx)}.should.raise StandardError
      end

      it "raises if a platform with an unsupported deployment target is activated" do
        lambda {@spec.activate_platform(:ios, '4.0')}.should.raise StandardError
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
        @spec.instance_variable_get('@define_for_platforms').should == Specification::PLATFORMS
      end
    end

    #-------------------------------------------------------------------------#

    describe "Hooks" do
      before do
        @spec =  Spec.new
      end

      it "it executes the pre install hook and returns whether it was executed" do
        @spec.pre_install!(nil, nil).should == FALSE
        @spec.pre_install do; end
        @spec.pre_install!(nil, nil).should == TRUE
      end

      it "it executes the post install hook and returns whether it was executed" do
        @spec.post_install!(nil).should == FALSE
        @spec.post_install do; end
        @spec.post_install!(nil).should == TRUE
      end
    end

    #-------------------------------------------------------------------------#

      before do
      end
      end

      end

      end

      end

      end

      end

      end

    end
  end


      end

        end
      end

      end

      end

      end
    end
  end
end
