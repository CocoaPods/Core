require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Specification::DSL do

    describe "Root specification attributes" do
      before do
        @spec = Spec.new do |s|
          s.name = "Pod"
        end
      end

      it "allows to specify the name" do
        @spec.name = "Name"
        @spec.attributes_hash["name"].should == "Name"
      end

      it "allows to specify the version" do
        @spec.version = "1.0"
        @spec.attributes_hash["version"].should == "1.0"
      end

      it "allows to specify the authors" do
        hash = { 'Darth Vader' => 'darthvader@darkside.com',
                 'Wookiee' => 'wookiee@aggrrttaaggrrt.com' }
        @spec.authors = hash
        @spec.attributes_hash["authors"].should == hash
      end

      it "allows to specify the authors in the singular form" do
        @spec.author = { 'orta' => 'orta.therox@gmail.com' }
        @spec.attributes_hash["authors"].should == { 'orta' => 'orta.therox@gmail.com' }
      end

      it "allows to specify the license" do
        @spec.license = { :type => 'MIT', :file => 'MIT-LICENSE' }
        @spec.attributes_hash["license"].should == { "type" => 'MIT', "file" => 'MIT-LICENSE' }
      end

      it "allows to specify the homepage" do
        @spec.homepage = 'www.example.com'
        @spec.attributes_hash["homepage"].should == 'www.example.com'
      end

      it "allows to specify the homepage" do
        @spec.source = { :git => 'www.example.com/repo.git' }
        @spec.attributes_hash["source"].should == { "git" => 'www.example.com/repo.git' }
      end

      it "allows to specify the summary" do
        @spec.summary = 'text'
        @spec.attributes_hash["summary"].should == 'text'
      end

      it "allows to specify the description" do
        @spec.description = 'text'
        @spec.attributes_hash["description"].should == 'text'
      end

      it "allows to specify a prepare command" do
        @spec.prepare_command = "ruby build_files.rb"
        @spec.attributes_hash["prepare_command"].should == "ruby build_files.rb"
      end
    end

    #-----------------------------------------------------------------------------#

    describe "Platform" do
      before do
        @spec = Spec.new do |s|
          s.name = "Pod"
        end
      end

      it "allows to specify the supported platform" do
        @spec.platform = :ios
        @spec.attributes_hash["platforms"].should == { "ios" => nil }
      end

      it "allows to specify the deployment target along the supported platform as a shortcut" do
        @spec.platform = :ios, '6.0'
        @spec.attributes_hash["platforms"].should == { "ios" => "6.0" }
      end

      it "allows to specify a deployment target for each platform" do
        @spec.ios.deployment_target = '6.0'
        @spec.attributes_hash["platforms"]["ios"].should == '6.0'
      end

      it "doesnt' allows to specify the deployment target without a platform" do
        e = lambda { @spec.deployment_target = '6.0' }.should.raise Informative
        e.message.should.match /declared only per platform/
      end
    end

    #-----------------------------------------------------------------------------#

    describe "Build settings" do
      before do
        @spec = Spec.new do |s|
          s.name = "Pod"
        end
      end

      #------------------#

      describe "dependency" do

        it "allows to specify a dependencies" do
          @spec.dependencies = {'SVStatusHUD' => ['~>1.0', '< 1.4']}
          @spec.attributes_hash["dependencies"].should == {'SVStatusHUD' => ['~>1.0', '< 1.4']}
        end

        it "allows to specify a single dependency as a shortcut" do
          @spec.dependency('SVStatusHUD', '~>1.0', '< 1.4')
          @spec.attributes_hash["dependencies"].should == {'SVStatusHUD' => ['~>1.0', '< 1.4']}
        end

        it "allows to specify a single dependency as a shortcut with one version requirement" do
          @spec.dependency('SVStatusHUD', '~>1.0')
          @spec.attributes_hash["dependencies"].should == {'SVStatusHUD' => ['~>1.0']}
        end

        it "allows to specify a single dependency as a shortcut with no version requirements" do
          @spec.dependency('SVStatusHUD')
          @spec.attributes_hash["dependencies"].should == {'SVStatusHUD' => []}
        end

        it "raises if the specification requires itself" do
          should.raise Informative do
            @spec.dependency('Pod')
          end.message.should.match /can't require itself/
        end

        it "raises if the specification requires one of its parents" do
          @spec.subspec 'subspec' do |sp|
          end
          subspec = @spec.subspecs.first
          should.raise Informative do
            subspec.dependency('Pod')
          end.message.should.match /can't require one of its parents/
        end

        it "raises if the requirements are not supported" do
          should.raise Informative do
            @spec.dependency('SVProgressHUD', :head)
          end.message.should.match /Unsupported version requirements/
        end

      end

      #------------------#

      it "allows to specify whether the specification requires ARC" do
        @spec.requires_arc = true
        @spec.attributes_hash["requires_arc"].should == true
      end

      it "allows to specify the frameworks" do
        @spec.framework = %w[ QuartzCore CoreData ]
        @spec.attributes_hash["frameworks"].should == %w[ QuartzCore CoreData ]
      end

      it "allows to specify the weak frameworks" do
        @spec.weak_frameworks = %w[ Twitter iAd ]
        @spec.attributes_hash["weak_frameworks"].should == %w[ Twitter iAd ]
      end

      it "allows to specify the libraries" do
        @spec.libraries = 'z', 'xml2'
        @spec.attributes_hash["libraries"].should == %w[ z xml2 ]
      end

      it "allows to specify compiler flags" do
        @spec.compiler_flags = %w[ -Wdeprecated-implementations -Wunused-value ]
        @spec.attributes_hash["compiler_flags"].should == %w[ -Wdeprecated-implementations -Wunused-value ]
      end

      it "allows to specify xcconfig settings" do
        @spec.xcconfig = { 'OTHER_LDFLAGS' => '-lObjC' }
        @spec.attributes_hash["xcconfig"].should == { 'OTHER_LDFLAGS' => '-lObjC' }
      end

      it "allows to specify the contents of the prefix header" do
        @spec.prefix_header_contents = '#import <UIKit/UIKit.h>'
        @spec.attributes_hash["prefix_header_contents"].should == '#import <UIKit/UIKit.h>'
      end

      it "allows to specify the path of compiler header file" do
        @spec.prefix_header_file = 'iphone/include/prefix.pch'
        @spec.attributes_hash["prefix_header_file"].should == 'iphone/include/prefix.pch'
      end

      it "allows to specify a directory to use for the headers" do
        @spec.header_dir = 'Three20Core'
        @spec.attributes_hash["header_dir"].should == 'Three20Core'
      end

      it "allows to specify a directory to preserver the namespacing of the headers" do
        @spec.header_mappings_dir = 'src/include'
        @spec.attributes_hash["header_mappings_dir"].should == 'src/include'
      end

    end

    #-----------------------------------------------------------------------------#

    describe "File patterns attributes" do
      before do
        @spec = Spec.new do |s|
          s.name = "Pod"
        end
      end

      it "allows to specify the source files" do
        @spec.source_files = [ "lib_classes/**/*" ]
        @spec.attributes_hash["source_files"].should == [ "lib_classes/**/*" ]
      end

      it "allows to specify the public headers files" do
        @spec.public_header_files = [ "include/**/*" ]
        @spec.attributes_hash["public_header_files"].should == [ "include/**/*" ]
      end

      it "allows to specify the private headers files" do
        @spec.private_header_files = [ "private/**/*" ]
        @spec.attributes_hash["private_header_files"].should == [ "private/**/*" ]
      end

      it "allows to specify the frameworks bundles shipped with the Pod" do
        @spec.vendored_frameworks = [ "Parse.framework" ]
        @spec.attributes_hash["vendored_frameworks"].should == [ "Parse.framework" ]
      end


      it "allows to specify the libraries shipped with the Pod" do
        @spec.vendored_libraries = [ "libProj4.a" ]
        @spec.attributes_hash["vendored_libraries"].should == [ "libProj4.a" ]
      end

      it "allows to specify the resources bundles shipped with the Pod" do
        @spec.resource_bundles = { 'MapBox' => 'MapView/Map/Resources/*.png' }
        @spec.attributes_hash["resource_bundles"].should == { 'MapBox' => 'MapView/Map/Resources/*.png' }
      end

      it "allows to specify the resources files" do
        @spec.resources = ['frameworks/CrashReporter.framework']
        @spec.attributes_hash["resources"].should == ['frameworks/CrashReporter.framework']
      end

      it "allows to specify the paths to exclude" do
        @spec.exclude_files = ["Classes/**/unused.{h,m}"]
        @spec.attributes_hash["exclude_files"].should == ["Classes/**/unused.{h,m}"]
      end

      it "allows to specify the paths to preserve" do
        @spec.preserve_paths = ["Frameworks/*.framework"]
        @spec.attributes_hash["preserve_paths"].should == ["Frameworks/*.framework"]
      end

    end

    #-----------------------------------------------------------------------------#

    describe "Hooks" do
      before do
        @spec = Spec.new
      end

      it "stores a block to run before the installation" do
        value = ''
        @spec.post_install do value << 'modified' end
        @spec.post_install!(nil)
        value.should == 'modified'
      end

      it "stores a block to run after the installation" do
        value = ''
        @spec.post_install do value << 'modified' end
        @spec.post_install!(nil)
        value.should == 'modified'
      end
    end

    #-----------------------------------------------------------------------------#

    describe "Subspecs" do
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
        @spec.attributes_hash["default_subspec"].should == 'Preferred-Subspec'
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
        @spec.attributes_hash["ios"]["preserve_paths"].should == [ 'APath' ]
        @spec.attributes_hash["preserve_paths"].should.be.nil
        @spec.attributes_hash["osx"].should.be.nil
      end

      it "allows to specify OS X attributes" do
        @spec.osx.preserve_paths = [ 'APath' ]
        @spec.attributes_hash["osx"]["preserve_paths"].should == [ 'APath' ]
        @spec.attributes_hash["preserve_paths"].should.be.nil
        @spec.attributes_hash["ios"].should.be.nil
      end
    end

    #-----------------------------------------------------------------------------#

    describe "Attributes default values" do

      it "doesn't requires arc by default" do
        attr = Specification::DSL.attributes[:requires_arc]
        attr.default(:ios).should == false
        attr.default(:osx).should == false
      end

    end

    #-----------------------------------------------------------------------------#

    describe "Attributes singular form" do

      it "allows to use the singular form the attributes which support it" do
        attributes = Specification::DSL.attributes.values
        singularized = attributes.select { |attr| attr.singularize? }
        spec = Specification.new
        singularized.each do |attr|
          spec.should.respond_to(attr.writer_name)
        end
        singularized.map{ |attr| attr.name.to_s }.sort.should == %w[
          authors compiler_flags  frameworks libraries preserve_paths
          resource_bundles resources screenshots vendored_frameworks
          vendored_libraries weak_frameworks
        ]
      end
    end

    #-----------------------------------------------------------------------------#

  end
end
