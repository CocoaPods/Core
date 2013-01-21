require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe Source do
    describe "In general" do

      before do
        @source = Source.new(fixture('spec-repos/master'))
      end

      it "return its name" do
        @source.name.should == 'master'
      end

      it "returns the sets of all the available Pods" do
        set_names = @source.pod_sets.map(&:name)
        set_names.should.include('JSONKit')
        set_names.should.include('Reachability')
      end

      it "returns the available versions of a Pod" do
        @source.versions('Reachability').map(&:to_s).should == %w| 3.1.0 3.0.0 2.0.5 2.0.4 |
      end

      it "returns the specification loaded from the Ruby DSL of a given version of a Pod" do
        spec = @source.specification('Reachability', Version.new('3.0.0'))
        spec.name.should == 'Reachability'
        spec.version.should.to_s == '3.0.0'
      end

      it "returns the specification loaded from a YAML file of a given version of a Pod" do
        source = Source.new(fixture('spec-repos/test_repo'))
        spec = source.specification('YAMLSpec', Version.new('1.0'))
        spec.name.should == 'YAMLSpec'
        spec.version.should.to_s == '1.0'
      end

      it "returns favors the YAML version of a specification if both are available" do
        source = Source.new(fixture('spec-repos/test_repo'))
        spec = source.specification('YAMLSpec', Version.new('0.9'))
        spec.name.should == 'YAMLSpec'
        spec.version.should.to_s == '0.9'
        path = fixture('spec-repos/test_repo/YAMLSpec/0.9')

        (path + 'YAMLSpec.podspec').should.exist
        spec.defined_in_file.should == path + 'YAMLSpec.podspec.yaml'
      end

      it "properly configures the sources of a set in search by name" do
        source = Source.new(fixture('spec-repos/test_repo'))
        sets = source.search_by_name('monkey', true)
        sets.count.should == 1
        set = sets.first
        set.name.should == 'BananaLib'
        set.sources.map(&:name).should == %w| test_repo |
      end

      it "can be ordered according to its name" do
        s1 = Source.new(Pathname.new 'customized')
        s2 = Source.new(Pathname.new 'master')
        s3 = Source.new(Pathname.new 'private')
        [s3, s1, s2].sort.should == [s1, s2, s3]
      end
    end
  end

  describe Source::Aggregate do
    describe "In general" do

      before do
        @aggregate = Source::Aggregate.new(fixture('spec-repos'))
      end
      # BananaLib is available only in test_repo.
      # JSONKit is in test repo has version 1.4 (duplicated) and the 999.999.999.

      it "returns all the sources" do
        @aggregate.all.map(&:name).should == %w| master test_repo |
      end

      it "returns the name of all the available pods" do
        root_spec_names = @aggregate.all_pods
        root_spec_names.should.include('JSONKit')
        root_spec_names.should.include('BananaLib')
      end

      it "returns all the available sets with the sources configured" do
        sets = @aggregate.all_sets
        banana_sets = sets.select{ |set| set.name == 'BananaLib' }
        banana_sets.count.should == 1
        banana_sets.first.sources.map(&:name).should == %w| test_repo |

        json_set = sets.select{ |set| set.name == 'JSONKit' }
        json_set.count.should == 1
        json_set.first.sources.map(&:name).should == %w| master test_repo |
      end

      it "searches the sets by dependency" do
        dep = Dependency.new('JSONKit')
        set = @aggregate.search(dep)
        set.name.should == 'JSONKit'
        set.sources.map(&:name).should == %w| master test_repo |
      end

      it "searches the sets specifying a dependency on a subspec" do
        dep = Dependency.new('RestKit/JSON')
        set = @aggregate.search(dep)
        set.name.should == 'RestKit'
        set.sources.map(&:name).should == %w| master |
      end

      it "returns nil if a specification can't be found" do
        dep = Dependency.new('DoesNotExist')
        set = @aggregate.search(dep)
        set.should == nil
      end

      it "raises if a subspec can't be found" do
        lambda {
          dep = Dependency.new('RestKit/DoesNotExist')
          set = @aggregate.search(dep)
        }.should.raise StandardError
      end

      it "searches the sets by name" do
        sets = @aggregate.search_by_name('JSONKit')
        sets.count.should == 1
        set = sets.first
        set.name.should == 'JSONKit'
        set.sources.map(&:name).should == %w| master test_repo |
      end

      it "properly configures the sources of a set in search by name" do
        sets = @aggregate.search_by_name('BananaLib')
        sets.count.should == 1
        set = sets.first
        set.name.should == 'BananaLib'
        set.sources.map(&:name).should == %w| test_repo |
      end
    end
  end
end
