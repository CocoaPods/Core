require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe Specification do
    describe 'In general' do
      before do
        @spec = Spec.new do |s|
          s.name = 'Pod'
          s.version = '1.0'
          s.subspec 'Subspec' do |_sp|
          end
        end
        @subspec = @spec.subspecs.first
      end

      it 'returns the parent' do
        expect(@subspec.parent).to eq(@spec)
      end

      it 'returns the attributes hash' do
        expect(@spec.attributes_hash).to eq({ 'name' => 'Pod', 'version' => '1.0' })
        expect(@subspec.attributes_hash).to eq({ 'name' => 'Subspec' })
      end

      it 'returns the subspecs' do
        expect(@spec.subspecs).to eq([@subspec])
      end

      it 'allows dup-ing' do
        dup = @spec.dup
        expect(dup.subspecs.first.parent).to be(dup)
      end

      it 'returns whether it is equal to another specification' do
        expect(@spec).to eq(@spec)
      end

      it 'is not equal to another specification if the name is different' do
        expect(@spec).not_to eq(Spec.new do |s|
          s.name = 'Seed'
          s.version = '1.0'
        end)
      end

      it 'is not equal to another specification if the version if different' do
        expect(@spec).not_to eq(Spec.new do |s|
          s.name = 'Pod'
          s.version = '2.0'
        end)
      end

      it 'is equal to another if the name and the version match regardless of the attributes' do
        expect(@spec).to eq(Spec.new do |s|
          s.name = 'Pod'
          s.version = '1.0'
          s.source_files = 'Classes'
        end)
      end

      it 'provides support for Array#uniq' do
        spec_1 = Spec.new do |s|
          s.name = 'Pod'
          s.version = '1.0'
        end
        spec_2 = Spec.new do |s|
          s.name = 'Pod'
          s.version = '1.0'
        end
        expect([spec_1, spec_2].uniq.count).to eq(1)
      end

      it 'provides support for being used as a the key of a Hash' do
        spec_1 = Spec.new do |s|
          s.name = 'Pod'
          s.version = '1.0'
        end
        spec_2 = Spec.new do |s|
          s.name = 'Pod'
          s.version = '1.0'
        end
        hash = {}
        hash[spec_1] = 'VALUE_1'
        hash[spec_2] = 'VALUE_2'
        expect(hash[spec_1]).to eq('VALUE_2')
      end

      it 'strips newlines from versions' do
        spec = Spec.new do |s|
          s.name = 'Pod'
          s.version = "1.2.0\n"
        end

        expect(spec.to_hash['version']).to eq('1.2.0')
      end

      it 'resets hash value when name changes' do
        expect(@spec.hash_value).to be_nil
        original_hash = @spec.hash
        expect(@spec.hash_value).not_to be_nil
        @spec.name = 'NewPodName'
        expect(@spec.hash_value).to be_nil
        new_hash = @spec.hash
        expect(original_hash).not_to eq(new_hash)
      end

      it 'resets hash value when version changes' do
        expect(@spec.hash_value).to be_nil
        original_hash = @spec.hash
        expect(@spec.hash_value).not_to be_nil
        @spec.version = '1.1'
        expect(@spec.hash_value).to be_nil
        new_hash = @spec.hash
        expect(original_hash).not_to eq(new_hash)
      end

      describe '#to_s' do
        it 'produces a string representation suitable for UI output.' do
          expect(@spec.to_s).to eq('Pod (1.0)')
        end

        it 'handles invalid version strings' do
          @spec.version = '{SOME_VERSION}'
          expect(@spec.to_s).to eq('Pod ({SOME_VERSION})')
        end

        it 'includes the version in subspecs' do
          expect(@subspec.to_s).to eq('Pod/Subspec (1.0)')
        end

        it 'includes malformed versions in subspecs' do
          @spec.version = '{SOME_VERSION}'
          expect(@subspec.to_s).to eq('Pod/Subspec ({SOME_VERSION})')
        end
      end

      it 'handles the case where no version is available in the string representation' do
        spec_1 = Spec.new { |s| s.name = 'Pod' }
        expect(spec_1.to_s).to eq('Pod')
      end

      it 'handles the case where no name is available in the string representation' do
        spec_1 = Spec.new
        expect(spec_1.to_s).to eq('No-name')
      end

      it 'returns any empty array without any script phases' do
        spec = @spec.dup
        expect(spec.script_phases).to eq([])
      end

      it 'returns the script phases with keys converted to symbols' do
        spec = @spec.dup
        spec.script_phase = [{ 'name' => 'Hello World', 'script' => 'echo "Hello World"', 'execution_position' => :before_compile }]
        expect(spec.script_phases).to eq([{ :name => 'Hello World', :script => 'echo "Hello World"', :execution_position => :before_compile }])
      end

      it 'returns the script phases with default execution position' do
        spec = @spec.dup
        spec.script_phase = [{ 'name' => 'Hello World', 'script' => 'echo "Hello World"' }]
        expect(spec.script_phases).to eq([{ :name => 'Hello World', :script => 'echo "Hello World"', :execution_position => :any }])
      end

      describe '#validate_cocoapods_version' do
        it 'passes when none is specified' do
          spec_1 = Specification.new
          expect { spec_1.validate_cocoapods_version }.not_to raise_error
        end

        it 'passes when the requirement is satisfied' do
          spec_1 = Specification.new { |s| s.cocoapods_version = '>= 0.1.0' }
          expect { spec_1.validate_cocoapods_version }.not_to raise_error
        end

        it 'fails when the requirement is not satisfied' do
          spec_1 = Specification.new { |s| s.cocoapods_version = '= 999999.0.0' }
          expect { spec_1.validate_cocoapods_version }.to raise_error(Informative, /CocoaPods version/)
        end
      end

      describe '::name_and_version_from_string' do
        it 'returns the name and the version of a Specification from its #to_s output' do
          name, version = Specification.name_and_version_from_string('libPusher (1.0)')
          expect(name).to eq('libPusher')
          expect(version).to eq(Version.new('1.0'))
        end

        it 'takes into account the full name of the subspec returning the name and the version' do
          string = 'RestKit/JSON (1.0)'
          name = Specification.name_and_version_from_string(string).first
          expect(name).to eq('RestKit/JSON')
        end

        it 'handles names without version' do
          string = 'RestKit/JSON'
          name, version = Specification.name_and_version_from_string(string)
          expect(name).to eq('RestKit/JSON')
          expect(version.version).to be_empty
        end

        it 'handles names with a space without version' do
          string = 'RestKit/Subspec JSON'
          name, version = Specification.name_and_version_from_string(string)
          expect(name).to eq('RestKit/Subspec JSON')
          expect(version.version).to be_empty
        end

        it 'handles names with special characters without version' do
          string = 'RestKit_-+JSON'
          name, version = Specification.name_and_version_from_string(string)
          expect(name).to eq('RestKit_-+JSON')
          expect(version.version).to be_empty
        end

        it 'handles names with a space with version' do
          string = 'RestKit/Subspec JSON (1.0)'
          name, version = Specification.name_and_version_from_string(string)
          expect(name).to eq('RestKit/Subspec JSON')
          expect(version.version).to eq('1.0')
        end

        it 'handles names with special characters with version' do
          string = 'RestKit_-+JSON (1.0)'
          name, version = Specification.name_and_version_from_string(string)
          expect(name).to eq('RestKit_-+JSON')
          expect(version.version).to eq('1.0')
        end

        it 'raises if an invalid string representation is provided' do
          expect do
            Specification.name_and_version_from_string('missing_version ()')
          end.to raise_error(Informative, /Invalid string representation/)
        end
      end

      describe '::root_name' do
        it 'returns the root name of a given specification name' do
          expect(Specification.root_name('Pod')).to eq('Pod')
          expect(Specification.root_name('Pod/Subspec')).to eq('Pod')
        end
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Hierarchy' do
      before do
        @spec = Spec.new do |s|
          s.name = 'Pod'
          s.subspec 'Subspec' do |_sp|
          end
          s.test_spec do |_tsp|
          end
          s.app_spec do |_asp|
          end
        end
        @subspec = @spec.subspecs.first
        @test_subspec = @spec.test_specs.first
        @app_subspec = @spec.app_specs.first
      end

      it 'returns the root spec' do
        expect(@spec.root).to eq(@spec)
        expect(@subspec.root).to eq(@spec)
        expect(@test_subspec.root).to eq(@spec)
        expect(@app_subspec.root).to eq(@spec)
      end

      it 'returns whether it is a root spec' do
        expect(@spec.root?).to be(true)
        expect(@subspec.root?).to be(false)
        expect(@test_subspec.root?).to be(false)
        expect(@app_subspec.root?).to be(false)
      end

      it 'returns whether it is a subspec' do
        expect(@spec.subspec?).to be(false)
        expect(@subspec.subspec?).to be(true)
        expect(@test_subspec.subspec?).to be(true)
        expect(@app_subspec.subspec?).to be(true)
      end

      it 'returns whether it is a library_specification' do
        expect(@spec.library_specification?).to be(true)
        expect(@subspec.library_specification?).to be(true)
        expect(@test_subspec.library_specification?).to be(false)
        expect(@app_subspec.library_specification?).to be(false)
      end

      it 'returns whether it is a non_library_specification' do
        expect(@spec.non_library_specification?).to be(false)
        expect(@subspec.non_library_specification?).to be(false)
        expect(@test_subspec.non_library_specification?).to be(true)
        expect(@app_subspec.non_library_specification?).to be(true)
      end

      it 'returns whether it is a test_specification' do
        expect(@spec.test_specification?).to be(false)
        expect(@subspec.test_specification?).to be(false)
        expect(@test_subspec.test_specification?).to be(true)
        expect(@app_subspec.test_specification?).to be(false)
      end

      it 'returns whether it is a app_specification' do
        expect(@spec.app_specification?).to be(false)
        expect(@subspec.app_specification?).to be(false)
        expect(@test_subspec.app_specification?).to be(false)
        expect(@app_subspec.app_specification?).to be(true)
      end

      it 'returns the correct spec_type' do
        expect(@spec.spec_type).to eq(:library)
        expect(@subspec.spec_type).to eq(:library)
        expect(@test_subspec.spec_type).to eq(:test)
        expect(@app_subspec.spec_type).to eq(:app)
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Dependencies' do
      before do
        @spec = Spec.new do |s|
          s.name = 'Pod'
          s.version = '1.0'
          s.dependency 'AFNetworking'
          s.osx.dependency 'MagicalRecord'
          s.subspec 'Subspec' do |sp|
            sp.dependency 'libPusher'
            sp.subspec 'Subsubspec' do |_ssp|
            end
          end
          s.subspec 'SubspecOSX' do |sp|
            sp.platform = :osx
          end
          s.subspec 'SubspeciOS' do |sp|
            sp.platform = :ios
          end
        end
        @subspec = @spec.subspecs[0]
        @subspec_osx = @spec.subspecs[1]
        @subspec_ios = @spec.subspecs[2]
        @subsubspec = @subspec.subspecs.first
      end

      it 'returns the recursive subspecs' do
        expect(@spec.recursive_subspecs.sort_by(&:name)).to eq([@subspec, @subsubspec, @subspec_osx, @subspec_ios])
      end

      it 'returns a subspec given the absolute name' do
        expect(@spec.subspec_by_name('Pod/Subspec')).to eq(@subspec)
        expect(@spec.subspec_by_name('Pod/Subspec/Subsubspec')).to eq(@subsubspec)
      end

      it "doesn't return the test subspec given its name" do
        @spec = Spec.new do |s|
          s.name = 'Pod'
          s.version = '1.0'
          s.dependency 'AFNetworking'
          s.osx.dependency 'MagicalRecord'
          s.test_spec {}
        end
        expect(@spec.subspec_by_name('Pod/Tests', false)).to be_nil
      end

      it "does return the test subspec given it's name when including test subspecs" do
        @spec = Spec.new do |s|
          s.name = 'Pod'
          s.version = '1.0'
          s.dependency 'AFNetworking'
          s.osx.dependency 'MagicalRecord'
          s.test_spec {}
        end
        test_spec = @spec.test_specs.first
        expect(@spec.subspec_by_name('Pod/Tests', false, true)).to eq(test_spec)
      end

      it "doesn't return the app subspec given its name" do
        @spec = Spec.new do |s|
          s.name = 'Pod'
          s.version = '1.0'
          s.dependency 'AFNetworking'
          s.osx.dependency 'MagicalRecord'
          s.app_spec {}
        end
        expect(@spec.subspec_by_name('Pod/App', false)).to be_nil
      end

      it "does return the app subspec given it's name when including app subspecs" do
        @spec = Spec.new do |s|
          s.name = 'Pod'
          s.version = '1.0'
          s.dependency 'AFNetworking'
          s.osx.dependency 'MagicalRecord'
          s.app_spec {}
        end
        app_spec = @spec.app_specs.first
        expect(@spec.subspec_by_name('Pod/App', false, true)).to eq(app_spec)
      end

      it 'returns a subspec given the relative name' do
        expect(@subspec.subspec_by_name('Subspec/Subsubspec')).to eq(@subsubspec)
      end

      it "raises if it can't find a subspec with the given name" do
        expect { @spec.subspec_by_name('Pod/Nonexistent') }.to raise_error(Informative)
      end

      it 'raises if there is a base name case mis-match' do
        expect { @spec.subspec_by_name('pod') }.to raise_error(Informative)
      end

      it "returns if it can't find a subspec with the given name and raise_if_missing is false" do
        expect(@spec.subspec_by_name('Pod/Nonexistent', false)).to be_nil
      end

      it "returns if it can't find a deeply nested subspec with the given name and raise_if_missing is false" do
        expect(@spec.subspec_by_name('Pod/Subspec/Subsubspec/Missing', false)).to be_nil
      end

      describe 'deprecated podspec' do
        it 'returns nil for an empty deprecated spec' do
          @spec = Spec.new do |s|
            s.deprecated_in_favor_of = 'SomeOtherSpec'
          end
          expect(@spec.subspec_by_name('subspec', false)).to be_nil
        end
      end

      it 'returns the default subspecs' do
        spec = @spec.dup
        spec.default_subspecs = 'Subspec1', 'Subspec2'
        expect(spec.default_subspecs).to eq(%w(Subspec1 Subspec2))
      end

      it 'supports the specification of the default subspecs as a string' do
        spec = @spec.dup
        spec.default_subspecs = 'Subspec1'
        expect(spec.default_subspecs).to eq(%w(Subspec1))
      end

      it 'supports the specification of the default subspecs as a symbol' do
        spec = @spec.dup
        spec.default_subspecs = :none
        expect(spec.default_subspecs).to eq(:none)
      end

      it 'returns the dependencies on its subspecs' do
        expect(@spec.subspec_dependencies.sort).to eq([
          Dependency.new('Pod/Subspec', '1.0'),
          Dependency.new('Pod/SubspecOSX', '1.0'),
          Dependency.new('Pod/SubspeciOS', '1.0')])
      end

      it 'returns the dependencies on its subspecs for a given platform' do
        expect(@spec.subspec_dependencies(:ios)).to eq([
          Dependency.new('Pod/Subspec', '1.0'),
          Dependency.new('Pod/SubspeciOS', '1.0'),
        ])
      end

      it 'returns no default subspecs if none is specified' do
        @spec.default_subspecs = :none
        expect(@spec.subspec_dependencies).to be_empty
      end

      it 'returns a dependency on a default subspecs if it is specified' do
        @spec.default_subspecs = 'Subspec', 'SubspeciOS'
        expect(@spec.subspec_dependencies).to eq([
          Dependency.new('Pod/Subspec', '1.0'),
          Dependency.new('Pod/SubspeciOS', '1.0'),
        ])
      end

      it 'excludes the test subspec from the subspec dependencies' do
        @spec.test_spec {}
        expect(@spec.subspec_dependencies.sort).to eq([
          Dependency.new('Pod/Subspec', '1.0'),
          Dependency.new('Pod/SubspecOSX', '1.0'),
          Dependency.new('Pod/SubspeciOS', '1.0')])
      end

      it 'excludes the app subspec from the subspec dependencies' do
        @spec.app_spec {}
        expect(@spec.subspec_dependencies.sort).to eq([
          Dependency.new('Pod/Subspec', '1.0'),
          Dependency.new('Pod/SubspecOSX', '1.0'),
          Dependency.new('Pod/SubspeciOS', '1.0')])
      end

      it 'returns all the dependencies' do
        expect(@spec.dependencies.sort).to eq([
          Dependency.new('AFNetworking'),
          Dependency.new('MagicalRecord')])
      end

      it 'returns the test spec dependencies' do
        test_spec = @spec.test_spec { |s| s.dependency 'OCMock' }
        expect(test_spec.dependencies.sort).to eq([
          Dependency.new('AFNetworking'),
          Dependency.new('MagicalRecord'),
          Dependency.new('OCMock'),
        ])
      end

      it 'returns the app spec dependencies' do
        app_spec = @spec.app_spec { |s| s.dependency 'OCMock' }
        expect(app_spec.dependencies.sort).to eq([
          Dependency.new('AFNetworking'),
          Dependency.new('MagicalRecord'),
          Dependency.new('OCMock'),
        ])
      end

      it 'returns the dependencies given the platform' do
        expect(@spec.dependencies(:ios).sort).to eq([Dependency.new('AFNetworking')])
      end

      it 'inherits the dependencies of the parent' do
        expect(@subsubspec.dependencies(:ios).sort).to eq([Dependency.new('AFNetworking'), Dependency.new('libPusher')])
      end

      it 'returns all the dependencies including the ones on subspecs given a platform' do
        expect(@spec.all_dependencies.sort).to eq([
          Dependency.new('AFNetworking'),
          Dependency.new('MagicalRecord'),
          Dependency.new('Pod/Subspec', '1.0'),
          Dependency.new('Pod/SubspecOSX', '1.0'),
          Dependency.new('Pod/SubspeciOS', '1.0')])
      end

      it 'returns all the dependencies for a given platform' do
        expect(@spec.all_dependencies(:ios).sort).to eq([
          Dependency.new('AFNetworking'),
          Dependency.new('Pod/Subspec', '1.0'),
          Dependency.new('Pod/SubspeciOS', '1.0')])
      end

      it 'returns always true that a dependency is whitelisted if no configurations are specified' do
        @spec = Spec.new do |s|
          s.name = 'Pod'
          s.version = '1.0'
          s.dependency 'AFNetworking'
        end
        expect(@spec.dependency_whitelisted_for_configuration?(Dependency.new('AFNetworking'), :debug)).to be(true)
        expect(@spec.dependency_whitelisted_for_configuration?(Dependency.new('AFNetworking'), 'debug')).to be(true)
        expect(@spec.dependency_whitelisted_for_configuration?(Dependency.new('AFNetworking'), 'Debug')).to be(true)
        expect(@spec.dependency_whitelisted_for_configuration?(Dependency.new('AFNetworking'), :release)).to be(true)
        expect(@spec.dependency_whitelisted_for_configuration?(Dependency.new('AFNetworking'), 'release')).to be(true)
        expect(@spec.dependency_whitelisted_for_configuration?(Dependency.new('AFNetworking'), 'Release')).to be(true)
      end

      it 'returns correctly whether a dependency is whitelisted for a given config' do
        @spec = Spec.new do |s|
          s.name = 'Pod'
          s.version = '1.0'
          s.dependency 'AFNetworking', :configurations => ['Debug']
        end
        expect(@spec.dependency_whitelisted_for_configuration?(Dependency.new('AFNetworking'), :debug)).to be(true)
        expect(@spec.dependency_whitelisted_for_configuration?(Dependency.new('AFNetworking'), 'debug')).to be(true)
        expect(@spec.dependency_whitelisted_for_configuration?(Dependency.new('AFNetworking'), 'Debug')).to be(true)
        expect(@spec.dependency_whitelisted_for_configuration?(Dependency.new('AFNetworking'), :release)).to be(false)
        expect(@spec.dependency_whitelisted_for_configuration?(Dependency.new('AFNetworking'), 'release')).to be(false)
        expect(@spec.dependency_whitelisted_for_configuration?(Dependency.new('AFNetworking'), 'Release')).to be(false)
      end

      it 'returns correctly whether a dependency is whitelisted for a given config in a subspec' do
        @spec = Spec.new do |s|
          s.name = 'Pod'
          s.version = '1.0'
          s.subspec 'Subspec' do |sp|
            sp.dependency 'AFNetworking', :configurations => ['Debug']
          end
        end
        @subspec = @spec.subspecs.first
        expect(@subspec.dependency_whitelisted_for_configuration?(Dependency.new('AFNetworking'), :debug)).to be(true)
        expect(@subspec.dependency_whitelisted_for_configuration?(Dependency.new('AFNetworking'), 'debug')).to be(true)
        expect(@subspec.dependency_whitelisted_for_configuration?(Dependency.new('AFNetworking'), 'Debug')).to be(true)
        expect(@subspec.dependency_whitelisted_for_configuration?(Dependency.new('AFNetworking'), :release)).to be(false)
        expect(@subspec.dependency_whitelisted_for_configuration?(Dependency.new('AFNetworking'), 'release')).to be(false)
        expect(@subspec.dependency_whitelisted_for_configuration?(Dependency.new('AFNetworking'), 'Release')).to be(false)
      end
    end

    #-------------------------------------------------------------------------#

    describe 'DSL Helpers' do
      before do
        @spec = Spec.new do |s|
          s.name = 'Pod'
          s.version = '1.0'
          s.subspec 'Subspec' do |_sp|
          end
        end
        @subspec = @spec.subspecs.first
      end

      it 'reports if it is locally sourced' do
        @spec.source = { 'path' => '/tmp/local/path' }
        expect(@spec.local?).to be(true)
      end

      it 'returns whether it is supported on a given platform' do
        @spec.platform = :ios, '4.0'
        expect(@spec.supported_on_platform?(:ios)).to be(true)
        expect(@spec.supported_on_platform?(:ios, '4.0')).to be(true)
        expect(@spec.supported_on_platform?(:ios, '3.0')).to be(false)
        expect(@spec.supported_on_platform?(:osx)).to be(false)
        expect(@spec.supported_on_platform?(:osx, '10.5')).to be(false)
      end

      it 'returns the available platforms for which the pod is supported' do
        @spec.platform = :ios, '4.0'
        expect(@spec.available_platforms).to eq([Platform.new(:ios, '4.0')])
      end

      it 'inherits the name of the supported platforms from the parent' do
        @spec.platform = :ios, '4.0'
        expect(@subspec.available_platforms).to eq([Platform.new(:ios, '4.0')])
      end

      it 'returns the deployment target for the given platform' do
        @spec.platform = :ios, '4.0'
        expect(@spec.deployment_target(:ios)).to eq('4.0')
      end

      it 'allows a subspec to override the deployment target of the parent' do
        @spec.platform = :ios, '4.0'
        @subspec.ios.deployment_target = '5.0'
        expect(@subspec.deployment_target(:ios)).to eq('5.0')
      end

      it 'inherits the deployment target from the parent' do
        @spec.platform = :ios, '4.0'
        expect(@subspec.deployment_target(:ios)).to eq('4.0')
      end

      it 'returns the names of the supported platforms as specified by the user' do
        @spec.platform = :ios, '4.0'
        expect(@spec.send(:supported_platform_names)).to eq(['ios'])
      end

      it 'inherits the supported platform from the parent' do
        @spec.platform = :ios
        expect(@subspec.send(:supported_platform_names)).to eq(['ios'])
      end

      it 'returns the consumer for the given symbolic name of a platform' do
        @spec.ios.source_files = 'ios-files'
        consumer = @spec.consumer(:ios)
        expect(consumer.spec).to eq(@spec)
        expect(consumer.platform_name).to eq(:ios)
        expect(consumer.source_files).to eq(['ios-files'])
      end

      it 'returns the consumer of a given platform' do
        consumer = @spec.consumer(Platform.new :ios)
        expect(consumer.spec).to eq(@spec)
        expect(consumer.platform_name).to eq(:ios)
      end

      it 'caches the consumers per platform' do
        expect(@spec.consumer(:ios)).to eq(@spec.consumer(:ios))
        expect(@spec.consumer(:ios).platform_name).to eq(:ios)
        expect(@spec.consumer(:osx).platform_name).to eq(:osx)
      end
    end

    #-------------------------------------------------------------------------#

    describe 'DSL Attribute writers' do
      before do
        @spec = Spec.new
      end

      it 'stores the value of an attribute' do
        @spec.store_attribute(:attribute, 'value')
        expect(@spec.attributes_hash).to eq({
          'name' => nil,
          'attribute' => 'value',
        })
      end

      it 'stores the value of an attribute for a given platform' do
        @spec.store_attribute(:attribute, 'value', :ios)
        expect(@spec.attributes_hash).to eq({
          'name' => nil,
          'ios' => { 'attribute' => 'value' },
        })
      end

      it 'converts the keys of the hashes to a string' do
        @spec.store_attribute(:attribute, :key => 'value')
        expect(@spec.attributes_hash).to eq({
          'name' => nil,
          'attribute' => { 'key' => 'value' },
        })
      end

      it 'strips heredoc leading space from strings' do
        value = <<-EOS
          foo
            bar
        EOS
        @spec.store_attribute(:attribute, value)
        expect(@spec.attributes_hash).to eq({
          'name' => nil,
          'attribute' => "foo\n  bar",
        })
      end

      it 'strips trailing space from strings' do
        value = "foo\n"
        @spec.store_attribute(:attribute, value)
        expect(@spec.attributes_hash).to eq({
          'name' => nil,
          'attribute' => 'foo',
        })
      end

      it 'declares attribute writer methods' do
        Specification::DSL.attributes.values.each do |attr|
          value = case attr.supported_types.first
                  when Array then %w(a_value)
                  when FalseClass then false
                  when Hash then { :key => 'value' }
                  when String then 'a_value'
                  when TrueClass then true
                  end

          @spec.send(attr.writer_name, value)
          expect(@spec.attributes_hash[attr.name.to_s]).to eq(value)
        end
      end

      it 'supports the singular form of attribute writer methods' do
        singular_attrs = Specification::DSL.attributes.values.select(&:writer_singular_form)
        singular_attrs.each do |attr|
          @spec.send(attr.writer_name, 'a_value')
          expect(@spec.attributes_hash[attr.name.to_s]).to eq('a_value')
        end
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Initialization from a file' do
      it 'can be initialized from a file' do
        spec = Spec.from_file(fixture('BananaLib.podspec'))
        expect(spec.class).to eq(Spec)
        expect(spec.name).to eq('BananaLib')
      end

      it 'can be initialized from a JSON file' do
        Dir.expects(:chdir).never
        spec = Spec.from_file(fixture('BananaLib.podspec.json'))
        expect(spec.class).to eq(Spec)
        expect(spec.name).to eq('BananaLib')
      end

      it "presents an informative if the given file file doesn't exits" do
        expect do
          Spec.from_file('Missing.podspec')
        end.to raise_error(Informative, /No podspec exists/)
      end

      it "presents an informative if it can't handle the specification format" do
        Pathname.any_instance.stubs(:exist?).returns(true)
        File.stubs(:open).returns('')
        expect do
          Spec.from_file('Missing.podspec.csv')
        end.to raise_error(Informative, /Unsupported specification format/)
      end

      it "is initialized in the context of the file's directory" do
        contents = File.read fixture('BananaLib.podspec')
        contents.sub!(/s\.name.*= '.+'/, 's.name = File.basename(Dir.pwd) + File.expand_path(__FILE__)')
        File.any_instance.stubs(:read).returns(contents)

        spec = Spec.from_file(fixture('BananaLib.podspec'))
        expect(spec.class).to eq(Spec)
        expect(spec.name).to eq('fixtures' + fixture('BananaLib.podspec').to_s)

        spec = Spec.from_file(fixture('BananaLib.podspec').relative_path_from(Pathname.pwd))
        expect(spec.class).to eq(Spec)
        expect(spec.name).to eq('fixtures' + fixture('BananaLib.podspec').to_s)
      end

      #--------------------------------------#

      before do
        @path = fixture('BananaLib.podspec')
        @spec = Spec.from_file(@path)
      end

      it 'returns the checksum of the file in which it is defined' do
        expect(@spec.checksum).to eq('4fb39cb6f34f694ab489d39df699c5b7c7f9ac79')
      end

      it 'returns a nil checksum if the specification is not defined in a file' do
        spec = Spec.new
        expect(spec.checksum).to be_nil
      end

      it 'reports the file from which it was initialized' do
        expect(@spec.defined_in_file).to eq(@path)
      end

      it 'raises if there is an attempt to set the file in which the spec is defined for a subspec' do
        spec = Spec.new do |s|
          s.name = 'Pod'
          s.version = '1.0'
          s.subspec 'Subspec' do |_sp|
          end
        end
        expect do
          spec.subspecs.first.defined_in_file = 'Some-file'
        end.to raise_error(StandardError, /can be set only for root specs/)
      end
    end

    #-------------------------------------------------------------------------#

    describe 'module name' do
      it 'uses the specification name as module name by default' do
        spec = Specification.new(nil, 'Three20')
        expect(spec.module_name).to eq('Three20')
      end

      it 'converts the name to a C99 identifier if required' do
        spec = Specification.new(nil, '500px')
        expect(spec.module_name).to eq('_500px')
      end

      it 'uses the header_dir as module name if specified' do
        spec = Specification.new(nil, 'Three20.swift')
        spec.header_dir = 'Three20'
        expect(spec.module_name).to eq('Three20')
      end

      it 'converts the header_dir to a C99 identifier if required' do
        spec = Specification.new(nil, 'Three20.swift')
        spec.header_dir = 'Three-20'
        expect(spec.module_name).to eq('Three_20')
      end

      it 'uses the defined module name if specified' do
        spec = Specification.new(nil, 'Three20.swift')
        spec.header_dir = 'Three20Core'
        spec.module_name = 'Three20'
        expect(spec.module_name).to eq('Three20')
      end
    end

    #-------------------------------------------------------------------------#

    describe '#c99ext_identifier' do
      before do
        @spec = Specification.new
      end

      it 'should mask, but keep leading numbers' do
        expect(@spec.send(:c99ext_identifier, '123BananaLib')).to eq('_123BananaLib')
      end

      it 'should mask invalid chars' do
        expect(@spec.send(:c99ext_identifier, 'iOS-App BânánàLïb')).to eq('iOS_App_BananaLib')
      end

      it 'should flatten multiple underscores to a single one' do
        expect(@spec.send(:c99ext_identifier, '$.swift')).to eq('_swift')
      end
    end

    #-------------------------------------------------------------------------#
  end
end
