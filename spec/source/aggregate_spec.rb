require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Source::Aggregate do
    # BananaLib is available only in test_repo.
    # JSONKit is in test repo has version 1.4 (duplicated) and the 999.999.999.
    #
    before do
      repos = [fixture('spec-repos/test_repo'), fixture('spec-repos/master')]
      @aggregate = Source::Aggregate.new(repos)
    end

    #-------------------------------------------------------------------------#

    describe 'In general' do
      it 'returns the sources' do
        @aggregate.sources.map(&:name).sort.should == %w(master test_repo)
      end

      it 'returns the name of all the available pods' do
        root_spec_names = @aggregate.all_pods
        root_spec_names.should.include('JSONKit')
        root_spec_names.should.include('BananaLib')
      end

      it 'returns all the available sets with the sources configured' do
        sets = @aggregate.all_sets
        banana_sets = sets.select { |set| set.name == 'BananaLib' }
        banana_sets.count.should == 1
        banana_sets.first.sources.map(&:name).should == %w(test_repo)

        json_set = sets.select { |set| set.name == 'JSONKit' }
        json_set.count.should == 1
        json_set.first.sources.map(&:name).should == %w(test_repo master)
      end

      it 'searches the sets by dependency' do
        dep = Dependency.new('JSONKit')
        set = @aggregate.search(dep)
        set.name.should == 'JSONKit'
        set.sources.map(&:name).should == %w(test_repo master)
      end

      it 'searches the sets specifying a dependency on a subspec' do
        dep = Dependency.new('RestKit/Network')
        set = @aggregate.search(dep)
        set.name.should == 'RestKit'
        set.sources.map(&:name).should == %w(master)
      end

      it "returns nil if a specification can't be found" do
        dep = Dependency.new('Does-not-exist')
        set = @aggregate.search(dep)
        set.should.nil?
      end

      it 'returns a set configured to use only the source which contains the highest version' do
        set = @aggregate.representative_set('JSONKit')
        set.versions.map(&:to_s).should == ['999.999.999', '1.13', '1.4']
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Search' do
      it 'searches the sets by name' do
        sets = @aggregate.search_by_name('JSONKit')
        sets.count.should == 1
        set = sets.first
        set.name.should == 'JSONKit'
        set.sources.map(&:name).should == %w(test_repo master)
      end

      it 'properly configures the sources of a set in search by name' do
        sets = @aggregate.search_by_name('BananaLib')
        sets.count.should == 1
        set = sets.first
        set.name.should == 'BananaLib'
        set.sources.map(&:name).should == %w(test_repo)
      end

      it 'performs a full text search' do
        @aggregate.stubs(:directories).returns([fixture('spec-repos/test_repo')])
        sets = @aggregate.search_by_name('Banana Corp', true)
        sets.count.should == 1
        sets.first.name.should == 'BananaLib'
      end

      it 'raises an informative if unable to find a Pod with the given name' do
        @aggregate.stubs(:directories).returns([fixture('spec-repos/test_repo')])
        should.raise Informative do
          @aggregate.search_by_name('Some-funky-name', true)
        end.message.should.match /Unable to find/
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Search Index' do
      before do
        @test_source = Source.new(fixture('spec-repos/test_repo'))
      end

      it 'generates the search index for source' do
        index = @aggregate.generate_search_index_for_source(@test_source)
        text = 'BananaLib Chunky bananas! Full of chunky bananas. Banana Corp Monkey Boy monkey@banana-corp.local'
        text.split.each do |word|
          index[word].should == ['BananaLib']
        end
        index['Faulty_spec'].should.be.nil
      end

      it 'generates the search index for changes in source' do
        changed_paths = ['Specs/JSONKit/1.4/JSONKit.podspec']
        index = @aggregate.generate_search_index_for_changes_in_source(@test_source, changed_paths)
        index['JSONKit'].should == ['JSONKit']
        index['BananaLib'].should.be.nil
      end
    end

    #-------------------------------------------------------------------------#
  end
end
