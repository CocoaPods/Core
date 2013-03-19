require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Source::Aggregate do

    # BananaLib is available only in test_repo.
    # JSONKit is in test repo has version 1.4 (duplicated) and the 999.999.999.
    #
    before do
      @sut = Source::Aggregate.new(fixture('spec-repos'))
    end

    #-------------------------------------------------------------------------#

    describe "In general" do

      it "returns all the sources" do
        @sut.all.map(&:name).should == %w| master test_repo |
      end

      it "returns the name of all the available pods" do
        root_spec_names = @sut.all_pods
        root_spec_names.should.include('JSONKit')
        root_spec_names.should.include('BananaLib')
      end

      it "returns all the available sets with the sources configured" do
        sets = @sut.all_sets
        banana_sets = sets.select{ |set| set.name == 'BananaLib' }
        banana_sets.count.should == 1
        banana_sets.first.sources.map(&:name).should == %w| test_repo |

        json_set = sets.select{ |set| set.name == 'JSONKit' }
        json_set.count.should == 1
        json_set.first.sources.map(&:name).should == %w| master test_repo |
      end

      it "searches the sets by dependency" do
        dep = Dependency.new('JSONKit')
        set = @sut.search(dep)
        set.name.should == 'JSONKit'
        set.sources.map(&:name).should == %w| master test_repo |
      end

      it "searches the sets specifying a dependency on a subspec" do
        dep = Dependency.new('RestKit/JSON')
        set = @sut.search(dep)
        set.name.should == 'RestKit'
        set.sources.map(&:name).should == %w| master |
      end

      it "returns nil if a specification can't be found" do
        dep = Dependency.new('Does-not-exist')
        set = @sut.search(dep)
        set.should == nil
      end

      it "raises if a subspec can't be found" do
        lambda {
          dep = Dependency.new('RestKit/Does-not-exist')
          set = @sut.search(dep)
        }.should.raise StandardError
      end

      it "returns the directories where the repos are defined" do
        @sut.dirs.map { |d| d.basename.to_s }.sort.should == ["master", "test_repo"]
      end

      it "returns an empty list for the directories if the repos dir doesn't exists" do
        aggregate = Source::Aggregate.new(Pathname.new('missing-dir'))
        aggregate.dirs.should == []
      end

      it "returns a set configured to use only the source which contains the highest version" do
        set = @sut.represenative_set('JSONKit')
        set.versions.map(&:to_s).should == ["999.999.999", "1.4"]
      end

    end

    #-------------------------------------------------------------------------#

    describe "Search" do

      it "searches the sets by name" do
        sets = @sut.search_by_name('JSONKit')
        sets.count.should == 1
        set = sets.first
        set.name.should == 'JSONKit'
        set.sources.map(&:name).should == %w| master test_repo |
      end

      it "properly configures the sources of a set in search by name" do
        sets = @sut.search_by_name('BananaLib')
        sets.count.should == 1
        set = sets.first
        set.name.should == 'BananaLib'
        set.sources.map(&:name).should == %w| test_repo |
      end

      it "performs a full text search" do
        @sut.stubs(:dirs).returns([fixture('spec-repos/test_repo')])
        sets = @sut.search_by_name('Banana Corp', true)
        sets.count.should == 1
        sets.first.name.should == 'BananaLib'
      end

      it "raises an informative if unable to find a Pod with the given name" do
        @sut.stubs(:dirs).returns([fixture('spec-repos/test_repo')])
        should.raise Informative do
          @sut.search_by_name('Some-funky-name', true)
        end.message.should.match /Unable to find/
      end

    end

    #-------------------------------------------------------------------------#

    describe "Search Index" do

      before do
        test_source = Source.new(fixture('spec-repos/test_repo'))
        @sut.stubs(:all).returns([test_source])
      end

      it "generates the search index from scratch" do
        index = @sut.generate_search_index
        index.keys.sort.should == ["BananaLib", "Faulty_spec", "JSONKit", "YAMLSpec"]
        index["BananaLib"]["version"].should == '1.0'
        index["BananaLib"]["summary"].should == 'Chunky bananas!'
        index["BananaLib"]["description"].should == 'Full of chunky bananas.'
        index["BananaLib"]["authors"].should == 'Banana Corp, Monkey Boy'
      end

      it "updates a given index" do
        old_index = {"Faulty_spec" => {}, "JSONKit" => {}, "YAMLSpec" => {}}
        index = @sut.update_search_index(old_index)
        index.keys.sort.should == ["BananaLib", "Faulty_spec", "JSONKit", "YAMLSpec"]
        index["BananaLib"]["version"].should == '1.0'
      end

      it "updates a set in the index if a lower version was stored" do
        old_index = {"BananaLib" => {"version" => '0.8'}}
        index = @sut.update_search_index(old_index)
        index["BananaLib"]["version"].should == '1.0'
      end

      it "updates a set in the search index if no information was stored" do
        old_index = {"BananaLib" => {}}
        index = @sut.update_search_index(old_index)
        index["BananaLib"]["version"].should == '1.0'
      end

      it "doesn't updates a set in the index if there already information for an equal or higher version" do
        old_index = {"BananaLib" => {"version" => '1.0', "summary" => "custom" }}
        index = @sut.update_search_index(old_index)
        index["BananaLib"]["summary"].should == 'custom'
      end

      it "loads only the specifications which need to be updated" do
        Specification.expects(:from_file).at_least_once
        index = @sut.generate_search_index
        Specification.expects(:from_file).never
        search_data = @sut.update_search_index(index)
      end

      it "deletes from the index the data of the sets which are not present in the aggregate" do
        old_index = {"Deleted-Pod" => {"version" => '1.0', "summary" => "custom" }}
        index = @sut.update_search_index(old_index)
        index["Deleted-Pod"].should.be.nil
      end

    end

    #-------------------------------------------------------------------------#

  end
end
