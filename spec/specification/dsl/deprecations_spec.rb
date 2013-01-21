require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Specification::DSL::Deprecations do

    before do
      @spec =  Spec.new
    end

    it "warns about the renamed `preferred_dependency`" do
      STDERR.expects(:puts)
      @spec.preferred_dependency='args'
      @spec.attributes_hash['default_subspec'].should == 'args'
    end

    it "warns about the deprecated `pre_install` hook" do
      STDERR.expects(:puts)
      def @spec.pre_install(pod, target_definition); end
    end

    it "presevers the functionality of the `pre_install` hook" do
      STDERR.expects(:puts)
      STDOUT.expects(:puts).with('Cheers! A B')
      def @spec.pre_install(pod, target_definition)
        CoreUI.puts "Cheers! #{pod} #{target_definition}"
      end
      @spec.pre_install!('A', 'B').should == TRUE
    end

    it "warns about the deprecated `post_install` hook" do
      STDERR.expects(:puts)
      def @spec.post_install(target_installer); end
    end

    it "presevers the functionality of the `post_install` hook" do
      STDERR.expects(:puts)
      STDOUT.expects(:puts).with('Cheers! A')
      def @spec.post_install(target_installer)
        CoreUI.puts "Cheers! #{target_installer}"
      end
      @spec.post_install!('A').should == TRUE
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
