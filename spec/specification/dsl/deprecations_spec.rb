require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Specification::DSL::Deprecations do

    before do
      @spec =  Spec.new
    end

    it "warns about the renamed `preferred_dependency`" do
      @spec.preferred_dependency='args'
      @spec.attributes_hash['default_subspec'].should == 'args'
      CoreUI.warnings.should.match /preferred_dependency.*default_subspec/
    end

    it "warns about the deprecated `pre_install` hook" do
      def @spec.pre_install(pod, target_definition); end
      CoreUI.warnings.should.match /pre_install.*deprecated/
    end

    it "preservers the functionality of the `pre_install` hook" do
      def @spec.pre_install(pod, target_definition)
        CoreUI.puts "Cheers! #{pod} #{target_definition}"
      end
      @spec.pre_install!('A', 'B').should == TRUE
      CoreUI.output.should.match /Cheers! A B/
    end

    it "warns about the deprecated `post_install` hook" do
      def @spec.post_install(target_installer); end
      CoreUI.warnings.should.match /post_install.*deprecated/
    end

    it "preservers the functionality of the `post_install` hook" do
      def @spec.post_install(target_installer)
        CoreUI.puts "Cheers! #{target_installer}"
      end
      @spec.post_install!('A').should == TRUE
      CoreUI.output.should.match /Cheers! A/
    end

    it "raises if the header_mappings hook is defined" do
      should.raise Informative do
        def @spec.header_mappings
        end
      end.message.should.match /header_mappings.*deprecated/
    end

    it "raises if the copy_header_mapping hook is defined" do
      should.raise Informative do
        def @spec.copy_header_mapping
        end
      end.message.should.match /copy_header_mapping.*deprecated/
    end

    it "warns about the deprecated `documentation` attribute" do
      @spec.documentation = {}
      CoreUI.warnings.should.match /documentation.*deprecated/
    end

    it "raises for the deprecated `clean_paths` attribute" do
      lambda { @spec.clean_paths = 'value' }.should.raise Informative
    end

    it "raises for the deprecated `part_of_dependency` attribute" do
      lambda { @spec.part_of_dependency = 'value' }.should.raise Informative
    end

    it "raises for the deprecated `part_of` attribute" do
      lambda { @spec.part_of = 'value' }.should.raise Informative
    end

    it "raises for the deprecated `exclude_header_search_paths` attribute" do
      lambda { @spec.exclude_header_search_paths = 'value' }.should.raise Informative
    end

    #-----------------------------------------------------------------------------#

    describe "Hooks" do
      before do
        @spec = Spec.new
      end

      it "stores a block to run before the installation" do
        value = ''
        @spec.post_install do value << 'modified' end
        @spec.post_install!(nil)
        value.should == 'modified'
      end

      it "stores a block to run after the installation" do
        value = ''
        @spec.post_install do value << 'modified' end
        @spec.post_install!(nil)
        value.should == 'modified'
      end

      it "warns about the deprecated `pre_install` hook" do
        @spec.pre_install {}
        CoreUI.warnings.should.match /pre install hook.*deprecated/
      end

      it "warns about the deprecated `pre_install` hook" do
        @spec.post_install {}
        CoreUI.warnings.should.match /post install hook.*deprecated/
      end
    end

    #-----------------------------------------------------------------------------#

  end
end
