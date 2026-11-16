require 'algoliasearch'
require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Source::Manager do
    extend SpecHelper::TemporaryDirectory

    before do
      @test_source = Source.new(fixture('spec-repos/test_repo'))
      @test_source_cdn_path = fixture('spec-repos/test_cdn_repo_local')
      File.open(@test_source_cdn_path.join('.url'), 'w') { |f| f.write('http://localhost:4321/') }
      @test_source_cdn = CDNSource.new(@test_source_cdn_path)

      @sources_manager = Source::Manager.new(fixture('spec-repos'))
      @sources_manager.search_index_path = SpecHelper.temporary_directory + 'search_index.json'
    end

    after do
      Pathname.glob(@test_source_cdn_path.join('*')).each(&:rmtree)
      @test_source_cdn_path.join('.url').rmtree
    end

    #-------------------------------------------------------------------------#

    describe 'In general' do
      it 'does not fail if the repos directory does not exist' do
        @sources_manager.stubs(:repos_dir).returns(Pathname.new('/foo/bar'))
        expect(@sources_manager.aggregate.sources).to eq([])
        expect(@sources_manager.all).to eq([])
      end

      it 'returns all the sources' do
        expect(@sources_manager.all.map(&:name)).to eq(%w(artsy test_cdn_repo_local test_empty_dir_repo test_prefixed_repo test_repo test_repo_without_specs_dir trunk))
      end

      it 'includes all sources in an aggregate for a dependency if no source is specified' do
        dependency = Dependency.new('JSONKit', '1.4')
        aggregate = @sources_manager.aggregate_for_dependency(dependency)
        expect(aggregate.sources.map(&:name)).to eq(%w(artsy test_cdn_repo_local test_empty_dir_repo test_prefixed_repo test_repo test_repo_without_specs_dir trunk))
      end

      it 'includes all sources in an aggregate for a dependency if non-existent source is specified' do
        dependency = Dependency.new('JSONKit', '1.4', :source => 'https://url/to/nonexistent/specs.git')
        aggregate = @sources_manager.aggregate_for_dependency(dependency)
        expect(aggregate.sources.map(&:name)).to eq(%w(artsy test_cdn_repo_local test_empty_dir_repo test_prefixed_repo test_repo test_repo_without_specs_dir trunk))
      end

      it 'includes only the one source in an aggregate for a dependency if a source is specified by URL' do
        repo_url = 'https://url/to/specs.git'
        dependency = Dependency.new('JSONKit', '1.4', :source => repo_url)

        source = mock
        source.stubs(:name).returns('repo')
        source.stubs(:repo).returns('path')

        @sources_manager.expects(:source_with_url).with(repo_url).returns(source)
        @sources_manager.expects(:source_from_path).with('path').returns(source)

        aggregate = @sources_manager.aggregate_for_dependency(dependency)
        expect(aggregate.sources.map(&:name)).to eq([source.name])
      end

      it 'includes only the one source in an aggregate for a dependency if a source is specified by name' do
        dependency = Dependency.new('JSONKit', '1.4', :source => 'repo_name')

        source = mock
        source.stubs(:name).returns('repo_name')
        source.stubs(:repo).returns('path')

        @sources_manager.expects(:source_with_url).with('repo_name').returns(nil)
        @sources_manager.expects(:source_with_name).with('repo_name').returns(source)
        @sources_manager.expects(:source_from_path).with('path').returns(source)

        aggregate = @sources_manager.aggregate_for_dependency(dependency)
        expect(aggregate.sources.map(&:name)).to eq([source.name])
      end

      it 'searches for the set of a dependency' do
        set = @sources_manager.search(Dependency.new('BananaLib'))
        expect(set.class).to eq(Specification::Set)
        expect(set.name).to eq('BananaLib')
      end

      it 'returns nil if it is not able to find a pod for the given dependency' do
        set = @sources_manager.search(Dependency.new('Windows-Lib'))
        expect(set).to be_nil
      end

      it 'searches sets by name' do
        sets = @sources_manager.search_by_name('BananaLib')
        expect(sets.all? { |s| s.class == Specification::Set }).to be(true)
        expect(sets.any? { |s| s.name == 'BananaLib' }).to be(true)
      end

      it 'can perform a full text search of the sets' do
        @sources_manager.stubs(:all).returns([@test_source])
        @sources_manager.stubs(:all_non_indexable).returns([])
        sets = @sources_manager.search_by_name('Chunky', true)
        expect(sets.all? { |s| s.class == Specification::Set }).to be(true)
        expect(sets.any? { |s| s.name == 'BananaLib' }).to be(true)
      end

      it 'can perform a full text regexp search of the sets' do
        @sources_manager.stubs(:all).returns([@test_source])
        @sources_manager.stubs(:all_non_indexable).returns([])
        sets = @sources_manager.search_by_name('Ch[aeiou]nky', true)
        expect(sets.all? { |s| s.class == Specification::Set }).to be(true)
        expect(sets.any? { |s| s.name == 'BananaLib' }).to be(true)
      end

      it 'can perform a full text search of the sets on a CDN' do
        @sources_manager.stubs(:all).returns([@test_source_cdn])
        @sources_manager.stubs(:all_non_indexable).returns([@test_source_cdn])
        Algolia::Index.any_instance.stubs(:search).with('beacon', :attributesToRetrieve => 'name').returns('hits' => [{ 'name' => 'BeaconKit' }])
        sets = @sources_manager.search_by_name('beacon', true)
        expect(sets.all? { |s| s.class == Specification::Set }).to be(true)
        expect(sets.any? { |s| s.name == 'BeaconKit' }).to be(true)
      end

      describe 'Sorting algorithm' do
        before do
          @test_search_results = %w(HockeyKit DLSuit VCLReachability NPReachability AVReachability PYNetwork
                                    SCNetworkReachability AFNetworking Networking).map do |name|
            Specification::Set.new(name)
          end
        end

        it 'puts pod with exact match at the first index while sorting' do
          regexps = [/networking/i]
          sets = @sources_manager.sorted_sets(@test_search_results, regexps)
          expect(sets[0].name).to eq('Networking')
        end

        it 'puts pod with less prefix length before pods with more prefix length in search results' do
          regexps = [/reachability/i]
          sets = @sources_manager.sorted_sets(@test_search_results, regexps)
          expect(sets.index { |s| s.name == 'AVReachability' }).to be < sets.index { |s| s.name == 'VCLReachability' }
        end

        it 'puts pod with more query word match before pods with less match in multi word query search results' do
          regexps = [/network/i, /reachability/i]
          sets = @sources_manager.sorted_sets(@test_search_results, regexps)
          expect(sets.index { |s| s.name == 'SCNetworkReachability' }).to be < sets.index { |s| s.name == 'AVReachability' }
        end

        it 'puts pod matching first query word before pods matching later words in multi word query search results' do
          regexps = [/network/i, /reachability/i]
          sets = @sources_manager.sorted_sets(@test_search_results, regexps)
          expect(sets.index { |s| s.name == 'PYNetwork' }).to be < sets.index { |s| s.name == 'AVReachability' }
        end

        it 'puts pod matching first query word before pods matching later words in multi word query search results' do
          regexps = [/network/i, /reachability/i]
          sets = @sources_manager.sorted_sets(@test_search_results, regexps)
          expect(sets.index { |s| s.name == 'PYNetwork' }).to be < sets.index { |s| s.name == 'AVReachability' }
        end

        it 'alphabetically sorts pods having exact other conditions' do
          regexps = [/reachability/i]
          sets = @sources_manager.sorted_sets(@test_search_results, regexps)
          expect(sets.index { |s| s.name == 'AVReachability' }).to be < sets.index { |s| s.name == 'NPReachability' }
        end

        it 'alphabetically sorts pods whose names does not match query' do
          regexps = [/reachability/i]
          sets = @sources_manager.sorted_sets(@test_search_results, regexps)
          expect(sets.index { |s| s.name == 'DLSuit' }).to be < sets.index { |s| s.name == 'HockeyKit' }
        end
      end

      it 'deletes the search index file if it is invalid' do
        @sources_manager.save_search_index(nil)
        expect(@sources_manager.stored_search_index).to be_nil
        expect(@sources_manager.search_index_path.exist?).to be(false)
      end

      it "generates the search index before performing a search if it doesn't exist" do
        @sources_manager.stubs(:all).returns([@test_source])
        @sources_manager.stubs(:all_non_indexable).returns([])
        Source::Aggregate.any_instance.expects(:generate_search_index_for_source).with(@test_source).returns('BananaLib' => ['BananaLib'])
        @sources_manager.updated_search_index = nil
        @sources_manager.search_by_name('BananaLib', true)
      end

      describe 'managing sources by URL' do
        describe 'generating a repo name from a URL' do
          it 'uses `trunk` for the CDN CocoaPods repository' do
            url = 'https://cdn.cocoapods.org/'
            Pathname.any_instance.stubs(:exist?).
              returns(false).then.returns(true)
            expect(@sources_manager.send(:name_for_url, url)).to eq('trunk')
          end

          it 'uses `trunk` for the CDN CocoaPods repository without a slash' do
            url = 'https://cdn.cocoapods.org'
            Pathname.any_instance.stubs(:exist?).
              returns(false).then.returns(true)
            expect(@sources_manager.send(:name_for_url, url)).to eq('trunk')
          end

          it 'uses the organization and repo name for github.com URLs' do
            url = 'https://github.com/segiddins/banana.git'
            expect(@sources_manager.send(:name_for_url, url)).to eq('segiddins-banana')
          end

          it 'uses the organization name only for github.com specs URLs' do
            url = 'https://github.com/segiddins/Specs.git'
            expect(@sources_manager.send(:name_for_url, url)).to eq('segiddins')
          end

          it 'uses a combination of host and path for other URLs' do
            url = 'https://sourceforge.org/Artsy/Specs.git'
            expect(@sources_manager.send(:name_for_url, url)).to eq('sourceforge-artsy')
            url = 'https://sourceforge.org.au/Artsy/Specs.git'
            expect(@sources_manager.send(:name_for_url, url)).to eq('sourceforge-artsy')
            url = 'https://pvt.sourceforge.org.au/Artsy/Specs.git'
            expect(@sources_manager.send(:name_for_url, url)).to eq('sourceforge-artsy')
          end

          it 'does not remove /specs path component if it is not the last one' do
            url = 'https://sourceforge.org.au/Specs/Path/Repo.git'
            expect(@sources_manager.send(:name_for_url, url)).to eq('sourceforge-specs-path-repo')
          end

          it 'can understand arbitrary URI schemes' do
            url = 'banana://website.org/Artsy/Specs.git'
            expect(@sources_manager.send(:name_for_url, url)).to eq('website-artsy')
          end

          it 'should raise on completely ridiculous non-URL input' do
            url = '    '
            expect do
              @sources_manager.send(:name_for_url, url)
            end.to raise_error(Informative, "Couldn't determine repo name for URL: #{url}")
          end

          it 'supports scp-style URLs' do
            url = 'git@git-host.com:specs.git'
            expect(@sources_manager.send(:name_for_url, url)).to eq('git-host')

            url = 'org-123456789@github.com:mycompany/ios-companypods.git'
            expect(@sources_manager.send(:name_for_url, url)).to eq('mycompany-ios-companypods')

            url = 'git@git-host.com/specs.git'
            expect(@sources_manager.send(:name_for_url, url)).to eq('git-host')

            url = 'git@git-host.com:/specs.git'
            expect(@sources_manager.send(:name_for_url, url)).to eq('git-host')
            url = 'git@github.com/segiddins/Specs'
            expect(@sources_manager.send(:name_for_url, url)).to eq('segiddins')
          end

          it 'supports ssh URLs with an aliased hostname' do
            url = 'ssh://user@companyalias/pod-specs'
            expect(@sources_manager.send(:name_for_url, url)).to eq('companyalias-pod-specs')
          end

          it 'supports file URLs' do
            url = 'file:///Users/kurrytran/etc'
            expect(@sources_manager.send(:name_for_url, url)).to eq('users-kurrytran-etc')
            url = 'file:///Users/kurrytran/specs'
            expect(@sources_manager.send(:name_for_url, url)).to eq('users-kurrytran')
          end

          it 'uses the repo name if no parent directory' do
            url = 'file:///pod-specs'
            expect(@sources_manager.send(:name_for_url, url)).to eq('pod-specs')
          end

          it 'supports ssh URLs with no user component' do
            url = 'ssh://company.com/pods/specs.git'
            expect(@sources_manager.send(:name_for_url, url)).to eq('company-pods')
          end

          it 'supports ssh URLs with user and port' do
            url = 'ssh://git@company.com:1234/pods/specs.git'
            expect(@sources_manager.send(:name_for_url, url)).to eq('company-pods')
          end

          it 'supports ssh URls without .git' do
            url = 'git@ssh.dev.azure.com:v3/aa-aaaaa/aaa_aaa_aaaaa/aaa-aaa-aaaaa'
            expect(@sources_manager.send(:name_for_url, url)).to eq('azure-v3-aa-aaaaa-aaa_aaa_aaaaa-aaa-aaa-aaaaa')
          end

          it 'appends a number to the name if the base name dir exists' do
            url = 'https://github.com/segiddins/banana.git'
            Pathname.any_instance.stubs(:exist?).
              returns(true).then.returns(false)
            expect(@sources_manager.send(:name_for_url, url)).to eq('segiddins-banana-1')

            url = 'https://sourceforge.org/Artsy/Specs.git'
            Pathname.any_instance.stubs(:exist?).
              returns(true).then.returns(false)
            expect(@sources_manager.send(:name_for_url, url)).to eq('sourceforge-artsy-1')

            url = 'https://sourceforge.org/Artsy/Specs.git'
            Pathname.any_instance.stubs(:exist?).
              returns(true).then.
              returns(true).then.returns(false)
            expect(@sources_manager.send(:name_for_url, url)).to eq('sourceforge-artsy-2')
          end
        end

        describe '#source_with_url' do
          it 'should find CDN with trailing slash' do
            expect(@sources_manager.send(:source_with_url, 'https://cdn.cocoapods.org/').name).to eq('trunk')
          end

          it 'should find CDN without trailing slash' do
            expect(@sources_manager.send(:source_with_url, 'https://cdn.cocoapods.org').name).to eq('trunk')
          end
        end
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Updating Sources' do
      before do
        Source.any_instance.stubs(:unchanged_github_repo?).returns(false)
      end

      it 'updates search index for changed paths if source is updated' do
        prev_index = { @test_source.name => { 'Banana' => %w(SOME_POD), 'NON_EXISTING_WORD' => %w(SOME_POD JSONKit BananaLib) } }
        @sources_manager.expects(:stored_search_index).returns(prev_index)

        @sources_manager.expects(:save_search_index).with do |value|
          expect(value[@test_source.name]['BananaLib']).to include('BananaLib')
          expect(value[@test_source.name]['JSONKit']).to include('JSONKit')
          expect(value[@test_source.name]['Banana']).to include('SOME_POD')
          expect(value[@test_source.name]['Banana']).to include('BananaLib')
          expect(value[@test_source.name]['NON_EXISTING_WORD']).not_to include('JSONKit')
          expect(value[@test_source.name]['NON_EXISTING_WORD']).not_to include('BananaLib')
          expect(value[@test_source.name]['NON_EXISTING_WORD']).to include('SOME_POD')
        end
        changed_paths = { @test_source => %w(Specs/BananaLib/1.0/BananaLib.podspec Specs/JSONKit/1.4/JSONKit.podspec) }
        @sources_manager.update_search_index_if_needed(changed_paths)
      end

      it 'does not update search index if it does not contain source even if there are changes in source' do
        prev_index = {}
        @sources_manager.expects(:stored_search_index).returns(prev_index)

        @sources_manager.expects(:save_search_index).with do |value|
          expect(value[@test_source.name]).to be_nil
        end
        changed_paths = { @test_source => %w(Specs/BananaLib/1.0/BananaLib.podspec Specs/JSONKit/1.4/JSONKit.podspec) }
        @sources_manager.update_search_index_if_needed(changed_paths)
      end

      it 'process fork is called when updating search index in background' do
        Process.expects(:fork)

        changed_paths = { @test_source => %w(Specs/BananaLib/1.0/BananaLib.podspec Specs/JSONKit/1.4/JSONKit.podspec) }
        @sources_manager.update_search_index_if_needed_in_background(changed_paths)
      end

      it 'process fork is not called when updating search index in background on Windows' do
        Gem.stubs(:win_platform?).returns(true)
        Process.stubs(:fork).at_most(0)

        changed_paths = { @test_source => %w(Specs/BananaLib/1.0/BananaLib.podspec Specs/JSONKit/1.4/JSONKit.podspec) }
        @sources_manager.update_search_index_if_needed_in_background(changed_paths)
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Master repo' do
      it 'returns the master repo dir' do
        expect(@sources_manager.master_repo_dir.to_s).to match(%r{fixtures/spec-repos/trunk})
      end

      it 'returns an empty array for master sources when the master repo has not been set up' do
        Pathname.any_instance.stubs(:directory?).returns(false)
        expect(@sources_manager.master).to eq([])
      end

      it 'returns whether the master repo is functional' do
        expect(@sources_manager.master_repo_functional?).to be(true)
        @sources_manager.stubs(:repos_dir).returns(SpecHelper.temporary_directory)
        expect(@sources_manager.master_repo_functional?).to be(false)
      end
    end
  end
end
