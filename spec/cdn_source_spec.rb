require 'fileutils'
require 'algoliasearch'
require 'concurrent'
require 'typhoeus'
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

      def fulfilled_future(result)
        Concurrent::Promises.fulfilled_future(result)
      end

      def resolved_event
        Concurrent::Promises.resolved_event
      end

      def typhoeus_http_response_future(code, headers = {}, body = '')
        fulfilled_future(Typhoeus::Response.new(
                           :response_code => code,
                           :headers => headers,
                           :response_body => body,
        ))
      end

      def typhoeus_non_http_response_future(code)
        fulfilled_future(Typhoeus::Response.new(
                           :response_code => 0,
                           :return_code => code,
        ))
      end

      @remote_dir = fixture('mock_cdn_repo_remote')

      @path = fixture('spec-repos/test_cdn_repo_local')
      cleanup
      save_url('http://localhost:4321/')

      @source = CDNSource.new(@path)
    end

    after do
      cleanup
    end

    #-------------------------------------------------------------------------#

    describe 'In general' do
      it 'return its name' do
        expect(@source.name).to eq('test_cdn_repo_local')
      end

      it 'return its type' do
        expect(@source.type).to eq('CDN')
      end

      it 'works when the root URL has a trailing slash' do
        save_url('http://localhost:4321/')
        @source = CDNSource.new(@path)
        expect(@source.url).to eq('http://localhost:4321/')
      end

      it 'works when the root URL has a trailing path' do
        save_url('http://localhost:4321/trail/ing/path/')
        @source = CDNSource.new(@path)
        expect(@source.url).to eq('http://localhost:4321/trail/ing/path/')
      end

      it 'works when the root URL has no trailing slash' do
        save_url('http://localhost:4321')
        @source = CDNSource.new(@path)
        expect(@source.url).to eq('http://localhost:4321/')
      end

      it 'works when the root URL file has a newline' do
        save_url("http://localhost:4321/\n")
        @source = CDNSource.new(@path)
        expect(@source.url).to eq('http://localhost:4321/')
      end
    end

    #-------------------------------------------------------------------------#

    describe '#pods' do
      it 'returns the available Pods' do
        expect(@source.pods).to eq(%w(BeaconKit SDWebImage))
      end

      it "raises if the repo doesn't exist" do
        path = fixture('spec-repos/non_existing')
        @source = CDNSource.new(path)
        expect(@source.metadata).to be_nil
      end
    end

    #-------------------------------------------------------------------------#

    describe '#versions' do
      extend SpecHelper::TemporaryDirectory

      it 'returns the available versions of a Pod' do
        expect(@source.versions('BeaconKit').map(&:to_s)).to eq(%w(1.0.5 1.0.4 1.0.3 1.0.2 1.0.1 1.0.0))
      end

      it 'returns nil if the Pod could not be found' do
        expect(@source.versions('Unknown_Pod')).to be_nil
      end

      it 'does not error when a Pod name need URI escaping' do
        expect(@source.versions('СерафимиМногоꙮчитїи').map(&:to_s)).to eq(%w(1.0.0))
        expect(@source.specification('СерафимиМногоꙮчитїи', '1.0.0').name).to eq('СерафимиМногоꙮчитїи')
      end

      it 'uses netrc when provided' do
        save_url('http://localhost:4321/authorization')
        @source = CDNSource.new(@path)

        netrc_file = temporary_directory + '.netrc'
        File.open(netrc_file, 'w') { |f| f.write("machine localhost\nlogin user1\npassword xxx\n") }

        ENV['NETRC'] = temporary_directory.to_s
        auth = nil
        CDN_MOCK_SERVER.mount_proc('/authorization') do |req, res|
          auth = req['Authorization']
          res.body = ''
        end
        expect(@source.versions('Unknown_Pod')).to be_nil
        expect(auth).to eq('Basic dXNlcjE6eHh4')
      end

      it 'handles redirects' do
        relative_path = 'all_pods_versions_2_0_9.txt'
        original_url = 'http://localhost:4321/' + relative_path
        redirect_url = 'http://localhost:4321/redirected/' + relative_path
        @source.expects(:download_typhoeus_impl_async).
          with_url(original_url).
          returns(typhoeus_http_response_future(301, 'location' => redirect_url))
        @source.expects(:download_typhoeus_impl_async).
          with_url(redirect_url).
          returns(typhoeus_http_response_future(200, {}, 'BeaconKit/1.0.0'))
        @source.expects(:download_typhoeus_impl_async).
          with_url('http://localhost:4321/Specs/2/0/9/BeaconKit/1.0.0/BeaconKit.podspec.json').
          returns(typhoeus_http_response_future(200, {}, ''))

        @source.expects(:debug).with { |cmd| cmd.include? "CDN: #{@source.name} Relative path downloaded: all_pods_versions_2_0_9.txt, save ETag:" }
        @source.expects(:debug).with("CDN: #{@source.name} Redirecting from #{original_url} to #{redirect_url}")
        @source.expects(:debug).with { |cmd| cmd.include? "CDN: #{@source.name} Relative path downloaded: Specs/2/0/9/BeaconKit/1.0.0/BeaconKit.podspec.json, save ETag:" }
        expect(@source.versions('BeaconKit').map(&:to_s)).to eq(%w(1.0.0))
      end

      it 'handles responses with no headers' do
        @source.expects(:download_typhoeus_impl_async).
          with_url('http://localhost:4321/all_pods_versions_2_0_9.txt').
          returns(typhoeus_http_response_future(200, nil, 'BeaconKit/1.0.0'))
        @source.expects(:download_typhoeus_impl_async).
          with_url('http://localhost:4321/Specs/2/0/9/BeaconKit/1.0.0/BeaconKit.podspec.json').
          returns(typhoeus_http_response_future(200, nil, '{}'))
        expect do
          @source.versions('BeaconKit')
        end.not_to raise_error
      end

      it 'forces UTF-8 encoding for the body' do
        mock_json_body = mock
        mock_json_body.expects(:force_encoding).with('UTF-8').at_least_once
        @source.expects(:download_typhoeus_impl_async).
          with_url('http://localhost:4321/all_pods_versions_2_0_9.txt').
          returns(typhoeus_http_response_future(200, nil, 'BeaconKit/1.0.0'))
        @source.expects(:download_typhoeus_impl_async).
          with_url('http://localhost:4321/Specs/2/0/9/BeaconKit/1.0.0/BeaconKit.podspec.json').
          returns(typhoeus_http_response_future(200, {}, mock_json_body))
        expect do
          @source.versions('BeaconKit')
        end.not_to raise_error
      end

      it 'raises if unexpected HTTP error' do
        @source.expects(:download_typhoeus_impl_async).
          returns(typhoeus_http_response_future(500))
        expect do
          @source.versions('BeaconKit')
        end.to raise_error(Informative, a_string_including("CDN: #{@source.name} URL couldn\'t be downloaded: #{@url}all_pods_versions_2_0_9.txt Response: 500"))
      end

      it 'raises if unexpected non-HTTP error' do
        @source.expects(:download_typhoeus_impl_async).
          at_least_once.
          returns(typhoeus_non_http_response_future(:couldnt_connect))

        @source.expects(:sleep_async).at_least_once.with(anything).returns(resolved_event)

        expect do
          @source.versions('BeaconKit')
        end.to raise_error(
          Informative,
          a_string_including("CDN: #{@source.name} URL couldn\'t be downloaded: #{@url}all_pods_versions_2_0_9.txt Response: Couldn't connect to server"),
        )
      end

      it 'retries after unexpected HTTP error' do
        @source.expects(:download_typhoeus_impl_async).
          with_url('http://localhost:4321/all_pods_versions_2_0_9.txt').
          at_most(5).
          returns(typhoeus_http_response_future(503)).
          returns(typhoeus_http_response_future(503)).
          returns(typhoeus_http_response_future(503)).
          returns(typhoeus_http_response_future(503)).
          then.
          returns(typhoeus_http_response_future(200, {}, 'BeaconKit/1.0.0'))
        @source.expects(:download_typhoeus_impl_async).
          with_url('http://localhost:4321/Specs/2/0/9/BeaconKit/1.0.0/BeaconKit.podspec.json').
          returns(typhoeus_http_response_future(200, {}, ''))

        [4, 8, 16, 32].each do |seconds|
          @source.expects(:sleep_async).with(seconds).returns(resolved_event)
        end

        expect(@source.versions('BeaconKit').map(&:to_s)).to eq(%w(1.0.0))
      end

      it 'fails after unexpected HTTP error retries are exhausted' do
        @source.expects(:download_typhoeus_impl_async).
          with_url('http://localhost:4321/all_pods_versions_2_0_9.txt').
          at_most(5).
          returns(typhoeus_http_response_future(503)).
          returns(typhoeus_http_response_future(503)).
          returns(typhoeus_http_response_future(503)).
          returns(typhoeus_http_response_future(503)).
          returns(typhoeus_http_response_future(503))

        [4, 8, 16, 32].each do |seconds|
          @source.expects(:sleep_async).with(seconds).returns(resolved_event)
        end

        expect do
          @source.versions('BeaconKit')
        end.to raise_error(Informative, a_string_including("CDN: #{@source.name} URL couldn't be downloaded: http://localhost:4321/all_pods_versions_2_0_9.txt Response: 503"))
      end

      it 'retries after unexpected non-HTTP error' do
        @source.expects(:download_typhoeus_impl_async).
          with_url('http://localhost:4321/all_pods_versions_2_0_9.txt').
          at_most(5).
          returns(typhoeus_non_http_response_future(:couldnt_connect)).
          returns(typhoeus_non_http_response_future(:couldnt_connect)).
          returns(typhoeus_non_http_response_future(:couldnt_connect)).
          returns(typhoeus_non_http_response_future(:couldnt_connect)).
          then.
          returns(typhoeus_http_response_future(200, {}, 'BeaconKit/1.0.0'))
        @source.expects(:download_typhoeus_impl_async).
          with_url('http://localhost:4321/Specs/2/0/9/BeaconKit/1.0.0/BeaconKit.podspec.json').
          returns(typhoeus_http_response_future(200, {}, ''))

        [4, 8, 16, 32].each do |seconds|
          @source.expects(:sleep_async).with(seconds).returns(resolved_event)
        end

        expect(@source.versions('BeaconKit').map(&:to_s)).to eq(%w(1.0.0))
      end

      it 'fails after unexpected non-HTTP error retries are exhausted' do
        @source.expects(:download_typhoeus_impl_async).
          with_url('http://localhost:4321/all_pods_versions_2_0_9.txt').
          at_most(5).
          returns(typhoeus_non_http_response_future(:couldnt_connect)).
          returns(typhoeus_non_http_response_future(:couldnt_connect)).
          returns(typhoeus_non_http_response_future(:couldnt_connect)).
          returns(typhoeus_non_http_response_future(:couldnt_connect)).
          returns(typhoeus_non_http_response_future(:couldnt_connect))

        [4, 8, 16, 32].each do |seconds|
          @source.expects(:sleep_async).with(seconds).returns(resolved_event)
        end

        expect do
          @source.versions('BeaconKit')
        end.to raise_error(
          Informative,
          a_string_including("CDN: #{@source.name} URL couldn't be downloaded: http://localhost:4321/all_pods_versions_2_0_9.txt Response: Couldn't connect to server"),
        )
      end

      it 'raises cumulative error when more than one Future rejects' do
        @source.expects(:download_typhoeus_impl_async).
          with_url('http://localhost:4321/all_pods_versions_2_0_9.txt').
          returns(typhoeus_http_response_future(200, {}, 'BeaconKit/1.0.0/1.0.1/1.0.2/1.0.3/1.0.4/1.0.5'))
        versions = %w(0 1 2 3 4 5)
        messages = versions.map do |index|
          @source.expects(:download_typhoeus_impl_async).
            at_least_once.
            with_url("http://localhost:4321/Specs/2/0/9/BeaconKit/1.0.#{index}/BeaconKit.podspec.json").
            returns(typhoeus_http_response_future(500, {}, 'Some error'))
          "CDN: #{@source.name} URL couldn't be downloaded: #{@url}Specs/2/0/9/BeaconKit/1.0.#{index}/BeaconKit.podspec.json Response: 500 Some error"
        end

        expect do
          @source.versions('BeaconKit')
        end.to raise_error(Informative, a_string_including("CDN: #{@source.name} Repo update failed - 6 error(s):\n" + messages.join("\n")))
      end

      it 'returns cached versions for a Pod' do
        pod_path_children = %w(1.0.5 1.0.4 1.0.3 1.0.2 1.0.1 1.0.0)
        expect(@source.versions('BeaconKit').map(&:to_s)).to eq(pod_path_children)
        @source.expects(:download_file).never
        expect(@source.versions('BeaconKit').map(&:to_s)).to eq(pod_path_children)
        pod_versions = pod_path_children.map { |v| Version.new(v) }
        expect(@source.instance_variable_get(:@versions_by_name)).to eq({ 'BeaconKit' => pod_versions })
      end
    end

    #-------------------------------------------------------------------------#

    describe '#specification' do
      it 'returns the specification for the given name and version' do
        spec = @source.specification('BeaconKit', Version.new('1.0.5'))
        expect(spec.name).to eq('BeaconKit')
        expect(spec.version.to_s).to eq('1.0.5')
      end

      it 'downloads specification again if file is not valid' do
        # create empty podspec file
        FileUtils.mkdir_p(@path + 'Specs/2/0/9/BeaconKit/1.0.5')
        FileUtils.touch(@path + 'Specs/2/0/9/BeaconKit/1.0.5/BeaconKit.podspec.json')
        spec = @source.specification('BeaconKit', Version.new('1.0.5'))
        expect(spec.name).to eq('BeaconKit')
        expect(spec.version.to_s).to eq('1.0.5')
      end

      it 'does not attempt to access a version not in the version index' do
        @source.versions('BeaconKit')

        @source.expects(:download_file).never
        @source.expects(:local_file).never

        expect do
          @source.specification('BeaconKit', Version.new('9.9.9'))
        end.to raise_error(StandardError, a_string_including('Unable to find the specification BeaconKit (9.9.9) in the test_cdn_repo_local source.'))
      end
    end

    #-------------------------------------------------------------------------#

    describe '#all_specs' do
      it 'raises an error' do
        expect do
          @source.all_specs
        end.to raise_error(Informative, /Can't retrieve all the specs for a CDN-backed source, it will take forever/)
      end
    end

    #-------------------------------------------------------------------------#

    describe '#set' do
      it 'returns the set of a given Pod' do
        set = @source.set('BeaconKit')
        expect(set.name).to eq('BeaconKit')
        expect(set.sources).to eq([@source])
      end
    end

    #-------------------------------------------------------------------------#

    describe '#pod_sets' do
      it 'raises an error' do
        expect do
          @source.pod_sets
        end.to raise_error(Informative, /Can't retrieve all the pod sets for a CDN-backed source, it will take forever/)
      end
    end

    #-------------------------------------------------------------------------#

    describe '#search' do
      it 'searches for the Pod with the given name' do
        expect(@source.search('BeaconKit').name).to eq('BeaconKit')
      end

      it 'searches for the pod with the given dependency' do
        dep = Dependency.new('BeaconKit')
        expect(@source.search(dep).name).to eq('BeaconKit')
      end

      it 'supports dependencies on subspecs' do
        dep = Dependency.new('SDWebImage/MapKit')
        expect(@source.search(dep).name).to eq('SDWebImage')
      end

      it 'matches case' do
        @source.expects(:debug).with { |cmd| cmd =~ /CDN: #{@source.name} Relative path: all_pods_versions_9_5_b\.txt not available in this source set/ }
        @source.expects(:debug).with { |cmd| cmd =~ /CDN: #{@source.name} Relative path downloaded: all_pods_versions_9_5_b\.txt, save ETag:/ }
        expect(@source.search('bEacoNKIT')).to be_nil
      end

      describe '#search_by_name' do
        it 'properly configures the sources of a set in search by name' do
          sets = @source.search_by_name('beacon')
          expect(sets.count).to eq(1)
          set = sets.first
          expect(set.name).to eq('BeaconKit')
          expect(set.sources.map(&:name)).to eq(%w(test_cdn_repo_local))
        end

        it 'can use regular expressions' do
          sets = @source.search_by_name('be{0,1}acon')
          expect(sets.first.name).to eq('BeaconKit')
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
        expect(sets.first.name).to eq('BeaconKit')
      end

      it 'configures full-text search with Algolia from CDN file' do
        @source.search('BeaconKit')
        @source.expects(:download_file).with('AlgoliaSearch.yml').returns('AlgoliaSearch.yml')
        Algolia::Index.any_instance.stubs(:search).with('beacon', :attributesToRetrieve => 'name').returns('hits' => [{ 'name' => 'BeaconKit' }])
        sets = @source.search_by_name('beacon', true)
        expect(sets.first.name).to eq('BeaconKit')
      end

      it 'does not perform any heavy CDN operations if nothing was found' do
        @source.expects(:download_file).with('AlgoliaSearch.yml').returns('AlgoliaSearch.yml')
        Algolia::Index.any_instance.stubs(:search).with('beacon', :attributesToRetrieve => 'name').returns('hits' => [])
        @source.expects(:download_file).never
        expect(@source.search_by_name('beacon', true)).to eq([])
      end
    end

    #-------------------------------------------------------------------------#

    describe '#fuzzy_search' do
      it 'is case insensitive' do
        expect(@source.fuzzy_search('beaconkit').name).to eq('BeaconKit')
      end

      it 'matches misspells' do
        expect(@source.fuzzy_search('baconkit').name).to eq('BeaconKit')
      end

      it 'matches suffixes' do
        expect(@source.fuzzy_search('Kit').name).to eq('BeaconKit')
      end

      it 'returns nil if there is no match' do
        expect(@source.fuzzy_search('12345')).to be_nil
      end

      it 'matches abbreviations' do
        expect(@source.fuzzy_search('BKit').name).to eq('BeaconKit')
      end
    end

    #-------------------------------------------------------------------------#

    describe '#update' do
      it 'returns empty array' do
        File.open(@path.join('deprecated_podspecs.txt'), 'w') { |f| }
        CDNSource.any_instance.expects(:download_file).with('deprecated_podspecs.txt').returns('deprecated_podspecs.txt')
        CDNSource.any_instance.expects(:download_file_async).with('CocoaPods-version.yml').returns(fulfilled_future('CocoaPods-version.yml'))
        expect(@source.update(true)).to eq([])
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Representations' do
      it 'does not support hash representation' do
        expect do
          @source.to_hash
        end.to raise_error(Informative, /Can't retrieve all the specs for a CDN-backed source, it will take forever/)
      end

      it 'does not support yaml representation' do
        expect do
          @source.to_yaml
        end.to raise_error(Informative, /Can't retrieve all the specs for a CDN-backed source, it will take forever/)
      end
    end

    describe 'with non-empty prefix lengths' do
      describe '#specification_path' do
        it 'returns the path of a specification' do
          path = @source.specification_path('BeaconKit', '1.0.5')
          expect(path.to_s).to end_with('Specs/2/0/9/BeaconKit/1.0.5/BeaconKit.podspec.json')
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
        @source.expects(:download_file_async).with('CocoaPods-version.yml').returns(fulfilled_future('CocoaPods-version.yml'))
        @source.expects(:download_file_async).with('all_pods_versions_2_0_9.txt').returns(fulfilled_future('all_pods_versions_2_0_9.txt'))
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
