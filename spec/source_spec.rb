require File.expand_path('../spec_helper', __FILE__)

describe "Pod::Source" do
  before do
    @source = Pod::Source.new(fixture('spec-repos/master'))
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
    @source.versions('Reachability').map(&:to_s).should == %w| 3.0.0 2.0.5 2.0.4 |
  end

  it "returns the specification of a given version of a Pod" do
    spec = @source.specification('Reachability', Pod::Version.new('3.0.0'))
    spec.name.should == 'Reachability'
    spec.version.should.to_s == '3.0.0'
  end

  it "properly configures the sources of a set in seach by name" do
    source = Pod::Source.new(fixture('spec-repos/test_repo'))
    sets = source.search_by_name('monkey', true)
    sets.count.should == 1
    set = sets.first
    set.name.should == 'BananaLib'
    set.sources.map(&:name).should == %w| test_repo |
  end

  describe Pod::Source::Aggregate do
    before do
      @aggregate = Pod::Source::Aggregate.new(fixture('spec-repos'))
    end
    # BananaLib is available only in test_repo.
    # JSONKit is in test repo has version 1.4 (duplicated) and the 999.999.999.

    it "returns all the sources" do
      @aggregate.all.map(&:name).should == %w| master test_repo |
    end

    it "returns the name of all the available pods" do
      pod_names = @aggregate.all_pods
      pod_names.should.include('JSONKit')
      pod_names.should.include('BananaLib')
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
      dep = Pod::Dependency.new('JSONKit')
      set = @aggregate.search(dep)
      set.name.should == 'JSONKit'
      set.sources.map(&:name).should == %w| master test_repo |
    end

    it "searches the sets specifing a dependency on a subspec" do
      dep = Pod::Dependency.new('RestKit/JSON')
      set = @aggregate.search(dep)
      set.name.should == 'RestKit'
      set.sources.map(&:name).should == %w| master |
    end

    it "returns nil if a specification can't be found" do
      dep = Pod::Dependency.new('DoesNotExist')
      set = @aggregate.search(dep)
      set.should == nil
    end

    it "raises if a subspec can't be found" do
      lambda {
        dep = Pod::Dependency.new('RestKit/DoesNotExist')
        set = @aggregate.search(dep)
      }.should.raise Pod::StandardError
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
