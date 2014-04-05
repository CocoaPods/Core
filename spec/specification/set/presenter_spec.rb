require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Specification::Set::Presenter do

    describe 'Set Information' do
      before do
        set = set = Source::Aggregate.new(fixture('spec-repos')).search_by_name('JSONKit').first
        @presenter = Spec::Set::Presenter.new(set)
      end

      it 'returns the set used to initialize it' do
        @presenter.set.class.should == Specification::Set
        @presenter.set.name.should == 'JSONKit'
      end

      it 'initializes the default statistics provider is one is not given' do
        @presenter.statistics_provider.class.should == Spec::Set::Statistics
      end

      it 'returns the name' do
        @presenter.name.should == 'JSONKit'
      end

      it 'returns the version' do
        @presenter.version.should == Version.new('999.999.999')
      end

      it 'returns all the version sorted from the highest to the lowest' do
        @presenter.versions.map(&:to_s).should == ['999.999.999', '1.5pre', '1.4']
        @presenter.versions.last.class.should == Version
      end

      it 'returns the versions by source' do
        @presenter.verions_by_source.should == '1.5pre, 1.4 [master repo] - 999.999.999, 1.4 [test_repo repo]'
      end

      it 'returns the sources' do
        @presenter.sources.should == %w(master test_repo)
      end
    end

    describe 'Specification Information' do
      before do
        @source = Source.new(fixture('spec-repos/master'))
        set = Spec::Set.new('CocoaLumberjack', @source)
        @presenter = Spec::Set::Presenter.new(set)
      end

      it 'returns the specification' do
        @presenter.spec.class.should == Specification
        @presenter.spec.name.should == 'CocoaLumberjack'
      end

      it 'returns the specification authors' do
        @presenter.authors.should == 'Robbie Hanson'
        @presenter.spec.authors = ['Author 1', 'Author 2']
        @presenter.authors.should == 'Author 1 and Author 2'
        @presenter.spec.authors = ['Author 1', 'Author 2', 'Author 3']
        @presenter.authors.should == 'Author 1, Author 2, and Author 3'
      end

      it 'returns the homepage' do
        @presenter.homepage.should == 'https://github.com/robbiehanson/CocoaLumberjack'
      end

      it 'returns the description' do
        @presenter.description.should == "It is similar in concept to other popular " \
          "logging frameworks such as log4j, yet is designed specifically for "       \
          "objective-c, and takes advantage of features such as multi-threading, "    \
          "grand central dispatch (if available), lockless atomic operations, and "   \
          "the dynamic nature of the objective-c runtime."
      end

      it 'returns the summary' do
        @presenter.summary.should == 'A fast & simple, yet powerful & flexible logging framework for Mac and iOS.'
      end

      it 'returns the source_url' do
        @presenter.source_url.should == 'https://github.com/robbiehanson/CocoaLumberjack.git'
      end

      it 'returns the platform' do
        @presenter.platform.should == 'iOS - OS X'
      end

      it 'returns the license' do
        @presenter.license.should == 'BSD'
      end

      it 'returns the subspecs' do
        @presenter.subspecs.should.nil?

        set = Spec::Set.new('RestKit', @source)
        @presenter = Spec::Set::Presenter.new(set)
        subspecs = @presenter.subspecs
        subspecs.last.class.should == Specification
        subspecs.map(&:name).should == ['RestKit/Core', 'RestKit/ObjectMapping', 'RestKit/Network', 'RestKit/CoreData', 'RestKit/Testing', 'RestKit/Search', 'RestKit/Support']
      end
    end

    describe 'Statistics' do
      before do
        Spec::Set::Statistics.instance = nil
        @stats = Spec::Set::Statistics.instance
        @source = Source.new(fixture('spec-repos/master'))
        set = Spec::Set.new('CocoaLumberjack', @source)
        @presenter = Spec::Set::Presenter.new(set)
      end

      it 'returns the creation date' do
        @presenter.creation_date.should == Time.parse('2011-10-06 17:37:56 +0200')
      end

      it 'returns the GitHub likes' do
        @stats.expects(:github_watchers).with(@presenter.set).returns(731)
        @presenter.github_watchers.should == 731
      end

      it 'returns the GitHub forks' do
        @stats.expects(:github_forks).with(@presenter.set).returns(109)
        @presenter.github_forks.should == 109
      end

      it 'returns the GitHub last activity' do
        @stats.expects(:github_pushed_at).with(@presenter.set).returns(Time.parse('2012-07-12T17:36:21Z'))
        Time.stubs(:now).returns(Time.parse('2012-11-01 00:00:00 +0100'))
        @presenter.github_last_activity.should == '4 months ago'
      end
    end

    describe 'Private methods' do
      before do
        @presenter = Spec::Set::Presenter.new(nil)
      end

      it 'represents a past date with a relative description' do
        time = (Time.now - 60 * 60 * 24).to_s
        @presenter.send(:distance_from_now_in_words, time).should == 'less than a week ago'
        time = (Time.now - 60 * 60 * 24 * 15).to_s
        @presenter.send(:distance_from_now_in_words, time).should == '15 days ago'
        time = (Time.now - 60 * 60 * 24 * 45).to_s
        @presenter.send(:distance_from_now_in_words, time).should == '1 month ago'
        time = (Time.now - 60 * 60 * 24 * 400).to_s
        @presenter.send(:distance_from_now_in_words, time).should == 'more than a year ago'
      end
    end
  end
end
