require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Specification::YAMLSupport do

    describe "In general" do
      before do
        path = fixture('BananaLib.podspec')
        @spec = Spec.from_file(path)
      end

      it "returns the YAML representation" do
        attributes_hash = @spec.attributes_hash
        yaml_attributes_hash = Specification.from_yaml(@spec.to_yaml).attributes_hash
        attributes_hash.should == yaml_attributes_hash
      end

      it "can be initialized from a YAML file" do
        yaml_path = fixture('BananaLib.podspec.yaml')
        spec_from_yaml = Specification.from_file(yaml_path)
        spec_from_yaml.attributes_hash.should == @spec.attributes_hash
      end

      it "returns whether it safe to convert a specification to hash" do
        @spec.safe_to_hash?.should.be.true
      end

      it "returns that it is not safe to convert a specification to a hash if there is hook defined" do
        @spec.pre_install do; end
        @spec.safe_to_hash?.should.be.false
      end
    end

    #-------------------------------------------------------------------------#

    describe "YAML Syntax" do

      it "allows to specify multiplatform attributes" do
        yaml = <<-EOS
          name: Pod
          ios:
            source_files: Files
        EOS
        spec = Specification.from_yaml(yaml)
        consumer = Specification::Consumer.new(spec, :ios)
        consumer.source_files.should == ["Files"]
      end

      it "allows to specify the dependencies" do
        yaml = <<-EOS
          name: Pod
          dependencies:
            monkey: ~> 1.0.1
        EOS
        spec = Specification.from_yaml(yaml)
        spec.dependencies.should == [Dependency.new('monkey', '~> 1.0.1')]
      end

      it "allows to specify a platform with a deplyment target" do
        yaml = <<-EOS
          name: Pod
          platforms:
            ios: '6.0'
        EOS
        spec = Specification.from_yaml(yaml)
        spec.available_platforms.should == [Platform.new(:ios, '6.0')]
      end

      it "allows to specify a platform without a deplyment target" do
        yaml = <<-EOS
          name: Pod
          platforms:
            ios
        EOS
        spec = Specification.from_yaml(yaml)
        spec.available_platforms.should == [Platform.new(:ios)]
      end

      it "allows to specify a multiple platforms without a deplyment target" do
        yaml = <<-EOS
          name: Pod
          platforms:
            - ios
            - osx
        EOS
        spec = Specification.from_yaml(yaml)
        spec.available_platforms.sort.should == [Platform.new(:ios), Platform.new(:osx)]
      end

    end
  end
end
