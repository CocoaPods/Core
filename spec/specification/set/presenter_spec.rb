require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Specification::Set::Presenter do
    describe 'Set Information' do
      before do
        sources = [TrunkSource.new(fixture('spec-repos/trunk')), Source.new(fixture('spec-repos/test_repo'))]
        sets = Source::Aggregate.new(sources).search_by_name('JSONKit')
        set = sets.find { |s| s.name == 'JSONKit' }
        @presenter = Spec::Set::Presenter.new(set)
      end

      it 'returns the set used to initialize it' do
        expect(@presenter.set.class).to eq(Specification::Set)
        expect(@presenter.set.name).to eq('JSONKit')
      end

      it 'returns the name' do
        expect(@presenter.name).to eq('JSONKit')
      end

      it 'returns the version' do
        expect(@presenter.version).to eq(Version.new('999.999.999'))
      end

      it 'returns all the version sorted from the highest to the lowest' do
        expect(@presenter.versions.map(&:to_s)).to eq(['999.999.999', '1.13', '1.5pre', '1.4'])
        expect(@presenter.versions.last.class).to eq(Version)
      end

      it 'returns the versions by source' do
        expect(@presenter.versions_by_source).to eq('999.999.999, 1.13, 1.4 [test_repo repo] - 1.5pre, 1.4 [trunk repo]')
      end

      it 'returns the sources' do
        expect(@presenter.sources).to eq(%w(test_repo trunk))
      end

      it 'returns the correct deprecation description' do
        expect(@presenter.deprecation_description).to be_nil
        @presenter.spec.deprecated = true
        expect(@presenter.deprecation_description).to eq('[DEPRECATED]')
        @presenter.spec.deprecated_in_favor_of = 'NewMoreAwesomePod'
        expect(@presenter.deprecation_description).to eq('[DEPRECATED in favor of NewMoreAwesomePod]')
      end
    end

    describe 'Specification Information' do
      before do
        @source = TrunkSource.new(fixture('spec-repos/trunk'))
        set = Spec::Set.new('CocoaLumberjack', @source)
        @presenter = Spec::Set::Presenter.new(set)
      end

      it 'returns the specification' do
        expect(@presenter.spec.class).to eq(Specification)
        expect(@presenter.spec.name).to eq('CocoaLumberjack')
      end

      it 'returns the specification authors' do
        expect(@presenter.authors).to eq('Robbie Hanson')
        @presenter.spec.authors = ['Author 1', 'Author 2']
        expect(@presenter.authors).to eq('Author 1 and Author 2')
        @presenter.spec.authors = ['Author 1', 'Author 2', 'Author 3']
        expect(@presenter.authors).to eq('Author 1, Author 2, and Author 3')
      end

      it 'returns the homepage' do
        expect(@presenter.homepage).to eq('https://github.com/CocoaLumberjack/CocoaLumberjack')
      end

      it 'returns the description' do
        expect(@presenter.description).to eq('It is similar in concept to other popular ' \
          'logging frameworks such as log4j, yet is designed specifically for '       \
          'objective-c, and takes advantage of features such as multi-threading, '    \
          'grand central dispatch (if available), lockless atomic operations, and '   \
          'the dynamic nature of the objective-c runtime.')
      end

      it 'returns the summary' do
        expect(@presenter.summary).to eq('A fast & simple, yet powerful & flexible logging framework for Mac and iOS.')
      end

      it 'returns the source_url' do
        expect(@presenter.source_url).to eq('https://github.com/CocoaLumberjack/CocoaLumberjack.git')
      end

      it 'returns the platform' do
        expect(@presenter.platform).to eq('iOS 8.0 - macOS 10.10 - tvOS 9.0 - watchOS 3.0')
      end

      it 'returns the license' do
        expect(@presenter.license).to eq('BSD')
      end

      it 'returns the subspecs' do
        expect(@presenter.subspecs.map(&:name)).to eq(['CocoaLumberjack/Core', 'CocoaLumberjack/Swift'])

        set = Spec::Set.new('RestKit', @source)
        @presenter = Spec::Set::Presenter.new(set)
        subspecs = @presenter.subspecs
        expect(subspecs.last.class).to eq(Specification)
        expect(subspecs.map(&:name)).to eq(['RestKit/Core', 'RestKit/ObjectMapping', 'RestKit/Network', 'RestKit/CoreData', 'RestKit/Testing',
                                        'RestKit/Search', 'RestKit/Support', 'RestKit/CocoaLumberjack'])
      end
    end

    describe 'Statistics' do
      before do
        @source = TrunkSource.new(fixture('spec-repos/trunk'))
        set = Spec::Set.new('CocoaLumberjack', @source)
        metrics = {
          'github' => {
            'contributors' => 30,
            'created_at' => '2014-06-11 16:40:13 UTC',
            'forks' => 1726,
            'open_issues' => 242,
            'open_pull_requests' => 30,
            'stargazers' => 7188,
            'subscribers' => 425,
            'updated_at' => '2014-12-03 01:27:55 UTC',
          },
        }
        Metrics.stubs(:pod).returns(metrics)
        @presenter = Spec::Set::Presenter.new(set)
      end

      it 'returns the GitHub stars' do
        expect(@presenter.github_stargazers).to eq(7188)
      end

      it 'returns the GitHub forks' do
        expect(@presenter.github_forks).to eq(1726)
      end
    end
  end
end
