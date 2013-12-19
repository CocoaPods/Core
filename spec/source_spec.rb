require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe Source do

    before do
      @sut = Source.new(fixture('spec-repos/master'))
    end

    #-------------------------------------------------------------------------#

    describe "In general" do

      it "return its name" do
        @sut.name.should == 'master'
      end

      it "can be ordered according to its name" do
        s1 = Source.new(Pathname.new 'customized')
        s2 = Source.new(Pathname.new 'master')
        s3 = Source.new(Pathname.new 'private')
        [s3, s1, s2].sort.should == [s1, s2, s3]
      end

    end

    #-------------------------------------------------------------------------#

    describe "Queering the source" do

      it "returns the sets of all the available Pods" do
        set_names = @sut.pod_sets.map(&:name)
        set_names.should.include('JSONKit')
        set_names.should.include('Reachability')
      end

      it "returns the available versions of a Pod" do
        @sut.versions('Reachability').map(&:to_s).should == %w| 3.1.0 3.0.0 2.0.5 |
      end

      it "returns the specification for the given name and version" do
        spec = @sut.specification('Reachability', Version.new('3.0.0'))
        spec.name.should == 'Reachability'
        spec.version.should.to_s == '3.0.0'
      end

      it "returns the path of Ruby specification with a given name and version" do
        path = @sut.specification_path('Reachability', Version.new('3.0.0'))
        path.should == @sut.repo + 'Reachability/3.0.0/Reachability.podspec'
      end

      it "returns the path of JSON specification with a given name and version" do
        source = Source.new(fixture('spec-repos/test_repo'))
        path = source.specification_path('JSONSpec', Version.new('1.0'))
        path.should == source.repo + 'Specs/JSONSpec/1.0/JSONSpec.podspec.json'
      end

      it "favors the JSON version of a specification if both are available" do
        source = Source.new(fixture('spec-repos/test_repo'))
        ruby_path = source.repo + 'Specs/JSONSpec/0.9/JSONSpec.podspec.json'
        path = source.specification_path('JSONSpec', Version.new('0.9'))
        ruby_path.should.exist
        path.should == source.repo + 'Specs/JSONSpec/0.9/JSONSpec.podspec.json'
      end

      it "raises if it can't find a specification for the given version and name" do
        should.raise StandardError do
          @sut.specification_path('JSONSpec', Version.new('999'))
        end.message.should.match(/Unable to find the specification JSONSpec/)
      end

      it "returns all the specifications" do
        source = Source.new(fixture('spec-repos/test_repo'))
        source.all_specs.map(&:name).sort.uniq.should == ["BananaLib", "IncorrectPath", "JSONKit", "JSONSpec"]
      end

    end

    #-------------------------------------------------------------------------#

    describe "Searching the source" do
      describe "#search" do
        it "searches for the Pod with the given name" do
          source = Source.new(fixture('spec-repos/test_repo'))
          source.search('BananaLib').name.should == 'BananaLib'
        end

        it "searches for the pod with the given dependency" do
          source = Source.new(fixture('spec-repos/test_repo'))
          dep = Dependency.new('BananaLib')
          source.search(dep).name.should == 'BananaLib'
        end

        it "supports dependencies on subspecs" do
          source = Source.new(fixture('spec-repos/test_repo'))
          dep = Dependency.new('BananaLib/subspec')
          source.search(dep).name.should == 'BananaLib'
        end

      end

      describe "#search_by_name" do
        it "properly configures the sources of a set in search by name" do
          source = Source.new(fixture('spec-repos/test_repo'))
          sets = source.search_by_name('monkey', true)
          sets.count.should == 1
          set = sets.first
          set.name.should == 'BananaLib'
          set.sources.map(&:name).should == %w| test_repo |
        end
        
        it "can use regular expressions" do
          source = Source.new(fixture('spec-repos/test_repo'))
          sets = source.search_by_name('mon[ijk]ey', true)
          sets.first.name.should == 'BananaLib'
        end

        it "handles gracefully specification which can't load in search by name" do
          source = Source.new(fixture('spec-repos/test_repo'))
          should.not.raise do
            source.search_by_name('monkey', true)
          end
        end

        it "doesn't take into account case" do
          source = Source.new(fixture('spec-repos/test_repo'))
          source.search_by_name('BANANALIB', true).map(&:name).should == ['BananaLib']
          source.search_by_name('BANANALIB', false).map(&:name).should == ['BananaLib']
        end

        it "returns partial matches" do
          source = Source.new(fixture('spec-repos/test_repo'))
          source.search_by_name('Banana', true).map(&:name).should == ['BananaLib']
          source.search_by_name('Banana', false).map(&:name).should == ['BananaLib']
        end
      end

      describe "#fuzzy_search" do
        it "is case insensitive" do
          source = Source.new(fixture('spec-repos/master'))
          source.fuzzy_search('abmultiton').name.should == 'ABMultiton'
        end

        it "matches misspells" do
          source = Source.new(fixture('spec-repos/master'))
          source.fuzzy_search('ABMuton').name.should == 'ABMultiton'
        end

        it "matches abbreviations" do
          source = Source.new(fixture('spec-repos/master'))
          source.fuzzy_search('ObjSugar').name.should == "ObjectiveSugar"
        end

        it "matches suffixes" do
          source = Source.new(fixture('spec-repos/master'))
          source.fuzzy_search('table').name.should == "Routable"
        end

        it "returns nil if there is no match" do
          source = Source.new(fixture('spec-repos/master'))
          source.fuzzy_search('12345').should.be.nil
        end
      end

    end

    #-------------------------------------------------------------------------#

    describe "Representations" do

      before do
        @sut = Source.new(fixture('spec-repos/test_repo'))
      end

      it "returns the hash representation" do
        @sut.to_hash['BananaLib']['1.0']['name'].should == 'BananaLib'
      end

      it "returns the yaml representation" do
        yaml = @sut.to_yaml
        yaml.should.match /---/
        yaml.should.match /BananaLib:/
      end
    end

    #-------------------------------------------------------------------------#

    describe "Private Helpers" do

      describe "#specs_dir" do
        it "uses the `Specs` dir if it is present" do
          repo = fixture('spec-repos/test_repo')
          sut = Source.new(repo)
          sut.send(:specs_dir).should == repo + 'Specs'
        end

        it "uses the root of the repo as the specs dir if the `Specs` folder is not present" do
          repo = fixture('spec-repos/master')
          sut = Source.new(repo)
          sut.send(:specs_dir).should == repo
        end

        it "raises if unable to find the source with the given name" do
          repo = fixture('spec-repos/non_existing')
          sut = Source.new(repo)
          e = should.raise Informative do
            sut.send(:specs_dir)
          end
          e.message.should == 'Unable to find a source named: `non_existing`'
        end
      end

    end

    #-------------------------------------------------------------------------#

  end
end


