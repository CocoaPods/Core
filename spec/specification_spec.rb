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

      it "returns the attributes hash" do
        @spec.attributes_hash.should == {"name"=>"Pod", "version"=>"1.0"}
        @subspec.attributes_hash.should == {"name"=>"Subspec"}
      end

      it "returns the subspecs" do
        @spec.subspecs.should == [@subspec]
      end

      it "returns whether it is equal to another specification" do
        @spec.should == @spec
      end

      it "is not equal to another specification if the name is different" do
        spec = Spec.new { |s| s.name = 'Pod'; s.version = '1.0' }
        @spec.should.not == Spec.new { |s| s.name = 'Seed'; s.version = '1.0' }
      end

      it "is not equal to another specification if the version if different" do
        spec = Spec.new { |s| s.name = 'Pod'; s.version = '1.0' }
        @spec.should.not == Spec.new { |s| s.name = 'Pod'; s.version = '2.0' }
      end

      it "is equal to another if the name and the version match regardless of the attributes" do
        spec = Spec.new { |s| s.name = 'Pod'; s.version = '1.0' }
        @spec.should == Spec.new { |s| s.name = 'Pod'; s.version = '1.0'; s.source_files = "Classes" }
      end

      it "provides support for Array#uniq" do
        spec_1 = Spec.new { |s| s.name = 'Pod'; s.version = '1.0' }
        spec_2 = Spec.new { |s| s.name = 'Pod'; s.version = '1.0' }
        [spec_1, spec_2].uniq.count.should == 1
      end

      it "provides support for being used as a the key of a Hash" do
        spec_1 = Spec.new { |s| s.name = 'Pod'; s.version = '1.0' }
        spec_2 = Spec.new { |s| s.name = 'Pod'; s.version = '1.0' }
        hash = {}
        hash[spec_1] = "VALUE_1"
        hash[spec_2] = "VALUE_2"
        hash[spec_1].should == "VALUE_2"
      end

      it "produces a string representation suitable for UI output." do
        @spec.to_s.should == "Pod (1.0)"
      end

      it "returns the name and the version of a Specification from its #to_s output" do
        name, version = Specification.name_and_version_from_string("libPusher (1.0)")
        name.should == "libPusher"
        version.should == Version.new("1.0")
      end

      it "takes into account head information while returning the name and the version" do
        name, version = Specification.name_and_version_from_string("libPusher (HEAD based on 1.0)")
        name.should == "libPusher"
        version.should == Version.new("HEAD based on 1.0")
      end

      it "takes into account the full name of the subspec returning the name and the version" do
        name, version = Specification.name_and_version_from_string("RestKit/JSON (1.0)")
        name.should == "RestKit/JSON"
      end

      it "returns the root name of a given specification name" do
        Specification.root_name('Pod').should == 'Pod'
        Specification.root_name('Pod/Subspec').should == 'Pod'
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

      it "returns the recursive subspecs" do
        @spec.recursive_subspecs.sort_by(&:name).should == [@subspec, @subsubspec, @subspec_osx]
      end

      it "returns a subspec given the absolute name" do
        @spec.subspec_by_name('Pod/Subspec').should == @subspec
        @spec.subspec_by_name('Pod/Subspec/Subsubspec').should == @subsubspec
      end

      it "returns a subspec given the relative name" do
        @subspec.subspec_by_name('Subspec/Subsubspec').should == @subsubspec
      end

      it "raises if it can't find a subspec with the given name" do
        lambda { @spec.subspec_by_name('Pod/Nonexistent') }.should.raise StandardError
      end

      it "returns the default subspec" do
        @spec.default_subspec = 'Subspec'
        @spec.default_subspec.should == 'Subspec'
      end

      it "returns the dependencies on its subspecs" do
        @spec.subspec_dependencies.sort.should == [
          Dependency.new('Pod/Subspec', '1.0'),
          Dependency.new('Pod/SubspecOSX', '1.0') ]
      end

      it "returns the dependencies on its subspecs for a given platform" do
        @spec.subspec_dependencies(:ios).should == [
          Dependency.new('Pod/Subspec', '1.0')
        ]
      end

      it "returns a dependency on a default subspec if it is specified" do
        @spec.default_subspec = 'Subspec'
        @spec.subspec_dependencies.should == [
          Dependency.new('Pod/Subspec', '1.0')
        ]
      end

      it "returns all the dependencies" do
        @spec.dependencies.sort.should == [
          Dependency.new('AFNetworking'),
          Dependency.new('MagicalRecord') ]
      end

      it "returns the dependencies given the platform" do
        @spec.dependencies(:ios).sort.should == [ Dependency.new('AFNetworking') ]
      end

      it "inherits the dependencies of the parent" do
        @subsubspec.dependencies(:ios).sort.should == [ Dependency.new('AFNetworking'), Dependency.new('libPusher') ]
      end

      it "returns all the dependencies including the ones on subspecs given a platform" do
        @spec.all_dependencies.sort.should == [
          Dependency.new('AFNetworking'),
          Dependency.new('MagicalRecord'),
          Dependency.new('Pod/Subspec', '1.0'),
          Dependency.new('Pod/SubspecOSX', '1.0') ]
      end

      it "returns all the dependencies for a given platform" do
        @spec.all_dependencies(:ios).sort.should == [
          Dependency.new('AFNetworking'),
          Dependency.new('Pod/Subspec', '1.0') ]
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
        @spec.source = {"local" => '/tmp/local/path'}
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
        @spec.available_platforms.should == [Platform.new(:ios, '4.0')]
      end

      it "inherits the name of the supported platforms from the parent" do
        @spec.platform = :ios, '4.0'
        @subspec.available_platforms.should == [Platform.new(:ios, '4.0')]
      end

      it "returns the deployment target for the given platform" do
        @spec.platform = :ios, '4.0'
        @spec.deployment_target(:ios).should == '4.0'
      end

      it "allows a subspec to override the deployment target of the parent" do
        @spec.platform = :ios, '4.0'
        @subspec.ios.deployment_target = '5.0'
        @subspec.deployment_target(:ios).should == '5.0'
      end

      it "inherits the deployment target from the parent" do
        @spec.platform = :ios, '4.0'
        @subspec.deployment_target(:ios).should == '4.0'
      end

      it "returns the names of the supported platforms as specified by the user" do
        @spec.platform = :ios, '4.0'
        @spec.send(:supported_platform_names).should == ["ios"]
      end

      it "inherits the supported platform from the parent" do
        @spec.platform = :ios
        @subspec.send(:supported_platform_names).should == ["ios"]
      end

      it "returns the consumer for the given symbolic name of a platform" do
        @spec.ios.source_files = 'ios-files'
        consumer = @spec.consumer(:ios)
        consumer.spec.should == @spec
        consumer.platform_name.should == :ios
        consumer.source_files.should == ['ios-files']
      end

      it "returns the consumer of a given platform" do
        consumer = @spec.consumer(Platform.new :ios)
        consumer.spec.should == @spec
        consumer.platform_name.should == :ios
      end

      it "caches the consumers per platform" do
        @spec.consumer(:ios).should.equal?@spec.consumer(:ios)
        @spec.consumer(:ios).platform_name.should == :ios
        @spec.consumer(:osx).platform_name.should == :osx
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


    describe "DSL Attribute writers" do

      before do
        @spec =  Spec.new
      end

      it "stores the value of an attribute" do
        @spec.store_attribute(:attribute, "value")
        @spec.attributes_hash.should == {
          "name" => nil,
          "attribute" => "value"
        }
      end

      it "stores the value of an attribute for a given platform" do
        @spec.store_attribute(:attribute, "value", :ios)
        @spec.attributes_hash.should == {
          "name" => nil,
          "ios" => { "attribute" => "value" }
        }
      end

      it "converts the keys of the hashes to a string" do
        @spec.store_attribute(:attribute, { :key => "value" })
        @spec.attributes_hash.should == {
          "name" => nil,
          "attribute" => { "key" => "value" }
        }
      end

      it "declares attribute writer methods" do
        Specification::DSL.attributes.values.each do |attr|
          @spec.send(attr.writer_name, 'a_value')
          @spec.attributes_hash[attr.name.to_s].should == 'a_value'
        end
      end

      it "supports the singular form of attribute writer methods" do
        singular_attrs = Specification::DSL.attributes.values.select { |a| a.writer_singular_form }
        singular_attrs.each do |attr|
          @spec.send(attr.writer_name, 'a_value')
          @spec.attributes_hash[attr.name.to_s].should == 'a_value'
        end
      end
    end

    #-------------------------------------------------------------------------#

    describe "Initialization from a file" do

      it "can be initialized from a file" do
        spec = Spec.from_file(fixture('BananaLib.podspec'))
        spec.class.should == Spec
        spec.name.should == 'BananaLib'
      end

      it "can be initialized from a YAML file" do
        spec = Spec.from_file(fixture('BananaLib.podspec.yaml'))
        spec.class.should == Spec
        spec.name.should == 'BananaLib'
      end

      #--------------------------------------#

      before do
        @path = fixture('BananaLib.podspec')
        @spec = Spec.from_file(@path)
      end

      it "returns the checksum of the file in which it is defined" do
        @spec.checksum.should == '8ff74d56f7a56f314d56f187cabfe342b8bfbc6b'
      end

      it "returns a nil checksum if the specification is not defined in a file" do
        spec = Spec.new
        spec.checksum.should.be.nil
      end

      it "reports the file from which it was initialized" do
        @spec.defined_in_file.should == @path
      end
    end

    #-------------------------------------------------------------------------#

  end
end
