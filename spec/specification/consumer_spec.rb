require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Specification::Consumer do
    describe 'In general' do
      before do
        @spec = Spec.new do |s|
          s.name = 'Pod'
          s.platform = :ios, '6.0'
        end
        @consumer = Specification::Consumer.new(@spec, :ios)
      end

      it 'returns the specification' do
        expect(@consumer.spec).to eq(@spec)
      end

      it 'returns the platform' do
        expect(@consumer.platform_name).to eq(:ios)
      end

      it 'can be initialized with a platform instance' do
        @consumer = Specification::Consumer.new(@spec, Platform.new(:ios, '6.1'))
        expect(@consumer.platform_name.class).to eq(Symbol)
        expect(@consumer.platform_name).to eq(:ios)
      end

      it 'raises if the specification does not supports the given platform' do
        platform = Platform.new(:ios, '4.3')
        expect { Specification::Consumer.new(@spec, platform) }.to raise_error(StandardError, /not compatible with iOS 4.3/)
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Regular attributes' do
      before do
        @spec = Spec.new do |s|
          s.name = 'Pod'
          s.subspec 'Subspec' do |_sp|
          end
        end
        @subspec = @spec.subspecs.first
        @consumer = Specification::Consumer.new(@spec, :ios)
        @subspec_consumer = Specification::Consumer.new(@subspec, :ios)
      end

      #------------------#

      it 'allows to specify whether the specification requires ARC' do
        @spec.requires_arc = false
        expect(@consumer.requires_arc?).to be(false)
      end

      it 'requires arc by default' do
        expect(@consumer.requires_arc?).to be(true)
      end

      it 'inherits where it requires arc from the parent' do
        @spec.requires_arc = false
        expect(@subspec_consumer.requires_arc?).to be(false)
      end

      it "doesn't inherit whether it requires ARC from the parent if it is false" do
        @spec.requires_arc = true
        @subspec.requires_arc = false
        expect(@subspec_consumer.requires_arc?).to be(false)
      end

      #----------------#

      it 'allows to specify the frameworks' do
        @spec.framework = %w(QuartzCore CoreData)
        expect(@consumer.frameworks).to eq(%w(QuartzCore CoreData))
      end

      it 'allows to specify a single framework' do
        @spec.framework = 'QuartzCore'
        expect(@consumer.frameworks).to eq(%w(QuartzCore))
      end

      it 'inherits the frameworks of the parent' do
        @spec.framework = 'QuartzCore'
        @subspec.framework = 'CoreData'
        expect(@subspec_consumer.frameworks).to eq(%w(QuartzCore CoreData))
      end

      #------------------#

      it 'allows to specify the weak frameworks' do
        @spec.weak_frameworks = %w(Twitter iAd)
        expect(@consumer.weak_frameworks).to eq(%w(Twitter iAd))
      end

      it 'allows to specify a single weak framework' do
        @spec.weak_framework = 'Twitter'
        expect(@consumer.weak_frameworks).to eq(%w(Twitter))
      end

      it 'inherits the weak frameworks of the parent' do
        @spec.weak_framework    = 'Twitter'
        @subspec.weak_framework = 'iAd'
        expect(@subspec_consumer.weak_frameworks).to eq(%w(Twitter iAd))
      end

      #------------------#

      it 'allows to specify the libraries' do
        @spec.libraries = 'z', 'xml2'
        expect(@consumer.libraries).to eq(%w(z xml2))
      end

      it 'allows to specify a single library' do
        @spec.library = 'z'
        expect(@consumer.libraries).to eq(%w(z))
      end

      it 'inherits the libraries from the parent' do
        @spec.library    = 'z'
        @subspec.library = 'xml2'
        expect(@subspec_consumer.libraries).to eq(%w(z xml2))
      end

      #------------------#

      it 'allows to specify compiler flags' do
        @spec.compiler_flags = %w(-Wdeprecated-implementations -Wunused-value)
        expect(@consumer.compiler_flags).to eq(%w(-Wdeprecated-implementations -Wunused-value))
      end

      it 'allows to specify a single compiler flag' do
        @spec.compiler_flag = '-Wdeprecated-implementations'
        expect(@consumer.compiler_flags).to eq(%w(-Wdeprecated-implementations))
      end

      it 'inherits the compiler flags from the parent' do
        @spec.compiler_flag = '-Wdeprecated-implementations'
        @subspec.compiler_flag = '-Wunused-value'
        expect(@subspec_consumer.compiler_flags).to eq(%w(-Wdeprecated-implementations -Wunused-value))
      end

      it 'merges the compiler flags so values for platforms can be specified' do
        @spec.compiler_flags = '-Wdeprecated-implementations'
        @spec.ios.compiler_flags = '-Wunused-value'
        expect(@consumer.compiler_flags).to eq(%w(-Wdeprecated-implementations -Wunused-value))
        osx_consumer = Specification::Consumer.new(@spec, :osx)
        expect(osx_consumer.compiler_flags).to eq(%w(-Wdeprecated-implementations))
      end

      #------------------#

      it 'allows to specify xcconfig settings' do
        @spec.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-lObjC' }
        expect(@consumer.pod_target_xcconfig).to eq({ 'OTHER_LDFLAGS' => '-lObjC' })
      end

      it 'inherits the xcconfig values from the parent' do
        @spec.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-lObjC' }
        @subspec.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-Wl -no_compact_unwind' }
        expect(@subspec_consumer.pod_target_xcconfig).to eq({ 'OTHER_LDFLAGS' => '-lObjC -Wl -no_compact_unwind' })
      end

      it 'merges the xcconfig values so values for platforms can be specified' do
        @spec.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-lObjC' }
        @spec.ios.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-Wl -no_compact_unwind' }
        expect(@consumer.pod_target_xcconfig).to eq({ 'OTHER_LDFLAGS' => '-lObjC -Wl -no_compact_unwind' })
        osx_consumer = Specification::Consumer.new(@spec, :osx)
        expect(osx_consumer.pod_target_xcconfig).to eq({ 'OTHER_LDFLAGS' => '-lObjC' })
      end

      it 'merges the legacy xcconfig attribute' do
        @spec.attributes_hash['xcconfig'] = { 'OTHER_LDFLAGS' => '-Wl' }
        @spec.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-lObjC' }
        @spec.user_target_xcconfig = { 'OTHER_LDFLAGS' => '-lObjC' }

        expect(@consumer.pod_target_xcconfig).to eq({ 'OTHER_LDFLAGS' => '-Wl -lObjC' })
        expect(@consumer.user_target_xcconfig).to eq({ 'OTHER_LDFLAGS' => '-Wl -lObjC' })
      end

      #------------------#

      describe 'info_plist' do
        it 'allows specifying Info.plist values' do
          value = {
            'SOME_VAR' => 'SOME_VALUE',
          }
          @spec.info_plist = value
          expect(@consumer.info_plist).to eq(value)
        end

        it 'does not inherit values from the parent' do
          @spec.info_plist = {
            'SOME_VAR' => 'SOME_VALUE',
          }
          @subspec.info_plist = {
            'OTHER_VAR' => 'OTHER_VALUE',
          }
          expect(@subspec_consumer.info_plist).to eq({
            'OTHER_VAR' => 'OTHER_VALUE',
          })
        end

        it 'allows specifying values by platform' do
          @spec.info_plist = { 'CFBundleIdentifier' => 'org.cocoapods.MyLib' }
          @spec.osx.info_plist = { 'CFBundleIdentifier' => 'org.cocoapods.MyLibOSX' }
          osx_consumer = Specification::Consumer.new(@spec, :osx)
          expect(osx_consumer.info_plist).to eq({ 'CFBundleIdentifier' => 'org.cocoapods.MyLibOSX' })
          expect(@consumer.info_plist).to eq({ 'CFBundleIdentifier' => 'org.cocoapods.MyLib' })
        end
      end

      #------------------#

      it 'allows to specify the contents of the prefix header' do
        @spec.prefix_header_contents = '#import <UIKit/UIKit.h>'
        expect(@consumer.prefix_header_contents).to eq('#import <UIKit/UIKit.h>')
      end

      it 'allows to specify the contents of the prefix header as an array' do
        @spec.prefix_header_contents = ['#import <UIKit/UIKit.h>', '#import <Foundation/Foundation.h>']
        expect(@consumer.prefix_header_contents).to eq("#import <UIKit/UIKit.h>\n#import <Foundation/Foundation.h>")
      end

      it 'strips the indentation of the prefix headers' do
        headers = <<-DESC
          #import <UIKit/UIKit.h>
          #import <Foundation/Foundation.h>
        DESC
        @spec.prefix_header_contents = headers
        expect(@consumer.prefix_header_contents).to eq("#import <UIKit/UIKit.h>\n#import <Foundation/Foundation.h>")
      end

      it 'inherits the contents of the prefix header' do
        @spec.prefix_header_contents = '#import <UIKit/UIKit.h>'
        expect(@subspec_consumer.prefix_header_contents).to eq('#import <UIKit/UIKit.h>')
      end

      #------------------#

      it 'allows to specify the path of compiler header file' do
        @spec.prefix_header_file = 'iphone/include/prefix.pch'
        expect(@consumer.prefix_header_file).to eq('iphone/include/prefix.pch')
      end

      it 'inherits the path of compiler header file from the parent' do
        @spec.prefix_header_file = 'iphone/include/prefix.pch'
        expect(@subspec_consumer.prefix_header_file).to eq('iphone/include/prefix.pch')
      end

      #------------------#

      it 'allows to specify a module name' do
        @spec.module_name = 'Three20Core'
        expect(@consumer.module_name).to eq('Three20Core')
      end

      #------------------#

      it 'allows to specify a directory to use for the headers' do
        @spec.header_dir = 'Three20Core'
        expect(@consumer.header_dir).to eq('Three20Core')
      end

      it 'inherits the directory to use for the headers from the parent' do
        @spec.header_dir = 'Three20Core'
        expect(@subspec_consumer.header_dir).to eq('Three20Core')
      end

      #------------------#

      it 'allows to specify a directory to preserver the namespacing of the headers' do
        @spec.header_mappings_dir = 'src/include'
        expect(@consumer.header_mappings_dir).to eq('src/include')
      end

      it 'inherits the directory to use for the headers from the parent' do
        @spec.header_mappings_dir = 'src/include'
        expect(@subspec_consumer.header_mappings_dir).to eq('src/include')
      end

      #------------------#

      it 'returns nil for test type for a root spec' do
        expect(@consumer.test_type).to be_nil
      end

      it 'returns nil for test type for subspec' do
        expect(@subspec_consumer.test_type).to be_nil
      end

      it 'returns the default test type for a test subspec' do
        @spec.test_spec {}
        test_spec = @spec.test_specs.first
        test_consumer = Specification::Consumer.new(test_spec, :ios)
        expect(test_consumer.test_type).to eq(:unit)
      end

      it 'allows to specify the unit test type for a test subspec' do
        @spec.test_spec {}
        test_spec = @spec.test_specs.first
        test_spec.test_type = :unit
        test_consumer = Specification::Consumer.new(test_spec, :ios)
        expect(test_consumer.test_type).to eq(:unit)
      end

      it 'allows to specify the ui test type for a test subspec' do
        @spec.test_spec {}
        test_spec = @spec.test_specs.first
        test_spec.test_type = :ui
        test_consumer = Specification::Consumer.new(test_spec, :ios)
        expect(test_consumer.test_type).to eq(:ui)
      end

      it 'returns the test type as a symbol when consuming JSON specs' do
        @spec.test_spec {}
        test_spec = @spec.test_specs.first
        test_spec.test_type = :unit
        json_spec = @spec.to_json
        test_consumer = Specification::Consumer.new(Specification.from_json(json_spec).test_specs.first, :ios)
        expect(test_consumer.test_type).to eq(:unit)
      end

      it 'allows to specify whether the specification requires an app host' do
        @spec.test_spec {}
        test_spec = @spec.test_specs.first
        test_spec.requires_app_host = true
        test_consumer = Specification::Consumer.new(test_spec, :ios)
        expect(test_consumer.requires_app_host?).to be(true)
      end

      it 'allows to specify a specific app host to use' do
        @spec.test_spec {}
        test_spec = @spec.test_specs.first
        test_spec.app_host_name = 'Foo/App'
        test_consumer = Specification::Consumer.new(test_spec, :ios)
        expect(test_consumer.app_host_name).to eq('Foo/App')
      end

      it 'returns the scheme configuration of a test spec' do
        @spec.test_spec {}
        test_spec = @spec.test_specs.first
        test_spec.scheme = { :launch_arguments => ['Arg1'] }
        test_consumer = Specification::Consumer.new(test_spec, :ios)
        expect(test_consumer.scheme).to eq({ :launch_arguments => ['Arg1'] })
      end

      #------------------#

      it 'returns the script phases in correct format' do
        @spec.script_phases = { :name => 'Hello World', :script => 'echo "Hello World"' }
        expect(@consumer.script_phases).to eq([{ :name => 'Hello World', :script => 'echo "Hello World"', :execution_position => :any }])
      end

      it 'returns the script phases in correct format with optional options' do
        @spec.script_phases = { :name => 'Hello Ruby World', :script => 'puts "Hello Ruby World"', :shell_path => 'usr/bin/ruby' }
        expect(@consumer.script_phases).to eq([
          { :name => 'Hello Ruby World', :script => 'puts "Hello Ruby World"', :shell_path => 'usr/bin/ruby', :execution_position => :any },
        ])
      end

      it 'returns the script phases in correct format for multiple script phases' do
        @spec.script_phases = [
          { :name => 'Hello World', :script => 'echo "Hello World"' },
          { :name => 'Hello Ruby World', :script => 'puts "Hello Ruby World"', :shell_path => 'usr/bin/ruby' },
        ]
        expect(@consumer.script_phases).to eq([
          { :name => 'Hello World', :script => 'echo "Hello World"', :execution_position => :any },
          { :name => 'Hello Ruby World', :script => 'puts "Hello Ruby World"', :shell_path => 'usr/bin/ruby', :execution_position => :any },
        ])
      end

      it 'handles multi-platform script phases' do
        @spec.ios.script_phases = { :name => 'Hello World iOS', :script => 'echo "Hello World iOS"' }
        expect(@consumer.script_phases).to eq([{ :name => 'Hello World iOS', :script => 'echo "Hello World iOS"', :execution_position => :any }])
      end

      it 'returns both global and multi platform script phases' do
        @spec.script_phases = { :name => 'Hello World', :script => 'echo "Hello World"' }
        @spec.ios.script_phases = { :name => 'Hello World iOS', :script => 'echo "Hello World iOS"', :execution_position => :any }
        expect(@consumer.script_phases).to eq([
          { :name => 'Hello World', :script => 'echo "Hello World"', :execution_position => :any },
          { :name => 'Hello World iOS', :script => 'echo "Hello World iOS"', :execution_position => :any },
        ])
      end

      it 'retains the value set for execution position' do
        @spec.script_phases = { :name => 'Hello World', :script => 'echo "Hello World"', :execution_position => :before_compile }
        @spec.ios.script_phases = { :name => 'Hello World iOS', :script => 'echo "Hello World iOS"', :execution_position => :after_compile }
        expect(@consumer.script_phases).to eq([
          { :name => 'Hello World', :script => 'echo "Hello World"', :execution_position => :before_compile },
          { :name => 'Hello World iOS', :script => 'echo "Hello World iOS"', :execution_position => :after_compile },
        ])
      end

      it 'returns the empty array if no script phases have been specified' do
        expect(@consumer.script_phases).to eq([])
      end
    end

    #-------------------------------------------------------------------------#

    describe 'File patterns attributes' do
      before do
        @spec = Spec.new do |s|
          s.name = 'Pod'
          s.subspec 'Subspec' do |_sp|
          end
        end
        @subspec = @spec.subspecs.first
        @consumer = Specification::Consumer.new(@spec, :ios)
        @subspec_consumer = Specification::Consumer.new(@subspec, :ios)
      end

      it "doesn't inherits the files patterns from the parent" do
        @spec.source_files = ['lib_classes/**/*']
        @subspec.source_files = ['subspec_classes/**/*']
        expect(@subspec_consumer.source_files).to eq(['subspec_classes/**/*'])
      end

      it 'wraps strings in an array' do
        @spec.source_files = 'lib_classes/**/*'
        expect(@consumer.source_files).to eq(['lib_classes/**/*'])
      end

      #------------------#

      it 'returns the source files' do
        @spec.source_files = ['lib_classes/**/*']
        expect(@consumer.source_files).to eq(['lib_classes/**/*'])
      end

      #------------------#

      it 'returns the public headers files' do
        @spec.public_header_files = ['include/**/*']
        expect(@consumer.public_header_files).to eq(['include/**/*'])
      end

      it 'returns the project headers files' do
        @spec.project_header_files = ['project/**/*']
        expect(@consumer.project_header_files).to eq(['project/**/*'])
      end

      it 'returns the private headers files' do
        @spec.private_header_files = ['private/**/*']
        expect(@consumer.private_header_files).to eq(['private/**/*'])
      end

      #------------------#

      it 'returns the frameworks bundles' do
        @spec.vendored_frameworks = ['MyFramework.framework', 'MyOtherFramework.framework']
        expect(@consumer.vendored_frameworks).to eq(['MyFramework.framework', 'MyOtherFramework.framework'])
      end

      #------------------#

      it 'returns the library files' do
        @spec.vendored_libraries = ['libProj4.a', 'libJavaScriptCore.a']
        expect(@consumer.vendored_libraries).to eq(['libProj4.a', 'libJavaScriptCore.a'])
      end

      #------------------#

      it 'returns the on demand resources specified as a string wrapped in an array' do
        @spec.on_demand_resources = { 'Maps' => 'MapView/Map/Resources/*.png' }
        expect(@consumer.on_demand_resources).to eq({ 'Maps' => { :paths => ['MapView/Map/Resources/*.png'], :category => :download_on_demand } })
      end

      it 'returns the on demand resources specified as an array wrapped in an array' do
        @spec.on_demand_resources = { 'Levels' => %w[Levels/Level1/Resources/*.png Levels/Level2/Resources/*.png] }
        expect(@consumer.on_demand_resources).to eq({
          'Levels' => { :paths => %w[Levels/Level1/Resources/*.png Levels/Level2/Resources/*.png], :category => :download_on_demand },
        })
      end

      it 'handles multi-platform on demand resources' do
        @spec.ios.on_demand_resources = { 'Maps' => 'MapView/Map/Resources/*.png' }
        expect(@consumer.on_demand_resources).to eq({ 'Maps' => { :paths => ['MapView/Map/Resources/*.png'], :category => :download_on_demand } })
      end

      it 'handles on demand resources with categories' do
        @spec.on_demand_resources = { 'Maps' => { :paths => 'MapView/Map/Resources/*.png', :category => :initial_install } }
        expect(@consumer.on_demand_resources).to eq({ 'Maps' => { :paths => ['MapView/Map/Resources/*.png'], :category => :initial_install } })
      end

      it 'handles on demand resources with keys and values as strings' do
        @spec.on_demand_resources = { 'Maps' => { 'paths' => 'MapView/Map/Resources/*.png', 'category' => 'initial_install' } }
        expect(@consumer.on_demand_resources).to eq({ 'Maps' => { :paths => ['MapView/Map/Resources/*.png'], :category => :initial_install } })
      end

      it 'merges multi platform on demand resources if needed' do
        @spec.on_demand_resources = { 'Maps' => 'MapView/Map/Resources/*.png' }
        @spec.ios.on_demand_resources = { 'Maps-iOS' => ['MapView/Map/iOS/Resources/*.png'] }
        expect(@consumer.on_demand_resources).to eq({
          'Maps' => { :paths => ['MapView/Map/Resources/*.png'], :category => :download_on_demand },
          'Maps-iOS' => { :paths => ['MapView/Map/iOS/Resources/*.png'], :category => :download_on_demand },
        })
      end

      it 'returns the resource bundles' do
        @spec.resource_bundles = { 'MapBox' => 'MapView/Map/Resources/*.png' }
        expect(@consumer.resource_bundles).to eq({ 'MapBox' => ['MapView/Map/Resources/*.png'] })
      end

      it 'handles multi-platform resource bundles' do
        @spec.ios.resource_bundles = { 'MapBox' => 'MapView/Map/Resources/*.png' }
        expect(@consumer.resource_bundles).to eq({ 'MapBox' => ['MapView/Map/Resources/*.png'] })
      end

      it 'merges multi platform resource bundles if needed' do
        @spec.resource_bundles = { 'MapBox' => 'MapView/Map/Resources/*.png' }
        @spec.ios.resource_bundles = { 'MapBox-iOS' => ['MapView/Map/iOS/Resources/*.png'] }
        expect(@consumer.resource_bundles).to eq({
          'MapBox' => ['MapView/Map/Resources/*.png'],
          'MapBox-iOS' => ['MapView/Map/iOS/Resources/*.png'],
        })
      end

      it 'merges the file patterns of multi platform resource bundles if needed' do
        @spec.resource_bundles = { 'MapBox' => 'MapView/Map/Resources/*.png' }
        @spec.ios.resource_bundles = { 'MapBox' => ['MapView/Map/iOS/Resources/*.png'] }
        expect(@consumer.resource_bundles).to eq({
          'MapBox' => ['MapView/Map/Resources/*.png', 'MapView/Map/iOS/Resources/*.png'],
        })
      end

      it 'returns the empty hash if no resource bundles have been specified' do
        expect(@consumer.resource_bundles).to eq({})
      end

      #------------------#

      it 'returns the resources files' do
        @spec.resources = ['frameworks/CrashReporter.framework']
        expect(@consumer.resources).to eq(['frameworks/CrashReporter.framework'])
      end

      it "doesn't inherit resources from the parent" do
        @spec.resources = ['parent_resources/*']
        @subspec.resources = ['subspec_resources/*']
        expect(@subspec_consumer.resources).to eq(['subspec_resources/*'])
      end

      it 'has a singular form for resources' do
        @spec.resource = 'lib_resources/file.png'
        expect(@consumer.resources).to eq(['lib_resources/file.png'])
      end

      #------------------#

      it 'returns the paths to exclude' do
        @spec.exclude_files = 'Classes/**/unused.{h,m}'
        expect(@consumer.exclude_files).to eq(['Classes/**/unused.{h,m}'])
      end

      #------------------#

      it 'returns the paths to preserve' do
        @spec.preserve_paths = ['Frameworks/*.framework']
        expect(@consumer.preserve_paths).to eq(['Frameworks/*.framework'])
      end

      it 'can accept a single path to preserve' do
        @spec.preserve_path = 'Frameworks/*.framework'
        expect(@consumer.preserve_paths).to eq(['Frameworks/*.framework'])
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Dependencies' do
      before do
        @spec = Spec.new do |s|
          s.name = 'Pod'
          s.dependency 'AFNetworking'
          s.osx.dependency 'MagicalRecord'
          s.subspec 'Subspec' do |sp|
            sp.dependency 'libPusher', '1.0'
          end
        end
        @subspec = @spec.subspecs.first
        @subspec = @spec.subspecs.first
        @consumer = Specification::Consumer.new(@spec, :ios)
        @subspec_consumer = Specification::Consumer.new(@subspec, :ios)
      end

      it 'returns the dependencies on other Pods for the activated platform' do
        expect(@consumer.dependencies).to eq([Dependency.new('AFNetworking')])
      end

      it 'inherits the dependencies of the parent' do
        expect(@subspec_consumer.dependencies.sort).to eq([
          Dependency.new('AFNetworking'), Dependency.new('libPusher', '1.0')])
      end

      it 'takes into account the dependencies specified for a platform' do
        osx_consumer = Specification::Consumer.new(@spec, :osx)
        expect(osx_consumer.dependencies.sort).to eq([
          Dependency.new('AFNetworking'), Dependency.new('MagicalRecord')])
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Private helpers' do
      before do
        @spec = Spec.new do |s|
          s.name = 'Pod'
          s.source_files = 'spec_files'
          s.ios.source_files = 'ios_files'
          s.framework = 'spec_framework'
          s.subspec 'Subspec' do |ss|
            ss.source_files = 'subspec_files'
            ss.framework = 'subspec_framework'
          end
        end
        @subspec = @spec.subspecs.first
        @consumer = Specification::Consumer.new(@spec, :ios)
        @subspec_consumer = Specification::Consumer.new(@subspec, :ios)
      end

      #--------------------------------------#

      describe '#value_for_attribute' do
        it 'takes into account inheritance' do
          expect(@subspec_consumer.frameworks).to eq(%w(spec_framework subspec_framework))
        end

        it 'takes into account multiplatform values' do
          expect(@consumer.source_files).to eq(%w(spec_files ios_files))
          osx_consumer = Specification::Consumer.new(@spec, :osx)
          expect(osx_consumer.source_files).to eq(['spec_files'])
        end

        it 'takes into account a default value if specified' do
          expect(@consumer.requires_arc).to eq(true)
        end

        it 'initializes the value to the empty container if no value could be resolved' do
          expect(@consumer.libraries).to eq([])
        end
      end

      #--------------------------------------#

      describe '#value_with_inheritance' do
        it 'handles root specs' do
          attr = Specification::DSL.attributes[:source_files]
          value = @consumer.send(:value_with_inheritance, @spec, attr)
          expect(value).to eq(%w(spec_files ios_files))
        end

        it 'takes into account the value of the parent if needed' do
          attr = Specification::DSL.attributes[:frameworks]
          value = @consumer.send(:value_with_inheritance, @subspec, attr)
          expect(value).to eq(%w(spec_framework subspec_framework))
        end

        it "doesn't inherits value of the parent if the attribute is not inherited" do
          attr = Specification::DSL.attributes[:source_files]
          attr.stubs(:inherited?).returns(false)
          value = @consumer.send(:value_with_inheritance, @subspec, attr)
          expect(value).to eq(['subspec_files'])
        end
      end

      #--------------------------------------#

      describe '#raw_value_for_attribute' do
        it 'returns the raw value as stored in the specification' do
          attr = Specification::DSL.attributes[:source_files]
          osx_consumer = Specification::Consumer.new(@spec, :osx)
          value = osx_consumer.send(:raw_value_for_attribute, @spec, attr)
          expect(value).to eq(['spec_files'])
        end

        it 'takes into account the multi-platform values' do
          attr = Specification::DSL.attributes[:source_files]
          value = @consumer.send(:raw_value_for_attribute, @spec, attr)
          expect(value).to eq(%w(spec_files ios_files))
        end
      end

      #--------------------------------------#

      describe '#merge_values' do
        it 'returns the current value if the value to merge is nil' do
          attr = Specification::DSL::Attribute.new(:test, :container => Hash)
          result = @consumer.send(:merge_values, attr, 'value', nil)
          expect(result).to eq('value')
        end

        it 'returns the value to merge if the current value is nil' do
          attr = Specification::DSL::Attribute.new(:test, :container => Hash)
          result = @consumer.send(:merge_values, attr, nil, 'value')
          expect(result).to eq('value')
        end

        it 'handles boolean values' do
          attr = Specification::DSL::Attribute.new(:test, :types => [TrueClass, FalseClass])
          expect(@consumer.send(:merge_values, attr, false, nil)).to eq(false)
          expect(@consumer.send(:merge_values, attr, false, false)).to eq(false)
          expect(@consumer.send(:merge_values, attr, false, true)).to eq(true)
          expect(@consumer.send(:merge_values, attr, true, false)).to eq(false)
        end

        it 'concatenates the values of attributes contained in an array' do
          attr = Specification::DSL::Attribute.new(:test, :container => Array)
          result = @consumer.send(:merge_values, attr, 'CoreGraphics', 'CoreData')
          expect(result).to eq(%w(CoreGraphics CoreData))
        end

        it 'handles hashes while merging values' do
          attr = Specification::DSL::Attribute.new(:test, :container => Hash)
          result = @consumer.send(:merge_values, attr, { :value1 => '1' }, :value2 => '2')
          expect(result).to eq({
            :value1 => '1',
            :value2 => '2',
          })
        end

        it 'merges the values of the keys of hashes contained in an array' do
          attr = Specification::DSL::Attribute.new(:test, :container => Hash)
          value = { :resources => %w(A B) }
          value_to_mege = { :resources => 'C' }
          result = @consumer.send(:merge_values, attr, value, value_to_mege)
          expect(result).to eq({ :resources => %w(A B C) })
        end

        it 'merges the values of the keys of hashes contained in a string' do
          attr = Specification::DSL::Attribute.new(:test, :container => Hash)
          value = { 'OTHER_LDFLAGS' => '-lObjC' }
          value_to_mege = { 'OTHER_LDFLAGS' => '-framework SystemConfiguration' }
          result = @consumer.send(:merge_values, attr, value, value_to_mege)
          expect(result).to eq({ 'OTHER_LDFLAGS' => '-lObjC -framework SystemConfiguration' })
        end

        it 'returns the original value if the attribute is a string' do
          attr = Specification::DSL::Attribute.new(:test, {})
          existing_value = 'header_dir_1'
          value_to_mege = 'header_dir_2'
          result = @consumer.send(:merge_values, attr, existing_value, value_to_mege)
          expect(result).to eq('header_dir_2')
        end
      end

      #--------------------------------------#
    end
  end
end
