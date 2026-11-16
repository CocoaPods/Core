require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe Source do
    before do
      @path = fixture('spec-repos/test_repo')
      @source = Source.new(@path)
    end

    #-------------------------------------------------------------------------#

    describe 'In general' do
      it 'return its name' do
        expect(@source.name).to eq('test_repo')
      end

      it 'return its type when git' do
        expect(@source.type).to eq('git')
      end

      it 'return its type when git' do
        @path = fixture('spec-repos/test_empty_dir_repo')
        @source = Source.new(@path)
        expect(@source.type).to eq('file system')
      end

      it 'can be ordered according to its name' do
        s1 = Source.new(Pathname.new 'customized')
        s2 = Source.new(Pathname.new 'master')
        s3 = Source.new(Pathname.new 'private')
        expect([s3, s1, s2].sort).to eq([s1, s2, s3])
      end
    end

    #-------------------------------------------------------------------------#

    describe '#pods' do
      it 'returns the available Pods' do
        expect(@source.pods).to eq(%w(BananaLib Faulty_spec IncorrectPath JSONKit JSONSpec React))
      end

      it "raises if the repo doesn't exists" do
        @path = fixture('spec-repos/non_existing')
        @source = Source.new(@path)
        expect do
          @source.pods
        end.to raise_error(Informative, /Unable to find a source named: `non_existing`/)
      end

      it 'returns corresponding pods for given specification paths' do
        paths = %w(Specs/BananaLib/1.0/BananaLib.podspec)
        expect(@source.pods_for_specification_paths(paths)).to eq(%w(BananaLib))
        paths = %w(Specs/monkey/1.0.2/monkey.podspec Specs/JSONKit/1.4/JSONKit.podspec)
        expect(@source.pods_for_specification_paths(paths)).to eq(%w(monkey JSONKit))
      end
    end

    #-------------------------------------------------------------------------#

    describe '#versions' do
      it 'returns the available versions of a Pod' do
        expect(@source.versions('JSONKit').map(&:to_s)).to eq(['999.999.999', '1.13', '1.4'])
      end

      it 'returns nil if the Pod could not be found' do
        expect(@source.versions('Unknown_Pod')).to be_nil
      end

      it 'returns cached versions for a Pod' do
        pod_path = @source.pod_path('JSONKit')
        pod_path_children = pod_path.children
        pod_path_children.each { |v| v.expects(:directory?).returns(true).once }
        pod_path.expects(:children).returns(pod_path_children)
        @source.expects(:pod_path).with('JSONKit').twice.returns(pod_path)
        expect(@source.versions('JSONKit').map(&:to_s)).to eq(['999.999.999', '1.13', '1.4'])
        expect(@source.versions('JSONKit').map(&:to_s)).to eq(['999.999.999', '1.13', '1.4'])
        expect(@source.instance_variable_get(:@versions_by_name)).to eq({ 'JSONKit' => [Version.new('999.999.999'), Version.new('1.13'), Version.new('1.4')] })
      end
    end

    #-------------------------------------------------------------------------#

    describe '#specification' do
      it 'returns the specification for the given name and version' do
        spec = @source.specification('JSONKit', Version.new('1.4'))
        expect(spec.name).to eq('JSONKit')
        expect(spec.version.to_s).to eq('1.4')
      end
    end

    #-------------------------------------------------------------------------#

    describe '#all_specs' do
      it 'returns all the specifications' do
        expected = %w(BananaLib IncorrectPath JSONKit JSONSpec React)
        expect(@source.all_specs.map(&:name).sort.uniq).to eq(expected)
      end
    end

    #-------------------------------------------------------------------------#

    describe '#set' do
      it 'returns the set of a given Pod' do
        set = @source.set('BananaLib')
        expect(set.name).to eq('BananaLib')
        expect(set.sources).to eq([@source])
      end
    end

    #-------------------------------------------------------------------------#

    describe '#pod_sets' do
      it 'returns all the pod sets' do
        expected = %w(BananaLib Faulty_spec IncorrectPath JSONKit JSONSpec React)
        expect(@source.pod_sets.map(&:name).sort.uniq).to eq(expected)
      end
    end

    #-------------------------------------------------------------------------#

    describe '#search' do
      it 'searches for the Pod with the given name' do
        expect(@source.search('BananaLib').name).to eq('BananaLib')
      end

      it 'searches for the pod with the given dependency' do
        dep = Dependency.new('BananaLib')
        expect(@source.search(dep).name).to eq('BananaLib')
      end

      it 'supports dependencies on subspecs' do
        dep = Dependency.new('BananaLib/subspec')
        expect(@source.search(dep).name).to eq('BananaLib')
      end

      it 'matches case' do
        expect(@source.search('bAnAnAlIb')).to be_nil
      end

      describe 'when there is an empty directory' do
        before { @empty_dir = @path.join('Specs', 'Empty').tap(&:mkpath) }
        after { FileUtils.rm_r @empty_dir }

        it 'returns nil' do
          expect(@source.search('Empty')).to be_nil
        end
      end

      describe '#search_by_name' do
        it 'properly configures the sources of a set in search by name' do
          source = Source.new(fixture('spec-repos/test_repo'))
          sets = source.search_by_name('monkey', true)
          expect(sets.count).to eq(1)
          set = sets.first
          expect(set.name).to eq('BananaLib')
          expect(set.sources.map(&:name)).to eq(%w(test_repo))
        end

        it 'can use regular expressions' do
          source = Source.new(fixture('spec-repos/test_repo'))
          sets = source.search_by_name('mon[ijk]ey', true)
          expect(sets.first.name).to eq('BananaLib')
        end
      end
    end

    #-------------------------------------------------------------------------#

    describe '#search_by_name' do
      it 'supports full text search' do
        sets = @source.search_by_name('monkey', true)
        expect(sets.map(&:name)).to eq(['BananaLib'])
        expect(sets.map(&:sources)).to eq([[@source]])
      end

      it 'The search is case insensitive' do
        pods = @source.search_by_name('MONKEY', true)
        expect(pods.map(&:name)).to eq(['BananaLib'])
      end

      it 'supports partial matches' do
        pods = @source.search_by_name('MON', true)
        expect(pods.map(&:name)).to eq(['BananaLib'])
      end

      it "handles gracefully specification which can't be loaded" do
        expect do
          @source.specification('Faulty_spec', '1.0.0')
        end.to raise_error(Informative, a_string_including('Invalid podspec'))

        expect do
          @source.search_by_name('monkey', true)
        end.not_to raise_error
      end
    end

    #-------------------------------------------------------------------------#

    describe '#fuzzy_search' do
      it 'is case insensitive' do
        expect(@source.fuzzy_search('bananalib').name).to eq('BananaLib')
      end

      it 'matches misspells' do
        expect(@source.fuzzy_search('banalib').name).to eq('BananaLib')
      end

      it 'matches suffixes' do
        expect(@source.fuzzy_search('Lib').name).to eq('BananaLib')
      end

      it 'returns nil if there is no match' do
        expect(@source.fuzzy_search('12345')).to be_nil
      end

      it 'matches abbreviations' do
        expect(@source.fuzzy_search('BLib').name).to eq('BananaLib')
      end
    end

    #-------------------------------------------------------------------------#

    describe '#update' do
      describe 'for a GitHub source' do
        before do
          # The master source repo uses GitHub, so we recycle that here. Note
          # that we initialize it as just a `Source`, though.
          @path = fixture('spec-repos/artsy')
          @source = Source.new(@path)
        end

        it 'does not git fetch if the GitHub API returns not-modified' do
          VCR.use_cassette('Source_nofetch', :record => :new_episodes) do
            @source.expects(:update_git_repo).never
            @source.send :update, true
          end
        end

        it 'fetches if the GitHub API returns modified' do
          VCR.use_cassette('Source_fetch', :record => :new_episodes) do
            @source.expects(:update_git_repo)
            @source.send :update, true
          end
        end

        it 'clears the versions by name cache when updated' do
          VCR.use_cassette('Source_fetch', :record => :new_episodes) do
            @source.expects(:update_git_repo).with(true)
            @source.versions('React')
            expect(@source.instance_variable_get(:@versions_by_name).count).to eq(1)
            @source.send :update, true
            expect(@source.instance_variable_get(:@versions_by_name)).to be_empty
          end
        end
      end

      describe 'for a non-GitHub source' do
        it 'always calls update_git_repo' do
          @source.expects(:url).returns('https://myhost.com/myorg/myrepo.git')
          @source.expects(:update_git_repo)
          @source.send :update, true
        end
      end

      it 'uses the only fast forward git option' do
        @source.expects(:`).with("env -u GIT_CONFIG git -C \"#{@path}\" checkout master")
        @source.expects(:`).with("env -u GIT_CONFIG git -C \"#{@path}\" pull --ff-only 2>&1")
        @source.send :update_git_repo
      end

      it 'checks out the appropriate branch' do
        path = @source.repo.join('.git', 'cocoapods_branch')
        path.dirname.mkpath
        path.open('w') { |f| f << 'random_branch' }
        @source.expects(:`).with("env -u GIT_CONFIG git -C \"#{@path}\" checkout random_branch")
        @source.expects(:`).with("env -u GIT_CONFIG git -C \"#{@path}\" pull --ff-only 2>&1")
        begin
          @source.send(:update_git_repo)
        ensure
          path.delete if path.file?
        end
      end

      it 'uses git diff with name only option' do
        @source.expects(:`).with { |cmd| expect(cmd).to include('--name-only') }.returns('')
        @source.send :diff_until_commit_hash, 'DUMMY_HASH'
      end

      it 'finds diff of commits before/after repo update' do
        @source.expects(:`).with { |cmd| expect(cmd).to include('DUMMY_HASH..HEAD') }.returns('')
        @source.send :diff_until_commit_hash, 'DUMMY_HASH'
      end
    end

    #-------------------------------------------------------------------------#

    describe '#verify_compatibility!' do
      it 'raises while asked to version information of a source if it is not compatible' do
        @source.stubs(:metadata).returns(Source::Metadata.new('min' => '999.0'))
        expect { @source.verify_compatibility! }.to raise_error(Informative) do |e|
          expect(e.message).to match(/Update CocoaPods/)
          expect(e.message).to match(/(currently using #{CORE_VERSION})/)
        end
        @source.stubs(:metadata).returns(Source::Metadata.new('max' => '0.0.1'))
        expect { @source.verify_compatibility! }.to raise_error(Informative) do |e|
          expect(e.message).to match(/Update CocoaPods/)
          expect(e.message).to match(/(currently using #{CORE_VERSION})/)
        end
      end
    end

    # #-------------------------------------------------------------------------#

    describe 'Representations' do
      it 'returns the hash representation' do
        expect(@source.to_hash['BananaLib']['1.0']['name']).to eq('BananaLib')
      end

      it 'returns the yaml representation' do
        yaml = @source.to_yaml
        expect(yaml).to match(/---/)
        expect(yaml).to match(/BananaLib:/)
      end
    end

    #-------------------------------------------------------------------------#

    before do
      path = fixture('spec-repos/test_repo')
      @source = Source.new(path)
    end

    #-------------------------------------------------------------------------#

    describe 'In general' do
      it 'returns its name' do
        expect(@source.name).to eq('test_repo')
      end
    end

    #-------------------------------------------------------------------------#

    describe '#pods' do
      it 'returns the available Pods' do
        expect(@source.pods).to eq(%w(BananaLib Faulty_spec IncorrectPath JSONKit JSONSpec React))
      end

      it 'raises if the repo does not exist' do
        path = fixture('spec-repos/non_existing')
        @source = Source.new(path)
        expect do
          @source.pods
        end.to raise_error(Informative, /Unable to find a source named: `non_existing`/)
      end

      it "doesn't include the `.` and the `..` dir entries" do
        expect(@source.pods).not_to include('.')
        expect(@source.pods).not_to include('..')
      end

      it 'only consider directories' do
        File.stubs(:directory?).returns(false)
        Pathname.any_instance.stubs(:directory?).returns(false)
        expect(@source.pods).to eq([])
      end

      it 'uses the `Specs` dir if it is present' do
        expect(@source.send(:specs_dir).to_s).to end_with('test_repo/Specs')
      end

      it 'uses the root of the repo as the specs dir if the `Specs` folder is not present' do
        repo = fixture('spec-repos/test_repo_without_specs_dir')
        @source = Source.new(repo)
        expect(@source.send(:specs_dir).to_s).to end_with('test_repo_without_specs_dir')
      end
    end

    #-------------------------------------------------------------------------#

    describe '#versions' do
      it 'returns the versions for the given Pod' do
        expect(@source.versions('JSONKit').map(&:to_s)).to eq(['999.999.999', '1.13', '1.4'])
      end

      it 'returns nil the Pod is unknown' do
        expect(@source.versions('Unknown_Pod')).to be_nil
      end

      it 'raises if the name of the Pod is not provided' do
        expect do
          @source.versions(nil)
        end.to raise_error(ArgumentError, /No name/)
      end

      it 'raises if a non-version-name directory is encountered' do
        Pathname.any_instance.stubs(:children).returns([Pathname.new('/Hello')])
        Pathname.any_instance.stubs(:directory?).returns(true)
        expect { @source.versions('JSONKit') }.to raise_error(Informative) do |e|
          expect(e.message).to match(/Hello/)
          expect(e.message).not_to match(/Malformed version number string/)
        end
      end
    end

    #-------------------------------------------------------------------------#

    describe '#specification' do
      it 'returns the specification for the given version of a Pod' do
        spec = @source.specification('JSONKit', '1.4')
        expect(spec.name).to eq('JSONKit')
        expect(spec.version.to_s).to eq('1.4')
      end

      it 'returns nil if the Pod is unknown' do
        expect do
          @source.specification('Unknown_Pod', '1.4')
        end.to raise_error(StandardError, /Unable to find the specification Unknown_Pod/)
      end

      it "raises if the version of the Pod doesn't exists" do
        expect do
          @source.specification('JSONKit', '0.99.0')
        end.to raise_error(StandardError, /Unable to find the specification JSONKit/)
      end

      it 'raises if the name of the Pod is not provided' do
        expect do
          @source.specification(nil, '1.4')
        end.to raise_error(ArgumentError, /No name/)
      end

      it 'raises if the name of the Pod is not provided' do
        expect do
          @source.specification('JSONKit', nil)
        end.to raise_error(ArgumentError, /No version/)
      end
    end

    #-------------------------------------------------------------------------#

    describe '#specification_path' do
      it 'returns the path of a specification' do
        path = @source.specification_path('JSONKit', '1.4')
        expect(path.to_s).to end_with('test_repo/Specs/JSONKit/1.4/JSONKit.podspec')
      end

      it 'prefers JSON podspecs if one exists' do
        Pathname.any_instance.stubs(:exist?).returns(true)
        path = @source.specification_path('JSONSpec', '0.9')
        expect(path.to_s).to end_with('Specs/JSONSpec/0.9/JSONSpec.podspec.json')
      end

      it 'raises if the name of the Pod is not provided' do
        expect do
          @source.specification_path(nil, '1.4')
        end.to raise_error(ArgumentError, /No name/)
      end

      it 'raises if the name of the Pod is not provided' do
        expect do
          @source.specification_path('JSONKit', nil)
        end.to raise_error(ArgumentError, /No version/)
      end
    end

    #-------------------------------------------------------------------------#

    describe 'with non-empty prefix lengths' do
      before do
        @path = fixture('spec-repos/test_prefixed_repo')
        @source = Source.new(@path)
      end

      describe '#pods' do
        it 'returns the available Pods' do
          expect(@source.pods).to eq(%w(BananaLib Faulty_spec IncorrectPath JSONKit JSONSpec))
        end

        it 'returns corresponding pods for given specification paths' do
          paths = %w(Specs/BananaLib/1.0/BananaLib.podspec)
          expect(@source.pods_for_specification_paths(paths)).to eq(%w(BananaLib))
          paths = %w(Specs/monkey/1.0.2/monkey.podspec Specs/JSONKit/1.4/JSONKit.podspec)
          expect(@source.pods_for_specification_paths(paths)).to eq(%w(monkey JSONKit))
        end
      end

      #-------------------------------------------------------------------------#

      describe '#versions' do
        it 'returns the available versions of a Pod' do
          expect(@source.versions('JSONKit').map(&:to_s)).to eq(['999.999.999', '1.13', '1.4'])
        end

        it 'returns nil if the Pod could not be found' do
          expect(@source.versions('Unknown_Pod')).to be_nil
        end
      end

      #-------------------------------------------------------------------------#

      describe '#specification' do
        it 'returns the specification for the given name and version' do
          spec = @source.specification('JSONKit', Version.new('1.4'))
          expect(spec.name).to eq('JSONKit')
          expect(spec.version.to_s).to eq('1.4')
        end
      end

      #-------------------------------------------------------------------------#

      describe '#all_specs' do
        it 'returns all the specifications' do
          expected = %w(BananaLib IncorrectPath JSONKit JSONSpec)
          expect(@source.all_specs.map(&:name).sort.uniq).to eq(expected)
        end
      end

      #-------------------------------------------------------------------------#

      describe '#set' do
        it 'returns the set of a given Pod' do
          set = @source.set('BananaLib')
          expect(set.name).to eq('BananaLib')
          expect(set.sources).to eq([@source])
        end
      end

      #-------------------------------------------------------------------------#

      describe '#pod_sets' do
        it 'returns all the pod sets' do
          expected = %w(BananaLib Faulty_spec IncorrectPath JSONKit JSONSpec)
          expect(@source.pod_sets.map(&:name).sort.uniq).to eq(expected)
        end
      end

      #-------------------------------------------------------------------------#

      describe '#search' do
        it 'searches for the Pod with the given name' do
          expect(@source.search('BananaLib').name).to eq('BananaLib')
        end

        it 'matches case' do
          expect(@source.search('bAnAnAlIb')).to be_nil
        end

        describe '#search_by_name' do
          it 'properly configures the sources of a set in search by name' do
            sets = @source.search_by_name('monkey', true)
            expect(sets.count).to eq(1)
            set = sets.first
            expect(set.name).to eq('BananaLib')
            expect(set.sources.map(&:name)).to eq(%w(test_prefixed_repo))
          end

          it 'can use regular expressions' do
            sets = @source.search_by_name('mon[ijk]ey', true)
            expect(sets.first.name).to eq('BananaLib')
          end
        end
      end

      #-------------------------------------------------------------------------#

      describe '#search_by_name' do
        it 'supports full text search' do
          sets = @source.search_by_name('monkey', true)
          expect(sets.map(&:name)).to eq(['BananaLib'])
          expect(sets.map(&:sources)).to eq([[@source]])
        end

        it 'The search is case insensitive' do
          pods = @source.search_by_name('MONKEY', true)
          expect(pods.map(&:name)).to eq(['BananaLib'])
        end

        it 'supports partial matches' do
          pods = @source.search_by_name('MON', true)
          expect(pods.map(&:name)).to eq(['BananaLib'])
        end

        it "handles gracefully specification which can't be loaded" do
          expect do
            @source.specification('Faulty_spec', '1.0.0')
          end.to raise_error(Informative, a_string_including('Invalid podspec'))

          expect do
            @source.search_by_name('monkey', true)
          end.not_to raise_error
        end
      end

      #-------------------------------------------------------------------------#

      describe '#fuzzy_search' do
        it 'is case insensitive' do
          expect(@source.fuzzy_search('bananalib').name).to eq('BananaLib')
        end

        it 'matches misspells' do
          expect(@source.fuzzy_search('banalib').name).to eq('BananaLib')
        end

        it 'matches suffixes' do
          expect(@source.fuzzy_search('Lib').name).to eq('BananaLib')
        end

        it 'returns nil if there is no match' do
          expect(@source.fuzzy_search('12345')).to be_nil
        end

        it 'matches abbreviations' do
          expect(@source.fuzzy_search('BLib').name).to eq('BananaLib')
        end
      end

      #-------------------------------------------------------------------------#

      describe 'Representations' do
        it 'returns the hash representation' do
          expect(@source.to_hash['BananaLib']['1.0']['name']).to eq('BananaLib')
        end

        it 'returns the yaml representation' do
          yaml = @source.to_yaml
          expect(yaml).to match(/---/)
          expect(yaml).to match(/BananaLib:/)
        end
      end

      #-------------------------------------------------------------------------#

      describe '#pods' do
        it 'returns the available Pods' do
          expect(@source.pods).to eq(%w(BananaLib Faulty_spec IncorrectPath JSONKit JSONSpec))
        end

        it "doesn't include the `.` and the `..` dir entries" do
          expect(@source.pods).not_to include('.')
          expect(@source.pods).not_to include('..')
        end

        it 'only consider directories' do
          File.stubs(:directory?).returns(false)
          Pathname.any_instance.stubs(:directory?).returns(false)
          expect(@source.pods).to eq([])
        end
      end

      #-------------------------------------------------------------------------#

      describe '#versions' do
        it 'returns the versions for the given Pod' do
          expect(@source.versions('JSONKit').map(&:to_s)).to eq(['999.999.999', '1.13', '1.4'])
        end

        it 'returns nil the Pod is unknown' do
          expect(@source.versions('Unknown_Pod')).to be_nil
        end

        it 'raises if a non-version-name directory is encountered' do
          Pathname.any_instance.stubs(:children).returns([Pathname.new('/Hello')])
          Pathname.any_instance.stubs(:directory?).returns(true)
          expect { @source.versions('JSONKit') }.to raise_error(Informative) do |e|
            expect(e.message).to match(/Hello/)
            expect(e.message).not_to match(/Malformed version number string/)
          end
        end
      end

      #-------------------------------------------------------------------------#

      describe '#specification' do
        it 'returns the specification for the given version of a Pod' do
          spec = @source.specification('JSONKit', '1.4')
          expect(spec.name).to eq('JSONKit')
          expect(spec.version.to_s).to eq('1.4')
        end

        it 'returns nil if the Pod is unknown' do
          expect do
            @source.specification('Unknown_Pod', '1.4')
          end.to raise_error(StandardError, /Unable to find the specification Unknown_Pod/)
        end

        it "raises if the version of the Pod doesn't exists" do
          expect do
            @source.specification('JSONKit', '0.99.0')
          end.to raise_error(StandardError, /Unable to find the specification JSONKit/)
        end
      end

      #-------------------------------------------------------------------------#

      describe '#specification_path' do
        it 'returns the path of a specification' do
          path = @source.specification_path('JSONKit', '1.4')
          expect(path.to_s).to end_with('test_prefixed_repo/Specs/1/3/f/JSONKit/1.4/JSONKit.podspec')
        end
      end
    end
  end
end
