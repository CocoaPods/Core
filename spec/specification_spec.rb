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

    it "it reports if it is locally sourced" do
      @spec.activate_platform(:ios)
      @spec.source = {:local => '/tmp/local/path'}
      @spec.local?.should.be.true
    end

    it "returns the available platforms for which the pod is supported" do
      @spec.platform = :ios, '4.0'
      @spec.available_platforms.count.should == 1
      @spec.available_platforms.first.should == :ios
      @spec.available_platforms.first.deployment_target.should == Pod::Version.new('4.0')
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
      @path = fixture('banana-lib/BananaLib.podspec')
      @spec = Pod::Spec.from_file(@path)
    end

    xit "can be initialized from a file" do
      @spec.class.should == Pod::Spec
    end

    xit "reports the file from which it was initialized" do
      @spec.from_file.should == @path
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
      end
      @subspec = @spec.subspecs.first
      @subsubspec = @subspec.subspecs.first
    end

    it "returns the recursive subspecs" do
      @spec.recursive_subspecs.sort_by(&:name).should == [@subspec, @subsubspec]
    end

    xit "returns a subspec with the given name" do
      @spec.subspec_by_name('Pod/Subspec').should == @subspec
      @spec.subspec_by_name('Pod/Subspec/Subsubspec').should == @subsubspec
    end

    it "raises if it can't find a subspec with the given name" do
      lambda { @spec.subspec_by_name('Pod/Subspec') }.should.raise Pod::StandardError
    end

    xit "returns the dependencies on specification of other Pods" do
      @spec.activate_platform(:ios)
      @spec.external_dependencies.map(&:name).should == [ Pod::Dependency.new('AFNetworking') ]
      @subsubspec.external_dependencies.map(&:name).should == [ Pod::Dependency.new('libPusher') ]
      @subsubspec.external_dependencies.map(&:name).should == []
    end

    xit "returns the dependencies on specification of other Pods regardless of the platform" do
      deps = @spec.external_dependencies(true).map(&:name)
      deps.should == [ Pod::Dependency.new('AFNetworking'), Pod::Dependency.new('MagicalRecord') ]
    end

    it "by default it returns dependencies on its subspecs" do
      @spec.activate_platform(:ios)
      @spec.subspec_dependencies.should == [ Pod::Dependency.new('Pod/Subspec', '1.0') ]
    end

    xit "returns a dependency on a preferred subspec is specified" do

    end

    xit "returns all the dependencies" do
      @spec.activate_platform(:ios)
      deps = @spec.dependencies.sort_by(&:name)
      deps.should == [ 'AFNetworking', Pod::Dependency.new('Pod/Subspec', '1.0') ]
    end
  end

  #-----------------------------------------------------------------------------#

  describe "Multi-platform support" do

    #     xit "does not cache platform attributes and can activate another platform" do
    #       @spec.stubs(:platform).returns nil
    #       @spec.activate_platform(:ios)
    #       @subsubspec.source_files.map { |f| f.to_s }.should == %w[ spec.m  subspec_ios.m subsubspec.m ]
    #       @spec.activate_platform(:osx)
    #       @subsubspec.source_files.map { |f| f.to_s }.should == %w[ spec.m  subspec_osx.m subsubspec.m ]
    #     end

    #     xit "returns the top level parent spec" do
    #       @spec.subspecs.first.top_level_parent.should == @spec
    #       @spec.subspecs.first.subspecs.first.top_level_parent.should == @spec
    #     end
    #

    #     xit "returns the platform that the static library should be build for" do
    #       @spec.platform = :ios
    #       @spec.platform.should == :ios
    #     end
    #
    #     xit "returns the platform and the deployment target" do
    #       @spec.platform = :ios, '4.0'
    #       @spec.platform.should == :ios
    #       @spec.platform.deployment_target.should == Pod::Version.new('4.0')
    #     end
    #
    #
    #     xit "can be activated for a supported platform" do
    #       @spec.platform = :ios
    #       lambda {@spec.activate_platform(:ios)}.should.not.raise Pod::StandardError
    #     end
    #
    #     xit "raised if attempted to be activated for an unsupported platform" do
    #       @spec.platform = :osx, '10.7'
    #       lambda {@spec.activate_platform(:ios)}.should.raise Pod::StandardError
    #       lambda {@spec.activate_platform(:ios, '10.6')}.should.raise Pod::StandardError
    #     end
    #
    #     xit "raises if not activated for a platform before accessing a multi-platform value" do
    #       @spec.platform = :ios
    #       lambda {@spec.source_files}.should.raise Pod::StandardError
    #     end
    #
    #     xit "has the same active platform across the chain attributes" do
    #       @spec.activate_platform(:ios)
    #       @subspec.active_platform.should == :ios
    #       @subsubspec.active_platform.should == :ios
    #
    #       @spec.stubs(:platform).returns nil
    #       @subsubspec.activate_platform(:osx)
    #       @subspec.active_platform.should == :osx
    #       @spec.active_platform.should == :osx
    #     end

  end
end

#-------------------------------------------------------------------------------#

describe Pod::Specification::PlatformProxy do
  describe "In general" do

    xit "declares the writer methods of the multi-platform attributes" do

    end

    xit "forwards multi-platform attributes to the specification" do

    end

  end
end
