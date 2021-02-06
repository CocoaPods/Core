require 'fileutils'
require 'algoliasearch'
require File.expand_path('../spec_helper', __FILE__)

module Mocha
  class Expectation
    def with_url(expected_url)
      with { |url, _| url == expected_url }
    end
  end
end

module Pod
  describe CDNSource do
    before do
      def canonical_file(relative_path)
        @remote_dir.join(relative_path)
      end

      def read_canonical_file(relative_path)
        File.read(canonical_file(relative_path))
      end

      def get_etag(relative_path)
        path = @source.repo.join(relative_path)
        etag_path = path.sub_ext(path.extname + '.etag')
        File.read(etag_path) if File.exist?(etag_path)
      end

      def all_local_files
        [@source.repo.join('**/*.yml'), @source.repo.join('**/*.txt'), @source.repo.join('**/*.json')].map(&Pathname.method(:glob)).flatten
      end

      def save_url(url)
        @url = url
        File.open(@path.join('.url'), 'w') { |f| f.write(url) }
      end

      def cleanup
        Pathname.glob(@path.join('*')).each(&:rmtree)
        @path.join('.url').delete if @path.join('.url').exist?
        ENV['NETRC'] = nil
      end

      def print_dir(tag)
        STDERR.puts tag
        STDERR.puts Pathname.glob(@path.join('*')).sort.join("\n")
      end

      @remote_dir = fixture('mock_cdn_repo_remote')

      @path = fixture('spec-repos/test_cdn_repo_local')
      cleanup
      save_url('http://localhost:4321/')

      @source = CDNSource.new(@path)
      @source.stubs(:make_sleep).returns(nil)
      
      @save_log_level = Async.logger.level

      # silence "unawaited task error" false positives to reduce log noise
      # see https://github.com/socketry/async/issues/91 for more discussion
      # uncomment for debug purposes
      # Async.logger.level = :fatal
    end

    after do
      @source.unstub(:make_sleep)
      WebMock.reset!
      Async.logger.level = @save_log_level
      cleanup
    end

    #-------------------------------------------------------------------------#

    describe 'In general' do
      it 'return its name' do
        @source.name.should == 'test_cdn_repo_local'
      end

      it 'return its type' do
        @source.type.should == 'CDN'
      end

      it 'works when the root URL has a trailing slash' do
        save_url('http://localhost:4321/')
        @source = CDNSource.new(@path)
        @source.url.should == 'http://localhost:4321/'
      end

      it 'works when the root URL has a trailing path' do
        save_url('http://localhost:4321/trail/ing/path/')
        @source = CDNSource.new(@path)
        @source.url.should == 'http://localhost:4321/trail/ing/path/'
      end

      it 'works when the root URL has no trailing slash' do
        save_url('http://localhost:4321')
        @source = CDNSource.new(@path)
        @source.url.should == 'http://localhost:4321/'
      end

      it 'works when the root URL file has a newline' do
        save_url("http://localhost:4321/\n")
        @source = CDNSource.new(@path)
        @source.url.should == 'http://localhost:4321/'
      end
    end

    #-------------------------------------------------------------------------#

    describe '#pods' do
      it 'returns the available Pods' do
        @source.pods.should == %w(BeaconKit SDWebImage)
      end

      it "raises if the repo doesn't exist" do
        path = fixture('spec-repos/non_existing')
        @source = CDNSource.new(path)
        @source.metadata.should.be.nil?
      end
    end

    #-------------------------------------------------------------------------#

    describe '#versions' do
      extend SpecHelper::TemporaryDirectory

      it 'returns the available versions of a Pod' do
        @source.versions('BeaconKit').map(&:to_s).should == %w(1.0.5 1.0.4 1.0.3 1.0.2 1.0.1 1.0.0)
      end

      it 'returns nil if the Pod could not be found' do
        @source.versions('Unknown_Pod').should.be.nil
      end

      it 'does not error when a Pod name need URI escaping' do
        @source.versions('СерафимиМногоꙮчитїи').map(&:to_s).should == %w(1.0.0)
        @source.specification('СерафимиМногоꙮчитїи', '1.0.0').name.should == 'СерафимиМногоꙮчитїи'
      end

      it 'uses netrc when provided' do
        save_url('http://localhost:4321/authorization')
        @source = CDNSource.new(@path)

        netrc_file = temporary_directory + '.netrc'
        File.open(netrc_file, 'w', 0o600) { |f| f.write("machine localhost\nlogin user1\npassword xxx\n") }

        ENV['NETRC'] = temporary_directory.to_s
        auth = nil
        CDN_MOCK_SERVER.mount_proc('/authorization') do |req, res|
          auth = req['Authorization']
          res.body = ''
        end
        @source.versions('Unknown_Pod').should.be.nil
        auth.should == 'Basic dXNlcjE6eHh4'
      end

      it 'handles redirects' do
        relative_path = 'all_pods_versions_2_0_9.txt'
        original_url = 'http://localhost:4321/' + relative_path
        redirect_url = 'http://localhost:4321/redirected/' + relative_path

        WebMock.stub_request(:get, original_url).
          to_return(:status => 301, :headers => { 'location' => redirect_url })
        WebMock.stub_request(:get, redirect_url).
          to_return(:status => 200, :headers => {}, :body => 'BeaconKit/1.0.0')
        WebMock.stub_request(:get, 'http://localhost:4321/Specs/2/0/9/BeaconKit/1.0.0/BeaconKit.podspec.json').
          to_return(:status => 200, :headers => {}, :body => '')

        @source.expects(:debug).with { |cmd| cmd.include? "CDN: #{@source.name} Relative path downloaded: all_pods_versions_2_0_9.txt, save ETag:" }
        @source.expects(:debug).with("CDN: #{@source.name} Redirecting from #{original_url} to #{redirect_url}")
        @source.expects(:debug).with { |cmd| cmd.include? "CDN: #{@source.name} Relative path downloaded: Specs/2/0/9/BeaconKit/1.0.0/BeaconKit.podspec.json, save ETag:" }
        @source.versions('BeaconKit').map(&:to_s).should == %w(1.0.0)
      end

      it 'raises if unexpected HTTP error' do
        WebMock.stub_request(:get, 'http://localhost:4321/all_pods_versions_2_0_9.txt').
          to_return(:status => 500, :headers => {}, :body => '')

        should.raise Informative do
          @source.versions('BeaconKit')
        end.message.
          should.include "CDN: #{@source.name} URL couldn't be downloaded: #{@url}all_pods_versions_2_0_9.txt Response: 500"
      end

      it 'raises if unexpected non-HTTP error' do
        WebMock.stub_request(:get, 'http://localhost:4321/all_pods_versions_2_0_9.txt').
          to_raise(SocketError)

        should.raise Informative do
          @source.versions('BeaconKit')
        end.message.
          should.include "CDN: #{@source.name} URL couldn\'t be downloaded: #{@url}all_pods_versions_2_0_9.txt Response: Couldn't connect to server"
      end

      it 'retries after unexpected HTTP error' do
        WebMock.stub_request(:get, 'http://localhost:4321/all_pods_versions_2_0_9.txt').
          to_return(:status => 503, :headers => {}, :body => '').
          to_return(:status => 503, :headers => {}, :body => '').
          to_return(:status => 503, :headers => {}, :body => '').
          to_return(:status => 503, :headers => {}, :body => '').
          to_return(:status => 200, :headers => {}, :body => 'BeaconKit/1.0.0')

        WebMock.stub_request(:get, 'http://localhost:4321/Specs/2/0/9/BeaconKit/1.0.0/BeaconKit.podspec.json').
          to_return(:status => 200, :headers => {}, :body => '')

        [4, 8, 16, 32].each_with_index do |seconds, i|
          @source.expects(:backoff_time).with(Pod::CDNSource::MAX_NUMBER_OF_RETRIES - i).returns(seconds)
        end

        @source.versions('BeaconKit').map(&:to_s).should == %w(1.0.0)
      end

      it 'fails after unexpected HTTP error retries are exhausted' do
        WebMock.stub_request(:get, 'http://localhost:4321/all_pods_versions_2_0_9.txt').
          to_return(:status => 503, :headers => {}, :body => '').
          to_return(:status => 503, :headers => {}, :body => '').
          to_return(:status => 503, :headers => {}, :body => '').
          to_return(:status => 503, :headers => {}, :body => '').
          to_return(:status => 503, :headers => {}, :body => '')

        [4, 8, 16, 32].each_with_index do |seconds, i|
          @source.expects(:backoff_time).with(Pod::CDNSource::MAX_NUMBER_OF_RETRIES - i).returns(seconds)
        end

        should.raise Informative do
          @source.versions('BeaconKit')
        end.message.should.include "CDN: #{@source.name} URL couldn't be downloaded: http://localhost:4321/all_pods_versions_2_0_9.txt Response: 503"
      end

      it 'retries after unexpected non-HTTP error' do
        WebMock.stub_request(:get, 'http://localhost:4321/all_pods_versions_2_0_9.txt').
          to_raise(SocketError).
          to_raise(SocketError).
          to_raise(SocketError).
          to_raise(SocketError).
          to_return(:status => 200, :headers => {}, :body => 'BeaconKit/1.0.0')

        WebMock.stub_request(:get, 'http://localhost:4321/Specs/2/0/9/BeaconKit/1.0.0/BeaconKit.podspec.json').
          to_return(:status => 200, :headers => {}, :body => '')

        [4, 8, 16, 32].each_with_index do |seconds, i|
          @source.expects(:backoff_time).with(Pod::CDNSource::MAX_NUMBER_OF_RETRIES - i).returns(seconds)
        end

        @source.versions('BeaconKit').map(&:to_s).should == %w(1.0.0)
      end

      it 'fails after unexpected non-HTTP error retries are exhausted' do
        WebMock.stub_request(:get, 'http://localhost:4321/all_pods_versions_2_0_9.txt').
          to_raise(SocketError).
          to_raise(SocketError).
          to_raise(SocketError).
          to_raise(SocketError).
          to_raise(SocketError)

        [4, 8, 16, 32].each_with_index do |seconds, i|
          @source.expects(:backoff_time).with(Pod::CDNSource::MAX_NUMBER_OF_RETRIES - i).returns(seconds)
        end

        should.raise Informative do
          @source.versions('BeaconKit')
        end.message.should.include "CDN: #{@source.name} URL couldn't be downloaded: http://localhost:4321/all_pods_versions_2_0_9.txt Response: Couldn't connect to server"
      end

      it 'raises cumulative error when concurrent requests have errors' do
        WebMock.stub_request(:get, 'http://localhost:4321/all_pods_versions_2_0_9.txt').
          to_return(:status => 200, :headers => {}, :body => 'BeaconKit/1.0.0/1.0.1/1.0.2/1.0.3/1.0.4/1.0.5')

        messages = %w(0 1 2 3 4 5).map do |index|
          WebMock.stub_request(:get, "http://localhost:4321/Specs/2/0/9/BeaconKit/1.0.#{index}/BeaconKit.podspec.json").
            to_return(:status => 500, :headers => {}, :body => 'Some error')

          "CDN: #{@source.name} URL couldn't be downloaded: #{@url}Specs/2/0/9/BeaconKit/1.0.#{index}/BeaconKit.podspec.json Response: 500 Some error"
        end

        should.raise Informative do
          @source.versions('BeaconKit')
        end.message.should.include "CDN: #{@source.name} Repo update failed - 6 error(s):\n" + messages.join("\n")
      end

      it 'raises cumulative error only for errored requests' do
        WebMock.stub_request(:get, 'http://localhost:4321/all_pods_versions_2_0_9.txt').
          to_return(:status => 200, :headers => {}, :body => 'BeaconKit/1.0.0/1.0.1/1.0.2/1.0.3/1.0.4/1.0.5')
        WebMock.stub_request(:get, 'http://localhost:4321/Specs/2/0/9/BeaconKit/1.0.4/BeaconKit.podspec.json').
          to_return(:status => 200, :headers => {}, :body => 'BeaconKit/1.0.0/1.0.1/1.0.2/1.0.3/1.0.4/1.0.5')

        messages = %w(0 1 2 3 5).map do |index|
          WebMock.stub_request(:get, "http://localhost:4321/Specs/2/0/9/BeaconKit/1.0.#{index}/BeaconKit.podspec.json").
            to_return(:status => 500, :headers => {}, :body => 'Some error')

          "CDN: #{@source.name} URL couldn't be downloaded: #{@url}Specs/2/0/9/BeaconKit/1.0.#{index}/BeaconKit.podspec.json Response: 500 Some error"
        end

        should.raise Informative do
          @source.versions('BeaconKit')
        end.message.should.include "CDN: #{@source.name} Repo update failed - 5 error(s):\n" + messages.join("\n")
      end

      it 'returns cached versions for a Pod' do
        pod_path_children = %w(1.0.5 1.0.4 1.0.3 1.0.2 1.0.1 1.0.0)
        @source.versions('BeaconKit').map(&:to_s).should == pod_path_children
        @source.expects(:download_file).never
        @source.versions('BeaconKit').map(&:to_s).should == pod_path_children
        pod_versions = pod_path_children.map { |v| Version.new(v) }
        @source.instance_variable_get(:@versions_by_name).should == { 'BeaconKit' => pod_versions }
      end
    end

    #-------------------------------------------------------------------------#

    describe '#specification' do
      it 'returns the specification for the given name and version' do
        spec = @source.specification('BeaconKit', Version.new('1.0.5'))
        spec.name.should == 'BeaconKit'
        spec.version.should.to_s == '1.0.5'
      end

      it 'downloads specification again if file is not valid' do
        # create empty podspec file
        FileUtils.mkdir_p(@path + 'Specs/2/0/9/BeaconKit/1.0.5')
        FileUtils.touch(@path + 'Specs/2/0/9/BeaconKit/1.0.5/BeaconKit.podspec.json')
        spec = @source.specification('BeaconKit', Version.new('1.0.5'))
        spec.name.should == 'BeaconKit'
        spec.version.should.to_s == '1.0.5'
      end

      it 'does not attempt to access a version not in the version index' do
        @source.versions('BeaconKit')

        @source.expects(:download_file).never
        @source.expects(:local_file).never

        should.raise StandardError do
          @source.specification('BeaconKit', Version.new('9.9.9'))
        end.message.should.include 'Unable to find the specification BeaconKit (9.9.9) in the test_cdn_repo_local source.'
      end
    end

    #-------------------------------------------------------------------------#

    describe '#all_specs' do
      it 'raises an error' do
        should.raise Informative do
          @source.all_specs
        end.message.should.match /Can't retrieve all the specs for a CDN-backed source, it will take forever/
      end
    end

    #-------------------------------------------------------------------------#

    describe '#set' do
      it 'returns the set of a given Pod' do
        set = @source.set('BeaconKit')
        set.name.should == 'BeaconKit'
        set.sources.should == [@source]
      end
    end

    #-------------------------------------------------------------------------#

    describe '#pod_sets' do
      it 'raises an error' do
        should.raise Informative do
          @source.pod_sets
        end.message.should.match /Can't retrieve all the pod sets for a CDN-backed source, it will take forever/
      end
    end

    #-------------------------------------------------------------------------#

    describe '#search' do
      it 'searches for the Pod with the given name' do
        @source.search('BeaconKit').name.should == 'BeaconKit'
      end

      it 'searches for the pod with the given dependency' do
        dep = Dependency.new('BeaconKit')
        @source.search(dep).name.should == 'BeaconKit'
      end

      it 'supports dependencies on subspecs' do
        dep = Dependency.new('SDWebImage/MapKit')
        @source.search(dep).name.should == 'SDWebImage'
      end

      it 'matches case' do
        @source.expects(:debug).with { |cmd| cmd =~ /CDN: #{@source.name} Relative path downloaded: all_pods_versions_9_5_b\.txt, save ETag:/ }
        @source.search('bEacoNKIT').should.be.nil?
      end

      describe '#search_by_name' do
        it 'properly configures the sources of a set in search by name' do
          sets = @source.search_by_name('beacon')
          sets.count.should == 1
          set = sets.first
          set.name.should == 'BeaconKit'
          set.sources.map(&:name).should == %w(test_cdn_repo_local)
        end

        it 'can use regular expressions' do
          sets = @source.search_by_name('be{0,1}acon')
          sets.first.name.should == 'BeaconKit'
        end
      end
    end

    #-------------------------------------------------------------------------#

    describe '#search_by_name - Algolia' do
      before do
        @source.send(:download_file, 'AlgoliaSearch.yml')
      end

      it 'supports full-text search with Algolia' do
        @source.search('BeaconKit')
        Algolia::Index.any_instance.stubs(:search).with('beacon', :attributesToRetrieve => 'name').returns('hits' => [{ 'name' => 'BeaconKit' }])
        sets = @source.search_by_name('beacon', true)
        sets.first.name.should == 'BeaconKit'
      end

      it 'configures full-text search with Algolia from CDN file' do
        @source.search('BeaconKit')
        @source.expects(:download_file).with('AlgoliaSearch.yml').returns('AlgoliaSearch.yml')
        Algolia::Index.any_instance.stubs(:search).with('beacon', :attributesToRetrieve => 'name').returns('hits' => [{ 'name' => 'BeaconKit' }])
        sets = @source.search_by_name('beacon', true)
        sets.first.name.should == 'BeaconKit'
      end

      it 'does not perform any heavy CDN operations if nothing was found' do
        @source.expects(:download_file).with('AlgoliaSearch.yml').returns('AlgoliaSearch.yml')
        Algolia::Index.any_instance.stubs(:search).with('beacon', :attributesToRetrieve => 'name').returns('hits' => [])
        @source.expects(:download_file).never
        @source.search_by_name('beacon', true).should == []
      end
    end

    #-------------------------------------------------------------------------#

    describe '#fuzzy_search' do
      it 'is case insensitive' do
        @source.fuzzy_search('beaconkit').name.should == 'BeaconKit'
      end

      it 'matches misspells' do
        @source.fuzzy_search('baconkit').name.should == 'BeaconKit'
      end

      it 'matches suffixes' do
        @source.fuzzy_search('Kit').name.should == 'BeaconKit'
      end

      it 'returns nil if there is no match' do
        @source.fuzzy_search('12345').should.be.nil
      end

      it 'matches abbreviations' do
        @source.fuzzy_search('BKit').name.should == 'BeaconKit'
      end
    end

    #-------------------------------------------------------------------------#

    describe '#update' do
      it 'returns empty array' do
        File.open(@path.join('deprecated_podspecs.txt'), 'w') {}

        CDNSource.any_instance.expects(:download_file).with('deprecated_podspecs.txt').returns('deprecated_podspecs.txt')
        CDNSource.any_instance.expects(:download_file_async).with('CocoaPods-version.yml')
        @source.update(true).should == []
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Representations' do
      it 'does not support hash representation' do
        should.raise Informative do
          @source.to_hash
        end.message.should.match /Can't retrieve all the specs for a CDN-backed source, it will take forever/
      end

      it 'does not support yaml representation' do
        should.raise Informative do
          @source.to_yaml
        end.message.should.match /Can't retrieve all the specs for a CDN-backed source, it will take forever/
      end
    end

    describe 'with non-empty prefix lengths' do
      describe '#specification_path' do
        it 'returns the path of a specification' do
          path = @source.specification_path('BeaconKit', '1.0.5')
          path.to_s.should.end_with?('Specs/2/0/9/BeaconKit/1.0.5/BeaconKit.podspec.json')
        end
      end
    end

    describe 'with cached files' do
      before do
        @source.search('BeaconKit')
      end

      it 'refreshes all index files' do
        File.open(@path.join('deprecated_podspecs.txt'), 'w') { |f| }
        @source.expects(:download_file).with('deprecated_podspecs.txt').returns('deprecated_podspecs.txt')
        @source.expects(:download_file_async).with('CocoaPods-version.yml')
        @source.expects(:download_file_async).with('all_pods_versions_2_0_9.txt')
        @source.update(true)
      end

      it 'refreshes deprecated podspecs' do
        @source.search('СерафимиМногоꙮчитїи')
        @source.specification('СерафимиМногоꙮчитїи', '1.0.0')
        @source.update(true)
        @source = CDNSource.new(@path)

        @source.expects(:debug).with("CDN: #{@source.name} Going to update 4 files")

        expected_files = %w(
          deprecated_podspecs.txt
          CocoaPods-version.yml
          all_pods_versions_2_0_9.txt
          all_pods_versions_3_8_f.txt
          Specs/3/8/f/СерафимиМногоꙮчитїи/1.0.0/СерафимиМногоꙮчитїи.podspec.json
        )
        expected_files.each do |path|
          @source.expects(:debug).with { |cmd| cmd == "CDN: #{@source.name} Relative path: #{path}, has ETag? #{get_etag(@path.join(path))}" }
          @source.expects(:debug).with { |cmd| cmd == "CDN: #{@source.name} Relative path not modified: #{path}" }
        end
        @source.update(true)
      end

      it 'handles ETag and If-None-Match headers' do
        @source.update(true)
        @source = CDNSource.new(@path)

        @source.expects(:debug).with("CDN: #{@source.name} Going to update 2 files")

        expected_files = %w(deprecated_podspecs.txt CocoaPods-version.yml all_pods_versions_2_0_9.txt)
        expected_files.each do |path|
          @source.expects(:debug).with("CDN: #{@source.name} Relative path: #{path}, has ETag? #{get_etag(@path.join(path))}")
          @source.expects(:debug).with("CDN: #{@source.name} Relative path not modified: #{path}")
        end
        @source.update(true)
      end
    end
  end
end
