require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Source::GitHubDataProvider do

    before do
      @sut = Source::GitHubDataProvider.new('CocoaPods/Specs', 'json_podspecs')
    end

    #-------------------------------------------------------------------------#

    describe 'In general' do
      it 'returns the name of the source' do
        @sut.name.should == 'CocoaPods/Specs'
      end

      it 'returns the type of the source' do
        @sut.type.should == 'GitHub API'
      end
    end

    #-------------------------------------------------------------------------#

    describe '#pods' do
      it 'returns the list of all the Pods' do
        VCR.use_cassette('GitHubDataProvider', :record => :new_episodes) do
          @sut.pods.should.include?('ARAnalytics')
        end
      end

      it 'only considers directories to compute the name of Pods' do
        VCR.use_cassette('GitHubDataProvider', :record => :new_episodes) do
          @sut.pods.should.not.include?('Readme.md')
        end
      end

      it 'returns nil if no Pods could be found' do
        VCR.use_cassette('GitHubDataProvider', :record => :new_episodes) do
          @sut = Source::GitHubDataProvider.new('CocoaPods/Missing_Specs')
          @sut.pods.should.be.nil
        end
      end
    end

    #-------------------------------------------------------------------------#

    describe '#versions' do
      it 'returns the available versions of a Pod' do
        VCR.use_cassette('GitHubDataProvider', :record => :new_episodes) do
          @sut.versions('A3GridTableView').should == ['0.0.1']
        end
      end

      it 'returns nil the Pod is unknown' do
        VCR.use_cassette('GitHubDataProvider', :record => :new_episodes) do
          @sut.versions('Unknown_Pod').should.be.nil
        end
      end

      it 'raises if the name of the Pod is not provided' do
        should.raise ArgumentError do
          @sut.versions(nil)
        end.message.should.match /No name/
      end
    end

    #-------------------------------------------------------------------------#

    describe '#specification' do
      it 'returns the specification given the name and the version' do
        VCR.use_cassette('GitHubDataProvider', :record => :new_episodes) do
          spec = @sut.specification('ARAnalytics', '1.3.1')
          spec.name.should == 'ARAnalytics'
          spec.version.to_s.should == '1.3.1'
        end
      end

      it 'returns nil if the Pod is unknown' do
        VCR.use_cassette('GitHubDataProvider', :record => :new_episodes) do
          spec = @sut.specification('Unknown_Pod', '1.3.1')
          spec.should.be.nil
        end
      end

      it "returns nil if the version of the Pod doesn't exists" do
        VCR.use_cassette('GitHubDataProvider', :record => :new_episodes) do
          spec = @sut.specification('ARAnalytics', '0.99.0')
          spec.should.be.nil
        end
      end

      it 'raises if the name of the Pod is not provided' do
        should.raise ArgumentError do
          @sut.specification(nil, '0.99.0')
        end.message.should.match /No name/
      end

      it 'raises if the name of the Pod is not provided' do
        should.raise ArgumentError do
          @sut.specification('ARAnalytics', nil)
        end.message.should.match /No version/
      end
    end

    #-------------------------------------------------------------------------#

    describe '#specification_contents' do
      it 'returns the specification given the name and the version' do
        VCR.use_cassette('GitHubDataProvider', :record => :new_episodes) do
          spec = @sut.specification_contents('ARAnalytics', '1.3.1')
          spec.should.include("{\n  \"name\": \"ARAnalytics\",\n  \"version\": \"1.3.1\"")
        end
      end

      it 'returns nil if the Pod is unknown' do
        VCR.use_cassette('GitHubDataProvider', :record => :new_episodes) do
          spec = @sut.specification_contents('Unknown_Pod', '1.3.1')
          spec.should.be.nil
        end
      end

      it "returns nil if the version of the Pod doesn't exists" do
        VCR.use_cassette('GitHubDataProvider', :record => :new_episodes) do
          spec = @sut.specification_contents('ARAnalytics', '0.99.0')
          spec.should.be.nil
        end
      end

      it 'raises if the name of the Pod is not provided' do
        should.raise ArgumentError do
          @sut.specification_contents(nil, '0.99.0')
        end.message.should.match /No name/
      end

      it 'raises if the name of the Pod is not provided' do
        should.raise ArgumentError do
          @sut.specification_contents('ARAnalytics', nil)
        end.message.should.match /No version/
      end
    end

    #-------------------------------------------------------------------------#

  end
end
