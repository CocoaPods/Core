require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Specification::DSL do

    describe "Root specification attributes" do
      before do
        @spec = Spec.new do |s|
          s.name = "Pod"
          s.subspec 'Subspec' do |sp|
          end
        end
        @subspec = @spec.subspecs.first
      end

      it "returns the name" do
        @spec.name.should == "Pod"
      end

      it "includes the name of the parent in the names of subspecs" do
        @subspec.name.should == "Pod/Subspec"
      end

      it "returns the version" do
        @spec.version = '1.0'
        @spec.version.should == Version.new('1.0')
      end

      it "returns the authors" do
        hash = { 'Darth Vader' => 'darthvader@darkside.com',
                 'Wookiee' => 'wookiee@aggrrttaaggrrt.com' }
        @spec.authors = hash
        @spec.authors.should == hash
      end

      it "allows to specify the authors as an array if no email is available" do
        @spec.authors = 'Darth Vader', 'Wookiee'
        @spec.authors.should == { 'Darth Vader' => nil, 'Wookiee' => nil }
      end

      it "allows to specify a single author with no email" do
        @spec.authors = 'Darth Vader'
        @spec.authors.should == { 'Darth Vader' => nil }
      end

      it "allows to specify the authors as an array of strings and hashes" do
        @spec.authors = [ 'Darth Vader',
                          { 'Wookiee' => 'wookiee@aggrrttaaggrrt.com' } ]
        @spec.authors.should == { 'Darth Vader' => nil,
                                  'Wookiee' => 'wookiee@aggrrttaaggrrt.com' }
      end

      it "returns the license" do
        @spec.license = 'MIT'
        @spec.license.should == { :type => 'MIT' }
      end

      it "allows to specify the file containing the license if needed" do
        @spec.license = { :type => 'MIT', :file => 'MIT-LICENSE' }
        @spec.license.should == { :type => 'MIT', :file => 'MIT-LICENSE' }
      end

      it "allows to specify the entire text of the license if needed" do
        @spec.license = { :type => 'MIT', :text => <<-TEXT
                        Copyright
                        MIT-LICENSE
                          TEXT
        }
        @spec.license.should == { :type => 'MIT', :text => "Copyright\nMIT-LICENSE" }
      end

      it "checks for unknown keys in the license" do
        lambda { @spec.license = { :name => 'MIT' } }.should.raise StandardError
      end

      it "returns the homepage" do
        @spec.homepage = 'www.example.com'
        @spec.homepage.should == 'www.example.com'
      end

      it "returns the source" do
        @spec.source = { :git => 'www.example.com/repo.git' }
        @spec.source.should == { :git => 'www.example.com/repo.git' }
      end

      it "checks the source for unknown keys" do
        call = lambda { @spec.source = { :tig => 'www.example.com/repo.tig' } }
        call.should.raise StandardError
      end

      it "returns the summary" do
        @spec.summary = 'A library that describes the meaning of life.'
        @spec.summary.should == 'A library that describes the meaning of life.'
      end

      it "returns the descriptions" do
        desc = <<-DESC
           A library that computes the meaning of life. Features:
           1. Is self aware
           ...
           42. Likes candies.
        DESC
        @spec.description = desc
        @spec.description.should == desc.strip_heredoc
      end

      it "returns any setting to pass to the appledoc tool" do
        settings =  { :appledoc => ['--no-repeat-first-par', '--no-warn-invalid-crossref'] }
        @spec.documentation = settings
        @spec.documentation.should == settings
      end
    end

    #-----------------------------------------------------------------------------#

    describe "Platform attributes" do
      before do
        @spec = Spec.new do |s|
          s.name = "Pod"
          s.subspec 'Subspec' do |sp|
          end
        end
        @subspec = @spec.subspecs.first
      end

      it "allows to specify a single supported platform" do
        @spec.platform = :ios, '4.3'
        @spec.platform.should == :ios
      end

      it "inherits the platform from the parent if no specified" do
        @spec.platform = :ios, '4.3'
        @subspec.platform.should == :ios
      end

      it "allows to specify a deployment target for each platform" do
        @spec.ios.deployment_target = '4.3'
        @spec.activate_platform(:ios)
        @spec.deployment_target(:ios).should == Version.new('4.3')
      end

      it "returns the list of the available platforms" do
        @spec.available_platforms.sort_by{ |p| p.name.to_s }.should == [
          Platform.new(:ios),
          Platform.new(:osx),
        ]
      end

      it "takes into account the platform of the parent for returning the list of the available platforms" do
        @spec.platform = :ios, '4.3'
        @subspec.available_platforms.sort_by(&:name).should == [ Platform.new(:ios, 4.3), ]
      end

      it "takes into account the specified deployment targets for returning the list of the available platforms" do
        @spec.platform = :ios, '4.3'
        @subspec.ios.deployment_target = '6.0'
        @subspec.available_platforms.sort_by(&:name).should == [ Platform.new(:ios, '6.0') ]
      end

      it "prioritizes the explicitly defined platform for returning the list of the available platforms" do
        @subspec.platform = :ios, '4.3'
        @subspec.ios.deployment_target = '6.0'
        @subspec.available_platforms.sort_by(&:name).should == [ Platform.new(:ios, '4.3') ]
      end
    end

    #-----------------------------------------------------------------------------#

    describe "Regular attributes" do
      before do
        @spec = Spec.new do |s|
          s.name = "Pod"
          s.subspec 'Subspec' do |sp|
          end
        end
        @subspec = @spec.subspecs.first
        @spec.activate_platform(:ios)
      end

      #------------------#

      it "allows to specify whether the specification requires ARC" do
        @spec.requires_arc = true
        @spec.requires_arc.should.be.true
      end

      it "doesn't requires arc by default" do
        @spec.requires_arc.should == nil
      end

      it "inherits where it requires arc from the parent" do
        @spec.requires_arc = true
        @subspec.requires_arc.should.be.true
      end

      #------------------#

      it "allows to specify the frameworks" do
        @spec.framework = %w[ QuartzCore CoreData ]
        @spec.frameworks.should == %w[ QuartzCore CoreData ]
      end

      it "allows to specify a single framework" do
        @spec.framework = 'QuartzCore'
        @spec.frameworks.should == %w[ QuartzCore ]
      end

      it "inherits the frameworks of the parent" do
        @spec.framework = 'QuartzCore'
        @subspec.framework = 'CoreData'
        @subspec.frameworks.should == %w[ QuartzCore CoreData ]
      end

      #------------------#

      it "allows to specify the weak frameworks" do
        @spec.weak_frameworks = %w[ Twitter iAd ]
        @spec.weak_frameworks.should == %w[ Twitter iAd ]
      end

      it "allows to specify a single weak framework" do
        @spec.weak_framework = 'Twitter'
        @spec.weak_frameworks.should == %w[ Twitter ]
      end

      it "inherits the weak frameworks of the parent" do
        @spec.framework    = 'Twitter'
        @subspec.framework = 'iAd'
        @subspec.frameworks.should == %w[ Twitter iAd ]
      end

      #------------------#

      it "allows to specify the libraries" do
        @spec.libraries = 'z', 'xml2'
        @spec.libraries.should  == %w[ z xml2 ]
      end

      it "allows to specify a single library" do
        @spec.library = 'z'
        @spec.libraries.should  == %w[ z ]
      end

      it "inherits the libraries from the parent" do
        @spec.library    = 'z'
        @subspec.library = 'xml2'
        @subspec.libraries.should == %w[ z xml2 ]
      end

      #------------------#

      it "allows to specify compiler flags" do
        @spec.compiler_flags = %w[ -Wdeprecated-implementations -Wunused-value ]
        @spec.compiler_flags.should == %w[ -Wdeprecated-implementations -Wunused-value ]
      end

      it "allows to specify a single compiler flag" do
        @spec.compiler_flag = '-Wdeprecated-implementations'
        @spec.compiler_flags.should == %w[ -Wdeprecated-implementations ]
      end

      it "inherits the compiler flags from the parent" do
        @spec.compiler_flag = '-Wdeprecated-implementations'
        @subspec.compiler_flag = '-Wunused-value'
        @subspec.compiler_flags.should == %w[ -Wdeprecated-implementations -Wunused-value ]
      end

      it "merges the compiler flags so values for platforms can be specified" do
        @spec.compiler_flags = '-Wdeprecated-implementations'
        @spec.ios.compiler_flags = '-Wunused-value'
        @spec.activate_platform(:ios)
        @spec.compiler_flags.should == %w[ -Wdeprecated-implementations -Wunused-value ]
        @spec.activate_platform(:osx)
        @spec.compiler_flags.should == %w[ -Wdeprecated-implementations ]
      end

      #------------------#

      it "allows to specify xcconfig settings" do
        @spec.xcconfig = { 'OTHER_LDFLAGS' => '-lObjC' }
        @spec.xcconfig.should == { 'OTHER_LDFLAGS' => '-lObjC' }
      end

      it "inherits the xcconfig values from the parent" do
        @spec.xcconfig = { 'OTHER_LDFLAGS' => '-lObjC' }
        @subspec.xcconfig = { 'OTHER_LDFLAGS' => '-Wl -no_compact_unwind' }
        @subspec.xcconfig.should == { 'OTHER_LDFLAGS' => '-lObjC -Wl -no_compact_unwind' }
      end

      it "merges the xcconfig values so values for platforms can be specified" do
        @spec.xcconfig = { 'OTHER_LDFLAGS' => '-lObjC' }
        @spec.ios.xcconfig = { 'OTHER_LDFLAGS' => '-Wl -no_compact_unwind' }
        @spec.activate_platform(:ios)
        @spec.xcconfig.should == { 'OTHER_LDFLAGS' => '-lObjC -Wl -no_compact_unwind' }
        @spec.activate_platform(:osx)
        @spec.xcconfig.should == { 'OTHER_LDFLAGS' => '-lObjC' }
      end

      #------------------#

      it "allows to specify the contents of the prefix header" do
        @spec.prefix_header_contents = '#import <UIKit/UIKit.h>'
        @spec.prefix_header_contents.should == '#import <UIKit/UIKit.h>'
      end

      it "allows to specify the contents of the prefix header as an array" do
        @spec.prefix_header_contents = '#import <UIKit/UIKit.h>', '#import <Foundation/Foundation.h>'
        @spec.prefix_header_contents.should == "#import <UIKit/UIKit.h>\n#import <Foundation/Foundation.h>"
      end

      it "inherits the contents of the prefix header" do
        @spec.prefix_header_contents = '#import <UIKit/UIKit.h>'
        @subspec.prefix_header_contents.should == '#import <UIKit/UIKit.h>'
      end

      #------------------#

      it "allows to specify the path of compiler header file" do
        @spec.prefix_header_file = 'iphone/include/prefix.pch'
        @spec.prefix_header_file.should == 'iphone/include/prefix.pch'
      end

      it "inherits the path of compiler header file from the parent" do
        @spec.prefix_header_file = 'iphone/include/prefix.pch'
        @subspec.prefix_header_file.should == 'iphone/include/prefix.pch'
      end

      #------------------#

      it "allows to specify a directory to use for the headers" do
        @spec.header_dir = 'Three20Core'
        @spec.header_dir.should == 'Three20Core'
      end

      it "inherits the directory to use for the headers from the parent" do
        @spec.header_dir = 'Three20Core'
        @subspec.header_dir.should == 'Three20Core'
      end

      #------------------#

      it "allows to specify a directory to preserver the namespacing of the headers" do
        @spec.header_mappings_dir = 'src/include'
        @spec.header_mappings_dir.should == 'src/include'
      end

      it "inherits the directory to use for the headers from the parent" do
        @spec.header_mappings_dir = 'src/include'
        @subspec.header_mappings_dir.should == 'src/include'
      end

    end

    #-----------------------------------------------------------------------------#

    describe "File patterns attributes" do
      before do
        @spec = Spec.new do |s|
          s.name = "Pod"
          s.subspec 'Subspec' do |sp|
          end
        end
        @subspec = @spec.subspecs.first
        @spec.activate_platform(:ios)
      end

      it "inherits the files patterns from the parent" do
        @spec.source_files = [ "lib_classes/**/*" ]
        @subspec.source_files = [ "subspec_classes/**/*" ]
        @subspec.source_files.should == [ "lib_classes/**/*", "subspec_classes/**/*" ]
      end

      it "wraps strings in an array" do
        @spec.source_files = "lib_classes/**/*"
        @spec.source_files.should == [ "lib_classes/**/*" ]
      end

      #------------------#

      it "returns the source files" do
        @spec.source_files = [ "lib_classes/**/*" ]
        @spec.source_files.should == [ "lib_classes/**/*" ]
      end

      it "has a default value for the source files" do
        @spec.source_files.should == [ "Classes/**/*.{h,m}" ]
      end


      #------------------#

      it "returns the public headers files" do
        @spec.public_header_files = [ "include/**/*" ]
        @spec.public_header_files.should == [ "include/**/*" ]
      end

      #------------------#

      it "returns the resources files" do
        @spec.resources = { :frameworks => ['frameworks/CrashReporter.framework'] }
        @spec.resources.should == { :frameworks => ['frameworks/CrashReporter.framework'] }
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

        @subspec.resources.should == {
          :frameworks => ['frameworks/*'],
          :shared_support => ['shared_support/*'],
          :resources => ['parent_resources/*', 'subspec_resources/*'],
        }

      end

      it "wrap to arrays resources specified as a string with a destination" do
        @spec.resources = { :frameworks => 'frameworks/CrashReporter.framework' }
        @spec.resources.should == { :frameworks => ['frameworks/CrashReporter.framework'] }
      end

      it "assigns the `:resources` destination if resources are not specified with one" do
        @spec.resources = 'frameworks/CrashReporter.framework'
        @spec.resources.should == { :resources => ['frameworks/CrashReporter.framework'] }
      end

      it "has a default value for the resources files" do
        @spec.resources.should == { :resources => [ 'Resources/**/*' ] }
      end

      it "has a singular form for resources" do
        @spec.resource = [ "lib_resources/**/*" ]
        @spec.resources.should == {:resources=>["lib_resources/**/*"]}
      end

      it "checks for unknown destinations in the resources" do
        lambda { @spec.resources = { :my_custom_folder => 'Resources/**/*' } }.should.raise StandardError
      end

      #------------------#

      it "returns the paths to exclude" do
        @spec.exclude_files = "Classes/**/unused.{h,m}"
        @spec.exclude_files.should == ["Classes/**/unused.{h,m}"]
      end

      it "has a default value for the paths to exclude" do
        @spec.exclude_files.should ==  ["Classes/osx/**/*", "Resources/osx/**/*"]
        @spec.activate_platform(:osx)
        @spec.exclude_files.should ==  ["Classes/ios/**/*", "Resources/ios/**/*"]
      end

      #------------------#

      it "returns the paths to preserve" do
        @spec.preserve_paths = ["Frameworks/*.framework"]
        @spec.preserve_paths.should == ["Frameworks/*.framework"]
      end

      it "can accept a single path to preserve" do
        @spec.preserve_path = "Frameworks/*.framework"
        @spec.preserve_paths.should == ["Frameworks/*.framework"]
      end

    end

    #-----------------------------------------------------------------------------#

    describe "Hooks" do
      before do
        @spec = Spec.new do |s|
        end
      end

      it "returns false if the pre install hook was not executed" do
        @spec.pre_install(nil, nil).should == FALSE
      end

      it "returns false if the post install hook was not executed" do
        @spec.post_install(nil).should == FALSE
      end

    end

    #-----------------------------------------------------------------------------#

    describe "Dependencies & Subspecs" do
      before do
        @spec = Spec.new do |s|
        end
      end

      it "allows to specify as subspec" do
        @spec = Spec.new do |s|
          s.name = 'Spec'
          s.subspec 'Subspec' do |sp|
          end
        end
        subspec = @spec.subspecs.first
        subspec.parent.should == @spec
        subspec.class.should == Specification
        subspec.name.should == 'Spec/Subspec'
      end

      it "allows to specify a preferred dependency" do
        @spec.default_subspec = 'Preferred-Subspec'
        @spec.activate_platform(:ios)
        @spec.default_subspec.should == 'Preferred-Subspec'
      end

      it "allows to specify a dependency" do
        @spec.dependency('SVStatusHUD', '~>1.0', '< 1.4')
        @spec.activate_platform(:ios)
        dep = @spec.external_dependencies.first
        dep.name.should == 'SVStatusHUD'
        dep.requirements_list.sort.should == ["< 1.4", "~> 1.0"]
      end
    end

    #-----------------------------------------------------------------------------#

    describe "Multi-Platform" do
      before do
        @spec = Spec.new do |s|
          s.name = "Pod"
        end
      end

      it "allows to specify iOS attributes" do
        @spec.ios.preserve_paths = [ 'APath' ]
        @spec.activate_platform(:ios)
        @spec.preserve_paths.should == [ 'APath' ]
        @spec.activate_platform(:osx)
        @spec.preserve_paths.should == []
      end

      it "allows to specify OS X attributes" do
        @spec.osx.preserve_paths = [ 'APath' ]
        @spec.activate_platform(:osx)
        @spec.preserve_paths.should == [ 'APath' ]
        @spec.activate_platform(:ios)
        @spec.preserve_paths.should == []
      end
    end
  end
end
