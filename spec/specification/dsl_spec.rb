require File.expand_path('../../spec_helper', __FILE__)

describe Pod::Specification do

  describe "DSL - Root specification attributes" do
    before do
      @spec = Pod::Spec.new do |s|
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
      @spec.version.should == Pod::Version.new('1.0')
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

    xit "checks for unknown keys in the license" do

    end

    it "returns the homepage" do
      @spec.homepage = 'www.example.com'
      @spec.homepage.should == 'www.example.com'
    end

    it "returns the source" do
      @spec.source = { :git => 'www.example.com/repo.git' }
      @spec.source.should == { :git => 'www.example.com/repo.git' }
    end

    xit "checks the source for unknown keys" do
      call = lambda { @spec.source = { :tig => 'www.example.com/repo.tig' } }
      call.should.raise Pod::StandardError
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

  describe "DSL - Platform attributes" do
    before do
      @spec = Pod::Spec.new do |s|
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
      @spec.deployment_target.should == '4.3'
    end

    it "returns the list of the available platforms" do
      @spec.available_platforms.sort_by(&:name).should == [
        Pod::Platform.new(:ios),
        Pod::Platform.new(:osx),
      ]
    end

    it "takes into account the platform of the parent for returning the list of the available platforms" do
      @spec.platform = :ios, '4.3'
      @subspec.available_platforms.sort_by(&:name).should == [ Pod::Platform.new(:ios, 4.3), ]
    end

    it "takes into account the specified deployment targets for returning the list of the available platforms" do
      @spec.platform = :ios, '4.3'
      @subspec.ios.deployment_target = '6.0'
      @subspec.available_platforms.sort_by(&:name).should == [ Pod::Platform.new(:ios, '6.0') ]
    end

    it "prioritizes the explicitly defined platform for returning the list of the available platforms" do
      @subspec.platform = :ios, '4.3'
      @subspec.ios.deployment_target = '6.0'
      @subspec.available_platforms.sort_by(&:name).should == [ Pod::Platform.new(:ios, '4.3') ]
    end
  end

  #-----------------------------------------------------------------------------#

  describe "DSL - Regular attributes" do
    before do
      @spec = Pod::Spec.new do |s|
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

    xit "merges the compiler flags so values for platforms can be specified" do
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

    xit "inherits the xcconfig values from the parent" do
      @spec.xcconfig = { 'OTHER_LDFLAGS' => '-lObjC' }
      @subspec.xcconfig = { 'OTHER_LDFLAGS' => '-Wl -no_compact_unwind' }
      @subspec.xcconfig.should == { 'OTHER_LDFLAGS' => '-lObjC -Wl -no_compact_unwind' }
    end

    xit "merges the xcconfig values so values for platforms can be specified" do
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

    it "inherits the contents of the prefix header" do
      @spec.prefix_header_contents = '#import <UIKit/UIKit.h>'
      @subspec.prefix_header_contents.should == '#import <UIKit/UIKit.h>'
    end

    #------------------#

    it "allows to specify the path of compiler header file" do
      @spec.prefix_header_file = 'iphone/include/prefix.pch'
      @spec.prefix_header_file.should == Pathname.new('iphone/include/prefix.pch')
    end

    xit "inherits the path of compiler header file from the parent" do
      @spec.prefix_header_file = 'iphone/include/prefix.pch'
      @subspec.prefix_header_file.should == Pathname.new('iphone/include/prefix.pch')
    end

    #------------------#

    it "allows to specify a directory to use for the headers" do
      @spec.header_dir = 'Three20Core'
      @spec.header_dir.should == Pathname.new('Three20Core')
    end

    xit "inherits the directory to use for the headers from the parent" do
      @spec.header_dir = 'Three20Core'
      @subspec.header_dir.should == Pathname.new('Three20Core')
    end

    #------------------#

    it "allows to specify a directory to preserver the namespacing of the headers" do
      @spec.header_mappings_dir = 'src/include'
      @spec.header_mappings_dir.should == Pathname.new('src/include')
    end

    xit "inherits the directory to use for the headers from the parent" do
      @spec.header_mappings_dir = 'src/include'
      @subspec.header_mappings_dir.should == Pathname.new('src/include')
    end

  end

  #-----------------------------------------------------------------------------#

  describe "DSL - File patterns attributes" do
    before do
      @spec = Pod::Spec.new do |s|
        s.name = "Pod"
        s.subspec 'Subspec' do |sp|
        end
      end
      @subspec = @spec.subspecs.first
      @spec.activate_platform(:ios)
    end

    it "returns the source files" do
      @spec.source_files = [ "lib_classes/**/*.{h,m}" ]
      @spec.source_files.should == [ "lib_classes/**/*.{h,m}" ]
    end

    it "inherits the source files from the parent" do
      @spec.source_files = [ "lib_classes/**/*.{h,m}" ]
      @subspec.source_files = [ "subspec_classes/**/*.{h,m}" ]
      @subspec.source_files.should == [ "lib_classes/**/*.{h,m}", "subspec_classes/**/*.{h,m}" ]
    end

    xit "has a default value for the source files" do
      @spec.source_files.should == [ "classes/**/*.{h,m}" ]
    end

    #------------------#

    xit "returns the source files to exclude" do

    end

    xit "inherits the source files to exclude from the parent" do

    end

    xit "has a default value for the source files to exclude" do

    end

    #------------------#

    xit "returns the public headers files" do

    end

    xit "inherits the public headers files from the parent" do

    end

    #------------------#

    xit "returns the path of the resources" do

    end

    xit "can accept the path of a single resource" do

    end

    xit "inherits the path of the resources form the parent" do

    end

    #------------------#

    xit "returns the paths to preserve" do

    end

    xit "can accept a single path to preserve" do

    end

    xit "returns the path of the resources form the parent" do

    end
  end

  #-----------------------------------------------------------------------------#

  describe "DSL - Hooks" do

    xit "returns false if the pre install hook was not executed" do

    end

    xit "returns false if the post install hook was not executed" do

    end

  end

  #-----------------------------------------------------------------------------#

  describe "DSL - Dependencies & Subspecs" do
    before do
      @spec = Pod::Spec.new do |s|
        s.name = "Pod"
        s.subspec 'Subspec' do |sp|
        end
        s.subspec 'Preferred-Subspec' do |sp|
        end
      end
      @subspec = @spec.subspecs.first
    end

    xit "allows to specify as subspec" do

    end

    xit "returns the subspecs" do

    end

    it "allows to specify a preferred dependency" do
      @spec.preferred_dependency = 'Preferred-Subspec'
      @spec.activate_platform(:ios)
      @spec.preferred_dependency.should == 'Preferred-Subspec'
    end

    xit "allows to specify a dependency" do

    end

    xit "returns the dependencies" do

    end
  end

  #-----------------------------------------------------------------------------#

  describe "DSL - Multi-Platform" do

    xit "allows to specify iOS attributes" do

    end

    xit "allows to specify OS X attributes" do

    end

  end

