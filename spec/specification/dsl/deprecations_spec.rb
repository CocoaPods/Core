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
  end
end
