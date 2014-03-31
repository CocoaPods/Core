require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Podfile::TargetDefinition do

    before do
      @sut = Podfile::Workspace.new
    end

    describe "Attributes" do

      it "inherits from the base model" do
        @sut.is_a?(Podfile::BaseModel).should.be.true
      end

      it "allows to specify a name" do
        @sut.name = 'MyApp'
        @sut.name.should == 'MyApp'
      end

      it "allows to add a project description" do
        project = Podfile::Project.new
        @sut.add_project(project)
        @sut.projects.should == [project]
      end

      it "raises if there is an attempt to add a project without the correct class" do
        project = Object.new
        should.raise ArgumentError do
          @sut.add_project(project)
        end.message.should.include? 'Podfile::Project'
      end

    end

    #-------------------------------------------------------------------------#

    describe "Hash conversion" do
      it "uses string for the keys of the hash" do
        keys = Podfile::TargetDefinition::HASH_KEYS
        keys.map(&:class).uniq.should == [String]
      end
    end

    #-------------------------------------------------------------------------#

  end
end