end

#   describe "In general" do
#     before do
#       @spec = Pod::Spec.new
#     end
#
#     xit "returns the platform that the static library should be build for" do
#       @spec.platform = :ios
#       @spec.platform.should == :ios
#     end
#
#     xit "returns the platform and the deployment target" do
#       @spec.platform = :ios, '4.0'
#       @spec.platform.should == :ios
#       @spec.platform.deployment_target.should == Pod::Version.new('4.0')
#     end
#
#     xit "returns the available platforms for which the pod is supported" do
#       @spec.platform = :ios, '4.0'
#       @spec.available_platforms.count.should == 1
#       @spec.available_platforms.first.should == :ios
#       @spec.available_platforms.first.deployment_target.should == Pod::Version.new('4.0')
#     end
#
#     xit "returns the license of the Pod" do
#       @spec.license = {
#         :type => 'MIT',
#         :file => 'LICENSE',
#         :text => 'Permission is hereby granted ...'
#       }
#       @spec.license.should == {
#         :type => 'MIT',
#         :file => 'LICENSE',
#         :text => 'Permission is hereby granted ...'
#       }
#     end
#
#     xit "returns the license of the Pod specified in the old format" do
#       @spec.license = 'MIT'
#       @spec.license.should == {
#         :type => 'MIT',
#       }
#     end
#
#     xit "returns the documentation of the Pod" do
#       @spec.documentation = {
#         :html => 'http://EXAMPLE/#{@name}/documentation',
#         :appledoc => ['--project-name', '#{@name}',
#                       '--project-company', '"Company Name"',
#                       '--company-id', 'com.company',
#                       '--ignore', 'Common',
#                       '--ignore', '.m']
#       }
#       @spec.documentation[:html].should == 'http://EXAMPLE/#{@name}/documentation'
#       @spec.documentation[:appledoc].should == ['--project-name', '#{@name}',
#                                                 '--project-company', '"Company Name"',
#                                                 '--company-id', 'com.company',
#                                                 '--ignore', 'Common',
#                                                 '--ignore', '.m']
#     end
#
#     xit "takes a list of paths to clean" do
#       @spec.clean_paths = 'Demo', 'Doc'
#       @spec.clean_paths.should == %w{ Demo Doc }
#     end
#
#     xit "takes a list of paths to preserve" do
#       @spec.preserve_paths = 'script.sh'
#       @spec.activate_platform(:ios).preserve_paths.should == %w{ script.sh }
#     end
#
#     xit "takes a prefix header path which will be appended to the Pods pch file" do
#       @spec.prefix_header_file.should == nil
#       @spec.prefix_header_file = 'Classes/Demo.pch'
#       @spec.prefix_header_file.should == Pathname.new('Classes/Demo.pch')
#     end
#
#     xit "takes code that's to be appended to the Pods pch file" do
#       @spec.prefix_header_contents.should == nil
#       @spec.prefix_header_contents = '#import "BlocksKit.h"'
#       @spec.prefix_header_contents.should == '#import "BlocksKit.h"'
#     end
#
#     xit "can be activated for a supported platform" do
#       @spec.platform = :ios
#       lambda {@spec.activate_platform(:ios)}.should.not.raise Pod::StandardError
#     end
#
#     xit "raised if attempted to be activated for an unsupported platform" do
#       @spec.platform = :osx, '10.7'
#       lambda {@spec.activate_platform(:ios)}.should.raise Pod::StandardError
#       lambda {@spec.activate_platform(:ios, '10.6')}.should.raise Pod::StandardError
#     end
#
#     xit "raises if not activated for a platform before accessing a multi-platform value" do
#       @spec.platform = :ios
#       lambda {@spec.source_files}.should.raise Pod::StandardError
#     end
#
#     xit "returns self on activation for method chainablity" do
#       @spec.platform = :ios
#       @spec.activate_platform(:ios).should == @spec
#     end
#
#     xit "it handles local sources" do
#       @spec.activate_platform(:ios)
#       @spec.source = {:local => '/tmp/local/path'}
#       @spec.local?.should.be.true
#     end
#   end
#
#   describe "Loaded from a podspec" do
#     before do
#       fixture('banana-lib') # ensure the archive is unpacked
#       @spec = Pod::Specification.from_file(fixture('banana-lib/BananaLib.podspec'))
#     end
#
#     xit "has no parent if it is the top level spec" do
#       @spec.parent.nil?.should == true
#     end
#
#     xit "returns that it's not loaded from a podfile" do
#       @spec.should.not.be.podfile
#     end
#
#     xit "returns the path to the podspec" do
#       @spec.defined_in_file.should == fixture('banana-lib/BananaLib.podspec')
#     end
#
#     xit "returns the pod's name" do
#       @spec.name.should == 'BananaLib'
#     end
#
#     xit "returns the pod's version" do
#       @spec.version.should == Pod::Version.new('1.0')
#     end
#
#     xit "returns a list of authors and their email addresses" do
#       @spec.authors.should == {
#         'Banana Corp' => nil,
#         'Monkey Boy' => 'monkey@banana-corp.local'
#       }
#     end
#
#     xit "returns the pod's homepage" do
#       @spec.homepage.should == 'http://banana-corp.local/banana-lib.html'
#     end
#
#     xit "returns the pod's summary" do
#       @spec.summary.should == 'Chunky bananas!'
#     end
#
#     xit "returns the pod's description" do
#       @spec.description.should == 'Full of chunky bananas.'
#     end
#
#     xit "returns the pod's source" do
#       @spec.source.should == {
#         :git => 'http://banana-corp.local/banana-lib.git',
#         :tag => 'v1.0'
#       }
#     end
#
#     xit "returns the pod's source files" do
#       @spec.activate_platform(:ios).source_files.should == ['Classes/*.{h,m}', 'Vendor']
#       @spec.activate_platform(:osx).source_files.should == ['Classes/*.{h,m}', 'Vendor']
#     end
#
#     xit "returns the pod's dependencies" do
#       expected = Pod::Dependency.new('monkey', '~> 1.0.1', '< 1.0.9')
#       @spec.activate_platform(:ios).dependencies.should == [expected]
#       @spec.activate_platform(:osx).dependencies.should == [expected]
#     end
#
#     xit "returns the pod's xcconfig settings" do
#       @spec.activate_platform(:ios).xcconfig.should == { 'OTHER_LDFLAGS' => '-framework SystemConfiguration' }
#     end
#
#     # TODO Move those specs to the LocalPod class or the Target Integrator
#
#     xit "stores the frameworks" do
#       @spec.frameworks = 'CFNetwork', 'CoreText'
#       @spec.activate_platform(:ios).frameworks.should == ['CFNetwork', 'CoreText']
#       # @spec.activate_platform(:ios).xcconfig.should == {
#       #   'OTHER_LDFLAGS' => '-framework CFNetwork ' \
#       #                      '-framework CoreText '   \
#       #                      '-framework SystemConfiguration' }
#     end
#
#     # TODO Move those specs to the LocalPod class or the Target Integrator
#
#     xit "stores weak frameworks" do
#       @spec.weak_frameworks = 'Twitter'
#       @spec.activate_platform(:ios).weak_frameworks.should == ['Twitter']
#       # @spec.activate_platform(:ios).xcconfig.should == {
#       #   "OTHER_LDFLAGS"=>"-framework SystemConfiguration -weak_framework Twitter"
#       # }
#     end
#
#     # TODO Move those specs to the LocalPod class or the Target Integrator
#
#     xit "has a shortcut to add libraries to the xcconfig" do
#       @spec.libraries = 'z', 'xml2'
#       @spec.activate_platform(:ios).libraries.should == ['z', 'xml2']
#       # @spec.activate_platform(:ios).xcconfig.should == {
#       #   'OTHER_LDFLAGS' => '-lxml2 -lz -framework SystemConfiguration'
#       # }
#     end
#
#     xit "returns that it's equal to another specification if the name and version are equal" do
#       @spec.should == Pod::Spec.new { |s| s.name = 'BananaLib'; s.version = '1.0' }
#       @spec.should.not == Pod::Spec.new { |s| s.name = 'OrangeLib'; s.version = '1.0' }
#       @spec.should.not == Pod::Spec.new { |s| s.name = 'BananaLib'; s.version = '1.1' }
#       @spec.should.not == Pod::Spec.new
#     end
#
#     xit "never equals when it's from a Podfile" do
#       Pod::Spec.new.should.not == Pod::Spec.new
#     end
#
#     xit "adds compiler flags if ARC is required" do
#       @spec.parent.should == nil
#       @spec.requires_arc = true
#       @spec.activate_platform(:ios).compiler_flags.should == "-fobjc-arc"
#       @spec.activate_platform(:osx).compiler_flags.should == "-fobjc-arc"
#       @spec.compiler_flags = "-Wunused-value"
#       @spec.activate_platform(:ios).compiler_flags.should == "-Wunused-value -fobjc-arc"
#       @spec.activate_platform(:osx).compiler_flags.should == "-Wunused-value -fobjc-arc"
#     end
#   end
#
#   describe "A hierarchy" do
#     before do
#       @spec = Pod::Spec.new do |s|
#         s.name      = 'MainSpec'
#         s.version   = '0.999'
#         s.dependency  'awesome_lib'
#         s.subspec 'SubSpec.0' do |fss|
#           fss.platform  = :ios
#           fss.subspec 'SubSpec.0.0' do |sss|
#           end
#         end
#         s.subspec 'SubSpec.1'
#       end
#       @subspec = @spec.subspecs.first
#       @spec.activate_platform(:ios)
#     end
#
#     xit "automatically includes all the compatible subspecs as a dependencis if not preference is given" do
#       @spec.dependencies.map { |s| s.name }.should == %w[ awesome_lib MainSpec/SubSpec.0 MainSpec/SubSpec.1 ]
#       @spec.activate_platform(:osx).dependencies.map { |s| s.name }.should == %w[ awesome_lib MainSpec/SubSpec.1 ]
#     end
#
#     xit "uses the spec version for the dependencies" do
#       @spec.dependencies.
#         select { |d| d.name =~ /MainSpec/ }.
#         all?   { |d| d.requirement.to_s == '= 0.999' }.
#         should.be.true
#     end
#
#     xit "respects the preferred dependency for subspecs, if specified" do
#       @spec.preferred_dependency = 'SubSpec.0'
#       @spec.dependencies.map { |s| s.name }.should == %w[ awesome_lib MainSpec/SubSpec.0 ]
#     end
#
#     xit "raises if it has dependency on a self or on an upstream subspec" do
#       lambda { @subspec.dependency('MainSpec/SubSpec.0') }.should.raise Pod::StandardError
#       lambda { @subspec.dependency('MainSpec') }.should.raise Pod::StandardError
#     end
#
#     xit "inherits external dependencies from the parent" do
#       @subspec.dependencies.map { |s| s.name }.should == %w[ awesome_lib MainSpec/SubSpec.0/SubSpec.0.0 ]
#     end
#
#     xit "it accepts a dependency on a subspec that is in the same level of the hierarchy" do
#       @subspec.dependency('MainSpec/SubSpec.1')
#       @subspec.dependencies.map { |s| s.name }.should == %w[ MainSpec/SubSpec.1 awesome_lib MainSpec/SubSpec.0/SubSpec.0.0 ]
#     end
#   end
#
#   describe "A subspec" do
#     before do
#       @spec = Pod::Spec.new do |s|
#         s.name         = 'MainSpec'
#         s.version      = '1.2.3'
#         s.license      = 'MIT'
#         s.author       = 'Joe the Plumber'
#         s.source       = { :git => '/some/url' }
#         s.requires_arc = true
#         s.source_files = 'spec.m'
#         s.resource     = 'resource'
#         s.platform     = :ios
#         s.library      = 'xml'
#         s.framework    = 'CoreData'
#
#         s.subspec 'FirstSubSpec' do |fss|
#           fss.ios.source_files  = 'subspec_ios.m'
#           fss.osx.source_files  = 'subspec_osx.m'
#           fss.framework         = 'CoreGraphics'
#           fss.weak_framework    = 'Twitter'
#           fss.library           = 'z'
#
#           fss.subspec 'SecondSubSpec' do |sss|
#             sss.source_files = 'subsubspec.m'
#             sss.requires_arc = false
#           end
#         end
#       end
#       @subspec = @spec.subspecs.first
#       @subsubspec = @subspec.subspecs.first
#     end
#
#     xit "returns the top level parent spec" do
#       @spec.subspecs.first.top_level_parent.should == @spec
#       @spec.subspecs.first.subspecs.first.top_level_parent.should == @spec
#     end
#
#     xit "is named after the parent spec" do
#       @spec.subspecs.first.name.should == 'MainSpec/FirstSubSpec'
#       @spec.subspecs.first.subspecs.first.name.should == 'MainSpec/FirstSubSpec/SecondSubSpec'
#     end
#
#     xit "correctly resolves the inheritance chain" do
#       @spec.subspecs.first.subspecs.first.parent.should == @spec.subspecs.first
#       @spec.subspecs.first.parent.should == @spec
#     end
#
#     xit "automatically forwards top level attributes to the subspecs" do
#       @spec.activate_platform(:ios)
#       [:version, :license, :authors].each do |attr|
#         @spec.subspecs.first.send(attr).should == @spec.send(attr)
#         @spec.subspecs.first.subspecs.first.send(attr).should == @spec.send(attr)
#       end
#     end
#
#     xit "resolves correctly chained attributes" do
#       @spec.activate_platform(:ios)
#       @spec.source_files.map { |f| f.to_s }.should == %w[ spec.m  ]
#       @subspec.source_files.map { |f| f.to_s }.should == %w[ spec.m  subspec_ios.m ]
#       @subsubspec.source_files.map { |f| f.to_s }.should == %w[ spec.m  subspec_ios.m subsubspec.m ]
#       @subsubspec.resources.should == %w[ resource ]
#
#       @subsubspec.compiler_flags = '-Wdeprecated-implementations'
#       @subsubspec.compiler_flags.should == '-Wdeprecated-implementations'
#     end
#
#     xit "allows to specify arc settings for subspecs" do
#       @spec.activate_platform(:ios)
#       @spec.requires_arc.should == true
#       @subspec.requires_arc.should == true
#       @subsubspec.requires_arc.should == false
#     end
#
#     xit "returns empty arrays for chained attributes with no value in the chain" do
#       @spec = Pod::Spec.new do |s|
#         s.name         = 'MainSpec'
#         s.platform     = :ios
#         s.subspec 'FirstSubSpec' do |fss|
#           fss.subspec 'SecondSubSpec' do |sss|
#             sss.source_files = 'subsubspec.m'
#           end
#         end
#       end
#
#       @spec.activate_platform(:ios).source_files.should == []
#       @spec.subspecs.first.source_files.should == []
#       @spec.subspecs.first.subspecs.first.source_files.should == %w[ subsubspec.m ]
#     end
#
#     xit "does not cache platform attributes and can activate another platform" do
#       @spec.stubs(:platform).returns nil
#       @spec.activate_platform(:ios)
#       @subsubspec.source_files.map { |f| f.to_s }.should == %w[ spec.m  subspec_ios.m subsubspec.m ]
#       @spec.activate_platform(:osx)
#       @subsubspec.source_files.map { |f| f.to_s }.should == %w[ spec.m  subspec_osx.m subsubspec.m ]
#     end
#
#     xit "resolves correctly the available platforms" do
#       @spec.stubs(:platform).returns nil
#       @subspec.platform = :ios, '4.0'
#       @spec.available_platforms.map{ |p| p.to_sym }.should == [ :osx, :ios ]
#       @subspec.available_platforms.first.to_sym.should == :ios
#       @subsubspec.available_platforms.first.to_sym.should == :ios
#
#       @subsubspec.platform = :ios, '5.0'
#       @subspec.available_platforms.first.deployment_target.to_s.should == '4.0'
#       @subsubspec.available_platforms.first.deployment_target.to_s.should == '5.0'
#     end
#
#     xit "resolves reports correctly the supported platforms" do
#       @spec.stubs(:platform).returns nil
#       @subspec.platform = :ios, '4.0'
#       @subsubspec.platform = :ios, '5.0'
#       @spec.supports_platform?(:ios).should.be.true
#       @spec.supports_platform?(:osx).should.be.true
#       @subspec.supports_platform?(:ios).should.be.true
#       @subspec.supports_platform?(:osx).should.be.false
#       @subspec.supports_platform?(:ios, '4.0').should.be.true
#       @subspec.supports_platform?(:ios, '5.0').should.be.true
#       @subsubspec.supports_platform?(:ios).should.be.true
#       @subsubspec.supports_platform?(:osx).should.be.false
#       @subsubspec.supports_platform?(:ios, '4.0').should.be.false
#       @subsubspec.supports_platform?(:ios, '5.0').should.be.true
#       @subsubspec.supports_platform?(Pod::Platform.new(:ios, '4.0')).should.be.false
#       @subsubspec.supports_platform?(Pod::Platform.new(:ios, '5.0')).should.be.true
#     end
#
#     xit "raises a top level attribute is assigned to a spec with a parent" do
#       lambda { @subspec.version = '0.0.1' }.should.raise Pod::StandardError
#     end
#
#     xit "returns subspecs by name" do
#       @spec.subspec_by_name(nil).should == @spec
#       @spec.subspec_by_name('MainSpec').should == @spec
#       @spec.subspec_by_name('MainSpec/FirstSubSpec').should == @subspec
#       @spec.subspec_by_name('MainSpec/FirstSubSpec/SecondSubSpec').should == @subsubspec
#     end
#
#     xit "has the same active platform across the chain attributes" do
#       @spec.activate_platform(:ios)
#       @subspec.active_platform.should == :ios
#       @subsubspec.active_platform.should == :ios
#
#       @spec.stubs(:platform).returns nil
#       @subsubspec.activate_platform(:osx)
#       @subspec.active_platform.should == :osx
#       @spec.active_platform.should == :osx
#     end
#
#     xit "resolves the libraries correctly" do
#       @spec.activate_platform(:ios)
#       @spec.libraries.should       == %w[ xml ]
#       @subspec.libraries.should    == %w[ xml z ]
#       @subsubspec.libraries.should == %w[ xml z ]
#     end
#
#     xit "resolves the frameworks correctly" do
#       @spec.activate_platform(:ios)
#       @spec.frameworks.should       == %w[ CoreData ]
#       @subspec.frameworks.should    == %w[ CoreData CoreGraphics ]
#       @subsubspec.frameworks.should == %w[ CoreData CoreGraphics ]
#     end
#
#     xit "resolves the weak frameworks correctly" do
#       @spec.activate_platform(:ios)
#       @spec.weak_frameworks.should       == %w[  ]
#       @subspec.weak_frameworks.should    == %w[ Twitter ]
#     end
#
#     # TODO: check for the libraies and the frameworks
#
#     xit "the xcconfig hash" do
#       @spec.activate_platform(:ios)
#       @spec.xcconfig = { 'OTHER_LDFLAGS' => "-Wl -no_compact_unwind" }
#       @subspec.xcconfig = { 'OTHER_LDFLAGS' => "-all_load", 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
#
#       @spec.xcconfig.should == {"OTHER_LDFLAGS"=>"-Wl -no_compact_unwind"}
#       @subspec.xcconfig.should == {"OTHER_LDFLAGS"=>"-Wl -no_compact_unwind -all_load", "HEADER_SEARCH_PATHS"=>"$(SDKROOT)/usr/include/libxml2"}
#     end
#   end
#
#   describe "Local source" do
#     before do
#       @spec = Pod::Spec.new do |s|
#         s.name    = 'MainSpec'
#         s.source  = { :local => fixture("integration/JSONKit") }
#         s.source_files = "."
#       end
#     end
#
#     xit "is marked as local" do
#       @spec.should.be.local
#     end
#
#     xit "it returns the expanded local path" do
#       @spec.source.should == {:local => fixture("integration/JSONKit")}
#     end
#   end
#
#   describe "No platform specific values" do
#     before do
#       @spec = Pod::Spec.new do |s|
#         s.source_files   = 'file1', 'file2'
#         s.resources      = 'file1', 'file2'
#         s.xcconfig       =  { 'OTHER_LDFLAGS' => '-lObjC' }
#         s.framework      = 'QuartzCore'
#         s.library        = 'z'
#         s.compiler_flags = '-Wdeprecated-implementations'
#         s.requires_arc   = true
#
#         s.dependency 'JSONKit'
#         s.dependency 'SSZipArchive'
#       end
#     end
#
#     xit "returns the same list of source files for each platform" do
#       @spec.activate_platform(:ios).source_files.should == %w{ file1 file2 }
#       @spec.activate_platform(:osx).source_files.should == %w{ file1 file2 }
#     end
#
#     xit "returns the same list of resources for each platform" do
#       @spec.activate_platform(:ios).resources.should == %w{ file1 file2 }
#       @spec.activate_platform(:osx).resources.should == %w{ file1 file2 }
#     end
#
#     xit "returns the same list of xcconfig build settings for each platform" do
#       build_settings = { 'OTHER_LDFLAGS' => '-lObjC' }
#       @spec.activate_platform(:ios).xcconfig.should == build_settings
#       @spec.activate_platform(:osx).xcconfig.should == build_settings
#     end
#
#     xit "returns the same list of compiler flags for each platform" do
#       compiler_flags = '-Wdeprecated-implementations -fobjc-arc'
#       @spec.activate_platform(:ios).compiler_flags.should == compiler_flags
#       @spec.activate_platform(:osx).compiler_flags.should == compiler_flags
#     end
#
#     xit "returns the same list of dependencies for each platform" do
#       dependencies = %w{ JSONKit SSZipArchive }.map { |name| Pod::Dependency.new(name) }
#       @spec.activate_platform(:ios).dependencies.should == dependencies
#       @spec.activate_platform(:osx).dependencies.should == dependencies
#     end
#   end
#
#   describe "Platform specific values" do
#     before do
#       @spec = Pod::Spec.new do |s|
#         s.ios.source_files   = 'file1'
#         s.osx.source_files   = 'file1', 'file2'
#
#         s.ios.resource       = 'file1'
#         s.osx.resources      = 'file1', 'file2'
#
#         s.ios.xcconfig       = { 'OTHER_LDFLAGS' => '-lObjC' }
#         s.osx.xcconfig       = { 'OTHER_LDFLAGS' => '-lObjC -all_load' }
#
#         s.ios.framework      = 'QuartzCore'
#         s.osx.frameworks     = 'QuartzCore', 'CoreData'
#
#         s.ios.library        = 'z'
#         s.osx.libraries      = 'z', 'xml'
#
#         s.ios.compiler_flags = '-Wdeprecated-implementations'
#         s.osx.compiler_flags = '-Wfloat-equal'
#
#         s.requires_arc   = true # does not take platform options, just here to check it's added to compiler_flags
#
#         s.ios.dependency 'JSONKit'
#         s.osx.dependency 'SSZipArchive'
#
#         s.ios.deployment_target = '4.0'
#       end
#     end
#
#     xit "returns a different list of source files for each platform" do
#       @spec.activate_platform(:ios).source_files.should == %w{ file1 }
#       @spec.activate_platform(:osx).source_files.should == %w{ file1 file2 }
#     end
#
#     xit "returns a different list of resources for each platform" do
#       @spec.activate_platform(:ios).resources.should == %w{ file1 }
#       @spec.activate_platform(:osx).resources.should == %w{ file1 file2 }
#     end
#
#     xit "returns a different list of xcconfig build settings for each platform" do
#       @spec.activate_platform(:ios).xcconfig.should == { 'OTHER_LDFLAGS' => '-lObjC' }
#       @spec.activate_platform(:osx).xcconfig.should == { 'OTHER_LDFLAGS' => '-lObjC -all_load' }
#     end
#
#     xit "returns the list of the supported platforms and deployment targets" do
#       @spec.available_platforms.count.should == 2
#       @spec.available_platforms.should.include? Pod::Platform.new(:osx)
#       @spec.available_platforms.should.include? Pod::Platform.new(:ios, '4.0')
#     end
#
#     xit "returns the same list of compiler flags for each platform" do
#       @spec.activate_platform(:ios).compiler_flags.should == '-Wdeprecated-implementations -fobjc-arc'
#       @spec.activate_platform(:osx).compiler_flags.should == '-Wfloat-equal -fobjc-arc'
#     end
#
#     xit "returns the same list of dependencies for each platform" do
#       @spec.activate_platform(:ios).dependencies.should == [Pod::Dependency.new('JSONKit')]
#       @spec.activate_platform(:osx).dependencies.should == [Pod::Dependency.new('SSZipArchive')]
#     end
#   end
# end

