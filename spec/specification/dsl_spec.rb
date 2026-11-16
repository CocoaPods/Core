require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Specification::DSL do
    describe 'Root specification attributes' do
      before do
        @spec = Spec.new do |s|
          s.name = 'Pod'
        end
      end

      it 'allows to specify the name' do
        @spec.name = 'Name'
        expect(@spec.attributes_hash['name']).to eq('Name')
      end

      it 'allows to specify the version' do
        @spec.version = '1.0'
        expect(@spec.attributes_hash['version']).to eq('1.0')
      end

      it 'allows specifying the swift version in singular form' do
        @spec.swift_version = '3.0'
        expect(@spec.attributes_hash['swift_versions']).to eq('3.0')
      end

      it 'allows specifying multiple swift versions in singular form' do
        @spec.swift_version = '3.0', '4.0'
        expect(@spec.attributes_hash['swift_versions']).to eq(['3.0', '4.0'])
      end

      it 'allows specifying multiple swift versions as an array in singular form' do
        @spec.swift_version = ['3.0', '4.0']
        expect(@spec.attributes_hash['swift_versions']).to eq(['3.0', '4.0'])
      end

      it 'allows specifying the swift version in plural form' do
        @spec.swift_versions = '3.0'
        expect(@spec.attributes_hash['swift_versions']).to eq('3.0')
      end

      it 'allows specifying multiple swift versions in plural form' do
        @spec.swift_versions = '3.0', '4.0'
        expect(@spec.attributes_hash['swift_versions']).to eq(['3.0', '4.0'])
      end

      it 'allows specifying multiple swift versions as an array in plural form' do
        @spec.swift_versions = ['3.0', '4.0']
        expect(@spec.attributes_hash['swift_versions']).to eq(['3.0', '4.0'])
      end

      it 'allows specifying the cocoapods version' do
        @spec.cocoapods_version = '>= 0.36'
        expect(@spec.attributes_hash['cocoapods_version']).to eq('>= 0.36')
      end

      it 'allows to specify the authors' do
        hash = { 'Darth Vader' => 'darthvader@darkside.com',
                 'Wookiee' => 'wookiee@aggrrttaaggrrt.com' }
        @spec.authors = hash
        expect(@spec.attributes_hash['authors']).to eq(hash)
      end

      it 'allows to specify the authors in the singular form' do
        @spec.author = { 'orta' => 'orta.therox@gmail.com' }
        expect(@spec.attributes_hash['authors']).to eq({ 'orta' => 'orta.therox@gmail.com' })
      end

      it 'allows to specify the social media contact' do
        @spec.social_media_url = 'https://twitter.com/cocoapods'
        expect(@spec.attributes_hash['social_media_url']).to eq('https://twitter.com/cocoapods')
      end

      it 'allows to specify the readme' do
        @spec.readme = 'https://www.example.com/readme'
        expect(@spec.attributes_hash['readme']).to eq('https://www.example.com/readme')
      end

      it 'allows to specify the changelog' do
        @spec.changelog = 'https://www.example.com/changelog'
        expect(@spec.attributes_hash['changelog']).to eq('https://www.example.com/changelog')
      end

      it 'allows to specify the license' do
        @spec.license = { :type => 'MIT', :file => 'MIT-LICENSE' }
        expect(@spec.attributes_hash['license']).to eq({ 'type' => 'MIT', 'file' => 'MIT-LICENSE' })
      end

      it 'allows to specify the homepage' do
        @spec.homepage = 'www.example.com'
        expect(@spec.attributes_hash['homepage']).to eq('www.example.com')
      end

      it 'allows to specify the source' do
        @spec.source = { :git => 'www.example.com/repo.git' }
        expect(@spec.attributes_hash['source']).to eq({ 'git' => 'www.example.com/repo.git' })
      end

      it 'allows to specify the summary' do
        @spec.summary = 'text'
        expect(@spec.attributes_hash['summary']).to eq('text')
      end

      it 'allows to specify the description' do
        @spec.description = 'text'
        expect(@spec.attributes_hash['description']).to eq('text')
      end

      it 'allows to specify the documentation URL' do
        @spec.documentation_url = 'www.example.com'
        expect(@spec.attributes_hash['documentation_url']).to eq('www.example.com')
      end

      it 'allows to specify a prepare command' do
        @spec.prepare_command = 'ruby build_files.rb'
        expect(@spec.attributes_hash['prepare_command']).to eq('ruby build_files.rb')
      end

      it 'allows to specify whether the Pod has a static_framework' do
        @spec.static_framework = true
        expect(@spec.attributes_hash['static_framework']).to eq(true)
      end

      it 'allows to specify whether the Pod has been deprecated' do
        @spec.deprecated = true
        expect(@spec.attributes_hash['deprecated']).to eq(true)
      end

      it 'allows to specify the name of the Pod that this one has been deprecated in favor of' do
        @spec.deprecated_in_favor_of = 'NewMoreAwesomePod'
        expect(@spec.attributes_hash['deprecated_in_favor_of']).to eq('NewMoreAwesomePod')
      end

      it 'allows specifying info.plist values' do
        hash = {
          'SOME_VAR' => 'SOME_VALUE',
        }
        @spec.info_plist = hash
        expect(@spec.attributes_hash['info_plist']).to eq(hash)
      end
    end

    #-----------------------------------------------------------------------------#

    describe 'Platform' do
      before do
        @spec = Spec.new do |s|
          s.name = 'Pod'
        end
      end

      it 'allows to specify the supported platform' do
        @spec.platform = :ios
        expect(@spec.attributes_hash['platforms']).to eq({ 'ios' => nil })
      end

      it 'allows to specify the deployment target along the supported platform as a shortcut' do
        @spec.platform = :ios, '6.0'
        expect(@spec.attributes_hash['platforms']).to eq({ 'ios' => '6.0' })
      end

      it 'allows to specify a deployment target for each platform' do
        @spec.ios.deployment_target = '6.0'
        expect(@spec.attributes_hash['platforms']['ios']).to eq('6.0')
      end

      it "doesn't allows to specify the deployment target without a platform" do
        expect { @spec.deployment_target = '6.0' }.to raise_error(Informative, /declared only per platform/)
      end

      it 'allows to specify visionOS as supported platform' do
        @spec.platform = :visionos
        expect(@spec.attributes_hash['platforms']).to eq({ 'visionos' => nil })
      end

      it 'allows to specify a deployment target for the visionOS platform' do
        @spec.visionos.deployment_target = '1.0'
        expect(@spec.attributes_hash['platforms']['visionos']).to eq('1.0')
      end

      it 'allows to specify watchOS as supported platform' do
        @spec.platform = :watchos
        expect(@spec.attributes_hash['platforms']).to eq({ 'watchos' => nil })
      end

      it 'allows to specify a deployment target for the watchOS platform' do
        @spec.watchos.deployment_target = '2.0'
        expect(@spec.attributes_hash['platforms']['watchos']).to eq('2.0')
      end

      it 'allows to specify tvOS as supported platform' do
        @spec.platform = :tvos
        expect(@spec.attributes_hash['platforms']).to eq({ 'tvos' => nil })
      end

      it 'allows to specify a deployment target for the tvOS platform' do
        @spec.tvos.deployment_target = '9.0'
        expect(@spec.attributes_hash['platforms']['tvos']).to eq('9.0')
      end
    end

    #-----------------------------------------------------------------------------#

    describe 'Build settings' do
      before do
        @spec = Spec.new do |s|
          s.name = 'Pod'
        end
      end

      #------------------#

      describe 'dependency' do
        it 'allows to specify a dependencies' do
          @spec.dependencies = { 'SVStatusHUD' => ['~>1.0', '< 1.4'] }
          expect(@spec.attributes_hash['dependencies']).to eq({ 'SVStatusHUD' => ['~>1.0', '< 1.4'] })
        end

        it 'allows to specify a single dependency as a shortcut' do
          @spec.dependency('SVStatusHUD', '~>1.0', '< 1.4')
          expect(@spec.attributes_hash['dependencies']).to eq({ 'SVStatusHUD' => ['~>1.0', '< 1.4'] })
        end

        it 'allows to specify a single dependency as a shortcut with one version requirement' do
          @spec.dependency('SVStatusHUD', '~>1.0')
          expect(@spec.attributes_hash['dependencies']).to eq({ 'SVStatusHUD' => ['~>1.0'] })
        end

        it 'allows to specify a single dependency as a shortcut with no version requirements' do
          @spec.dependency('SVStatusHUD')
          expect(@spec.attributes_hash['dependencies']).to eq({ 'SVStatusHUD' => [] })
        end

        it 'allows a dependency whose name matches part of one of its parents names' do
          @spec.subspec 'subspectest' do |sp|
            sp.subspec 'subsubspec' do |ssp|
              ssp.dependency('subspec')
              expect(ssp.attributes_hash['dependencies']).to eq({ 'subspec' => [] })
            end
          end
        end

        it 'raises if the specification requires itself' do
          expect do
            @spec.dependency('Pod')
          end.to raise_error(Informative, /can't require itself/)
        end

        it 'raises if the specification requires one of its parents' do
          @spec.subspec 'subspec' do |_sp|
          end
          subspec = @spec.subspecs.first
          expect do
            subspec.dependency('Pod')
          end.to raise_error(Informative, /can't require one of its parents/)

          # Ensure nested subspecs are prevented from requiring one of their parents
          @spec.subspec 'subspec' do |sp|
            sp.subspec 'subsubspec' do |ssp|
              expect do
                ssp.dependency('Pod/subspec')
              end.to raise_error(Informative, /can't require one of its parents/)
            end
          end
        end

        it 'raises if the requirements are not supported' do
          expect do
            @spec.dependency('SVProgressHUD', :head)
          end.to raise_error(Informative, /Unsupported version requirements. \[\:head\] is not valid/)
        end

        it 'raises if the requirements specify :git' do
          expect do
            @spec.dependency('SVProgressHUD', :git => 'AnyPath')
          end.to raise_error(Informative, /Podspecs cannot specify the source of dependencies. The `:git` option is not supported.\.*/)
        end

        it 'raises if the requirements specify :path' do
          expect do
            @spec.dependency('SVProgressHUD', :path => 'AnyPath')
          end.to raise_error(Informative, /Podspecs cannot specify the source of dependencies. The `:path` option is not supported.\.*/)
        end

        it 'raises when attempting to assign a value to dependency' do
          expect do
            @spec.dependency = 'JSONKit', '1.5'
          end.to raise_error(Informative, /Cannot assign value to `dependency`. Did you mean: `dependency 'JSONKit', '1.5'`?/)
        end

        describe 'configurations for dependency' do
          it 'stores the whitelisted configurations for a given dependency' do
            @spec.dependency('SVProgressHUD', :configurations => %w(Debug Release))
            expect(@spec.attributes_hash['dependencies']).to eq({ 'SVProgressHUD' => [] })
            expect(@spec.attributes_hash['configuration_pod_whitelist']).to eq({ 'SVProgressHUD' => %w(debug release) })
          end

          it 'does not store the whitelisted configurations for a dependency if no configurations are specified' do
            @spec.dependency('SVProgressHUD')
            expect(@spec.attributes_hash['dependencies']).to eq({ 'SVProgressHUD' => [] })
            expect(@spec.attributes_hash['configuration_pod_whitelist']).to be_nil
          end

          it 'raises if a whitelisted configuration for a dependency is not supported' do
            expect do
              @spec.dependency('SVProgressHUD', :configurations => ['Beta'])
            end.to raise_error(Informative, 'Only `Debug` & `Release` are allowed under configurations for dependency on `SVProgressHUD`. Found `beta`.')
          end
        end
      end

      #------------------#

      it 'allows to specify whether the specification requires ARC' do
        @spec.requires_arc = false
        expect(@spec.attributes_hash['requires_arc']).to eq(false)
      end

      it 'allows to specify which files require ARC' do
        @spec.requires_arc = ['arc/*.{h,m}']
        expect(@spec.attributes_hash['requires_arc']).to eq(['arc/*.{h,m}'])

        @spec.requires_arc = 'arc/*.{h,m}'
        expect(@spec.attributes_hash['requires_arc']).to eq('arc/*.{h,m}')
      end

      it 'allows to specify the frameworks' do
        @spec.framework = %w(QuartzCore CoreData)
        expect(@spec.attributes_hash['frameworks']).to eq(%w(QuartzCore CoreData))
      end

      it 'allows to specify the weak frameworks' do
        @spec.weak_frameworks = %w(Twitter iAd)
        expect(@spec.attributes_hash['weak_frameworks']).to eq(%w(Twitter iAd))
      end

      it 'allows to specify the libraries' do
        @spec.libraries = 'z', 'xml2'
        expect(@spec.attributes_hash['libraries']).to eq(%w(z xml2))
      end

      it 'allows to specify compiler flags' do
        @spec.compiler_flags = %w(-Wdeprecated-implementations -Wunused-value)
        expect(@spec.attributes_hash['compiler_flags']).to eq(%w(-Wdeprecated-implementations -Wunused-value))
      end

      it 'allows to specify pod target xcconfig settings' do
        @spec.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-lObjC' }
        expect(@spec.attributes_hash['pod_target_xcconfig']).to eq({ 'OTHER_LDFLAGS' => '-lObjC' })
      end

      it 'allows to specify user target xcconfig settings' do
        @spec.user_target_xcconfig = { 'OTHER_CPLUSPLUSFLAGS' => '-std=c++1y' }
        expect(@spec.attributes_hash['user_target_xcconfig']).to eq({ 'OTHER_CPLUSPLUSFLAGS' => '-std=c++1y' })
      end

      it 'allows to specify the contents of the prefix header' do
        @spec.prefix_header_contents = '#import <UIKit/UIKit.h>'
        expect(@spec.attributes_hash['prefix_header_contents']).to eq('#import <UIKit/UIKit.h>')
      end

      it 'allows to specify the path of compiler header file' do
        @spec.prefix_header_file = 'iphone/include/prefix.pch'
        expect(@spec.attributes_hash['prefix_header_file']).to eq('iphone/include/prefix.pch')
      end

      it 'allows to skip prefix header file generation' do
        @spec.prefix_header_file = false
        expect(@spec.attributes_hash['prefix_header_file']).to eq(false)
      end

      it 'allows to specify a directory to use for the headers' do
        @spec.header_dir = 'Three20Core'
        expect(@spec.attributes_hash['header_dir']).to eq('Three20Core')
      end

      it 'allows to specify a directory to preserver the namespacing of the headers' do
        @spec.header_mappings_dir = 'src/include'
        expect(@spec.attributes_hash['header_mappings_dir']).to eq('src/include')
      end

      it 'allows to specify a custom module name' do
        @spec.module_name = 'Three20'
        expect(@spec.attributes_hash['module_name']).to eq('Three20')
      end

      it 'allows to specify a custom module map file' do
        @spec.module_map = 'module.modulemap'
        expect(@spec.attributes_hash['module_map']).to eq('module.modulemap')
      end

      it 'allows to skip modulemap file generation' do
        @spec.module_map = false
        expect(@spec.attributes_hash['module_map']).to eq(false)
      end

      it 'allows to specify the script phases shipped with the Pod' do
        @spec.script_phases = { :name => 'Hello World', :script => 'echo "Hello World"' }
        expect(@spec.attributes_hash['script_phases']).to eq({ 'name' => 'Hello World', 'script' => 'echo "Hello World"' })
      end

      it 'allows to specify the script phases shipped with the Pod as a hash' do
        @spec.script_phases = { :name => 'Hello Ruby World', :script => 'puts "Hello Ruby World"', :shell_path => 'usr/bin/ruby' }
        expect(@spec.attributes_hash['script_phases']).to eq({ 'name' => 'Hello Ruby World', 'script' => 'puts "Hello Ruby World"', 'shell_path' => 'usr/bin/ruby' })
      end
    end

    #-----------------------------------------------------------------------------#

    describe 'File patterns attributes' do
      before do
        @spec = Spec.new do |s|
          s.name = 'Pod'
        end
      end

      it 'allows to specify the source files' do
        @spec.source_files = ['lib_classes/**/*']
        expect(@spec.attributes_hash['source_files']).to eq(['lib_classes/**/*'])
      end

      it 'allows to specify the public headers files' do
        @spec.public_header_files = ['include/**/*']
        expect(@spec.attributes_hash['public_header_files']).to eq(['include/**/*'])
      end

      it 'allows to specify the project headers files' do
        @spec.project_header_files = ['project/**/*']
        expect(@spec.attributes_hash['project_header_files']).to eq(['project/**/*'])
      end

      it 'allows to specify the private headers files' do
        @spec.private_header_files = ['private/**/*']
        expect(@spec.attributes_hash['private_header_files']).to eq(['private/**/*'])
      end

      it 'allows to specify the frameworks bundles shipped with the Pod' do
        @spec.vendored_frameworks = ['Parse.framework']
        expect(@spec.attributes_hash['vendored_frameworks']).to eq(['Parse.framework'])
      end

      it 'allows to specify the libraries shipped with the Pod' do
        @spec.vendored_libraries = ['libProj4.a']
        expect(@spec.attributes_hash['vendored_libraries']).to eq(['libProj4.a'])
      end

      it 'allows to specify the on demand resources shipped with the Pod' do
        @spec.on_demand_resources = { 'Maps' => 'MapView/Map/Resources/*.png' }
        expect(@spec.attributes_hash['on_demand_resources']).to eq({ 'Maps' => 'MapView/Map/Resources/*.png' })
      end

      it 'allows to specify the on demand resources shipped with the Pod as an array' do
        @spec.on_demand_resources = { 'Levels' => %w[Levels/Level1/Resources/*.png Levels/Level2/Resources/*.png] }
        expect(@spec.attributes_hash['on_demand_resources']).to eq({ 'Levels' => %w[Levels/Level1/Resources/*.png Levels/Level2/Resources/*.png] })
      end

      it 'allows to specify the resources bundles shipped with the Pod' do
        @spec.resource_bundles = { 'MapBox' => 'MapView/Map/Resources/*.png' }
        expect(@spec.attributes_hash['resource_bundles']).to eq({ 'MapBox' => 'MapView/Map/Resources/*.png' })
      end

      it 'allows to specify the resources files' do
        @spec.resources = ['frameworks/CrashReporter.framework']
        expect(@spec.attributes_hash['resources']).to eq(['frameworks/CrashReporter.framework'])
      end

      it 'allows to specify the paths to exclude' do
        @spec.exclude_files = ['Classes/**/unused.{h,m}']
        expect(@spec.attributes_hash['exclude_files']).to eq(['Classes/**/unused.{h,m}'])
      end

      it 'allows to specify the paths to preserve' do
        @spec.preserve_paths = ['Frameworks/*.framework']
        expect(@spec.attributes_hash['preserve_paths']).to eq(['Frameworks/*.framework'])
      end
    end

    #-----------------------------------------------------------------------------#

    describe 'Subspecs' do
      before do
        @spec = Spec.new do |_s|
        end
      end

      it 'allows to specify as subspec' do
        @spec = Spec.new do |s|
          s.name = 'Spec'
          s.subspec 'Subspec' do |_sp|
          end
        end
        subspec = @spec.subspecs.first
        expect(subspec.parent).to eq(@spec)
        expect(subspec.class).to eq(Specification)
        expect(subspec.name).to eq('Spec/Subspec')
      end

      it 'should allow you to specify a preferred set of dependencies' do
        @spec.default_subspecs = 'Preferred-Subspec1', 'Preferred-Subspec2'
        expect(@spec.attributes_hash['default_subspecs']).to eq(%w(Preferred-Subspec1 Preferred-Subspec2))
      end

      it 'should allow you to specify an empty preferred set of dependencies' do
        @spec.default_subspecs = :none
        expect(@spec.attributes_hash['default_subspecs']).to eq(:none)
      end
    end

    #-----------------------------------------------------------------------------#

    describe 'Test specs' do
      before do
        @spec = Spec.new do |spec|
          spec.name = 'Spec'
          spec.test_spec do |test_spec|
            test_spec.test_type = :unit
          end
        end
      end

      it 'allows you to specify a unit test spec' do
        test_spec = @spec.subspecs.first
        expect(test_spec.class).to eq(Specification)
        expect(test_spec.name).to eq('Spec/Tests')
        expect(test_spec.test_specification?).to eq(true)
        expect(test_spec.test_type).to eq(:unit)
      end

      it 'allows you to specify a unit test type as string' do
        a_spec = Spec.new do |spec|
          spec.name = 'Spec'
          spec.test_spec do |test_spec|
            test_spec.test_type = 'unit'
          end
        end
        test_spec = a_spec.subspecs.first
        expect(test_spec.class).to eq(Specification)
        expect(test_spec.name).to eq('Spec/Tests')
        expect(test_spec.test_specification?).to eq(true)
        expect(test_spec.test_type).to eq(:unit)
      end

      it 'allows you to specify a ui test spec' do
        a_spec = Spec.new do |spec|
          spec.name = 'Spec'
          spec.test_spec do |test_spec|
            test_spec.test_type = :ui
          end
        end
        test_spec = a_spec.subspecs.first
        expect(test_spec.class).to eq(Specification)
        expect(test_spec.name).to eq('Spec/Tests')
        expect(test_spec.test_specification?).to eq(true)
        expect(test_spec.test_type).to eq(:ui)
      end

      it 'allows you to specify a ui test type as string' do
        a_spec = Spec.new do |spec|
          spec.name = 'Spec'
          spec.test_spec do |test_spec|
            test_spec.test_type = 'ui'
          end
        end
        test_spec = a_spec.subspecs.first
        expect(test_spec.class).to eq(Specification)
        expect(test_spec.name).to eq('Spec/Tests')
        expect(test_spec.test_specification?).to eq(true)
        expect(test_spec.test_type).to eq(:ui)
      end

      it 'allows you to specify a scheme for a test spec' do
        a_spec = Spec.new do |spec|
          spec.name = 'Spec'
          spec.test_spec do |test_spec|
            test_spec.test_type = 'unit'
            test_spec.scheme = { :launch_arguments => %w(Arg1 Arg2), :environment_variables => { 'Key1' => 'Val1' } }
          end
        end
        test_spec = a_spec.subspecs.first
        expect(test_spec.scheme).to eq({ :launch_arguments => %w(Arg1 Arg2), :environment_variables => { 'Key1' => 'Val1' } })
      end
    end

    #-----------------------------------------------------------------------------#

    describe 'Multi-Platform' do
      before do
        @spec = Spec.new do |s|
          s.name = 'Pod'
        end
      end

      it 'allows to specify iOS attributes' do
        @spec.ios.preserve_paths = ['APath']
        expect(@spec.attributes_hash['ios']['preserve_paths']).to eq(['APath'])
        expect(@spec.attributes_hash['preserve_paths']).to be_nil
        expect(@spec.attributes_hash['osx']).to be_nil
      end

      it 'allows to specify OS X attributes' do
        @spec.osx.preserve_paths = ['APath']
        expect(@spec.attributes_hash['osx']['preserve_paths']).to eq(['APath'])
        expect(@spec.attributes_hash['preserve_paths']).to be_nil
        expect(@spec.attributes_hash['ios']).to be_nil
      end

      it 'allows to specify OS X attributes as macOS' do
        @spec.macos.preserve_paths = ['APath']
        expect(@spec.attributes_hash['osx']['preserve_paths']).to eq(['APath'])
        expect(@spec.attributes_hash['preserve_paths']).to be_nil
        expect(@spec.attributes_hash['ios']).to be_nil
      end
    end

    #-----------------------------------------------------------------------------#

    describe 'Attributes default values' do
      it 'does requires arc by default' do
        attr = Specification::DSL.attributes[:requires_arc]
        expect(attr.default(:ios)).to eq(true)
        expect(attr.default(:osx)).to eq(true)
      end
    end

    #-----------------------------------------------------------------------------#

    describe 'Attributes singular form' do
      it 'allows to use the singular form the attributes which support it' do
        attributes = Specification::DSL.attributes.values
        singularized = attributes.select(&:singularize?)
        spec = Specification.new
        singularized.each do |attr|
          expect(spec).to respond_to(attr.writer_name)
        end
        expect(singularized.map { |attr| attr.name.to_s }.sort).to eq(%w(
          authors compiler_flags default_subspecs frameworks libraries on_demand_resources
          preserve_paths resource_bundles resources screenshots script_phases
          swift_versions vendored_frameworks vendored_libraries weak_frameworks
        ))
      end
    end

    #-----------------------------------------------------------------------------#
  end
end
