require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Source::Aggregate do
    # BananaLib is available only in test_repo.
    # JSONKit is in test repo has version 1.4 (duplicated) and the 999.999.999.
    #
    before do
      repos = [Source.new(fixture('spec-repos/test_repo')), Source.new(fixture('spec-repos/artsy'))]
      @aggregate = Source::Aggregate.new(repos)
    end

    #-------------------------------------------------------------------------#

    describe 'In general' do
      it 'returns the sources' do
        expect(@aggregate.sources.map(&:name).sort).to eq(%w(artsy test_repo))
      end

      it 'returns the name of all the available pods' do
        root_spec_names = @aggregate.all_pods
        expect(root_spec_names).to include('JSONKit')
        expect(root_spec_names).to include('BananaLib')
      end

      it 'returns all the available sets with the sources configured' do
        sets = @aggregate.all_sets
        banana_sets = sets.select { |set| set.name == 'BananaLib' }
        expect(banana_sets.count).to eq(1)
        expect(banana_sets.first.sources.map(&:name)).to eq(%w(test_repo))

        json_set = sets.select { |set| set.name == 'React' }
        expect(json_set.count).to eq(1)
        expect(json_set.first.sources.map(&:name)).to eq(%w(test_repo artsy))
      end

      it 'searches the sets by dependency' do
        dep = Dependency.new('React')
        set = @aggregate.search(dep)
        expect(set.name).to eq('React')
        expect(set.sources.map(&:name)).to eq(%w(test_repo artsy))
      end

      it 'searches the sets specifying a dependency on a subspec' do
        dep = Dependency.new('React/Core')
        set = @aggregate.search(dep)
        expect(set.name).to eq('React')
        expect(set.sources.map(&:name)).to eq(%w(test_repo artsy))
      end

      it "returns nil if a specification can't be found" do
        dep = Dependency.new('Does-not-exist')
        set = @aggregate.search(dep)
        expect(set).to be_nil
      end

      it 'returns a set configured to use only the source which contains the highest version' do
        set = @aggregate.representative_set('JSONKit')
        expect(set.versions.map(&:to_s)).to eq(['999.999.999', '1.13', '1.4'])
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Search' do
      it 'searches the sets by name' do
        sets = @aggregate.search_by_name('React')
        set = sets.find { |s| s.name == 'React' }
        expect(set.name).to eq('React')
        expect(set.sources.map(&:name)).to eq(%w(test_repo artsy))
      end

      it 'properly configures the sources of a set in search by name' do
        sets = @aggregate.search_by_name('BananaLib')
        expect(sets.count).to eq(1)
        set = sets.first
        expect(set.name).to eq('BananaLib')
        expect(set.sources.map(&:name)).to eq(%w(test_repo))
      end

      it 'performs a full text search' do
        @aggregate.stubs(:sources).returns([Source.new(fixture('spec-repos/test_repo'))])
        sets = @aggregate.search_by_name('Banana Corp', true)
        expect(sets.count).to eq(1)
        expect(sets.first.name).to eq('BananaLib')
      end

      it 'raises an informative if unable to find a Pod with the given name' do
        @aggregate.stubs(:sources).returns([Source.new(fixture('spec-repos/test_repo'))])
        expect do
          @aggregate.search_by_name('Some-funky-name', true)
        end.to raise_error(Informative, /Unable to find/)
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Search Index' do
      before do
        @test_source = Source.new(fixture('spec-repos/test_repo'))
      end

      it 'generates the search index for source' do
        index = @aggregate.generate_search_index_for_source(@test_source)
        text = 'BananaLib Chunky bananas! Full chunky bananas. Banana Corp Monkey Boy monkey@banana-corp.local'
        text.split.each do |word|
          expect(index[word]).to eq(%w(BananaLib))
        end
        expect(index['Faulty_spec']).to be_nil
      end

      it 'generates the search index for changes in source' do
        changed_paths = ['Specs/JSONKit/1.4/JSONKit.podspec']
        index = @aggregate.generate_search_index_for_changes_in_source(@test_source, changed_paths)
        expect(index['JSONKit']).to eq(%w(JSONKit))
        expect(index['BananaLib']).to be_nil
      end

      it 'generates correct vocabulary form given set' do
        set = Specification::Set.new('PodName', [])
        spec = Specification.new
        spec.stubs(:summary).returns("\n\n    Summary of\t\tpod name\n\n")
        spec.stubs(:description).returns("\n\n    \t\t       \n\n")
        spec.stubs(:authors).returns("\nauthor1\n" => nil, "\t\tauthor2" => '***woww---@mymail.com')
        set.stubs(:specification).returns(spec)

        vocabulary = %w(PodName Summary of pod name author1 author2 ***woww---@mymail.com)
        expect(@aggregate.send(:word_list_from_set, set)).to eq(vocabulary)
      end
    end

    #-------------------------------------------------------------------------#
  end
end
