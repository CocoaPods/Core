require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Specification::Consumer do

    describe "In general" do

      before do
        @spec = Spec.new do |s|
          s.name = "Pod"
        end
        @consumer = Specification::Consumer.new(@spec, :ios)
      end

      it "returns the specification" do
        @consumer.spec.should == @spec
      end

      it "returns the platform" do
        @consumer.consumer_platform.should == :ios
      end
    end

    #-------------------------------------------------------------------------#

    describe "Platform attributes" do
      # before do
      #   @spec = Spec.new do |s|
      #     s.name = "Pod"
      #     s.subspec 'Subspec' do |sp|
      #     end
      #   end
      #   @subspec = @spec.subspecs.first
      #   @consumer = Specification::Consumer.new(@spec, :ios)
      # end

      # it "allows to specify a single supported platform" do
      #   @spec.platform = :ios, '4.3'
      #   @consumer.platform.should == :ios
      # end

      # it "inherits the platform from the parent if no specified" do
      #   @spec.platform = :ios, '4.3'
      #   @subspec_consumer = Specification::Consumer.new(@subspec, :ios)
      #   @subspec_consumer.platform.should == :ios
      # end

      # it "allows to specify a deployment target for each platform" do
      #   @spec.ios.deployment_target = '4.3'
      #   @consumer.platform.should == :ios
      # end

      # it "returns the list of the available platforms" do
      #   @spec.available_platforms.sort_by{ |p| p.name.to_s }.should == [
      #     Platform.new(:ios),
      #     Platform.new(:osx),
      #   ]
      # end

      # it "takes into account the platform of the parent for returning the list of the available platforms" do
      #   @spec.platform = :ios, '4.3'
      #   @subspec.available_platforms.sort_by(&:name).should == [ Platform.new(:ios, 4.3), ]
      # end

      # it "takes into account the specified deployment targets for returning the list of the available platforms" do
      #   @spec.platform = :ios, '4.3'
      #   @subspec.ios.deployment_target = '6.0'
      #   @subspec.available_platforms.sort_by(&:name).should == [ Platform.new(:ios, '6.0') ]
      # end

      # it "prioritizes the explicitly defined platform for returning the list of the available platforms" do
      #   @subspec.platform = :ios, '4.3'
      #   @subspec.ios.deployment_target = '6.0'
      #   @subspec.available_platforms.sort_by(&:name).should == [ Platform.new(:ios, '4.3') ]
      # end
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
        @consumer.requires_arc?.should == false
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

      it "has a default value for the source files" do
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

      it "has a default value for the resources files" do
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

      it "has a default value for the paths to exclude" do
        @consumer.exclude_files.should ==  ["Classes/osx/**/*", "Resources/osx/**/*"]
        osx_consumer = Specification::Consumer.new(@spec, :osx)
        osx_consumer.exclude_files.should ==  ["Classes/ios/**/*", "Resources/ios/**/*"]
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
        @subspec_consumer.dependencies.should == [ Dependency.new('AFNetworking'), Dependency.new('libPusher') ]
      end

      it "takes into account the dependencies specified for a platform" do
        osx_consumer = Specification::Consumer.new(@spec, :osx)
        osx_consumer.dependencies.should == [ Dependency.new('AFNetworking'), Dependency.new('MagicalRecord') ]
      end
    end

    #-------------------------------------------------------------------------#

    describe "Private helpers" do

      before do
        @spec = Spec.new do |s|
          s.name = "Pod"
        end
        @consumer = Specification::Consumer.new(@spec, :ios)
      end

      it "handles hashes while merging values" do
        attr = Specification::DSL::Attribute.new(:test, { :container => Hash })
        result = @consumer.send(:merge_values, attr, {:value1 => '1'}, {:value2 => '2'})
        result.should == {
          :value1 => '1',
          :value2 => '2',
        }
      end
    end

  end
end
