require File.expand_path('../spec_helper', __FILE__)

module Pod
  class Sample
    extend SpecHelper::Fixture

    def self.yaml
      <<-LOCKFILE.strip_heredoc
        PODS:
          - BananaLib (1.0):
            - monkey (< 1.0.9, ~> 1.0.1)
          - JSONKit (1.4)
          - monkey (1.0.8)

        DEPENDENCIES:
          - BananaLib (~> 1.0)
          - JSONKit (from `path/JSONKit.podspec`)

        SPEC REPOS:
          trunk:
            - BananaLib
            - monkey

        EXTERNAL SOURCES:
          JSONKit:
            :podspec: path/JSONKit.podspec

        CHECKOUT OPTIONS:
          JSONKit:
            :podspec: path/JSONKit.podspec

        SPEC CHECKSUMS:
          BananaLib: d46ca864666e216300a0653de197668b12e732a1
          JSONKit: 92ae5f71b77c8dec0cd8d0744adab79d38560949

        PODFILE CHECKSUM: podfile_checksum

        COCOAPODS: #{CORE_VERSION}
      LOCKFILE
    end

    def self.quotation_marks_yaml
      <<-LOCKFILE.strip_heredoc
        PODS:
          - BananaLib (1.0):
            - monkey (< 1.0.9, ~> 1.0.1)
          - JSONKit (1.4)
          - monkey (1.0.8)

        DEPENDENCIES:
          - BananaLib (~> 1.0)
          - JSONKit (from `path/JSONKit.podspec`)

        SPEC REPOS:
          trunk:
            - BananaLib
            - monkey

        EXTERNAL SOURCES:
          JSONKit:
            :podspec: "path/JSONKit.podspec"

        CHECKOUT OPTIONS:
          JSONKit:
            :podspec: path/JSONKit.podspec

        SPEC CHECKSUMS:
          BananaLib: d46ca864666e216300a0653de197668b12e732a1
          JSONKit: '92ae5f71b77c8dec0cd8d0744adab79d38560949'

        PODFILE CHECKSUM: podfile_checksum

        COCOAPODS: #{CORE_VERSION}
      LOCKFILE
    end

    def self.podfile
      podfile = Podfile.new do
        platform :ios
        pod 'BananaLib', '~>1.0'
        pod 'JSONKit', :podspec => 'path/JSONKit.podspec'
      end
      podfile.stubs(:checksum).returns('podfile_checksum')
      podfile
    end

    def self.specs
      repo_path      = 'spec-repos/test_repo/'
      bananalib_path = repo_path + 'Specs/BananaLib/1.0/BananaLib.podspec'
      jsonkit_path   = repo_path + 'Specs/JSONKit/1.4/JSONKit.podspec'

      specs = [
        Specification.from_file(fixture(bananalib_path)),
        Specification.from_file(fixture(jsonkit_path)),
        Specification.new do |s|
          s.name = 'monkey'
          s.version = '1.0.8'
        end,
      ]
      specs
    end

    def self.checkout_options
      {
        'JSONKit' => {
          :podspec => 'path/JSONKit.podspec',
        },
      }
    end

    def self.specs_by_source
      {
        TrunkSource.new(fixture('spec-repos/trunk')) => specs.reject { |s| s.name == 'JSONKit' },
        Source.new(fixture('spec-repos/test_repo')) => [],
      }
    end
  end

  #---------------------------------------------------------------------------#

  describe Lockfile do
    describe 'In general' do
      extend SpecHelper::TemporaryDirectory

      before do
        @tmp_path = temporary_directory + 'Podfile.lock'
      end

      it 'stores the initialization hash' do
        lockfile = Lockfile.new(YAMLHelper.load_string(Sample.yaml))
        expect(lockfile.internal_data).to eq(YAMLHelper.load_string(Sample.yaml))
      end

      it 'loads from a file' do
        File.open(@tmp_path, 'w') { |f| f.write(Sample.yaml) }
        lockfile = Lockfile.from_file(@tmp_path)
        expect(lockfile.internal_data).to eq(YAMLHelper.load_string(Sample.yaml))
      end

      it "returns nil if it can't find the initialization file" do
        lockfile = Lockfile.from_file(temporary_directory + 'Podfile.lock_not_existing')
        expect(lockfile).to be_nil
      end

      it 'returns the file in which is defined' do
        File.open(@tmp_path, 'w') { |f| f.write(Sample.yaml) }
        lockfile = Lockfile.from_file(@tmp_path)
        expect(lockfile.defined_in_file).to eq(@tmp_path)
      end

      it "raises if the provided YAML doesn't returns a hash" do
        File.open(@tmp_path, 'w') { |f| f.write('value') }
        expect do
          Lockfile.from_file(@tmp_path)
        end.to raise_error(Informative, /Invalid Lockfile/)
      end

      #--------------------------------------#

      before do
        @lockfile = Lockfile.generate(Sample.podfile, Sample.specs, Sample.checkout_options, Sample.specs_by_source)
      end

      it 'returns whether it is equal to another' do
        podfile = Podfile.new do
          platform :ios
          pod 'BananaLib', '~>1.0'
        end
        expect(@lockfile).to eq(@lockfile)
        expect(@lockfile).not_to eq(Lockfile.generate(podfile, Sample.specs, Sample.checkout_options, Sample.specs_by_source))
      end

      it 'returns the list of the names of the  installed pods' do
        expect(@lockfile.pod_names).to eq(%w(BananaLib JSONKit monkey))
      end

      it 'returns the versions of a given pod' do
        expect(@lockfile.version('BananaLib')).to eq(Version.new('1.0'))
        expect(@lockfile.version('JSONKit')).to eq(Version.new('1.4'))
        expect(@lockfile.version('monkey')).to eq(Version.new('1.0.8'))
      end

      it 'returns the versions of a given pod handling the case in which the root spec was not stored' do
        @lockfile.stubs(:pod_versions).returns('BananaLib/Subspec' => Version.new(1.0))
        expect(@lockfile.version('BananaLib')).to eq(Version.new('1.0'))
      end

      it 'returns the spec repo of a given pod' do
        expect(@lockfile.spec_repo('BananaLib')).to eq('trunk')
        expect(@lockfile.spec_repo('JSONKit')).to be_nil
        expect(@lockfile.spec_repo('monkey')).to eq('trunk')
      end

      it 'returns the checksum for the given Pod' do
        expect(@lockfile.checksum('BananaLib')).to eq('d46ca864666e216300a0653de197668b12e732a1')
      end

      it 'returns the dependencies used for the last installation' do
        json_dep = Dependency.new('JSONKit')
        json_dep.external_source = { :podspec => 'path/JSONKit.podspec' }
        expect(@lockfile.dependencies).to eq([
          Dependency.new('BananaLib', '~>1.0'),
          json_dep,
        ])
      end

      it 'returns the spec repo sources' do
        expect(@lockfile.pods_by_spec_repo).to eq(Hash[Sample.specs_by_source.map do |source, specs|
          next unless source.name == 'trunk'
          ['trunk', specs.map(&:name)]
        end.compact])
      end

      it 'returns the spec repo sources when that section is missing' do
        @lockfile = Lockfile.new({})
        expect(@lockfile.pods_by_spec_repo).to eq({})
      end

      it 'only includes root names in spec repo sources' do
        @lockfile = Lockfile.generate(Sample.podfile, [], {}, TrunkSource.new(fixture('spec-repos/trunk')) => Pod::Spec.new do |s|
                                                                                                                s.name = 'foo'
                                                                                                                s.version = '1.0.0'
                                                                                                                s.subspec 'Core'
                                                                                                                s.subspec 'NotCore'
                                                                                                              end.recursive_subspecs)
        expect(@lockfile.pods_by_spec_repo).to eq({
          'trunk' => %w(foo),
        })
      end

      it 'includes the external source information in the generated dependencies' do
        dep = @lockfile.dependencies.find { |d| d.name == 'JSONKit' }
        expect(dep.external_source).to eq({ :podspec => 'path/JSONKit.podspec' })
      end

      it 'returns the dependency that locks the pod with the given name to the installed version' do
        json_dep = Dependency.new('JSONKit', '1.4')
        json_dep.external_source = { :podspec => 'path/JSONKit.podspec' }
        result = @lockfile.dependencies_to_lock_pod_named('JSONKit')
        expect(result).to eq([json_dep])
      end

      it 'raises if there is a request for a locking dependency for a not stored Pod' do
        expect do
          @lockfile.dependencies_to_lock_pod_named('Missing')
        end.to raise_error(StandardError, /without a known dependency/)
      end

      it 'returns the version of CocoaPods which generated the lockfile' do
        expect(@lockfile.cocoapods_version).to eq(Version.new(CORE_VERSION))
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Comparison with a Podfile' do
      before do
        @podfile = Podfile.new do
          platform :ios
          pod 'BlocksKit'
          pod 'JSONKit'
        end
        @specs = [
          Specification.new do |s|
            s.name = 'BlocksKit'
            s.version = '1.0.0'
          end,
          Specification.new do |s|
            s.name = 'JSONKit'
            s.version = '1.4'
          end]
        @checkout_options = {}
        @specs_by_source = {}
        @lockfile = Lockfile.generate(@podfile, @specs, @checkout_options, @specs_by_source)
      end

      it 'detects an added Pod' do
        podfile = Podfile.new do
          platform :ios
          pod 'BlocksKit'
          pod 'JSONKit'
          pod 'TTTAttributedLabel'
        end
        expect(@lockfile.detect_changes_with_podfile(podfile)).to eq({
          :changed => [],
          :removed => [],
          :unchanged => %w(BlocksKit JSONKit),
          :added => ['TTTAttributedLabel'],
        })
      end

      it 'detects a removed Pod' do
        podfile = Podfile.new do
          platform :ios
          pod 'BlocksKit'
        end
        expect(@lockfile.detect_changes_with_podfile(podfile)).to eq({
          :changed => [],
          :removed => ['JSONKit'],
          :unchanged => ['BlocksKit'],
          :added => [],
        })
      end

      it 'detects Pods whose version changed' do
        podfile = Podfile.new do
          platform :ios
          pod 'BlocksKit'
          pod 'JSONKit', '> 1.4'
        end
        expect(@lockfile.detect_changes_with_podfile(podfile)).to eq({
          :changed => ['JSONKit'],
          :removed => [],
          :unchanged => ['BlocksKit'],
          :added => [],
        })
      end

      it "it doesn't mark as changed Pods whose version changed but is still compatible with the Podfile" do
        podfile = Podfile.new do
          platform :ios
          pod 'BlocksKit'
          pod 'JSONKit', '> 1.0'
        end
        expect(@lockfile.detect_changes_with_podfile(podfile)).to eq({
          :changed => [],
          :removed => [],
          :unchanged => %w(BlocksKit JSONKit),
          :added => [],
        })
      end

      it 'detects Pods whose external source changed' do
        podfile = Podfile.new do
          platform :ios
          pod 'BlocksKit'
          pod 'JSONKit', :git => 'example1.com'
        end
        expect(@lockfile.detect_changes_with_podfile(podfile)).to eq({
          :changed => ['JSONKit'],
          :removed => [],
          :unchanged => ['BlocksKit'],
          :added => [],
        })
        @lockfile = Lockfile.generate(podfile, @specs, @checkout_options, @specs_by_source)
        podfile = Podfile.new do
          platform :ios
          pod 'BlocksKit'
          pod 'JSONKit', :git => 'example2.com'
        end
        expect(@lockfile.detect_changes_with_podfile(podfile)).to eq({
          :changed => ['JSONKit'],
          :removed => [],
          :unchanged => ['BlocksKit'],
          :added => [],
        })
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Serialization' do
      extend SpecHelper::TemporaryDirectory

      before do
        @lockfile = Lockfile.generate(Sample.podfile, Sample.specs, Sample.checkout_options, Sample.specs_by_source)
      end

      it 'can be store itself at the given path' do
        path = SpecHelper.temporary_directory + 'Podfile.lock'
        @lockfile.write_to_disk(path)
        loaded = Lockfile.from_file(path)
        expect(loaded).to eq(@lockfile)
      end

      it "won't write to disk if the equivalent lockfile is already there" do
        path = SpecHelper.temporary_directory + 'Podfile.lock'
        old_yaml = %(---\nhi: "./hi"\n)
        path.open('w') { |f| f.write old_yaml }
        @lockfile.stubs(:to_hash).returns('hi' => './hi')
        @lockfile.stubs(:to_yaml).returns("---\nhi: ./hi\n")
        path.expects(:open).with('w').never
        @lockfile.write_to_disk(path)
        expect(path.read).to eq(old_yaml)
      end

      it 'overwrites a different lockfile' do
        path = SpecHelper.temporary_directory + 'Podfile.lock'
        path.delete if path.exist?
        @lockfile.write_to_disk(path)

        @lockfile = Lockfile.new('COCOAPODS' => '0.0.0')
        @lockfile.write_to_disk(path)

        expect(@lockfile).to eq(Lockfile.from_file(path))
      end

      it 'fix strange quotation marks in lockfile' do
        yaml_string = Sample.quotation_marks_yaml
        yaml_string = yaml_string.tr("'", '')
        yaml_string = yaml_string.tr('"', '')
        expect(yaml_string).to eq(Sample.yaml)
      end

      it 'generates a hash representation' do
        hash = @lockfile.to_hash
        expect(hash).to eq({
          'PODS' => [
            { 'BananaLib (1.0)' => ['monkey (< 1.0.9, ~> 1.0.1)'] },
            'JSONKit (1.4)', 'monkey (1.0.8)'],
          'DEPENDENCIES' => ['BananaLib (~> 1.0)', 'JSONKit (from `path/JSONKit.podspec`)'],
          'SPEC REPOS' => { 'trunk' => %w(BananaLib monkey) },
          'EXTERNAL SOURCES' => { 'JSONKit' => { :podspec => 'path/JSONKit.podspec' } },
          'CHECKOUT OPTIONS' => { 'JSONKit' => { :podspec => 'path/JSONKit.podspec' } },
          'SPEC CHECKSUMS' => { 'BananaLib' => 'd46ca864666e216300a0653de197668b12e732a1', 'JSONKit' => '92ae5f71b77c8dec0cd8d0744adab79d38560949' },
          'PODFILE CHECKSUM' => 'podfile_checksum',
          'COCOAPODS' => CORE_VERSION,
        })
      end

      it 'handles when the podfile has no checksum' do
        podfile = Sample.podfile
        podfile.stubs(:checksum).returns(nil)
        @lockfile = Lockfile.generate(podfile, Sample.specs, Sample.checkout_options, Sample.specs_by_source)
        expect(@lockfile.to_hash).not_to have_key('PODFILE CHECKSUM')
      end

      it 'generates an ordered YAML representation' do
        expect(@lockfile.to_yaml).to eq(Sample.yaml)
      end

      it 'generates a valid YAML representation' do
        expect(YAMLHelper.load_string(@lockfile.to_yaml)).to eq(YAMLHelper.load_string(Sample.yaml))
      end

      it 'serializes correctly external dependencies' do
        podfile = Podfile.new do
          platform :ios
          pod 'BananaLib',  :git => 'www.example.com', :tag => '1.0'
        end
        specs = [
          Specification.new do |s|
            s.name = 'BananaLib'
            s.version = '1.0'
          end,
          Specification.new do |s|
            s.name = 'monkey'
            s.version = '1.0.8'
          end,
        ]
        checkout_options = {
          'BananaLib' => { :git => 'www.example.com', :tag => '1.0' },
        }
        specs_by_source = { TrunkSource.new(fixture('spec-repos/trunk')) => specs.select { |s| s.name == 'monkey' } }
        lockfile = Lockfile.generate(podfile, specs, checkout_options, specs_by_source)
        expect(lockfile.internal_data['DEPENDENCIES'][0]).to eq('BananaLib (from `www.example.com`, tag `1.0`)')
        expect(lockfile.internal_data['EXTERNAL SOURCES']['BananaLib']).to eq({ :git => 'www.example.com', :tag => '1.0' })
      end

      describe 'when the Podfile is empty' do
        before do
          @lockfile = Lockfile.generate(Podfile.new, [], [], {})
        end

        it 'generates a lockfile with only the version' do
          expect(@lockfile.to_yaml).to eq("COCOAPODS: #{CORE_VERSION}\n")
        end
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Generation from a Podfile' do
      before do
        @lockfile = Lockfile.generate(Sample.podfile, Sample.specs, Sample.checkout_options, Sample.specs_by_source)
      end

      it 'stores the information of the installed pods and of their dependencies' do
        expect(@lockfile.internal_data['PODS']).to eq([
          { 'BananaLib (1.0)' => ['monkey (< 1.0.9, ~> 1.0.1)'] },
          'JSONKit (1.4)',
          'monkey (1.0.8)',
        ])
      end

      it 'stores the information of the dependencies of the Podfile' do
        expect(@lockfile.internal_data['DEPENDENCIES']).to eq([
          'BananaLib (~> 1.0)', 'JSONKit (from `path/JSONKit.podspec`)'
        ])
      end

      it 'stores the information of the external sources' do
        expect(@lockfile.internal_data['EXTERNAL SOURCES']).to eq({
          'JSONKit' => { :podspec => 'path/JSONKit.podspec' },
        })
      end

      it 'stores the checksum of the specifications' do
        expect(@lockfile.internal_data['SPEC CHECKSUMS']).to eq({
          'BananaLib' => 'd46ca864666e216300a0653de197668b12e732a1',
          'JSONKit' => '92ae5f71b77c8dec0cd8d0744adab79d38560949',
        })
      end

      it 'store the version of the CocoaPods Core gem' do
        expect(@lockfile.internal_data['COCOAPODS']).to eq(CORE_VERSION)
      end

      it 'it includes all the information that it is expected to store' do
        expect(@lockfile.internal_data).to eq(YAMLHelper.load_string(Sample.yaml))
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Private helpers' do
      describe '#generate_pods_data' do
        it 'groups multiple dependencies for the same pod' do
          specs = [
            Specification.new do |s|
              s.name = 'BananaLib'
              s.version = '1.0'
              s.dependency 'monkey', '< 1.0.9'
            end,
            Specification.new do |s|
              s.name = 'BananaLib'
              s.version = '1.0'
              s.dependency 'tree', '~> 1.0.1'
            end,
          ]
          pods_data = Lockfile.send(:generate_pods_data, specs)
          expect(pods_data).to eq([
            { 'BananaLib (1.0)' => ['monkey (< 1.0.9)', 'tree (~> 1.0.1)'] },
          ])
        end

        it 'sort pods by lowercase' do
          specs = [
            Specification.new do |s|
              s.name = 'a'
              s.version = '1.0'
              s.dependency 'monkey', '< 1.0.9'
            end,
            Specification.new do |s|
              s.name = 'b'
              s.version = '1.0'
            end,
            Specification.new do |s|
              s.name = 'C'
              s.version = '1.0'
              s.dependency 'tree', '~> 1.0.1'
            end,
          ]
          pods_data = Lockfile.send(:generate_pods_data, specs)
          expect(pods_data).to eq([
            { 'a (1.0)' => ['monkey (< 1.0.9)'] },
            'b (1.0)',
            { 'C (1.0)' => ['tree (~> 1.0.1)'] },
          ])
        end

        it 'sorts dependencies for the pod by lowercase' do
          specs = [
            Specification.new do |s|
              s.name = 'BananaLib'
              s.version = '1.0'
              s.dependency 'a', '< 1.0.9'
            end,
            Specification.new do |s|
              s.name = 'BananaLib'
              s.version = '1.0'
              s.dependency 'b', '< 1.0.8'
            end,
            Specification.new do |s|
              s.name = 'BananaLib'
              s.version = '1.0'
              s.dependency 'C', '~> 1.0.1'
            end,
          ]
          pods_data = Lockfile.send(:generate_pods_data, specs)
          expect(pods_data).to eq([
            { 'BananaLib (1.0)' => ['a (< 1.0.9)', 'b (< 1.0.8)', 'C (~> 1.0.1)'] },
          ])
        end
      end

      describe '#generate_dependencies_data' do
        it 'sorts dependencies by lowercase' do
          podfile = Podfile.new do
            pod 'a'
            pod 'b'
            pod 'C'
          end
          dependencies_data = Lockfile.send(:generate_dependencies_data, podfile)
          expect(dependencies_data).to eq(%w(a b C))
        end
      end

      describe '#generate_spec_repos' do
        it 'sorts specs per spec repo by lowercase' do
          spec_repos = {
            TrunkSource.new(fixture('spec-repos/trunk')) => [
              Specification.new do |s|
                s.name = 'a'
                s.version = '1.0'
              end,
              Specification.new do |s|
                s.name = 'b'
                s.version = '1.0'
              end,
              Specification.new do |s|
                s.name = 'C'
                s.version = '1.0'
              end,
            ],
          }
          spec_repos_data = Lockfile.send(:generate_spec_repos, spec_repos)
          expect(spec_repos_data).to eq({ 'trunk' => %w(a b C) })
        end
      end

      describe '#generate_spec_repos_with_duplicated_source' do
        it 'merges specs if sources have same key' do
          spec_repos = {
            Source.new(fixture('spec-repos/trunk')) => [
              Specification.new do |s|
                s.name = 'a'
                s.version = '1.0'
              end,
              Specification.new do |s|
                s.name = 'b'
                s.version = '1.0'
              end,
              Specification.new do |s|
                s.name = 'C'
                s.version = '1.0'
              end,
            ],
            Source.new(fixture('spec-repos/trunk')) => [
              Specification.new do |s|
                s.name = 'd'
                s.version = '1.0'
              end,
              Specification.new do |s|
                s.name = 'E'
                s.version = '1.0'
              end,
            ],
          }
          spec_repos_data = Lockfile.send(:generate_spec_repos, spec_repos)
          expect(spec_repos_data).to eq({ 'trunk' => %w(a b C d E) })
        end
      end
    end
  end
end
