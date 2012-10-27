require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe Dependency do
    it "merges dependencies (taken from newer RubyGems version)" do
      dep1 = Dependency.new('bananas', '>= 1.8')
      dep2 = Dependency.new('bananas', '1.9')
      dep1.merge(dep2).should == Dependency.new('bananas', '>= 1.8', '1.9')
    end

    it "returns the name of the dependency, or the name of the pod of which this is a subspec" do
      dep = Dependency.new('RestKit')
      dep.top_level_spec_name.should == 'RestKit'
      dep = Dependency.new('RestKit/Networking')
      dep.top_level_spec_name.should == 'RestKit'
    end

    it "returns a copy of the dependency but for the top level spec, if it's a subspec" do
      dep = Dependency.new('RestKit', '>= 1.2.3')
      dep.to_top_level_spec_dependency.should == Dependency.new('RestKit', '>= 1.2.3')
      dep = Dependency.new('RestKit/Networking', '>= 1.2.3')
      dep.to_top_level_spec_dependency.should == Dependency.new('RestKit', '>= 1.2.3')
    end

    it "is equal to another dependency if `external_source' is the same" do
      dep1 = Dependency.new('bananas', :git => 'GIT-URL')
      dep2 = Dependency.new('bananas')
      dep1.should.not == dep2
      dep3 = Dependency.new('bananas', :git => 'GIT-URL')
      dep1.should == dep3
    end

    it "takes into account the `head` option to check for equality" do
      dep1 = Dependency.new('bananas', :head)
      dep2 = Dependency.new('bananas', :head)
      dep3 = Dependency.new('bananas')
      dep1.should == dep2
      dep1.should.not == dep3
    end

    it 'raises if created without either valid name/version/external requirements or a block' do
      lambda { Dependency.new }.should.raise Pod::StandardError
    end

    describe "with a hash of external source settings" do
      before do
        @dependency = Dependency.new("cocoapods", :git => "git://github.com/cocoapods/cocoapods")
      end

      it 'identifies itself as an external dependency' do
        @dependency.should.be.external
      end
    end

    describe "with flags" do
      it "identifies itself as a `bleeding edge' dependency" do
        dependency = Dependency.new("cocoapods", :head)
        dependency.should.be.head
        dependency.to_s.should == "cocoapods (HEAD)"
      end

      it "only supports the `:head' option on the last version of a pod" do
        should.raise Pod::StandardError do
          Dependency.new("cocoapods", "1.2.3", :head)
        end
      end

      it "raises if an invalid flag is given" do
        should.raise ArgumentError do
          Dependency.new("cocoapods", :foot)
        end
      end
    end

    describe "Dependency::ExternalSources" do
      # before do
      #   @sandbox = temporary_sandbox
      # end

      xit "marks a LocalPod as downloaded if it's from GitSource" do
        dependency = Dependency.new("Reachability", :git => fixture('integration/Reachability'))
        dependency.external_source.copy_external_source_into_sandbox(@sandbox, Platform.ios)
        @sandbox.installed_pod_named('Reachability', Platform.ios).downloaded.should.be.true
      end

      xit "creates a copy of the podspec (GitSource)" do
        dependency = Dependency.new("Reachability", :git => fixture('integration/Reachability'))
        dependency.external_source.copy_external_source_into_sandbox(@sandbox, Platform.ios)
        path = @sandbox.root + 'Local Podspecs/Reachability.podspec'
        path.should.exist?
      end

      xit "creates a copy of the podspec (PodspecSource)" do
        dependency = Dependency.new("Reachability", :podspec => fixture('integration/Reachability/Reachability.podspec').to_s)
        dependency.external_source.copy_external_source_into_sandbox(@sandbox, Platform.ios)
        path = @sandbox.root + 'Local Podspecs/Reachability.podspec'
        path.should.exist?
      end

      xit "creates a copy of the podspec (LocalSource)" do
        dependency = Dependency.new("Reachability", :local => fixture('integration/Reachability'))
        dependency.external_source.copy_external_source_into_sandbox(@sandbox, Platform.ios)
        path = @sandbox.root + 'Local Podspecs/Reachability.podspec'
        path.should.exist?
      end
    end
  end
end
