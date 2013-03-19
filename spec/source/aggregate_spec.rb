require File.expand_path('../../spec_helper', __FILE__)

module Pod

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
        dep = Dependency.new('Does-not-exist')
        set = @aggregate.search(dep)
        set.should == nil
      end

      it "raises if a subspec can't be found" do
        lambda {
          dep = Dependency.new('RestKit/Does-not-exist')
          set = @aggregate.search(dep)
        }.should.raise StandardError
      end

      #-----------------------------------------------------------------------#

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

      it "performs a full text search" do
        @aggregate.stubs(:dirs).returns([fixture('spec-repos/test_repo')])
        sets = @aggregate.search_by_name('Banana Corp', true)
        sets.count.should == 1
        sets.first.name.should == 'BananaLib'
      end

      it "raises an informative if unable to find a Pod with the given name" do
        @aggregate.stubs(:dirs).returns([fixture('spec-repos/test_repo')])
        should.raise Informative do
          @aggregate.search_by_name('Some-funky-name', true)
        end.message.should.match /Unable to find/
      end

      #-----------------------------------------------------------------------#

      it "returns the directories where the repos are defined" do
        @aggregate.dirs.map { |d| d.basename.to_s }.sort.should == ["master", "test_repo"]
      end

      it "returns an empty list for the directories if the repos dir doesn't exists" do
        aggregate = Source::Aggregate.new(Pathname.new('missing-dir'))
        aggregate.dirs.should == []
      end
    end

    #-------------------------------------------------------------------------#

  end
end
