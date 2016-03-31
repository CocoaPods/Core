require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Source::Metadata do
    before do
      @metadata_hash = {
        'min' => '0.33.1',
        'max' => '1.9.9',
        'last' => CORE_VERSION,
        'prefix_lengths' => [1, 1, 1],
        'last_compatible_versions' => ['0.22.0', '0.11.0', '0.20.5'],
      }
      @metadata = Source::Metadata.new(@metadata_hash)
    end

    describe '#initialize' do
      it 'sets the minimum_cocoapods_version' do
        @metadata.minimum_cocoapods_version.should == Version.new('0.33.1')
      end

      it 'sets the maximum_cocoapods_version' do
        @metadata.maximum_cocoapods_version.should == Version.new('1.9.9')
      end

      it 'sets the prefix_lengths' do
        @metadata.prefix_lengths.should == [1, 1, 1]
      end

      it 'sets the latest_cocoapods_version' do
        @metadata.latest_cocoapods_version.should == Version.new(CORE_VERSION)
      end

      it 'sets the last_compatible_versions' do
        @metadata.last_compatible_versions.should == [
          Pod::Version.new('0.11.0'),
          Pod::Version.new('0.20.5'),
          Pod::Version.new('0.22.0'),
        ]
      end
    end

    describe '#compatible?' do
      it 'returns whether a repository is compatible' do
        @metadata = Source::Metadata.new('min' => '0.0.1')
        @metadata.compatible?('1.0.0').should.be.true

        @metadata = Source::Metadata.new('max' => '999.0')
        @metadata.compatible?('1.0.0').should.be.true

        @metadata = Source::Metadata.new('min' => '999.0')
        @metadata.compatible?('1.0.0').should.be.false

        @metadata = Source::Metadata.new('max' => '0.0.1')
        @metadata.compatible?('1.0.0').should.be.false
      end
    end
  end
end
