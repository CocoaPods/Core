require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe Dependency do
    describe 'In general' do
      it 'can be initialized with no requirements' do
        dependency = Dependency.new('bananas')
        expect(dependency.name).to eq('bananas')
      end

      it 'can be initialized with multiple requirements' do
        dependency = Dependency.new('bananas', '> 1.0', '< 2.0')
        expect(dependency.requirement.to_s).to eq('< 2.0, > 1.0')
      end

      it 'can be initialized with a requirement on a pre-release version' do
        dependency = Dependency.new('bananas', '> 1.0-pre')
        expect(dependency.requirement.to_s).to eq('> 1.0-pre')
      end

      it 'can be initialized with multiple requirements and a podspec source' do
        dependency = Dependency.new('bananas', '> 1.0', '< 2.0', :source => 'https://github.com/CocoaPods/CocoaPods.git')
        expect(dependency.requirement.to_s).to eq('< 2.0, > 1.0')
        expect(dependency.podspec_repo).to eq('https://github.com/CocoaPods/CocoaPods.git')
      end

      it 'can be initialized with a requirement on a pre-release version and a podspec source' do
        dependency = Dependency.new('bananas', '> 1.0-pre', :source => 'https://github.com/CocoaPods/CocoaPods.git')
        expect(dependency.requirement.to_s).to eq('> 1.0-pre')
        expect(dependency.podspec_repo).to eq('https://github.com/CocoaPods/CocoaPods.git')
      end

      it 'can be initialized with an external source' do
        dep = Dependency.new('cocoapods', :git => 'git://github.com/cocoapods/cocoapods')
        expect(dep).to be_external
      end

      it 'can be initialized with an empty external source and not be considered external' do
        dep = Dependency.new('cocoapods', :git => nil)
        expect(dep).not_to be_external
      end

      it 'knows if it is local' do
        dep = Dependency.new('cocoapods', :path => '/tmp/cocoapods')
        expect(dep).to be_local
      end

      it "says it isn't local if nothing was passed in" do
        dep = Dependency.new('cocoapods')
        expect(dep).not_to be_local
      end

      it 'raises if initialized with an external source and requirements are provided' do
        expect do
          Dependency.new('cocoapods', '1.0', :git => 'git://github.com/cocoapods/cocoapods')
        end.to raise_error(Informative)
      end

      describe '#from_string' do
        it 'creates a dependency from a string' do
          d = Dependency.from_string('BananaLib (1.0)')
          expect(d.name).to eq('BananaLib')
          expect(d.requirement).to be_satisfied_by(Version.new('1.0'))
          expect(d.external_source).to be_nil
        end

        it 'creates a dependency from a string with multiple version requirements' do
          d = Dependency.from_string('FontAwesomeIconFactory (< 2.0, >= 1.0.1)')
          expect(d.name).to eq('FontAwesomeIconFactory')
          expect(d.requirement).to eq(Requirement.new('< 2.0', '>= 1.0.1'))
        end

        it "doesn't include external source when initialized from a string as incomplete and thus it should be provided by the client" do
          d = Dependency.from_string("BananaLib (from `www.example.com', tag `1.0')")
          expect(d.name).to eq('BananaLib')
          expect(d.requirement).to be_none
          expect(d.external?).to be(false)
        end

        it 'handles strings with no requirements' do
          d = Dependency.from_string('AFNetworking')
          expect(d.name).to eq('AFNetworking')
          expect(d.requirement).to be_none
        end

        it 'handles names with a space' do
          d = Dependency.from_string('RestKit/Subspec JSON (= 1.0)')
          expect(d.name).to eq('RestKit/Subspec JSON')
          expect(d.requirement).to eq(Requirement.new('= 1.0'))
        end

        it 'handles names with a space and external source' do
          d = Dependency.from_string("RestKit/Subspec JSON (from `www.example.com', tag `1.0')")
          expect(d.requirement).to be_none
          expect(d.external?).to be(false)
        end

        it 'handles names with a space and no requirements' do
          d = Dependency.from_string('RestKit/Subspec JSON')
          expect(d.name).to eq('RestKit/Subspec JSON')
          expect(d.requirement).to be_none
        end
      end

      it 'includes the external sources in the string representation' do
        dependency = Dependency.new('cocoapods', :hg => 'example.com')
        expect(dependency.to_s).to eq('cocoapods (from `example.com`)')
      end

      it 'raises if version requirements are specified for an external source' do
        expect do
          Dependency.new('cocoapods', '1.2.3', :git => 'example.com')
        end.to raise_error(Pod::Informative)
      end

      it 'raises if an invalid initialization flag is given' do
        expect do
          Dependency.new('cocoapods', :foot)
        end.to raise_error(ArgumentError)
      end

      it 'can store a specific version which is used in place of the requirements' do
        dependency = Dependency.new('cocoapods', '> 1.0')
        dependency.specific_version = Version.new('1.23')
        expect(dependency.requirement.as_list).to eq(['= 1.23'])
      end

      #--------------------------------------#

      it 'preserves the external source on duplication' do
        dep = Dependency.new('bananas', :podspec => 'bananas')
        expect(dep.dup.external_source).to eq({ :podspec => 'bananas' })
      end

      #--------------------------------------#

      it 'returns the name of the dependency, or the name of the pod of which this is a subspec' do
        dep = Dependency.new('RestKit')
        expect(dep.root_name).to eq('RestKit')
        dep = Dependency.new('RestKit/Networking')
        expect(dep.root_name).to eq('RestKit')
      end

      it 'returns a copy of the dependency but for the top level spec, if it is a subspec' do
        dep = Dependency.new('RestKit', '>= 1.2.3')
        expect(dep.to_root_dependency).to eq(Dependency.new('RestKit', '>= 1.2.3'))
        dep = Dependency.new('RestKit/Networking', '>= 1.2.3')
        expect(dep.to_root_dependency).to eq(Dependency.new('RestKit', '>= 1.2.3'))
      end

      #--------------------------------------#

      it 'returns whether it is compatible with another dependency' do
        dep1 = Dependency.new('bananas', '>= 1.8')
        dep2 = Dependency.new('bananas', '1.9')
        expect(dep1.compatible?(dep2)).to be(true)
      end

      it 'is not compatible with another dependency with non satisfied version requirements' do
        dep1 = Dependency.new('bananas', '> 1.9')
        dep2 = Dependency.new('bananas', '1.9')
        expect(dep1.compatible?(dep2)).to be(false)
      end

      it 'is not compatible with another if the external sources differ' do
        dep1 = Dependency.new('bananas', :podspec => 'bananas')
        dep2 = Dependency.new('bananas', '1.9')
        expect(dep1.compatible?(dep2)).to be(false)
      end

      #--------------------------------------#

      it 'is equal to another dependency if `external_source` is the same' do
        dep1 = Dependency.new('bananas', :git => 'GIT-URL')
        dep2 = Dependency.new('bananas')
        expect(dep1).not_to eq(dep2)
        dep3 = Dependency.new('bananas', :git => 'GIT-URL')
        expect(dep1).to eq(dep3)
      end

      it 'is equal to another dependency if `podspec_repo` is the same' do
        dep1 = Dependency.new('bananas', :source => 'GIT-URL')
        dep2 = Dependency.new('bananas')
        expect(dep1).not_to eq(dep2)
        dep3 = Dependency.new('bananas', :source => 'GIT-URL')
        expect(dep1).to eq(dep3)
      end

      it 'supports Array#uniq' do
        d_1 = Dependency.new('bananas')
        d_2 = Dependency.new('bananas')
        expect([d_1, d_2].uniq).to eq([d_1])
      end

      #--------------------------------------#

      it 'is able to match against proper SemVer pre-release versions' do
        dep = Dependency.new('bananas', '< 2.0.0')
        expect do
          dep.match?('bananas', '2.0.0-rc1')
        end.not_to raise_error
      end

      #--------------------------------------#

      it 'merges with another dependency' do
        dep1 = Dependency.new('bananas', '>= 1.8')
        dep2 = Dependency.new('bananas', '1.9')
        expect(dep1.merge(dep2)).to eq(Dependency.new('bananas', '>= 1.8', '1.9'))
      end

      it 'it preserves the external source while merging with another dependency' do
        dep1 = Dependency.new('bananas', '1.9')
        dep2 = Dependency.new('bananas', :podspec => 'bananas')

        result = dep1.merge(dep2)
        expect(result).to be_external
        expect(result.requirement.as_list).to eq(['= 1.9'])

        result = dep2.merge(dep1)
        expect(result).to be_external
        expect(result.requirement.as_list).to eq(['= 1.9'])
      end

      it 'raises if there is an attempt to merge with a dependency with a different name' do
        expect do
          dep1 = Dependency.new('bananas', '>= 1.8')
          dep2 = Dependency.new('orange', '1.9')
          dep1.merge(dep2)
        end.to raise_error(ArgumentError)
      end

      it 'preserves the podspec repo while merging' do
        dep1 = Dependency.new('bananas', '~> 1.9')
        dep2 = Dependency.new('bananas', :source => 'https://source.git')

        expected = Dependency.new('bananas', '~> 1.9', :source => 'https://source.git')
        expect(dep1.merge(dep2)).to eq(expected)
        expect(dep2.merge(dep1)).to eq(expected)
      end

      it 'raises if there is an attempt to merge with two different podspec repos' do
        expect do
          dep1 = Dependency.new('bananas', :source => 'https://other.git')
          dep2 = Dependency.new('bananas', :source => 'https://source.git')

          dep1.merge(dep2)
        end.to raise_error(ArgumentError)
      end

      it 'allows merging if both dependencies have the same podspec repo' do
        dep1 = Dependency.new('bananas', '~> 1.9', :source => 'https://source.git')
        dep2 = Dependency.new('bananas', :source => 'https://source.git')

        expected = Dependency.new('bananas', '~> 1.9', :source => 'https://source.git')
        expect(dep1.merge(dep2)).to eq(expected)
        expect(dep2.merge(dep1)).to eq(expected)
      end

      it 'raises when attempting to merge with a podspec repo and external source' do
        expect do
          dep1 = Dependency.new('bananas', :git => 'https://other.git')
          dep2 = Dependency.new('bananas', :source => 'https://source.git')

          dep1.merge(dep2)
        end.to raise_error(Informative)
      end

      it 'prefers the right hand side when external source keys overlap' do
        dep1 = Dependency.new('bananas', :git => 'https://other.git')
        dep2 = Dependency.new('bananas', :git => 'https://other/1.git')

        expect(dep1.merge(dep2)).to eq(Dependency.new('bananas', :git => 'https://other/1.git'))
        expect(dep2.merge(dep1)).to eq(Dependency.new('bananas', :git => 'https://other.git'))
      end

      #--------------------------------------#

      it 'returns whether a dependency has pre-release requirements' do
        expect(Dependency.new('A')).not_to be_prerelease
        expect(Dependency.new('A', '1.0')).not_to be_prerelease
        expect(Dependency.new('A', '1.0', '< 3')).not_to be_prerelease

        expect(Dependency.new('A', '1.beta')).to be_prerelease
        expect(Dependency.new('A', '~> 1.0.0.beta')).to be_prerelease
        expect(Dependency.new('A', '~> 2', '< 1.0.0.beta')).to be_prerelease
      end

      #--------------------------------------#

      it 'matches a specification with the correct name' do
        dep = Dependency.new('bananas', '1.0')
        expect(dep.match?('bananas', '1.0')).to be_truthy
        expect(dep.match?('bananas', '1')).to be_truthy
        expect(dep.match?('bananas', '1.0.0')).to be_truthy
        expect(dep.match?('orange', '1.0')).to be_falsey
      end

      it 'matches any version if no requirements are provided' do
        dep = Dependency.new('bananas')
        expect(dep.match?('bananas', '1.0')).to be_truthy
      end

      it 'matches a specification with the correct version if requirements are provided' do
        dep = Dependency.new('bananas', '> 0.5')
        expect(dep.match?('bananas', '1.0')).to be_truthy
        expect(dep.match?('bananas', '1.0.0')).to be_truthy
        expect(dep.match?('bananas', '0.1')).to be_falsey
      end

      it 'matches a specification regardless of version specificity' do
        dep = Dependency.new('bananas', '~> 1.0.0')
        expect(dep.match?('bananas', '1.0')).to be_truthy
        expect(dep.match?('bananas', '1')).to be_truthy
        expect(dep.match?('bananas', '1.0.0.0')).to be_truthy

        dep = Dependency.new('bananas', '~> 1.0.0-a')
        expect(dep.match?('bananas', '1.0.0.0-a')).to be_truthy
        expect(dep.match?('bananas', '1.0.0-a')).to be_truthy
        expect(dep.match?('bananas', '1.0-a')).to be_truthy
      end

      it 'matching supports the comparison with pre-release version' do
        dep = Dependency.new('bananas', '> 0.5')
        expect(dep.match?('bananas', '1.0-rc1')).to be(true)
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Private helpers' do
      before do
        @dep = Dependency.new('bananas', '1.9')
      end

      describe '#external_source_description' do
        it 'returns the description of git sources' do
          source = {
            :git => 'example.com/repo.git',
            :branch => 'master',
            :commit => 'SHA',
            :tag => '1.0.0',
          }
          description = @dep.send(:external_source_description, source)
          expect(description).to eq('from `example.com/repo.git`, commit `SHA`, branch `master`, tag `1.0.0`')
        end

        it 'returns the description of other sources' do
          expect(@dep.send(:external_source_description, :hg => 'example.com')).to eq('from `example.com`')
          expect(@dep.send(:external_source_description, :svn => 'example.com')).to eq('from `example.com`')
          expect(@dep.send(:external_source_description, :podspec => 'example.com')).to eq('from `example.com`')
          expect(@dep.send(:external_source_description, :path => 'example.com')).to eq('from `example.com`')
          expect(@dep.send(:external_source_description, :other => 'example.com')).to match(/from.*example.com/)
        end
      end
    end

    #-------------------------------------------------------------------------#
  end
end
