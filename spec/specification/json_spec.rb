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
            'visionos'=> nil,
            'watchos' => nil,
          },
        }
        JSON.parse(spec.to_json).should == expected
      end

      it 'serializes tags with Pod::Version correctly' do
        spec = Specification.new(nil, 'BananaLib') do |spec|
          spec.version = '1.0'
          spec.version.class.should == Pod::Version
          spec.source = {
            :git => 'https://github.com/CocoaPods/CocoaPodsExampleLibrary.git',
            :tag => spec.version,
          }
        end
        expected = {
          'name' => 'BananaLib',
          'version' => '1.0',
          'source' => {
            'git' => 'https://github.com/CocoaPods/CocoaPodsExampleLibrary.git',
            'tag' => '1.0',
          },
          'platforms' => {
            'osx' => nil,
            'ios' => nil,
            'tvos' => nil,
            'visionos'=> nil,
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
            'visionos'=> nil,
            'watchos' => nil,
          },
        }
        JSON.parse(spec.to_pretty_json).should == expected
      end

      it 'terminates the json representation with a new line' do
        spec = Specification.new(nil, 'BananaLib')
        spec.to_pretty_json.should.end_with "\n"
      end

      it 'can round-trip' do
        spec = Specification.new do |s|
          s.name = 'BananaLib'
          s.platform = :ios, '9.0'
          s.app_spec 'App'
          s.test_spec 'Tests'
          s.version = '17.0'
          s.swift_versions = %w(5.0)
        end

        json = spec.to_pretty_json

        loaded_spec = Specification.from_json(json)
        new_json = loaded_spec.to_pretty_json

        new_json.should.equal json
      end

      it 'maintains correct order of keys across versions' do
        %w(14 15 16 17 18).each do |version|
          json = File.read(File.expand_path("../../fixtures/CannonPodder#{version}.podspec.json", __FILE__))
          loaded_spec = Specification.from_json(json)
          new_json = loaded_spec.to_pretty_json
          new_json.should.equal json
        end
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
        hash['subspecs'].should == [
          {
            'name' => 'GreenBanana',
            'source_files' => 'GreenBanana',
            'dependencies' => { 'AFNetworking' => [] },
          },
          {
            'name' => 'YellowBanana',
            'source_files' => 'YellowBanana',
            'dependencies' => { 'SDWebImage' => [] },
          },
        ]
      end

      it 'handles subspecs with different platforms' do
        subspec = @spec.subspec_by_name('BananaLib/GreenBanana')
        subspec.platforms = {
          'ios' => '9.0',
          'tvos' => '9.0',
        }
        hash = @spec.to_hash
        hash['subspecs'].should == [
          {
            'name' => 'GreenBanana',
            'source_files' => 'GreenBanana',
            'dependencies' => { 'AFNetworking' => [] },
            'platforms' => {
              'ios' => '9.0',
              'tvos' => '9.0',
            },
          },
          {
            'name' => 'YellowBanana',
            'source_files' => 'YellowBanana',
            'dependencies' => { 'SDWebImage' => [] },
          },
        ]
      end

      it 'handles subspecs when the parent spec specifies platforms and the subspec inherits' do
        @spec.platforms = {
          'tvos' => '9.0',
        }
        hash = @spec.to_hash
        hash['subspecs'].should == [
          {
            'name' => 'GreenBanana',
            'source_files' => 'GreenBanana',
            'dependencies' => { 'AFNetworking' => [] },
          },
          {
            'name' => 'YellowBanana',
            'source_files' => 'YellowBanana',
            'dependencies' => { 'SDWebImage' => [] },
          },
        ]
      end

      it 'writes script phases' do
        @spec.script_phases = [
          { :name => 'Hello World', :script => 'echo "Hello World"' },
          { :name => 'Hello World 2', :script => 'echo "Hello World 2"', :execution_position => :after_compile },
          { :name => 'Hello Ruby World', :script => 'puts "Hello Ruby World"', :shell_path => 'usr/bin/ruby' },
        ]
        hash = @spec.to_hash
        hash['script_phases'].should == [
          { :name => 'Hello World', :script => 'echo "Hello World"' },
          { :name => 'Hello World 2', :script => 'echo "Hello World 2"', :execution_position => :after_compile },
          { :name => 'Hello Ruby World', :script => 'puts "Hello Ruby World"', :shell_path => 'usr/bin/ruby' },
        ]
      end

      it 'writes scheme configuration' do
        @spec.scheme = { :launch_arguments => ['Arg1'] }
        hash = @spec.to_hash
        hash['scheme'].should == { 'launch_arguments' => ['Arg1'] }
      end

      it 'writes Info.plist configuration' do
        @spec.info_plist = {
          'CFBundleIdentifier' => 'org.cocoapods.MyAwesomeLib',
          'SOME_VAR' => 'SOME_VALUE',
        }
        hash = @spec.to_hash
        hash['info_plist'].should == {
          'CFBundleIdentifier' => 'org.cocoapods.MyAwesomeLib',
          'SOME_VAR' => 'SOME_VALUE',
        }
      end

      it 'writes test type for test subspec' do
        @spec.test_spec {}
        hash = @spec.to_hash
        hash['subspecs'].should == [
          {
            'name' => 'GreenBanana',
            'source_files' => 'GreenBanana',
            'dependencies' => { 'AFNetworking' => [] },
          },
          {
            'name' => 'YellowBanana',
            'source_files' => 'YellowBanana',
            'dependencies' => { 'SDWebImage' => [] },
          },
        ]
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

      it 'writes ui test type for test subspec in json' do
        @spec.test_spec do |test|
          test.test_type = :ui
        end
        hash = @spec.to_json
        hash.should.include '"name":"Tests","test_type":"ui"'
      end

      describe 'Dependency Configuration Support' do
        it 'does not write the configuration whitelist for a pod if unspecified' do
          @spec.dependency 'AFNetworking'
          hash = @spec.to_hash
          hash['configuration_pod_whitelist'].should.be.nil
        end

        it 'writes the array string configuration whitelist for a given pod' do
          @spec.dependency 'AFNetworking', :configurations => ['Debug']
          hash = @spec.to_hash
          hash['configuration_pod_whitelist'].should == {
            'AFNetworking' => [
              'debug',
            ],
          }
        end

        it 'writes the array symbol configuration whitelist for a given pod' do
          @spec.dependency 'AFNetworking', :configurations => [:debug]
          hash = @spec.to_hash
          hash['configuration_pod_whitelist'].should == {
            'AFNetworking' => [
              'debug',
            ],
          }
        end

        it 'writes the symbol configuration whitelist for a given pod' do
          @spec.dependency 'AFNetworking', :configurations => :debug
          hash = @spec.to_hash
          hash['configuration_pod_whitelist'].should == {
            'AFNetworking' => [
              'debug',
            ],
          }
        end

        it 'loads the configuration whitelist for a pod' do
          hash = {
            'name' => 'BananaLib',
            'version' => '1.0',
            'dependencies' => { 'AFNetworking' => [] },
            'configuration_pod_whitelist' => { 'AFNetworking' => ['debug'] },
          }
          result = Specification.from_hash(hash)
          result.dependency_whitelisted_for_configuration?(Dependency.new('AFNetworking'), 'debug').should.be.true
        end
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

      it 'can load app specification from hash' do
        hash = {
          'name' => 'BananaLib',
          'version' => '1.0',
          'subspecs' => [{ 'name' => 'GreenBanana', 'source_files' => 'GreenBanana' }],
          'appspecs' => [{ 'name' => 'App' }],
        }
        result = Specification.from_hash(hash)
        result.subspecs.count.should.equal 2
        result.app_specs.count.should.equal 1
        result.app_specs.first.name.should == 'BananaLib/App'
        result.app_specs.first.app_specification?.should.be.true
      end

      it 'can load scheme configuration from hash' do
        hash = {
          'name' => 'BananaLib',
          'version' => '1.0',
          'scheme' => { 'launch_arguments' => ['Arg1'] },
        }
        result = Specification.from_hash(hash)
        result.scheme.should == { :launch_arguments => ['Arg1'] }
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
          { :name => 'Hello World', :script => 'echo "Hello World"', :execution_position => :any },
          { :name => 'Hello Ruby World', :script => 'puts "Hello World"', :shell_path => '/usr/bin/ruby', :execution_position => :any },
        ]
      end

      it 'can load on demand resources from a hash' do
        hash = {
          'name' => 'BananaLib',
          'version' => '1.0',
          'on_demand_resources' => {
            'Tag1' => { :paths => 'Tag1Resources/*', :category => :download_on_demand },
            'Tag2' => ['Tag2Resources/*'],
            'Tag3' => 'Tag3Resources/bear.png*',
          },
        }
        result = Specification.from_hash(hash)
        result.on_demand_resources.count.should.equal 3
        result.on_demand_resources.should == {
          'Tag1' => { :paths => 'Tag1Resources/*', :category => :download_on_demand },
          'Tag2' => ['Tag2Resources/*'],
          'Tag3' => 'Tag3Resources/bear.png*',
        }
      end

      it 'can load default subspecs from hash' do
        hash = {
          'name' => 'BananaLib',
          'version' => '1.0',
          'default_subspecs' => 'BananaLibSubSpec',
          'subspecs' => [
            {
              'name' => 'BananaLibSubSpec',
            },
          ],
        }
        result = Specification.from_hash(hash)
        result.default_subspecs.should == ['BananaLibSubSpec']
      end

      it 'can load no default subspecs from hash' do
        hash = {
          'name' => 'BananaLib',
          'version' => '1.0',
          'default_subspecs' => 'none',
          'subspecs' => [
            {
              'name' => 'BananaLibSubSpec',
            },
          ],
        }
        result = Specification.from_hash(hash)
        result.default_subspecs.should == :none
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
        result.non_library_specs.count.should.equal 1
        result.app_specs.count.should.equal 0
        result.test_specs.first.test_specification?.should.be.true
        result.test_specs.first.app_specification?.should.be.false
        result.test_specs.first.test_type.should.equal :unit
      end

      it 'can throws with the path for malformed json' do
        json = '{"script_phases": [{name": "Hello World", "script": "echo \"Hello World\""}]}'
        should.raise JSON::ParserError do
          result = Specification.from_json(json, "path/to/spec.json")
        end.message.should.include 'path/to/spec.json'
      end

      it 'can load test specification from 1.3.0 JSON format' do
        json = '{"subspecs": [{"name": "Tests","test_type": "unit","source_files": "Tests/**/*.{h,m}"}]}'
        result = Specification.from_json(json)
        result.test_specs.count.should.equal 1
        result.non_library_specs.count.should.equal 1
        result.app_specs.count.should.equal 0
        result.test_specs.first.test_specification?.should.be.true
        result.test_specs.first.app_specification?.should.be.false
        result.test_specs.first.test_type.should.equal :unit
      end

      it 'can load test specification from json' do
        json = '{"testspecs": [{"name": "Tests","test_type": "unit","source_files": "Tests/**/*.{h,m}"}]}'
        result = Specification.from_json(json)
        result.non_library_specs.count.should.equal 1
        result.test_specs.count.should.equal 1
        result.app_specs.count.should.equal 0
        result.test_specs.first.test_specification?.should.be.true
        result.test_specs.first.app_specification?.should.be.false
        result.test_specs.first.test_type.should.equal :unit
      end

      it 'can load ui test specification from json' do
        json = '{"testspecs": [{"name": "Tests","test_type": "ui","source_files": "Tests/**/*.{h,m}"}]}'
        result = Specification.from_json(json)
        result.non_library_specs.count.should.equal 1
        result.test_specs.count.should.equal 1
        result.app_specs.count.should.equal 0
        result.test_specs.first.test_specification?.should.be.true
        result.test_specs.first.app_specification?.should.be.false
        result.test_specs.first.test_type.should.equal :ui
      end

      it 'can load app specification from json' do
        json = '{"appspecs": [{"name": "App","source_files": "App/**/*.{h,m}"}]}'
        result = Specification.from_json(json)
        result.app_specs.count.should.equal 1
        result.test_specs.count.should.equal 0
        result.non_library_specs.count.should.equal 1
        result.app_specs.first.app_specification?.should.be.true
        result.app_specs.first.test_specification?.should.be.false
      end

      it 'can load script phases from json' do
        json = '{"script_phases": [{"name": "Hello World", "script": "echo \"Hello World\""}]}'
        result = Specification.from_json(json)
        result.script_phases.count.should.equal 1
        result.script_phases.should == [
          { :name => 'Hello World', :script => 'echo "Hello World"', :execution_position => :any },
        ]
      end

      it 'can load on demand resources from json' do
        json = '{"on_demand_resources":{"tag1":{"paths":"Tag1Resources/*","category":"download_on_demand"},"tag2":"Tag2Resources/*","tag3":["Tag3Resources/*"]}}'
        result = Specification.from_json(json)
        result.on_demand_resources.count.should.equal 3
        result.on_demand_resources.should == {
          'tag1' => { 'paths' => 'Tag1Resources/*', 'category' => 'download_on_demand' },
          'tag2' => 'Tag2Resources/*',
          'tag3' => ['Tag3Resources/*'],
        }
      end

      it 'loads script phase execution position from json' do
        json = '{"script_phases": [{"name": "Hello World", "script": "echo \"Hello World\"", "execution_position": "before_compile"}]}'
        result = Specification.from_json(json)
        result.script_phases.count.should.equal 1
        result.script_phases.should == [
          { :name => 'Hello World', :script => 'echo "Hello World"', :execution_position => :before_compile },
        ]
      end

      it 'can load Info.plist configuration from json' do
        json = '{"info_plist": {"CFBundleIdentifier": "org.mycompany.MyLib"}}'
        result = Specification.from_json(json)
        result.info_plist.should == { 'CFBundleIdentifier' => 'org.mycompany.MyLib' }
      end

      it 'can be safely converted back and forth to a hash' do
        result = Specification.from_hash(@spec.to_hash)
        result.should == @spec
      end

      describe 'Swift Version Support' do
        it 'writes swift version in singular form' do
          @spec.swift_version = '1.0'
          hash = @spec.to_hash
          hash['swift_versions'].should == '1.0'
          hash['swift_version'].should == '1.0'
        end

        it 'writes swift version pluralized' do
          @spec.swift_versions = ['1.0']
          hash = @spec.to_hash
          hash['swift_versions'].should == ['1.0']
          hash['swift_version'].should == '1.0'
        end

        it 'does not alter the attribute hash when loading swift versions' do
          @spec.swift_versions = ['4.2', '5.0']
          first_hash = @spec.to_hash
          first_hash['swift_versions'].should == ['4.2', '5.0']
          first_hash['swift_version'].should == '5.0'
          spec_from_hash = Specification.from_hash(first_hash)
          second_hash = spec_from_hash.to_hash
          second_hash['swift_versions'].should == ['4.2', '5.0']
          second_hash['swift_version'].should == '5.0'
        end

        it 'reads swift version from a string' do
          hash = {
            'name' => 'BananaLib',
            'version' => '1.0',
            'swift_versions' => '3.2',
          }
          result = Specification.from_hash(hash)
          result.swift_versions.map(&:to_s).should == ['3.2']
        end

        it 'reads swift version from an array' do
          hash = {
            'name' => 'BananaLib',
            'version' => '1.0',
            'swift_versions' => %w(3.2 4.0),
          }
          result = Specification.from_hash(hash)
          result.swift_versions.map(&:to_s).should == %w(3.2 4.0)
        end

        it 'is backwards compatible with pre 1.7.0 swift version' do
          hash = {
            'name' => 'BananaLib',
            'version' => '1.0',
            'swift_version' => '3.2',
          }
          result = Specification.from_hash(hash)
          result.swift_versions.map(&:to_s).should == %w(3.2)
          result.swift_version.to_s.should == '3.2'
        end

        it 'combines old and new swift version declarations' do
          hash = {
            'name' => 'BananaLib',
            'version' => '1.0',
            'swift_version' => '3.2',
            'swift_versions' => %w(4.0 4.1),
          }
          result = Specification.from_hash(hash)
          result.swift_versions.map(&:to_s).should == %w(3.2 4.0 4.1)
          result.swift_version.to_s.should == '4.1'
        end

        describe 'Swift Package Manger dependencies' do
          it 'writes spm dependency' do
            @spec.spm_dependency(
              :url => 'http://github.com/foo/foo',
              :requirement => {:kind => 'upToNextMajorVersion', :minimumVersion => '1.0.0'},
              :products => ['Foo'],
            )
            hash = @spec.to_hash
            hash['spm_dependencies'].should == [
              {
                :url => 'http://github.com/foo/foo',
                :requirement => {:kind => 'upToNextMajorVersion', :minimumVersion => '1.0.0'},
                :products => ['Foo'],
              },
            ]
          end
        end
      end
    end
  end
end
