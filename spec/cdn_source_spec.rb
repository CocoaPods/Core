require 'fileutils'
require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe CDNSource do
    before do
      @path = fixture('spec-repos/test_cdn_repo_local')
      Pathname.glob(@path.join('*')).each(&:rmtree)
      @source = CDNSource.new(@path)
    end

    after do
      Pathname.glob(@path.join('*')).each(&:rmtree)
    end

    #-------------------------------------------------------------------------#

    describe 'In general' do
      it 'return its name' do
        @source.name.should == 'test_cdn_repo_local'
      end

      it 'return its type' do
        @source.type.should == 'CDN'
      end
    end

    #-------------------------------------------------------------------------#

    describe '#pods' do
      it 'returns the available Pods' do
        @source.pods.should == %w(BeaconKit SDWebImage)
      end

      it "raises if the repo doesn't exist" do
        path = fixture('spec-repos/non_existing')
        should.raise Informative do
          CDNSource.new(path)
        end.message.should.match /Unable to find a source named: `non_existing`/
      end
    end

    #-------------------------------------------------------------------------#

    describe '#versions' do
      it 'returns the available versions of a Pod' do
        @source.versions('BeaconKit').map(&:to_s).should == %w(1.0.5 1.0.4 1.0.3 1.0.2 1.0.1 1.0.0)
      end

      it 'returns nil if the Pod could not be found' do
        @source.expects(:debug).with { |cmd| cmd =~ /CDN: #{@source.name} Relative path couldn't be downloaded: Specs\/.*\/Unknown_Pod\/index\.txt Response: 404/ }
        @source.versions('Unknown_Pod').should.be.nil
      end

      it 'raises if unexpected HTTP error' do
        REST.expects(:get).returns(REST::Response.new(500))
        should.raise Informative do
          @source.versions('Unknown_Pod')
        end.message.should.match /CDN: .* Relative path couldn\'t be downloaded: .* Response: 500/
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
      it 'returns all the pod sets' do
        expected = %w(BeaconKit SDWebImage)
        @source.pod_sets.map(&:name).sort.uniq.should == expected
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
        @source.expects(:debug).with { |cmd| cmd =~ /CDN: #{@source.name} Relative path couldn't be downloaded: Specs\/.*\/bEacoNKIT\/index\.txt Response: 404/ }
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

    describe '#search_by_name' do
      it 'does not support full-text search' do
        should.raise Informative do
          @source.search_by_name('beacon', true)
        end.message.should.match /Can't perform full text search, it will take forever/
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
        CDNSource.any_instance.expects(:download_file).with('CocoaPods-version.yml').returns('CocoaPods-version.yml')
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

      def get_versions(relative_path)
        path = @source.repo.join(relative_path)
        File.read(path).split("\n")
      end

      it 'refreshes all index files' do
        @source.expects(:download_file).with('CocoaPods-version.yml').returns('CocoaPods-version.yml')
        pod_relative_path = @source.pod_path('BeaconKit').relative_path_from(@source.repo).join('index.txt').to_s
        @source.expects(:download_file).with(pod_relative_path).returns(pod_relative_path)
        get_versions(pod_relative_path).each do |version|
          podspec_relative_path = @source.pod_path('BeaconKit').relative_path_from(@source.repo).join(version).join('BeaconKit.podspec.json').to_s
          @source.expects(:download_file).with(podspec_relative_path).returns(podspec_relative_path)
        end
        @source.update(true)
      end

      def get_etag(relative_path)
        path = @source.repo.join(relative_path)
        etag_path = path.sub_ext(path.extname + '.etag')
        File.read(etag_path) if File.exist?(etag_path)
      end

      def all_local_files
        [@source.repo.join('**/*.yml'), @source.repo.join('**/*.txt'), @source.repo.join('**/*.json')].map(&Pathname.method(:glob)).flatten
      end

      it 'handles ETag and If-None-Match headers' do
        @source = CDNSource.new(@path)
        all_local_files.each do |path|
          relative_path = path.relative_path_from(@source.repo)
          @source.expects(:debug).with { |cmd| cmd == "CDN: #{@source.name} Relative path: #{relative_path}, has ETag? #{get_etag(path)}" }
          @source.expects(:debug).with { |cmd| cmd == "CDN: #{@source.name} Relative path not modified: #{relative_path}" }
        end
        @source.update(true)
      end
    end
  end
end
