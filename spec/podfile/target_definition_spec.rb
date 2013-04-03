require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Podfile::TargetDefinition do

    before do
      @podfile = Podfile.new
      @root = Podfile::TargetDefinition.new("MyApp", @podfile)
      @child = Podfile::TargetDefinition.new("MyAppTests", @root)
      @root.set_platform(:ios, '6.0')
    end

    #-------------------------------------------------------------------------#

    describe "In general" do

      it "returns its name" do
        @root.name.should == "MyApp"
      end

      it "returns the parent" do
        @root.parent.should == @podfile
        @child.parent.should == @root
      end

      #--------------------------------------#

      it "returns the children" do
        @root.children.should == [@child]
        @child.children.should == []
      end

      it "returns the recursive children" do
        @grand_child   = Podfile::TargetDefinition.new("MyAppTests", @child)
        @root.recursive_children.should == [@child, @grand_child]
        @child.recursive_children.should == [@grand_child]
        @grand_child.recursive_children.should == []
      end

      it "returns whether it is root" do
        @root.should.be.root
        @child.should.not.be.root
      end

      it "returns the root target definition" do
        @root.root.should == @root
        @child.root.should == @root
      end

      it "returns the podfile that specifies it" do
        @root.podfile.class.should == Podfile
        @child.podfile.class.should == Podfile
      end

      it "returns dependencies" do
        @root.store_pod('BlocksKit')
        @child.store_pod('OCMockito')
        @root.dependencies.map(&:name).should  == %w[ BlocksKit ]
        @child.dependencies.map(&:name).should == %w[ OCMockito BlocksKit ]
      end

      it "doesn't inherit dependencies if it is exclusive" do
        @root.store_pod('BlocksKit')
        @child.store_pod('OCMockito')
        @child.exclusive = true
        @child.dependencies.map(&:name).should == %w[ OCMockito ]
      end

      it "returns the non inherited dependencies" do
        @root.store_pod('BlocksKit')
        @child.store_pod('OCMockito')
        @root.non_inherited_dependencies.map(&:name).should == %w[ BlocksKit ]
        @child.non_inherited_dependencies.map(&:name).should == %w[ OCMockito ]
      end

      it "returns whether it is empty" do
        @root.store_pod('BlocksKit')
        @root.should.not.be.empty
        @child.should.be.empty
      end

      it "returns its label" do
        @root.label.should == 'Pods-MyApp'
      end

      it "returns `Pods` as the label if its name is default" do
        target_def = Podfile::TargetDefinition.new("Pods", @podfile)
        target_def.label.should == 'Pods'
      end

      it "includes the name of the parent in the label if any" do
        @child.label.should == 'Pods-MyApp-MyAppTests'
      end

      it "doesn't include the name of the parent in the label if it is exclusive" do
        @child.exclusive = true
        @child.label.should == 'Pods-MyAppTests'
      end
    end

    #-------------------------------------------------------------------------#

    describe "Attributes accessors" do

      it "is not exclusive by default by the default if the platform of the parent match" do
        @child.should.not.be.exclusive
      end

      it "is exclusive by the default if the platform of the parent doesn't match" do
        @root.set_platform(:osx, '10.6')
        @child.set_platform(:ios, '6.0')
        @child.should.be.exclusive
      end

      it "allows to set whether it is exclusive" do
        @child.should.not.be.exclusive
        @child.exclusive = true
        @child.should.be.exclusive
      end

      #--------------------------------------#

      it "doesn't specify any target to link with by default" do
        @root.link_with.should.be.nil
      end

      it "allows to set the names of the client targets that it should link with" do
        @root.link_with = ['appTarget1, appTarget2']
        @root.link_with.should.be == ['appTarget1, appTarget2']
      end

      it "wraps the targets specified by the user in an array" do
        @root.link_with = 'appTarget1'
        @root.link_with.should.be == ['appTarget1']
      end

      it "returns nil if the link_with array is empty" do
        @root.link_with = []
        @root.link_with.should.be.nil
      end

      #--------------------------------------#

      it "allows to specify whether it should link with the first target of project" do
        @root.link_with_first_target = true
        @root.should.link_with_first_target
      end

      it "returns that it shouldn't link with the first target if any target has been specified" do
        @root.link_with = 'appTarget1'
        @root.link_with_first_target = true
        @root.should.not.link_with_first_target
      end

      #--------------------------------------#

      it "doesn't specifies any user project by default" do
        @root.user_project_path.should.be.nil
      end

      it "allows to set the path of the user project" do
        @root.user_project_path = 'some/path/project.xcodeproj'
        @root.user_project_path.should == 'some/path/project.xcodeproj'
      end

      it "appends the extension to a specified user project if needed" do
        @root.user_project_path = 'some/path/project'
        @root.user_project_path.should == 'some/path/project.xcodeproj'
      end

      it "inherits the path of the user project from the parent" do
        @root.user_project_path = 'some/path/project.xcodeproj'
        @child.user_project_path.should == 'some/path/project.xcodeproj'
      end

      #--------------------------------------#

      it "doesn't specifies any project build configurations default" do
        @root.build_configurations.should.be.nil
      end

      it "allows to set the project build configurations" do
        @root.build_configurations = { 'Debug' => :debug, 'Release' => :release }
        @root.build_configurations.should == { 'Debug' => :debug, 'Release' => :release }
      end

      it "inherits the project build configurations from the parent" do
        @root.build_configurations = { 'Debug' => :debug, 'Release' => :release }
        @child.build_configurations.should == { 'Debug' => :debug, 'Release' => :release }
      end

      #--------------------------------------#

      it "doesn't inhibit all warnings by default" do
        @root.should.not.inhibit_all_warnings?
      end

      it "returns if it should inhibit all warnings" do
        @root.inhibit_all_warnings = true
        @root.should.inhibit_all_warnings?
      end

      it "inherits the option to inhibit all warnings from the parent" do
        @root.inhibit_all_warnings = true
        @child.should.inhibit_all_warnings?
      end

      #--------------------------------------#

      it "returns its platform" do
        @root.platform.should == Pod::Platform.new(:ios, '6.0')
      end

      it "inherits the platform form the parent" do
        @root.platform.should == Pod::Platform.new(:ios, '6.0')
      end

      it "provides a default deployment target if not specified" do
        @root.set_platform(:ios)
        @root.platform.should == Pod::Platform.new(:ios, '4.3')

        @root.set_platform(:osx)
        @root.platform.should == Pod::Platform.new(:osx, '10.6')
      end

      it "raises if the specified platform is unsupported" do
        e = lambda { @root.set_platform(:win) }.should.raise Podfile::StandardError
        e.message.should.match /Unsupported platform/
      end

      #--------------------------------------#

      it "stores a dependency on a pod as a sting if no requirements are provided" do
        @root.store_pod('BlocksKit')
        @root.send(:get_hash_value, 'dependencies').should == [
          "BlocksKit"
        ]
      end

      it "stores a dependency on a pod as a hash if requirements provided" do
        @root.store_pod('Reachability', '1.0')
        @root.send(:get_hash_value, 'dependencies').should == [
          {"Reachability"=>["1.0"]}
        ]
      end

      #--------------------------------------#

      it "stores a dependency on a podspec" do
        @root.store_podspec(:name => 'BlocksKit')
        @root.send(:get_hash_value, 'podspecs').should == [
          {:name=>"BlocksKit"}
        ]
      end

      it "stores a dependency on a podspec and sets is as auto-detect if no options are provided" do
        @root.store_podspec()
        @root.send(:get_hash_value, 'podspecs').should == [
          { :autodetect => true }
        ]
      end

      it "raises if the provided podspec options are unsupported" do
        e = lambda { @root.store_podspec(:invent => 'BlocksKit') }.should.raise Podfile::StandardError
        e.message.should.match /Unrecognized options/
      end

    end

    #-------------------------------------------------------------------------#

    describe "Hash representation" do

      it "returns the hash representation" do
        @child.store_pod('BlocksKit')
        @child.set_platform(:ios)
        @child.to_hash.should == {
          "name" => "MyAppTests",
          "dependencies"=>["BlocksKit"],
          "platform"=>"ios"
        }
      end

      it "stores the children in the hash representation" do
        child_2   = Podfile::TargetDefinition.new("MoarTests", @root)
        @root.store_pod('BlocksKit')
        @child.store_pod('RestKit')
        @root.to_hash.should == {
          "name" => "MyApp",
          "platform"=>{"ios"=>"6.0"},
          "dependencies"=> ["BlocksKit"],
          "children"=> [
            {
              "name" => "MyAppTests",
              "dependencies"=> [ "RestKit"]
            },
            {
              "name" => "MoarTests",
            }
          ]
        }
      end

      it "can be initialized from a hash" do
        @root.store_pod('BlocksKit')
        @child.store_pod('RestKit')
        converted = Podfile::TargetDefinition.from_hash(@root.to_hash, @podfile)
        converted.to_hash.should == @root.to_hash
      end

    end

    #-------------------------------------------------------------------------#

    describe "Private helpers" do

      before do
        @root.podfile.defined_in_file = SpecHelper::Fixture.fixture('Podfile')
      end

      #--------------------------------------#

      it "sets and retrieves a value in the internal hash" do
        @root.send(:set_hash_value, 'inhibit_all_warnings', true)
        @root.send(:get_hash_value, 'inhibit_all_warnings').should.be.true
      end

      it "raises if there is an attempt to access or set an unknown key in the internal hash" do
        lambda { @root.send(:set_hash_value, 'unknown', true) }.should.raise Pod::Podfile::StandardError
        lambda { @root.send(:get_hash_value, 'unknown') }.should.raise Pod::Podfile::StandardError
      end

      it "returns the dependencies specified by the user" do
        @root.store_pod('BlocksKit')
        @root.store_pod('AFNetworking', '1.0')
        dependencies = @root.send(:pod_dependencies)
        dependencies.map(&:to_s).should == ["BlocksKit", "AFNetworking (= 1.0)"]
      end

      #--------------------------------------#

      describe "#pod_dependencies" do

        it "handles dependencies which only indicate the name of the Pod" do
          @root.store_pod('BlocksKit')
          @root.send(:pod_dependencies).should == [
            Dependency.new('BlocksKit')
          ]
        end

        it "handles requirements" do
          @root.store_pod('BlocksKit', '> 1.0', '< 2.5')
          @root.send(:pod_dependencies).should == [
            Dependency.new('BlocksKit', ['> 1.0', '< 2.5'])
          ]
        end

        it "handles subspecs" do
          @root.store_pod('Spec/Subspec')
          @root.send(:pod_dependencies).should == [
            Dependency.new('Spec/Subspec')
          ]
        end

        it "handles dependencies options" do
          @root.store_pod('BlocksKit', :git => 'GIT-URL', :commit => '1234')
          @root.send(:pod_dependencies).should == [
            Dependency.new('BlocksKit', :git => 'GIT-URL', :commit => '1234')
          ]
        end

      end

      #--------------------------------------#

      describe "#podspec_dependencies" do

        it "returns the dependencies of podspecs" do
          path = SpecHelper::Fixture.fixture('BananaLib.podspec').to_s
          @root.store_podspec(:path => path)
          @root.send(:podspec_dependencies).should == [
            Dependency.new('monkey', '< 1.0.9', '~> 1.0.1')
          ]
        end

        it "reject the dependencies on subspecs" do
          path = SpecHelper::Fixture.fixture('BananaLib.podspec').to_s
          @root.store_podspec(:path => path)
          external_dep = Dependency.new('monkey', '< 1.0.9', '~> 1.0.1')
          internal_dep = Dependency.new('BananaLib/subspec')
          deps = [external_dep, internal_dep]
          Specification.any_instance.stubs(:dependencies).returns([deps])
          @root.send(:podspec_dependencies).should == [
            Dependency.new('monkey', '< 1.0.9', '~> 1.0.1')
          ]
        end

      end

      #--------------------------------------#

      describe "#podspec_path_from_options" do

        it "resolves a podspec given the absolute path" do
          options = {:path => SpecHelper::Fixture.fixture('BananaLib')}
          file = @root.send(:podspec_path_from_options, options)
          file.should == SpecHelper::Fixture.fixture('BananaLib.podspec')
        end

        it "resolves a podspec given the relative path" do
          options = {:path => 'BananaLib.podspec'}
          file = @root.send(:podspec_path_from_options, options)
          file.should == SpecHelper::Fixture.fixture('BananaLib.podspec')
        end

        it "add the extension if needed" do
          options = {:path => 'BananaLib'}
          file = @root.send(:podspec_path_from_options, options)
          file.should == SpecHelper::Fixture.fixture('BananaLib.podspec')
        end

        it "it expands the tilde in the provided path" do
          home_dir = File.expand_path("~")
          options = {:path => '~/BananaLib.podspec'}
          file = @root.send(:podspec_path_from_options, options)
          file.should == Pathname.new("#{home_dir}/BananaLib.podspec")
        end

        it "resolves a podspec given its name" do
          options = {:name => 'BananaLib'}
          file = @root.send(:podspec_path_from_options, options)
          file.should == SpecHelper::Fixture.fixture('BananaLib.podspec')
        end

        it "auto-detects the podspec" do
          options = {:autodetect => true}
          file = @root.send(:podspec_path_from_options, options)
          file.should == SpecHelper::Fixture.fixture('BananaLib.podspec')
        end

      end

    end

    #-------------------------------------------------------------------------#

  end
end
