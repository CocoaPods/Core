require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Specification::Set do
    describe 'In general' do
      before do
        @source = TrunkSource.new(fixture('spec-repos/trunk'))
        @set = Spec::Set.new('ReactiveObjC', @source)
      end

      it 'returns the name of the pod' do
        expect(@set.name).to eq('ReactiveObjC')
      end

      it 'returns the versions available for the pod ordered from highest to lowest' do
        expect(@set.versions).to all(be_a(Version))
        expect(@set.versions.map(&:to_s)).to eq(%w(3.1.1 3.1.0 3.0.0 2.1.2 2.1.1 2.1.0 2.0.0 1.0.2 1.0.1))
      end

      it 'returns the highest version available for the pod' do
        expect(@set.highest_version).to eq(Version.new('3.1.1'))
      end

      it 'returns the path of the spec with the highest version' do
        expect(@set.highest_version_spec_path).to eq(@source.repo + 'Specs/d/b/4/ReactiveObjC/3.1.1/ReactiveObjC.podspec.json')
      end

      it 'can test if it is equal to another set' do
        expect(@set).to eq(Spec::Set.new('ReactiveObjC', @source))
        expect(@set).not_to eq(Spec::Set.new('RestKit', @source))
      end

      it 'returns a hash representation' do
        spec_path = @source.repo + 'Specs/d/b/4/ReactiveObjC/3.1.1/ReactiveObjC.podspec.json'
        expect(@set.to_hash).to eq({
          'name' => 'ReactiveObjC',
          'versions' => {
            'trunk' => %w(3.1.1 3.1.0 3.0.0 2.1.2 2.1.1 2.1.0 2.0.0 1.0.2 1.0.1),
          },
          'highest_version' => '3.1.1',
          'highest_version_spec' => spec_path.to_s,
        })
      end

      #--------------------------------------#

      it 'ignores dot files when getting the version directories' do
        @set.versions
        `touch #{fixture('spec-repos/trunk/2/2/2/DfPodTest/.DS_Store')}`
        expect do
          @set.versions
        end.not_to raise_error
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Concerning multiple sources' do
      before do
        # JSONKit is in test repo has version 1.4 (duplicated) and the 999.999.999.
        repos = [Source.new(fixture('spec-repos/test_repo')), TrunkSource.new(fixture('spec-repos/trunk'))]
        @set = Source::Aggregate.new(repos).search_by_name('JSONKit').find { |set| set.name == 'JSONKit' }
      end

      it 'returns the sources where a podspec is available' do
        expect(@set.sources.map(&:name)).to eq(%w(test_repo trunk))
      end

      it 'returns all the available versions sorted from biggest to lowest' do
        expect(@set.versions.map(&:to_s)).to eq(%w(999.999.999 1.13 1.5pre 1.4))
      end

      it 'returns all the available versions by source sorted from biggest to lowest' do
        hash = {}
        @set.versions_by_source.each { |source, versions| hash[source.name] = versions.map(&:to_s) }
        expect(hash['trunk']).to eq(%w(1.5pre 1.4))
        expect(hash['test_repo']).to eq(%w(999.999.999 1.13 1.4))
        expect(hash.keys.sort).to eq(%w(test_repo trunk))
      end
    end
  end

  #---------------------------------------------------------------------------#

  describe Specification::Set::External do
    before do
      @spec = Spec.from_file(fixture('BananaLib.podspec'))
      @set = Spec::Set::External.new(@spec)
    end

    it 'returns the specification' do
      expect(@set.specification).to eq(@spec)
    end

    it 'returns the name' do
      expect(@set.name).to eq('BananaLib')
    end

    it 'returns whether it is equal to another set' do
      expect(@set).to eq(Spec::Set::External.new(@spec))
    end

    it 'returns the version of the specification' do
      expect(@set.versions.map(&:to_s)).to eq(['1.0'])
    end
  end

  #---------------------------------------------------------------------------#

  describe 'Handling empty directories' do
    before do
      repos = [Source.new(fixture('spec-repos/test_empty_dir_repo'))]
      @set = Source::Aggregate.new(repos).search_by_name('EmptyDir_spec').first
    end

    it 'raises when encountering empty directories' do
      expect(@set.name).to eq('EmptyDir_spec')
      expect { @set.specification }.to raise_error(Informative, a_string_including('Could not find the highest version for `EmptyDir_spec`.'))
    end
  end
end
