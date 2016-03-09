require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe MasterSource do
    before do
      @path = fixture('spec-repos/master')
      @source = MasterSource.new(@path)
    end

    #-------------------------------------------------------------------------#

    describe '#update' do
      it 'does not git fetch if the GitHub API returns not-modified' do
        VCR.use_cassette('MasterSource_nofetch', :record => :new_episodes) do
          @source.expects(:update_git_repo).never
          @source.send :update, true
        end
      end

      it 'fetches if the GitHub API returns not-modified' do
        VCR.use_cassette('MasterSource_fetch', :record => :new_episodes) do
          @source.expects(:update_git_repo)
          @source.send :update, true
        end
      end

      it 'uses the only fast forward git option' do
        @source.expects(:`).with { |cmd| cmd.should.include('--ff-only') }
        @source.send :update_git_repo
      end

      it 'uses git diff with name only option' do
        @source.expects(:`).with { |cmd| cmd.should.include('--name-only') }.returns('')
        @source.send :diff_until_commit_hash, 'DUMMY_HASH'
      end

      it 'finds diff of commits before/after repo update' do
        @source.expects(:`).with { |cmd| cmd.should.include('DUMMY_HASH..HEAD') }.returns('')
        @source.send :diff_until_commit_hash, 'DUMMY_HASH'
      end
    end

    #-------------------------------------------------------------------------#
  end
end
