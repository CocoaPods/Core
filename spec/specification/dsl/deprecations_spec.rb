require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Specification::DSL::Deprecations do

    before do
      @spec =  Spec.new
    end

    it "warns about the renamed `preferred_dependency`" do
      STDERR.expects(:puts)
      @spec.preferred_dependency='args'
    end

    it "warns about the deprecated `pre_install` hook" do
      STDERR.expects(:puts)
      def @spec.pre_install(pod, target_definition); end
    end

    it "warns about the deprecated `post_install` hook" do
      STDERR.expects(:puts)
      def @spec.post_install(target_installer); end
    end

    it "raises for the deprecated `clean_pahts` attribute" do
      lambda { @spec.clean_paths = 'value' }.should.raise StandardError
    end

    it "raises for the deprecated `part_of_dependency` attribute" do
      lambda { @spec.part_of_dependency = 'value' }.should.raise StandardError
    end

    it "raises for the deprecated `part_of` attribute" do
      lambda { @spec.part_of = 'value' }.should.raise StandardError
    end

    it "raises for the deprecated `exclude_header_search_paths` attribute" do
      lambda { @spec.exclude_header_search_paths = 'value' }.should.raise StandardError
    end

  end
end
