require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe Version do
    describe 'In general' do
      it 'initializes from a string' do
        version = Version.new('1.2.3')
        expect(version.version).to eq('1.2.3')
      end

      it 'initializes from a frozen string' do
        version = Version.new('1.2.3'.freeze)
        expect(version.version).to eq('1.2.3')
      end

      it 'serializes to a string' do
        version = Version.new('1.2.3')
        expect(version.to_s).to eq('1.2.3')
      end

      it 'does not accept negative versions' do
        expect do
          Version.new('-1')
        end.to raise_error(ArgumentError)
      end

      it 'identifies release versions' do
        version = Version.new('1.0.0')
        expect(version).not_to be_prerelease
        version = Version.new('1.0.0+exp.sha1.77cb5a')
        expect(version).not_to be_prerelease
      end

      it 'matches Semantic Version pre-release versions' do
        version = Version.new('1.0.0a1')
        expect(version).to be_prerelease
        version = Version.new('1.0.0-alpha')
        expect(version).to be_prerelease
        version = Version.new('1.0.0-alpha.1')
        expect(version).to be_prerelease
        version = Version.new('1.0.0-0.3.7')
        expect(version).to be_prerelease
        version = Version.new('1.0.0-x.7.z.92')
        expect(version).to be_prerelease
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Semantic Versioning' do
      it 'reports a version as semantic' do
        expect(Version.new('1.9.0')).to be_semantic
        expect(Version.new('1.10.0')).to be_semantic
      end

      it 'leniently reports version with two segments version a semantic' do
        expect(Version.new('1.0')).to be_semantic
      end

      it 'leniently reports version with one segment version a semantic' do
        expect(Version.new('1')).to be_semantic
      end

      it 'reports a pre-release version as semantic' do
        expect(Version.new('1.0.0-alpha')).to be_semantic
        expect(Version.new('1.0.0-alpha.1')).to be_semantic
        expect(Version.new('1.0.0-0.3.7')).to be_semantic
        expect(Version.new('1.0.0-x.7.z.92')).to be_semantic
      end

      it 'reports a version with metadata as semantic' do
        # Examples from http://semver.org/#spec-item-10
        expect(Version.new('1.0.0+5')).to be_semantic
        expect(Version.new('1.0.0+5114f85')).to be_semantic
        expect(Version.new('1.0.0-alpha+exp.sha.5114f85')).to be_semantic
      end

      it 'reports version with more than 3 segments not separated by a dash as non semantic' do
        expect(Version.new('1.0.2.3')).not_to be_semantic
      end

      it 'reports version with a dash without the X.Y.Z format as non semantic' do
        expect(Version.new('1.0-alpha')).not_to be_semantic
      end

      it 'returns the major identifier' do
        expect(Version.new('1.9.0').major).to eq(1)
        expect(Version.new('1.0.0-alpha').major).to eq(1)
        expect(Version.new('1.alpha').major).to eq(1)
      end

      it 'returns the minor identifier' do
        expect(Version.new('1.9.0').minor).to eq(9)
        expect(Version.new('1.0.0-alpha').minor).to eq(0)
        expect(Version.new('1').minor).to eq(0)
        expect(Version.new('1.alpha').minor).to eq(0)
      end

      it 'returns the patch identifier' do
        expect(Version.new('1.9.0').patch).to eq(0)
        expect(Version.new('1.0.1-alpha').patch).to eq(1)
        expect(Version.new('1').patch).to eq(0)
        expect(Version.new('1.alpha').patch).to eq(0)
        expect(Version.new('1.alpha.2').patch).to eq(0)
      end

      it 'correctly makes basic version comparisons' do
        expect(Version.new('1.0.0')).to be < Version.new('2.0.0')
        expect(Version.new('1.0.0')).to be < Version.new('1.0.1')
        expect(Version.new('1.0.0')).to be < Version.new('1.1.0')
        expect(Version.new('1.1.0')).to be < Version.new('1.1.1')
      end

      it 'correctly ignores metadata in comparisons' do
        expect(Version.new('1.0.0+fff')).to eq(Version.new('1.0.0'))
        expect(Version.new('1.0.0+fff')).to eq(Version.new('1.0.0+000'))
        expect(Version.new('1.0.0-beta.1+fff')).to eq(Version.new('1.0.0-beta.1+000'))
        expect(Version.new('1.1.0+fff')).to be < Version.new('1.1.1+fff')
      end

      it 'ignores missing numeric identifiers while comparing' do
        expect(Version.new('1.9.0-alpha')).to be < Version.new('1.9-beta')
        expect(Version.new('2.0.0-beta')).to be < Version.new('2.0-rc')
        expect(Version.new('2.0.0.0.0.0.1-beta')).to be > Version.new('2.0-rc')
      end

      it 'tie-breaks between semantically equal versions' do
        expect(Version.new('1')).to be < Version.new('1.0')
        expect(Version.new('1.0')).to be < Version.new('1.0.0')
        expect(Version.new('1.0-alpha')).to be < Version.new('1.0.0-alpha')
        expect(Version.new('1.1.1.1-alpha')).to be < Version.new('1.1.1.1.0-alpha')
      end

      it 'Follows semver when comparing between pre-release versions' do
        # Example from section 11 on semver.org
        expect(Version.new('1.0.0-alpha')).to be < Version.new('1.0.0-alpha.1')
        expect(Version.new('1.0.0-alpha.1')).to be < Version.new('1.0.0-alpha.beta')
        expect(Version.new('1.0.0-alpha.beta')).to be < Version.new('1.0.0-beta')
        expect(Version.new('1.0.0-beta')).to be < Version.new('1.0.0-beta.2')
        expect(Version.new('1.0.0-beta.2')).to be < Version.new('1.0.0-beta.11')
        expect(Version.new('1.0.0-beta.11')).to be < Version.new('1.0.0-rc.1')
        expect(Version.new('1.0.0-rc.1')).to be < Version.new('1.0.0')

        expect(Version.new('1.0.0-beta+fff')).to eq(Version.new('1.0.0-beta+000'))

        # Example from CocoaPods/CocoaPods#5718
        expect(Version.new('1.0-beta.8')).to be < Version.new('1.0-beta.8a')

        # Example from section 11.4.3 on semver.org
        expect(Version.new('1.0.0-beta.3rd.1')).not_to be >= Version.new('1.0.0-beta.ios17.1')
      end
    end

    #-------------------------------------------------------------------------#
  end
end
