require File.expand_path('../../spec_helper', __FILE__)
require 'json'

module Pod
  describe Specification::JSONSupport do
    describe 'JSON support' do
      it 'returns the json representation' do
        spec = Specification.new(nil, 'BananaLib')
        spec.version = '1.0'
        expected = {
          'name' => 'BananaLib',
          'version' => '1.0',
          'platforms' => {
            'osx' => nil,
            'ios' => nil,
            'tvos' => nil,
            'watchos' => nil,
          },
        }
        JSON.parse(spec.to_json).should == expected
      end

      it 'terminates the json representation with a new line' do
        spec = Specification.new(nil, 'BananaLib')
        spec.to_json.should.end_with "\n"
      end

      it 'allows to specify multi-platform attributes' do
        json = <<-DOC
        {
          "name": "BananaLib",
          "ios": {
            "source_files": "Files"
          }
        }
        DOC
        spec = Specification.from_json(json)
        consumer = Specification::Consumer.new(spec, :ios)
        consumer.source_files.should == ['Files']
      end
    end

    #-------------------------------------------------------------------------#

    describe 'pretty JSON support' do
      it 'returns the json representation' do
        spec = Specification.new(nil, 'BananaLib')
        spec.version = '1.0'
        expected = {
          'name' => 'BananaLib',
          'version' => '1.0',
          'platforms' => {
            'osx' => nil,
            'ios' => nil,
            'tvos' => nil,
            'watchos' => nil,
          },
        }
        JSON.parse(spec.to_pretty_json).should == expected
      end

      it 'terminates the json representation with a new line' do
        spec = Specification.new(nil, 'BananaLib')
        spec.to_pretty_json.should.end_with "\n"
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Hash conversion' do
      before do
        path = fixture('BananaLib.podspec')
        @spec = Spec.from_file(path)
      end

      it 'can be converted to a hash' do
        hash = @spec.to_hash
        hash['name'].should == 'BananaLib'
        hash['version'].should == '1.0'
      end

      it 'handles subspecs when converted to a hash' do
        hash = @spec.to_hash
        hash['subspecs'].should == [{
          'name' => 'GreenBanana',
          'source_files' => 'GreenBanana',
          'platforms' => {
            'osx' => nil,
            'ios' => nil,
            'tvos' => nil,
            'watchos' => nil,
          },
        }]
      end

      it 'can be loaded from an hash' do
        hash = {
          'name' => 'BananaLib',
          'version' => '1.0',
        }
        result = Specification.from_hash(hash)
        result.name.should == 'BananaLib'
        result.version.to_s.should == '1.0'
      end

      it 'can be safely converted back and forth to a hash' do
        result = Specification.from_hash(@spec.to_hash)
        result.should == @spec
      end

      it 'returns whether it safe to convert a specification to hash' do
        @spec.safe_to_hash?.should.be.true
      end
    end
  end
end
