require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Specification::Set do
    describe 'In general' do
      before do
        @source = Source.new(fixture('spec-repos/master'))
        @set = Spec::Set.new('CocoaLumberjack', @source)
      end

      it 'returns the name of the pod' do
        @set.name.should == 'CocoaLumberjack'
      end

      it 'returns the versions available for the pod ordered from highest to lowest' do
        @set.versions.should.all { |v| v.is_a?(Version) }
        @set.versions.map(&:to_s).should == %w(1.6.2 1.6.1 1.6 1.3.3 1.3.2 1.3.1 1.3 1.2.3 1.2.2 1.2.1 1.2 1.1 1.0)
      end

      it 'returns the highest version available for the pod' do
        @set.highest_version.should == Version.new('1.6.2')
      end

      it 'returns the path of the spec with the highest version' do
        @set.highest_version_spec_path.should == @source.repo + 'CocoaLumberjack/1.6.2/CocoaLumberjack.podspec'
      end

      it 'can test if it is equal to another set' do
        @set.should == Spec::Set.new('CocoaLumberjack', @source)
        @set.should.not == Spec::Set.new('RestKit', @source)
      end

      it 'returns a hash representation' do
        spec_path = @source.repo + 'CocoaLumberjack/1.6.2/CocoaLumberjack.podspec'
        @set.to_hash.should == {
          'name' => 'CocoaLumberjack',
          'versions' => {
            'master' => [
              '1.6.2', '1.6.1', '1.6', '1.3.3', '1.3.2', '1.3.1', '1.3', '1.2.3', '1.2.2',
              '1.2.1', '1.2', '1.1', '1.0'
            ],
          },
          'highest_version' => '1.6.2',
          'highest_version_spec' => spec_path.to_s,
        }
      end

      #--------------------------------------#

      it 'ignores dot files when getting the version directories' do
        `touch #{fixture('spec-repos/master/CocoaLumberjack/.DS_Store')}`
        should.not.raise do
          @set.versions
        end
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Concerning multiple sources' do
      before do
        # JSONKit is in test repo has version 1.4 (duplicated) and the 999.999.999.
        repos = [Source.new(fixture('spec-repos/test_repo')), Source.new(fixture('spec-repos/master'))]
        @set = Source::Aggregate.new(repos).search_by_name('JSONKit').first
      end

      it 'returns the sources where a podspec is available' do
        @set.sources.map(&:name).should == %w(test_repo master)
      end

      it 'returns all the available versions sorted from biggest to lowest' do
        @set.versions.map(&:to_s).should == %w(999.999.999 1.13 1.5pre 1.4)
      end

      it 'returns all the available versions by source sorted from biggest to lowest' do
        hash = {}
        @set.versions_by_source.each { |source, versions| hash[source.name] = versions.map(&:to_s) }
        hash['master'].should == %w(1.5pre 1.4)
        hash['test_repo'].should == %w(999.999.999 1.13 1.4)
        hash.keys.sort.should == %w(master test_repo)
      end
    end
  end

  #---------------------------------------------------------------------------#

  describe Specification::Set::External do
    before do
      @spec = Spec.from_file(fixture('BananaLib.podspec'))
      @set = Spec::Set::External.new(@spec)
    end

    it 'returns the specification' do
      @set.specification.should == @spec
    end

    it 'returns the name' do
      @set.name.should == 'BananaLib'
    end

    it 'returns whether it is equal to another set' do
      @set.should == Spec::Set::External.new(@spec)
    end

    it 'returns the version of the specification' do
      @set.versions.map(&:to_s).should == ['1.0']
    end
  end

  #---------------------------------------------------------------------------#

  describe 'Handling empty directories' do
    before do
      repos = [Source.new(fixture('spec-repos/test_empty_dir_repo'))]
      @set = Source::Aggregate.new(repos).search_by_name('EmptyDir_spec').first
    end

    it 'raises when encountering empty directories' do
      @set.name.should == 'EmptyDir_spec'
      exception = lambda { @set.specification }.should.raise Informative
      exception.message.should.include 'Could not find the highest version for `EmptyDir_spec`.'
    end
  end
end
