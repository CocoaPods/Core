require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe Dependency do
    describe "In general" do

      it "creates a dependency from a string" do
        d =  Dependency.from_string("BananaLib (1.0)")
        d.name.should == "BananaLib"
        d.requirement.should =~ Version.new("1.0")
        d.head.should.be.nil
        d.external_source.should.be.nil
      end

      it "doesn't include external source when initialized from a string as incomplete and thus it should be provided by the client" do
        d = Dependency.from_string("BananaLib (from `www.example.com', tag `1.0')")
        d.name.should == "BananaLib"
        d.requirement.should.be.none?
        d.external?.should.be.false
      end

      it 'identifies itself as an external dependency' do
        dep = Dependency.new("cocoapods", :git => "git://github.com/cocoapods/cocoapods")
        dep.should.be.external
      end

      it "identifies itself as a `head` dependency" do
        dependency = Dependency.new("cocoapods", :head)
        dependency.should.be.head
        dependency.to_s.should == "cocoapods (HEAD)"
      end

      it "includes the external sources in the string reppresentation" do
        dependency = Dependency.new("cocoapods", :hg => 'example.com')
        dependency.to_s.should == "cocoapods (from `example.com`)"
      end

      it "only supports the `:head` option on the last version of a pod" do
        should.raise Pod::StandardError do
          Dependency.new("cocoapods", "1.2.3", :head)
        end
      end

      it "preserves head information when initialized form a string" do
        d = Dependency.from_string("BananaLib (HEAD)")
        d.name.should == "BananaLib"
        d.requirement.should.be.none?
        d.head.should.be.true
        d.external_source.should.be.nil
      end

      it "raises if an invalid initialization flag is given" do
        should.raise ArgumentError do
          Dependency.new("cocoapods", :foot)
        end
      end

      #--------------------------------------#

      it "preserves the external source on duplication" do
        dep = Dependency.new('bananas', :podspec => 'bananas' )
        dep.dup.external_source.should == { :podspec => 'bananas' }
      end

      it "preserves the head information on duplication" do
        dep = Dependency.new('bananas', :head)
        dep.dup.head.should.be.true
      end

      #--------------------------------------#

      it "returns the name of the dependency, or the name of the pod of which this is a subspec" do
        dep = Dependency.new('RestKit')
        dep.root_name.should == 'RestKit'
        dep = Dependency.new('RestKit/Networking')
        dep.root_name.should == 'RestKit'
      end

      it "returns a copy of the dependency but for the top level spec, if it's a subspec" do
        dep = Dependency.new('RestKit', '>= 1.2.3')
        dep.to_root_dependency.should == Dependency.new('RestKit', '>= 1.2.3')
        dep = Dependency.new('RestKit/Networking', '>= 1.2.3')
        dep.to_root_dependency.should == Dependency.new('RestKit', '>= 1.2.3')
      end

      #--------------------------------------#

      it "returns whether it is compatible with another dependency" do
        dep1 = Dependency.new('bananas', '>= 1.8')
        dep2 = Dependency.new('bananas', '1.9')
        dep1.compatible?(dep2).should.be.true
      end

      it "is not compatible with another dependency with non satisfied version requirements" do
        dep1 = Dependency.new('bananas', '> 1.9')
        dep2 = Dependency.new('bananas', '1.9')
        dep1.compatible?(dep2).should.be.false
      end

      it "is not compatible with another if the head informations differ" do
        dep1 = Dependency.new('bananas', :head)
        dep2 = Dependency.new('bananas', '1.9')
        dep1.compatible?(dep2).should.be.false
      end

      it "is not compatible with another if the external sources differ" do
        dep1 = Dependency.new('bananas', :podspec => 'bananas' )
        dep2 = Dependency.new('bananas', '1.9')
        dep1.compatible?(dep2).should.be.false
      end

      #--------------------------------------#

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

      #--------------------------------------#

      it "merges with another dependency" do
        dep1 = Dependency.new('bananas', '>= 1.8')
        dep2 = Dependency.new('bananas', '1.9')
        dep1.merge(dep2).should == Dependency.new('bananas', '>= 1.8', '1.9')
      end

      it "it preserves head state while merging with another dependency" do
        dep1 = Dependency.new('bananas', '1.9')
        dep2 = Dependency.new('bananas', :head)
        result = dep1.merge(dep2)
        result.should.be.head
        result.requirement.as_list.should == ['= 1.9']
      end

      it "it preserves the external source while merging with another dependency" do
        dep1 = Dependency.new('bananas', '1.9')
        dep2 = Dependency.new('bananas', :podspec => 'bananas' )
        result = dep1.merge(dep2)
        result.should.be.external
        result.requirement.as_list.should == ['= 1.9']
      end
    end
  end
end

