require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Specification::DSL::Deprecations do

    before do
      @spec =  Spec.new
    end

    it 'warns about the renamed `preferred_dependency`' do
      @spec.preferred_dependency = 'args'
      @spec.attributes_hash['default_subspecs'].should == %w(args)
      CoreUI.warnings.should.match /preferred_dependency.*default_subspec/
    end

    it 'raises if the header_mappings hook is defined' do
      should.raise Informative do
        def @spec.header_mappings
        end
      end.message.should.match /header_mappings.*deprecated/
    end

    it 'raises if the copy_header_mapping hook is defined' do
      should.raise Informative do
        def @spec.copy_header_mapping
        end
      end.message.should.match /copy_header_mapping.*deprecated/
    end

    it 'warns about the deprecated `documentation` attribute' do
      @spec.documentation = {}
      CoreUI.warnings.should.match /documentation.*deprecated/
    end

    it 'raises for the deprecated `clean_paths` attribute' do
      lambda { @spec.clean_paths = 'value' }.should.raise Informative
    end

    it 'raises for the deprecated `part_of_dependency` attribute' do
      lambda { @spec.part_of_dependency = 'value' }.should.raise Informative
    end

    it 'raises for the deprecated `part_of` attribute' do
      lambda { @spec.part_of = 'value' }.should.raise Informative
    end

    it 'raises for the deprecated `exclude_header_search_paths` attribute' do
      lambda { @spec.exclude_header_search_paths = 'value' }.should.raise Informative
    end

    #-----------------------------------------------------------------------------#

  end
end
