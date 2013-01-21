require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Specification::Consumer do

    describe "In general" do

      before do
        @spec = Spec.new do |s|
          s.name = "Pod"
          s.platform = :ios
        end
        @consumer = Specification::Consumer.new(@spec, :ios)
      end

      it "returns the specification" do
        @consumer.spec.should == @spec
      end

      it "returns the platform" do
        @consumer.platform.should == :ios
      end

      it "raises if the specification does not suppor the given platform" do
        e = lambda {Specification::Consumer.new(@spec, :osx)}.should.raise StandardError
        e.message.should.match /not compatible with osx/
      end
    end

    #-------------------------------------------------------------------------#

    describe "Regular attributes" do
      before do
        @spec = Spec.new do |s|
          s.name = "Pod"
          s.subspec 'Subspec' do |sp|
          end
        end
        @subspec = @spec.subspecs.first
        @consumer = Specification::Consumer.new(@spec, :ios)
        @subspec_consumer = Specification::Consumer.new(@subspec, :ios)
      end

      #------------------#

      it "allows to specify whether the specification requires ARC" do
        @spec.requires_arc = true
        @consumer.requires_arc?.should.be.true
      end

      it "doesn't requires arc by default" do
        @consumer.requires_arc?.should.be.false
      end

      it "inherits where it requires arc from the parent" do
        @spec.requires_arc = true
        @subspec_consumer.requires_arc?.should.be.true
      end

      #----------------#

      it "allows to specify the frameworks" do
        @spec.framework = %w[ QuartzCore CoreData ]
        @consumer.frameworks.should == %w[ QuartzCore CoreData ]
      end

      it "allows to specify a single framework" do
        @spec.framework = 'QuartzCore'
        @consumer.frameworks.should == %w[ QuartzCore ]
      end

      it "inherits the frameworks of the parent" do
        @spec.framework = 'QuartzCore'
        @subspec.framework = 'CoreData'
        @subspec_consumer.frameworks.should == %w[ QuartzCore CoreData ]
      end

      #------------------#

      it "allows to specify the weak frameworks" do
        @spec.weak_frameworks = %w[ Twitter iAd ]
        @consumer.weak_frameworks.should == %w[ Twitter iAd ]
      end

      it "allows to specify a single weak framework" do
        @spec.weak_framework = 'Twitter'
        @consumer.weak_frameworks.should == %w[ Twitter ]
      end

      it "inherits the weak frameworks of the parent" do
        @spec.weak_framework    = 'Twitter'
        @subspec.weak_framework = 'iAd'
        @subspec_consumer.weak_frameworks.should == %w[ Twitter iAd ]
      end

      #------------------#

      it "allows to specify the libraries" do
        @spec.libraries = 'z', 'xml2'
        @consumer.libraries.should  == %w[ z xml2 ]
      end

      it "allows to specify a single library" do
        @spec.library = 'z'
        @consumer.libraries.should  == %w[ z ]
      end

      it "inherits the libraries from the parent" do
        @spec.library    = 'z'
        @subspec.library = 'xml2'
        @subspec_consumer.libraries.should == %w[ z xml2 ]
      end

      #------------------#

      it "allows to specify compiler flags" do
        @spec.compiler_flags = %w[ -Wdeprecated-implementations -Wunused-value ]
        @consumer.compiler_flags.should == %w[ -Wdeprecated-implementations -Wunused-value ]
      end

      it "allows to specify a single compiler flag" do
        @spec.compiler_flag = '-Wdeprecated-implementations'
        @consumer.compiler_flags.should == %w[ -Wdeprecated-implementations ]
      end

      it "inherits the compiler flags from the parent" do
        @spec.compiler_flag = '-Wdeprecated-implementations'
        @subspec.compiler_flag = '-Wunused-value'
        @subspec_consumer.compiler_flags.should == %w[ -Wdeprecated-implementations -Wunused-value ]
      end

      it "merges the compiler flags so values for platforms can be specified" do
        @spec.compiler_flags = '-Wdeprecated-implementations'
        @spec.ios.compiler_flags = '-Wunused-value'
        @consumer.compiler_flags.should == %w[ -Wdeprecated-implementations -Wunused-value ]
        osx_consumer = Specification::Consumer.new(@spec, :osx)
        osx_consumer.compiler_flags.should == %w[ -Wdeprecated-implementations ]
      end

      #------------------#

      it "allows to specify xcconfig settings" do
        @spec.xcconfig = { 'OTHER_LDFLAGS' => '-lObjC' }
        @consumer.xcconfig.should == { 'OTHER_LDFLAGS' => '-lObjC' }
      end

      it "inherits the xcconfig values from the parent" do
        @spec.xcconfig = { 'OTHER_LDFLAGS' => '-lObjC' }
        @subspec.xcconfig = { 'OTHER_LDFLAGS' => '-Wl -no_compact_unwind' }
        @subspec_consumer.xcconfig.should == { 'OTHER_LDFLAGS' => '-lObjC -Wl -no_compact_unwind' }
      end

      it "merges the xcconfig values so values for platforms can be specified" do
        @spec.xcconfig = { 'OTHER_LDFLAGS' => '-lObjC' }
        @spec.ios.xcconfig = { 'OTHER_LDFLAGS' => '-Wl -no_compact_unwind' }
        @consumer.xcconfig.should == { 'OTHER_LDFLAGS' => '-lObjC -Wl -no_compact_unwind' }
        osx_consumer = Specification::Consumer.new(@spec, :osx)
        osx_consumer.xcconfig.should == { 'OTHER_LDFLAGS' => '-lObjC' }
      end

      #------------------#

      it "allows to specify the contents of the prefix header" do
        @spec.prefix_header_contents = '#import <UIKit/UIKit.h>'
        @consumer.prefix_header_contents.should == '#import <UIKit/UIKit.h>'
      end

      it "allows to specify the contents of the prefix header as an array" do
        @spec.prefix_header_contents = '#import <UIKit/UIKit.h>', '#import <Foundation/Foundation.h>'
        @consumer.prefix_header_contents.should == "#import <UIKit/UIKit.h>\n#import <Foundation/Foundation.h>"
      end

      it "inherits the contents of the prefix header" do
        @spec.prefix_header_contents = '#import <UIKit/UIKit.h>'
        @subspec_consumer.prefix_header_contents.should == '#import <UIKit/UIKit.h>'
      end

      #------------------#

      it "allows to specify the path of compiler header file" do
        @spec.prefix_header_file = 'iphone/include/prefix.pch'
        @consumer.prefix_header_file.should == 'iphone/include/prefix.pch'
      end

      it "inherits the path of compiler header file from the parent" do
        @spec.prefix_header_file = 'iphone/include/prefix.pch'
        @subspec_consumer.prefix_header_file.should == 'iphone/include/prefix.pch'
      end

      #------------------#

      it "allows to specify a directory to use for the headers" do
        @spec.header_dir = 'Three20Core'
        @consumer.header_dir.should == 'Three20Core'
      end

      it "inherits the directory to use for the headers from the parent" do
        @spec.header_dir = 'Three20Core'
        @subspec_consumer.header_dir.should == 'Three20Core'
      end

      #------------------#

      it "allows to specify a directory to preserver the namespacing of the headers" do
        @spec.header_mappings_dir = 'src/include'
        @consumer.header_mappings_dir.should == 'src/include'
      end

      it "inherits the directory to use for the headers from the parent" do
        @spec.header_mappings_dir = 'src/include'
        @subspec_consumer.header_mappings_dir.should == 'src/include'
      end
    end

    #-------------------------------------------------------------------------#

    describe "File patterns attributes" do
      before do
        @spec = Spec.new do |s|
          s.name = "Pod"
          s.subspec 'Subspec' do |sp|
          end
        end
        @subspec = @spec.subspecs.first
        @consumer = Specification::Consumer.new(@spec, :ios)
        @subspec_consumer = Specification::Consumer.new(@subspec, :ios)
      end

      it "inherits the files patterns from the parent" do
        @spec.source_files = [ "lib_classes/**/*" ]
        @subspec.source_files = [ "subspec_classes/**/*" ]
        @subspec_consumer.source_files.should == [ "lib_classes/**/*", "subspec_classes/**/*" ]
      end

      it "wraps strings in an array" do
        @spec.source_files = "lib_classes/**/*"
        @consumer.source_files.should == [ "lib_classes/**/*" ]
      end

      #------------------#

      it "returns the source files" do
        @spec.source_files = [ "lib_classes/**/*" ]
        @consumer.source_files.should == [ "lib_classes/**/*" ]
      end

      it "returns the default for the source files attribute if no value is specified" do
        @consumer.source_files.should == [ "Classes/**/*.{h,m}" ]
      end

      #------------------#

      it "returns the public headers files" do
        @spec.public_header_files = [ "include/**/*" ]
        @consumer.public_header_files.should == [ "include/**/*" ]
      end

      #------------------#

      it "returns the resources files" do
        @spec.resources = { :frameworks => ['frameworks/CrashReporter.framework'] }
        @consumer.resources.should == { :frameworks => ['frameworks/CrashReporter.framework'] }
      end

      it "inherit resources from the parent" do
        @spec.resources = {
          :frameworks => ['frameworks/*'],
          :resources => 'parent_resources/*'
        }
        @subspec.resources = {
          :shared_support => ['shared_support/*'],
          :resources => ['subspec_resources/*']
        }

        @subspec_consumer.resources.should == {
          :frameworks => ['frameworks/*'],
          :shared_support => ['shared_support/*'],
          :resources => ['parent_resources/*', 'subspec_resources/*'],
        }
      end

      it "wrap to arrays resources specified as a string with a destination" do
        @spec.resources = { :frameworks => 'frameworks/CrashReporter.framework' }
        @consumer.resources.should == { :frameworks => ['frameworks/CrashReporter.framework'] }
      end

      it "assigns the `:resources` destination if resources are not specified with one" do
        @spec.resources = 'frameworks/CrashReporter.framework'
        @consumer.resources.should == { :resources => ['frameworks/CrashReporter.framework'] }
      end

      it "returns the default for the resources attribute if no value is specified" do
        @consumer.resources.should == { :resources => [ 'Resources/**/*' ] }
      end

      it "has a singular form for resources" do
        @spec.resource = [ "lib_resources/**/*" ]
        @consumer.resources.should == {:resources=>["lib_resources/**/*"]}
      end

      #------------------#

      it "returns the paths to exclude" do
        @spec.exclude_files = "Classes/**/unused.{h,m}"
        @consumer.exclude_files.should == ["Classes/**/unused.{h,m}"]
      end

      it "returns the default for the exclude files attribute if no value is specified" do
        @consumer.exclude_files.should ==  ["Classes/**/osx/**/*", "Resources/**/osx/**/*"]
        osx_consumer = Specification::Consumer.new(@spec, :osx)
        osx_consumer.exclude_files.should ==  ["Classes/**/ios/**/*", "Resources/**/ios/**/*"]
      end

      #------------------#

      it "returns the paths to preserve" do
        @spec.preserve_paths = ["Frameworks/*.framework"]
        @consumer.preserve_paths.should == ["Frameworks/*.framework"]
      end

      it "can accept a single path to preserve" do
        @spec.preserve_path = "Frameworks/*.framework"
        @consumer.preserve_paths.should == ["Frameworks/*.framework"]
      end

    end

    #-------------------------------------------------------------------------#

    describe "Dependencies" do
      before do
        @spec = Spec.new do |s|
          s.name = "Pod"
          s.dependency 'AFNetworking'
          s.osx.dependency 'MagicalRecord'
          s.subspec 'Subspec' do |sp|
            sp.dependency 'libPusher'
          end
        end
        @subspec = @spec.subspecs.first
        @subspec = @spec.subspecs.first
        @consumer = Specification::Consumer.new(@spec, :ios)
        @subspec_consumer = Specification::Consumer.new(@subspec, :ios)
      end

      it "returns the dependencies on other Pods for the activated platform" do
        @consumer.dependencies.should == [ Dependency.new('AFNetworking') ]
      end

      it "inherits the dependencies of the parent" do
        @subspec_consumer.dependencies.sort.should == [
          Dependency.new('AFNetworking'), Dependency.new('libPusher') ]
      end

      it "takes into account the dependencies specified for a platform" do
        osx_consumer = Specification::Consumer.new(@spec, :osx)
        osx_consumer.dependencies.sort.should == [
          Dependency.new('AFNetworking'), Dependency.new('MagicalRecord') ]
      end
    end

    #-------------------------------------------------------------------------#

    describe "Private helpers" do

      before do
        @spec = Spec.new do |s|
          s.name = "Pod"
          s.source_files = "spec_files"
          s.ios.source_files = "ios_files"
          s.subspec 'Subspec' do |ss|
            ss.source_files = "subspec_files"
          end
        end
        @subspec = @spec.subspecs.first
        @consumer = Specification::Consumer.new(@spec, :ios)
        @subspec_consumer = Specification::Consumer.new(@subspec, :ios)
      end

      #--------------------------------------#

      describe "#value_for_attribute" do

        it "takes into account inheritance" do
          @subspec_consumer.source_files.should == ["spec_files", "ios_files", "subspec_files"]
        end

        it "takes into account multiplatform values" do
          @consumer.source_files.should == ["spec_files", "ios_files"]
          osx_consumer = Specification::Consumer.new(@spec, :osx)
          osx_consumer.source_files.should == ["spec_files"]
        end

        it "takes into account a default value if specified" do
          @consumer.resources.should == {:resources=>["Resources/**/*"]}
        end

        it "initializes the value to the empty container if no value could be resolved" do
          @consumer.frameworks.should == []
        end

        it "doesn't triggers the lazy evaluation of Rake::FileList [TEMPORARY]" do
          @subspec.source_files = Rake::FileList.new('FileList-Resources')
          computed = @subspec_consumer.source_files
          computed.find { |value| value.class == Rake::FileList }.should.not.be.nil
        end
      end

      #--------------------------------------#

      describe "#value_with_inheritance" do

        it "handles root specs" do
          attr = Specification::DSL.attributes[:source_files]
          value = @consumer.send(:value_with_inheritance, @spec, attr)
          value.should == ["spec_files", "ios_files"]
        end

        it "takes into account the value of the parent if needed" do
          attr = Specification::DSL.attributes[:source_files]
          value = @consumer.send(:value_with_inheritance, @subspec, attr)
          value.should ==  ["spec_files", "ios_files", "subspec_files"]
        end

        it "doesn't inherits value of the parent if the attribute is not inherited" do
          attr = Specification::DSL.attributes[:source_files]
          attr.stubs(:inherited?).returns(false)
          value = @consumer.send(:value_with_inheritance, @subspec, attr)
          value.should ==  ["subspec_files"]
        end
      end

      #--------------------------------------#

      describe "#raw_value_for_attribute" do

        it "returns the raw value as stored in the specification" do
          attr = Specification::DSL.attributes[:source_files]
          osx_consumer = Specification::Consumer.new(@spec, :osx)
          value = osx_consumer.send(:raw_value_for_attribute, @spec, attr)
          value.should == ["spec_files"]
        end

        it "takes into account the multi-platform values" do
          attr = Specification::DSL.attributes[:source_files]
          value = @consumer.send(:raw_value_for_attribute, @spec, attr)
          value.should ==  ["spec_files", "ios_files"]
        end
      end

      #--------------------------------------#

      describe "#merge_values" do

        it "returns the current value if the value to merge is undefined" do
          attr = Specification::DSL::Attribute.new(:test, { :container => Hash })
          result = @consumer.send(:merge_values, attr, "value", nil)
          result.should == "value"
        end

        it "returns the value to merge if the current value is nil" do
          attr = Specification::DSL::Attribute.new(:test, { :container => Hash })
          result = @consumer.send(:merge_values, attr, nil, "value")
          result.should == "value"
        end

        it "concatenates the values of attributes contained in an array" do
          attr = Specification::DSL::Attribute.new(:test, { :container => Array })
          result = @consumer.send(:merge_values, attr, 'CoreGraphics', 'CoreData')
          result.should == ['CoreGraphics', 'CoreData']
        end

        it "handles hashes while merging values" do
          attr = Specification::DSL::Attribute.new(:test, { :container => Hash })
          result = @consumer.send(:merge_values, attr, {:value1 => '1'}, {:value2 => '2'})
          result.should == {
            :value1 => '1',
            :value2 => '2',
          }
        end

        it "merges the values of the keys of hashes contained in an array" do
          attr = Specification::DSL::Attribute.new(:test, { :container => Hash })
          value = {:resources => ['A', 'B']}
          value_to_mege = {:resources => 'C'}
          result = @consumer.send(:merge_values, attr, value, value_to_mege)
          result.should == {:resources => ['A', 'B', 'C']}
        end

        it "merges the values of the keys of hashes contained in a string" do
          attr = Specification::DSL::Attribute.new(:test, { :container => Hash })
          value = {'OTHER_LDFLAGS' => '-lObjC'}
          value_to_mege = {'OTHER_LDFLAGS' => '-framework SystemConfiguration'}
          result = @consumer.send(:merge_values, attr, value, value_to_mege)
          result.should == {'OTHER_LDFLAGS' => '-lObjC -framework SystemConfiguration'}
        end
      end

      #--------------------------------------#

    end
  end
end
