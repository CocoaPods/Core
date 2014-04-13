require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Specification::Linter do
    before do
      WebMock::API.stub_request(:head , /banana-corp.local/).to_return(:status => 200)
    end

    describe 'In general' do
      before do
        fixture_path = 'spec-repos/test_repo/Specs/BananaLib/1.0/BananaLib.podspec'
        @podspec_path = fixture(fixture_path)
      end

      it 'can be initialized with a specification' do
        spec = Specification.from_file(@podspec_path)
        @linter = Specification::Linter.new(spec)
        @linter.spec.name.should == 'BananaLib'
        @linter.file.should == @podspec_path
      end

      it 'can be initialized with a path' do
        @linter = Specification::Linter.new(@podspec_path)
        @linter.spec.name.should == 'BananaLib'
        @linter.file.should == @podspec_path
      end

      extend SpecHelper::TemporaryDirectory

      it 'catches specification load errors' do
        podspec = 'Pod::Spec.new do |s|; error; end'
        path = SpecHelper.temporary_directory + 'BananaLib.podspec'
        File.open(path, 'w') { |f| f.write(podspec) }
        lambda { Specification.from_file(path) }.should.raise Pod::DSLError
        lambda { Specification::Linter.new(path) }.should.not.raise
      end

      it 'includes an error indicating that the specification could not be loaded' do
        podspec = 'Pod::Spec.new do |s|; error; end'
        path = SpecHelper.temporary_directory + 'BananaLib.podspec'
        File.open(path, 'w') { |f| f.write(podspec) }
        linter = Specification::Linter.new(path)
        linter.lint
        linter.results.count.should == 1
        linter.results.first.message.should.match /spec.*could not be loaded/
      end

      before do
        fixture_path = 'spec-repos/test_repo/Specs/BananaLib/1.0/BananaLib.podspec'
        @podspec_path = fixture(fixture_path)
        @linter = Specification::Linter.new(@podspec_path)
      end

      it 'accepts a valid podspec' do
        valid = @linter.lint
        @linter.results.should == []
        valid.should.be.true
      end

      it 'compacts multi_platform attributes' do
        @linter.spec.platform = nil
        @linter.spec.source_files = '/Absolute'
        @linter.lint
        @linter.results.count.should == 1
        @linter.results.first.platforms.map(&:to_s).sort.should == %w(ios osx)
      end

      before do
        @linter.spec.name = nil
        @linter.spec.summary = 'A short description of.'
        Pathname.any_instance.stubs(:read).returns('config.ios?')
        @linter.lint
      end

      it 'returns the results of the lint' do
        results = @linter.results.map { |r| r.type.to_s }.sort.uniq
        results.should == %w(error warning)
      end

      it 'returns the errors results of the lint' do
        @linter.errors.map(&:type).uniq.should == [:error]
      end

      it 'returns the warnings results of the lint' do
        @linter.warnings.map(&:type).should == [:warning]
      end

    end

    #--------------------------------------#

    describe 'Root spec' do
      before do
        fixture_path = 'spec-repos/test_repo/Specs/BananaLib/1.0/BananaLib.podspec'
        @podspec_path = fixture(fixture_path)
        @linter = Specification::Linter.new(@podspec_path)
        @spec = @linter.spec
      end

      def message_should_include(*values)
        @linter.lint
        results = @linter.results
        results.should.not.be.nil

        matched = results.select do |result|
          values.all? do |value|
            result.message.downcase.include?(value.downcase)
          end
        end

        matched.size.should == 1
      end

      #------------------#

      xit 'checks for unrecognized keys' do

      end

      xit 'checks the type of the values of the attributes' do

      end

      xit 'checks for unknown keys in the license' do
        lambda { @spec.license = { :name => 'MIT' } }.should.raise StandardError
      end

      xit 'checks the source for unknown keys' do
        call = lambda { @spec.source = { :tig => 'www.example.com/repo.tig' } }
        call.should.raise StandardError
      end

      it 'checks the required attributes' do
        @spec.stubs(:name).returns(nil)
        message_should_include('name', 'required')
      end

      #------------------#

      it 'fails a specification whose name does not match the name of the `podspec` file' do
        @spec.stubs(:name).returns('another_name')
        message_should_include('name', 'match')
      end

      it 'fails a specification whose name contains whitespace' do
        @spec.stubs(:name).returns('bad name')
        message_should_include('name', 'whitespace')
      end

      #------------------#

      it 'checks that the version has been specified' do
        @spec.stubs(:version).returns(Pod::Version.new(nil))
        message_should_include('version', 'required')
      end

      it 'checks the version is higher than 0' do
        @spec.stubs(:version).returns(Pod::Version.new('0'))
        message_should_include('version', '0')
      end

      #------------------#

      it 'checks the summary length' do
        @spec.stubs(:summary).returns('sample ' * 100 + '.')
        @spec.stubs(:description).returns(nil)
        message_should_include('summary', 'short')
      end

      it 'checks the summary for the example value' do
        @spec.stubs(:summary).returns('A short description of.')
        message_should_include('summary', 'meaningful')
      end

      #------------------#

      it 'checks the description for the example value' do
        @spec.stubs(:description).returns('An optional longer description of.')
        message_should_include('description', 'meaningful')
      end

      it 'checks if the description is equal to the summary' do
        @spec.stubs(:description).returns(@linter.spec.summary)
        message_should_include('description', 'equal', 'summary')
      end

      it 'checks if the description is shorter than the summary' do
        @spec.stubs(:description).returns('sample.')
        message_should_include('description', 'shorter', 'summary')
      end

      #------------------#

      it 'checks if the homepage has been changed from default' do
        @spec.stubs(:homepage).returns('http://EXAMPLE/test')
        message_should_include('homepage', 'default')
      end

      #------------------#

      it 'checks whether the license type' do
        @spec.stubs(:license).returns(:file => 'License')
        message_should_include('license', 'type')
      end

      it 'checks the license type for the sample value' do
        @spec.stubs(:license).returns(:type => '(example)')
        message_should_include('license', 'type')
      end

      it 'checks whether the license type is empty' do
        @spec.stubs(:license).returns(:type => ' ')
        message_should_include('license', 'type')
      end

      #------------------#

      it 'checks for the example source' do
        @spec.stubs(:source).returns(:git => 'http://EXAMPLE.git', :tag => '1.0')
        message_should_include('source', 'example')
      end

      it 'checks that the commit is not specified as `HEAD`' do
        @spec.stubs(:version).returns(Version.new '0.0.1')
        @spec.stubs(:source).returns(:git => 'http://repo.git', :commit => 'HEAD')
        message_should_include('source', 'HEAD')
      end

      it 'checks that the version is included in the git tag when the version is a string' do
        @spec.stubs(:version).returns(Version.new '1.0.1')
        @spec.stubs(:source).returns(:git => 'http://repo.git', :tag => '1.0')
        message_should_include('git', 'version', 'tag')
      end

      it 'checks that the version is included in the git tag  when the version is a Version' do
        @spec.stubs(:version).returns(Version.new '1.0.1')
        @spec.stubs(:source).returns(:git => 'http://repo.git', :tag => (Version.new '1.0'))
        message_should_include('git', 'version', 'tag')
      end

      it 'checks that Github repositories use the `https` form (for compatibility)' do
        @spec.stubs(:source).returns(:git => 'http://github.com/repo.git', :tag => '1.0')
        message_should_include('Github', 'https')
      end

      it 'checks that Github repositories end in .git (for compatibility)' do
        @spec.stubs(:source).returns(:git => 'https://github.com/repo', :tag => '1.0')
        message_should_include('Github', '.git')
      end

      it 'does not warn for Github repositories with OAuth authentication' do
        @spec.stubs(:source).returns(:git => 'https://TOKEN:x-oauth-basic@github.com/COMPANY/REPO.git', :tag => '1.0')
        @linter.lint
        @linter.results.should.be.empty
      end

      it 'does not warn for local repositories with spaces' do
        @spec.stubs(:source).returns(:git => '/Users/kylef/Projects X', :tag => '1.0')
        @linter.lint
        @linter.results.should.be.empty
      end

      it 'does not warn for SSH repositories' do
        @spec.stubs(:source).returns(:git => 'git@bitbucket.org:kylef/test.git', :tag => '1.0')
        @linter.lint
        @linter.results.should.be.empty
      end

      it 'does not warn for SSH repositories on Github' do
        @spec.stubs(:source).returns(:git => 'git@github.com:kylef/test.git', :tag => '1.0')
        @linter.lint
        @linter.results.should.be.empty
      end

      it 'performs checks for Gist Github repositories' do
        @spec.stubs(:source).returns(:git => 'git://gist.github.com/2823399.git', :tag => '1.0')
        message_should_include('Github', 'https')
      end

      it 'checks the source of 0.0.1 specifications for commit or a tag' do
        @spec.stubs(:version).returns(Version.new '0.0.1')
        @spec.stubs(:source).returns(:git => 'www.banana-empire.git')
        message_should_include('sources', 'either', 'tag', 'commit')
      end

      it 'checks the source of a non 0.0.1 specifications for a tag' do
        @spec.stubs(:version).returns(Version.new '1.0.1')
        @spec.stubs(:source).returns(:git => 'www.banana-empire.git')
        message_should_include('sources', 'specify a tag.')
      end

      #------------------#

      it 'checks if the social_media_url has been changed from default' do
        @spec.stubs(:social_media_url).returns('https://twitter.com/EXAMPLE')
        message_should_include('social media URL', 'default')
      end

      #------------------#

      it 'checks that frameworks do not end with a .framework extension' do
        @spec.frameworks = %w(AddressBook.framework QuartzCore.framework)
        message_should_include('framework', 'name')
      end

      it 'checks that frameworks do not include unwanted characters' do
        @spec.frameworks = ['AddressBook, QuartzCore']
        message_should_include('framework', 'name')
      end

      it 'checks that weak frameworks do not end with a .framework extension' do
        @spec.weak_frameworks = %w(AddressBook.framework QuartzCore.framework)
        message_should_include('weak framework', 'name')
      end

      it 'checks that weak frameworks do not include unwanted characters' do
        @spec.weak_frameworks = ['AddressBook, QuartzCore']
        message_should_include('weak framework', 'name')
      end

      #------------------#

      it 'checks that libraries do not end with a .a extension' do
        @spec.libraries = %w(z.a xml.a)
        message_should_include('library', 'name')
      end

      it 'checks that libraries do not end with a .dylib extension' do
        @spec.libraries = %w(ssl.dylib z.dylib)
        message_should_include('library', 'name')
      end

      it 'checks that libraries do not begin with lib' do
        @spec.libraries = %w(libz libssl)
        message_should_include('library', 'name')
      end

      it 'checks that libraries do not contain unwanted characters' do
        @spec.libraries = ['ssl, z']
        message_should_include('library', 'name')
      end

      #------------------#

      it 'checks if the compiler flags disable warnings' do
        @spec.compiler_flags = '-some_flag', '-another -Wno_flags'
        message_should_include('warnings', 'disabled')
        @linter.lint
        message = @linter.results.first.message
        message.should.include('Warnings')
        message.should.include('disabled')
      end
    end
  end
end
