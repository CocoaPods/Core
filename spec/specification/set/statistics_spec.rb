require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Specification::Set::Statistics do

    #-------------------------------------------------------------------------#

    describe "In general" do
      before do
        @source = Source.new(fixture('spec-repos/master'))
        @set    = @source.search_by_name('JSONKit').first
        @stats  = Spec::Set::Statistics.new
      end

      it "returns the creation date of Pod" do
        @stats.creation_date(@set).should == Time.parse('2011-09-12 10:49:04 +0200')
      end

      it "returns the creation date of more Pods" do
        sets = [@set, @source.search_by_name('libPusher').first ]
        expected = {
          "JSONKit"=> Time.parse('2011-09-12 10:49:04 +0200'),
          "libPusher"=> Time.parse('2012-02-01 17:05:58 +0100'),
        }
        @stats.creation_dates(sets).should == expected
      end

      it "returns the GitHub watchers of a Pod" do
        repo_data = { 'watchers' => 2771 }
        GitHub.expects(:fetch_github_repo_data).with('git://github.com/johnezang/JSONKit.git').returns(repo_data)
        @stats.github_watchers(@set).should == 2771
      end

      it "returns the GitHub forks of a Pod" do
        repo_data = { 'forks' => 423 }
        GitHub.expects(:fetch_github_repo_data).with('git://github.com/johnezang/JSONKit.git').returns(repo_data)
        @stats.github_forks(@set).should == 423
      end

      it "returns the time of the last push from GitHub" do
        repo_data = { 'pushed_at' => "2012-07-12T17:36:21Z" }
        GitHub.expects(:fetch_github_repo_data).with('git://github.com/johnezang/JSONKit.git').returns(repo_data)
        @stats.github_pushed_at(@set).should == Time.parse("2012-07-12T17:36:21Z")
      end

      it "returns nil for GitHub based methods if the Pod is not hosted by GitHub" do
        @set.specification.source = { :git => 'example.com/repo.git' }
        @stats.github_watchers(@set).should  == nil
        @stats.github_forks(@set).should     == nil
        @stats.github_pushed_at(@set).should == nil
      end
    end

    #-------------------------------------------------------------------------#

    describe "Cache" do
      before do
        @source = Source.new(fixture('spec-repos/master'))
        @set    = @source.search_by_name('JSONKit').first
        @stats  = Spec::Set::Statistics.new
      end

      it "defaults the cache expiration to 3 days" do
        @stats.cache_expiration.should == 60 * 60 * 24 * 3
      end

      it "uses an in memory cache" do
        repo_data = { 'watchers' => 2771 }
        GitHub.expects(:fetch_github_repo_data).with('git://github.com/johnezang/JSONKit.git').returns(repo_data)
        @stats.github_watchers(@set).should == 2771
        GitHub.expects(:fetch_github_repo_data).never
        @stats.github_watchers(@set).should == 2771
      end

      extend SpecHelper::TemporaryDirectory

      before do
        @cache_hash = { 'JSONKit' => {
          :gh_watchers => 2771,
          :gh_forks    => 423,
          :pushed_at   => "2012-07-12T17:36:21Z",
          :gh_date     => Time.now
        }}
        @cache_file = temporary_directory + 'cache_file.yaml'
        File.open(@cache_file, 'w') { |f| f.write(YAML.dump(@cache_hash)) }
        @stats.cache_file = @cache_file
      end

      it "uses a cache file, if provided" do
        GitHub.expects(:fetch_github_repo_data).never
        @stats.github_watchers(@set).should == 2771
      end

      it "saves the cache after computing the creation date of a set" do
        @stats.creation_date(@set)
        cache_hash = YAML.load(@cache_file.read)
        cache_hash['JSONKit'][:creation_date].should == Time.parse('2011-09-12 10:49:04 +0200')
      end

      it "saves the cache after computing the creation date of many sets" do
        sets = [@set, @source.search_by_name('libPusher').first ]
        @stats.creation_dates(sets)
        cache_hash = YAML.load(@cache_file.read)
        cache_hash['JSONKit'][:creation_date].should == Time.parse('2011-09-12 10:49:04 +0200')
        cache_hash['libPusher'][:creation_date].should == Time.parse('2012-02-01 17:05:58 +0100')
      end

      it "saves the cache only one time cache after computing the creation date of many sets" do
        @stats.expects(:save_cache).once
        sets = [@set, @source.search_by_name('libPusher').first ]
        @stats.creation_dates(sets)
      end

      it "uses the cache of GitHub values if still valid" do
        GitHub.expects(:fetch_github_repo_data).never
        @stats.github_watchers(@set).should  == 2771
        @stats.github_forks(@set).should     == 423
        @stats.github_pushed_at(@set).should == Time.parse("2012-07-12T17:36:21Z")
      end

      before do
        @repo_fixture = { 'watchers' => 2771, 'forks' => 423, 'pushed_at' => "2012-07-12T17:36:21Z" }
        File.open(@cache_file, 'w') { |f| f.write(YAML.dump({ 'JSONKit' => {}})) }
        GitHub.expects(:fetch_github_repo_data).with('git://github.com/johnezang/JSONKit.git').returns(@repo_fixture)
      end

      it "saves the cache after retrieving GitHub information" do
        @stats.github_watchers(@set)
        saved_cache = YAML.load(@cache_file.read)
        saved_cache['JSONKit'][:gh_date] = nil
        @cache_hash['JSONKit'][:gh_date] = nil
        saved_cache.should == @cache_hash
      end

      it "updates the GitHub cache if not valid" do
        @cache_hash['JSONKit'][:gh_date] = (Time.now - 60 * 60 * 24 * 5)
        @stats.github_forks(@set).should == 423
      end

      it "stores in the cache time of the last access to the GitHub API" do
        @stats.github_watchers(@set)
        saved_cache = YAML.load(@cache_file.read)
        time_delta = (Time.now - saved_cache['JSONKit'][:gh_date])
        time_delta.should < 60
      end
    end

    #-------------------------------------------------------------------------#

  end
end
