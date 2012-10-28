require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe Dependency do
    describe "In general" do

      it "merges dependencies (taken from newer RubyGems version)" do
        dep1 = Dependency.new('bananas', '>= 1.8')
        dep2 = Dependency.new('bananas', '1.9')
        dep1.merge(dep2).should == Dependency.new('bananas', '>= 1.8', '1.9')
      end

      it "returns the name of the dependency, or the name of the pod of which this is a subspec" do
        dep = Dependency.new('RestKit')
        dep.pod_name.should == 'RestKit'
        dep = Dependency.new('RestKit/Networking')
        dep.pod_name.should == 'RestKit'
      end

      it "returns a copy of the dependency but for the top level spec, if it's a subspec" do
        dep = Dependency.new('RestKit', '>= 1.2.3')
        dep.to_pod_dependency.should == Dependency.new('RestKit', '>= 1.2.3')
        dep = Dependency.new('RestKit/Networking', '>= 1.2.3')
        dep.to_pod_dependency.should == Dependency.new('RestKit', '>= 1.2.3')
      end

      it "is equal to another dependency if `external_source` is the same" do
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
    end

    describe "External source" do
      before do
        @dependency = Dependency.new("cocoapods", :git => "git://github.com/cocoapods/cocoapods")
      end

      it 'identifies itself as an external dependency' do
        @dependency.should.be.external
      end
    end

    describe "Head" do
      it "identifies itself as a `head` dependency" do
        dependency = Dependency.new("cocoapods", :head)
        dependency.should.be.head
        dependency.to_s.should == "cocoapods (HEAD)"
      end

      it "only supports the `:head` option on the last version of a pod" do
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
  end
end
