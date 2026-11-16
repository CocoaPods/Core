require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe TrunkSource do
    before do
      @path = fixture('spec-repos/trunk')
      @source = TrunkSource.new(@path)
    end

    #-------------------------------------------------------------------------#

    it 'uses the correct repo name' do
      expect(@source.name).to eq('trunk')
    end

    it 'uses the correct repo URL' do
      expect(@source.url).to eq('https://cdn.cocoapods.org/')
    end

    #-------------------------------------------------------------------------#
  end
end
