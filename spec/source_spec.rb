require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe Source do

    before do
      @path = fixture('spec-repos/test_repo')
      provider = Source::FileSystemDataProvider.new(@path)
      @sut = Source.new(provider)
    end

    #-------------------------------------------------------------------------#

    describe 'In general' do
      it 'return its name' do
        @sut.name.should == 'test_repo'
      end

      it 'return its type' do
        @sut.type.should == 'file system'
      end

      it 'can be ordered according to its name' do
        s1 = Source.new(Pathname.new 'customized')
        s2 = Source.new(Pathname.new 'master')
        s3 = Source.new(Pathname.new 'private')
        [s3, s1, s2].sort.should == [s1, s2, s3]
      end
    end

    #-------------------------------------------------------------------------#

    describe '#pods' do
      it 'returns the available Pods' do
        @sut.pods.should == %w(BananaLib Faulty_spec IncorrectPath JSONKit JSONSpec)
      end

      it "raises if the repo doesn't exists" do
        @path = fixture('spec-repos/non_existing')
        provider = Source::FileSystemDataProvider.new(@path)
        @sut = Source.new(provider)
        e = should.raise Informative do
          @sut.pods
        end
        e.message.should == 'Unable to find the file system source named: `non_existing`'
      end
    end

    #-------------------------------------------------------------------------#

    describe '#versions' do
      it 'returns the available versions of a Pod' do
        @sut.versions('JSONKit').map(&:to_s).should == ['999.999.999', '1.4']
      end

      it 'returns nil if the Pod could not be found' do
        @sut.versions('Unknown_Pod').should.be.nil
      end
    end

    #-------------------------------------------------------------------------#

    describe '#specification' do
      it 'returns the specification for the given name and version' do
        spec = @sut.specification('JSONKit', Version.new('1.4'))
        spec.name.should == 'JSONKit'
        spec.version.should.to_s == '1.4'
      end
    end

    #-------------------------------------------------------------------------#

    describe '#all_specs' do
      it 'returns all the specifications' do
        expected = %w(BananaLib IncorrectPath JSONKit JSONSpec)
        @sut.all_specs.map(&:name).sort.uniq.should == expected
      end
    end

    #-------------------------------------------------------------------------#

    describe '#set' do
      it 'returns the set of a given Pod' do
        set = @sut.set('BananaLib')
        set.name.should == 'BananaLib'
        set.sources.should == [@sut]
      end
    end

    #-------------------------------------------------------------------------#

    describe '#pod_sets' do
      it 'returns all the pod sets' do
        expected = %w(BananaLib Faulty_spec IncorrectPath JSONKit JSONSpec)
        @sut.pod_sets.map(&:name).sort.uniq.should == expected
      end
    end

    #-------------------------------------------------------------------------#

    describe '#search' do
      it 'searches for the Pod with the given name' do
        @sut.search('BananaLib').name.should == 'BananaLib'
      end

      it 'searches for the pod with the given dependency' do
        dep = Dependency.new('BananaLib')
        @sut.search(dep).name.should == 'BananaLib'
      end

      it 'supports dependencies on subspecs' do
        dep = Dependency.new('BananaLib/subspec')
        @sut.search(dep).name.should == 'BananaLib'
      end

      describe '#search_by_name' do
        it 'properly configures the sources of a set in search by name' do
          source = Source.new(fixture('spec-repos/test_repo'))
          sets = source.search_by_name('monkey', true)
          sets.count.should == 1
          set = sets.first
          set.name.should == 'BananaLib'
          set.sources.map(&:name).should == %w(test_repo)
        end

        it 'can use regular expressions' do
          source = Source.new(fixture('spec-repos/test_repo'))
          sets = source.search_by_name('mon[ijk]ey', true)
          sets.first.name.should == 'BananaLib'
        end
      end
    end

    #-------------------------------------------------------------------------#

    describe '#search_by_name' do
      it 'supports full text search' do
        sets = @sut.search_by_name('monkey', true)
        sets.map(&:name).should == ['BananaLib']
        sets.map(&:sources).should == [[@sut]]
      end

      it 'The search is case insensitive' do
        pods = @sut.search_by_name('MONKEY', true)
        pods.map(&:name).should == ['BananaLib']
      end

      it 'supports partial matches' do
        pods = @sut.search_by_name('MON', true)
        pods.map(&:name).should == ['BananaLib']
      end

      it "handles gracefully specification which can't be loaded" do
        should.raise Informative do
          @sut.specification('Faulty_spec', '1.0.0')
        end.message.should.include 'Invalid podspec'

        should.not.raise do
          @sut.search_by_name('monkey', true)
        end
      end
    end

    #-------------------------------------------------------------------------#

    describe '#fuzzy_search' do
      it 'is case insensitive' do
        @sut.fuzzy_search('bananalib').name.should == 'BananaLib'
      end

      it 'matches misspells' do
        @sut.fuzzy_search('banalib').name.should == 'BananaLib'
      end

      it 'matches suffixes' do
        @sut.fuzzy_search('Lib').name.should == 'BananaLib'
      end

      it 'returns nil if there is no match' do
        @sut.fuzzy_search('12345').should.be.nil
      end

      it 'matches abbreviations' do
        @sut.fuzzy_search('BLib').name.should == 'BananaLib'
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Representations' do
      it 'returns the hash representation' do
        @sut.to_hash['BananaLib']['1.0']['name'].should == 'BananaLib'
      end

      it 'returns the yaml representation' do
        yaml = @sut.to_yaml
        yaml.should.match /---/
        yaml.should.match /BananaLib:/
      end
    end

    #-------------------------------------------------------------------------#

  end
end
