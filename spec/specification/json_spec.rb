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
        }]
      end

      it 'handles subspecs with different platforms' do
        subspec = @spec.subspec_by_name('BananaLib/GreenBanana')
        subspec.platforms = {
          'ios' => '9.0',
          'tvos' => '9.0',
        }
        hash = @spec.to_hash
        hash['subspecs'].should == [{
          'name' => 'GreenBanana',
          'source_files' => 'GreenBanana',
          'platforms' => {
            'ios' => '9.0',
            'tvos' => '9.0',
          },
        }]
      end

      it 'handles subspecs when the parent spec specifies platforms and the subspec inherits' do
        @spec.platforms = {
          'tvos' => '9.0',
        }
        hash = @spec.to_hash
        hash['subspecs'].should == [{
          'name' => 'GreenBanana',
          'source_files' => 'GreenBanana',
        }]
      end

      it 'writes script phases' do
        @spec.script_phases = [
          { :name => 'Hello World', :script => 'echo "Hello World"' },
          { :name => 'Hello Ruby World', :script => 'puts "Hello Ruby World"', :shell_path => 'usr/bin/ruby' },
        ]
        hash = @spec.to_hash
        hash['script_phases'].should == [
          { :name => 'Hello World', :script => 'echo "Hello World"' },
          { :name => 'Hello Ruby World', :script => 'puts "Hello Ruby World"', :shell_path => 'usr/bin/ruby' },
        ]
      end

      it 'writes test type for test subspec' do
        @spec.test_spec {}
        hash = @spec.to_hash
        hash['subspecs'].should == [{
          'name' => 'GreenBanana',
          'source_files' => 'GreenBanana',
        }]
        hash['testspecs'].should == [{
          'name' => 'Tests',
          'test_type' => :unit,
        }]
      end

      it 'writes test type for test subspec in json' do
        @spec.test_spec {}
        hash = @spec.to_json
        hash.should.include '"name":"Tests","test_type":"unit"'
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

      it 'can load test specification from hash' do
        hash = {
          'name' => 'BananaLib',
          'version' => '1.0',
          'subspecs' => [{ 'name' => 'GreenBanana', 'source_files' => 'GreenBanana' }],
          'testspecs' => [{ 'name' => 'Tests', 'test_type' => :unit }],
        }
        result = Specification.from_hash(hash)
        result.subspecs.count.should.equal 2
        result.test_specs.count.should.equal 1
        result.test_specs.first.test_specification?.should.be.true
        result.test_specs.first.test_type.should.equal :unit
      end

      it 'can load script phases from hash' do
        hash = {
          'name' => 'BananaLib',
          'version' => '1.0',
          'script_phases' => [
            { :name => 'Hello World', :script => 'echo "Hello World"' },
            { :name => 'Hello Ruby World', :script => 'puts "Hello World"', :shell_path => '/usr/bin/ruby' },
          ],
        }
        result = Specification.from_hash(hash)
        result.script_phases.count.should.equal 2
        result.script_phases.should == [
          { :name => 'Hello World', :script => 'echo "Hello World"' },
          { :name => 'Hello Ruby World', :script => 'puts "Hello World"', :shell_path => '/usr/bin/ruby' },
        ]
      end

      it 'can load test specification from 1.3.0 hash format' do
        hash = {
          'name' => 'BananaLib',
          'version' => '1.0',
          'subspecs' => [{ 'name' => 'GreenBanana', 'source_files' => 'GreenBanana' }, { 'name' => 'Tests', 'test_type' => :unit }],
        }
        result = Specification.from_hash(hash)
        result.subspecs.count.should.equal 2
        result.test_specs.count.should.equal 1
        result.test_specs.first.test_specification?.should.be.true
        result.test_specs.first.test_type.should.equal :unit
      end

      it 'can load test specification from 1.3.0 JSON format' do
        json = '{"subspecs": [{"name": "Tests","test_type": "unit","source_files": "Tests/**/*.{h,m}"}]}'
        result = Specification.from_json(json)
        result.test_specs.count.should.equal 1
        result.test_specs.first.test_specification?.should.be.true
        result.test_specs.first.test_type.should.equal :unit
      end

      it 'can load test specification from json' do
        json = '{"testspecs": [{"name": "Tests","test_type": "unit","source_files": "Tests/**/*.{h,m}"}]}'
        result = Specification.from_json(json)
        result.test_specs.count.should.equal 1
        result.test_specs.first.test_specification?.should.be.true
        result.test_specs.first.test_type.should.equal :unit
      end

      it 'can load script phases from json' do
        json = '{"script_phases": [{"name": "Hello World", "script": "echo \"Hello World\""}]}'
        result = Specification.from_json(json)
        result.script_phases.count.should.equal 1
        result.script_phases.should == [
          { :name => 'Hello World', :script => 'echo "Hello World"' },
        ]
      end

      it 'can be safely converted back and forth to a hash' do
        result = Specification.from_hash(@spec.to_hash)
        result.should == @spec
      end
    end
  end
end
