require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe LocalSource do
    before do
      @path = fixture('spec-repos/test_local_repo')
      @source = LocalSource.new(@path)
    end

    #-------------------------------------------------------------------------#

    describe 'In general' do
      it 'return its type' do
        @source.type.should == 'file system'
      end

      it 'is not updateable' do
        @source.updateable?.should.be.false
      end

      it 'is not indexable?' do
        @source.indexable?.should.be.false
      end
    end

    #-------------------------------------------------------------------------#

    describe '#pods' do
      it 'returns the available Pods' do
        @source.pods.should == %w(Artsy+UIFonts BananaLib JSONKit yoga)
      end

      it "raises if the repo doesn't exist" do
        @path = fixture('spec-repos/non_existing')
        @source = LocalSource.new(@path)
        should.raise Informative do
          @source.pods
        end.message.should.match /Unable to find a source named: `non_existing`/
      end
    end

    #-------------------------------------------------------------------------#

    describe '#versions' do
      it 'returns the available versions of a Pod' do
        @source.versions('JSONKit').map(&:to_s).should == ['1.13', '1.4']
      end

      it 'returns nil if the Pod could not be found' do
        @source.versions('Unknown_Pod').should.be.nil
      end

      it 'returns cached versions for a Pod' do
        all_specs = @source.all_specs
        @source.expects(:all_specs).returns(all_specs).once
        @source.versions('JSONKit').map(&:to_s).should == ['1.13', '1.4']
        @source.versions('JSONKit').map(&:to_s).should == ['1.13', '1.4']
        @source.instance_variable_get(:@versions_by_name).should == { 'JSONKit' => [Version.new('1.13'), Version.new('1.4')] }
      end
    end

    #-------------------------------------------------------------------------#

    describe '#specification' do
      it 'returns the specification for the given name and version' do
        spec = @source.specification('JSONKit', Version.new('1.4'))
        spec.name.should == 'JSONKit'
        spec.version.should.to_s == '1.4'
      end
    end

    #-------------------------------------------------------------------------#

    describe '#all_specs' do
      it 'returns all the specifications' do
        expected = %w(Artsy+UIFonts BananaLib JSONKit JSONKit yoga)
        @source.all_specs.map(&:name).sort.should == expected
      end
    end

    #-------------------------------------------------------------------------#

    describe '#set' do
      it 'returns the set of a given Pod' do
        set = @source.set('BananaLib')
        set.name.should == 'BananaLib'
        set.sources.should == [@source]
      end
    end

    #-------------------------------------------------------------------------#

    describe '#pod_sets' do
      it 'returns all the pod sets' do
        expected = %w(Artsy+UIFonts BananaLib JSONKit yoga)
        @source.pod_sets.map(&:name).sort.uniq.should == expected
      end
    end

    #-------------------------------------------------------------------------#

    describe '#search' do
      it 'searches for the Pod with the given name' do
        @source.search('BananaLib').name.should == 'BananaLib'
      end

      it 'searches for the pod with the given dependency' do
        dep = Dependency.new('BananaLib')
        @source.search(dep).name.should == 'BananaLib'
      end

      it 'supports dependencies on subspecs' do
        dep = Dependency.new('BananaLib/subspec')
        @source.search(dep).name.should == 'BananaLib'
      end

      it 'matches case' do
        @source.search('bAnAnAlIb').should.be.nil?
      end

      describe 'when there is an empty directory' do
        before { @empty_dir = @path.join('Specs', 'Empty').tap(&:mkpath) }
        after { FileUtils.rm_r @empty_dir }

        it 'returns nil' do
          @source.search('Empty').should.be.nil
        end
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
        sets = @source.search_by_name('monkey', true)
        sets.map(&:name).should == ['BananaLib']
        sets.map(&:sources).should == [[@source]]
      end

      it 'The search is case insensitive' do
        pods = @source.search_by_name('MONKEY', true)
        pods.map(&:name).should == ['BananaLib']
      end

      it 'supports partial matches' do
        pods = @source.search_by_name('MON', true)
        pods.map(&:name).should == ['BananaLib']
      end

      # it "handles gracefully specification which can't be loaded" do
      #   should.raise Informative do
      #     @source.specification('Faulty_spec', '1.0.0')
      #   end.message.should.include 'Invalid podspec'
      #
      #   should.not.raise do
      #     @source.search_by_name('monkey', true)
      #   end
      # end
    end

    #-------------------------------------------------------------------------#

    describe '#fuzzy_search' do
      it 'is case insensitive' do
        @source.fuzzy_search('bananalib').name.should == 'BananaLib'
      end

      it 'matches misspells' do
        @source.fuzzy_search('banalib').name.should == 'BananaLib'
      end

      it 'matches suffixes' do
        @source.fuzzy_search('Lib').name.should == 'BananaLib'
      end

      it 'returns nil if there is no match' do
        @source.fuzzy_search('12345').should.be.nil
      end

      it 'matches abbreviations' do
        @source.fuzzy_search('BLib').name.should == 'BananaLib'
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Representations' do
      it 'returns the hash representation' do
        @source.to_hash['BananaLib']['1.0']['name'].should == 'BananaLib'
      end

      it 'returns the yaml representation' do
        yaml = @source.to_yaml
        yaml.should.match /---/
        yaml.should.match /BananaLib:/
      end
    end
  end
end
