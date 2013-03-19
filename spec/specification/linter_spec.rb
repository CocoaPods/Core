require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Specification::Linter do
    describe 'In general' do
      before do
        fixture_path = 'spec-repos/test_repo/BananaLib/1.0/BananaLib.podspec'
        @podspec_path = fixture(fixture_path)
      end

      it "can be initialized with a specification" do
        spec = Specification.from_file(@podspec_path)
        @linter = Specification::Linter.new(spec)
        @linter.spec.name.should == 'BananaLib'
        @linter.file.should == @podspec_path
      end

      it "can be initialized with a path" do
        @linter = Specification::Linter.new(@podspec_path)
        @linter.spec.name.should == 'BananaLib'
        @linter.file.should == @podspec_path
      end

      extend SpecHelper::TemporaryDirectory

      it "catches specification load errors" do
        podspec = "Pod::Spec.new do |s|; error; end"
        path = SpecHelper.temporary_directory + 'BananaLib.podspec'
        File.open(path, 'w') {|f| f.write(podspec) }
        lambda { Specification.from_file(path) }.should.raise Pod::DSLError
        lambda { Specification::Linter.new(path) }.should.not.raise
      end

      it "includes an error indicating that the specification could not be loaded" do
        podspec = "Pod::Spec.new do |s|; error; end"
        path = SpecHelper.temporary_directory + 'BananaLib.podspec'
        File.open(path, 'w') {|f| f.write(podspec) }
        linter = Specification::Linter.new(path)
        linter.lint
        linter.results.count.should == 1
        linter.results.first.message.should.match /spec.*could not be loaded/
      end

      before do
        fixture_path = 'spec-repos/test_repo/BananaLib/1.0/BananaLib.podspec'
        podspec_path = fixture(fixture_path)
        @linter = Specification::Linter.new(@podspec_path)
      end

      it "accepts a valid podspec" do
        valid = @linter.lint
        @linter.results.should == []
        valid.should.be.true
      end

      it "compacts multi_platform attributes" do
        @linter.spec.platform = nil
        @linter.spec.source_files = '/Absolute'
        @linter.lint
        @linter.results.count.should == 1
        @linter.results.first.platforms.map(&:to_s).sort.should == %w[ios osx]
      end

      before do
        @linter.spec.name = nil
        @linter.spec.summary = 'A short description of.'
        Pathname.any_instance.stubs(:read).returns('config.ios?')
        @linter.lint
      end

      it "returns the results of the lint" do
        results = @linter.results.map{ |r| r.type.to_s }.sort.uniq
        results.should == %w[ error warning ]
      end

      it "returns the errors results of the lint" do
        @linter.errors.map(&:type).uniq.should == [:error]
      end

      it "returns the warnings results of the lint" do
        @linter.warnings.map(&:type).should == [:warning]
      end

      it "can operate in master repo mode" do
        fixture_path = 'spec-repos/test_repo/BananaLib/1.0/BananaLib.podspec'
        @podspec_path = fixture(fixture_path)
        @linter = Specification::Linter.new(@podspec_path)
        @spec = @linter.spec
        @spec.stubs(:source).returns({:git => 'https://github.com/repo', :tag => '1.0'})
        @linter.master_repo_mode = true
        @linter.lint
        error = @linter.results.find { |r| r.type == :error && r.message.match(/end in.*\.git/) }
        error.should.not.be.nil
      end
    end

    #--------------------------------------#

    describe 'Root spec' do
      before do
        fixture_path = 'spec-repos/test_repo/BananaLib/1.0/BananaLib.podspec'
        @podspec_path = fixture(fixture_path)
        @linter = Specification::Linter.new(@podspec_path)
        @spec = @linter.spec
      end

      def message_should_include(*values)
        @linter.lint
        result = @linter.results.first
        result.should.not.be.nil
        @linter.results.map(&:message).should == [result.message]
        message = result.message.downcase
        values.each do |value|
          message.should.include(value.downcase)
        end
      end

      #------------------#

      xit "checks for unrecognized keys" do

      end

      xit "checks the type of the values of the attributes" do

      end

      xit "checks for unknown keys in the license" do
        lambda { @spec.license = { :name => 'MIT' } }.should.raise StandardError
      end

      xit "checks the source for unknown keys" do
        call = lambda { @spec.source = { :tig => 'www.example.com/repo.tig' } }
        call.should.raise StandardError
      end

      it "checks the required attributes" do
        @spec.stubs(:name).returns(nil)
        message_should_include('name', 'required')
      end

      #------------------#

      it "fails a specification whose name does not match the name of the `podspec` file" do
        @spec.stubs(:name).returns('another_name')
        message_should_include('name', 'match')
      end

      #------------------#

      it "checks the summary length" do
        @spec.stubs(:summary).returns('sample ' * 100 + '.')
        @spec.stubs(:description).returns(nil)
        message_should_include('summary', 'short')
      end

      it "checks the summary for the example value" do
        @spec.stubs(:summary).returns('A short description of.')
        message_should_include('summary', 'meaningful')
      end

      it "checks the summary punctuation" do
        @spec.stubs(:summary).returns('sample')
        message_should_include('summary', 'punctuation')
      end

      it "checks to make sure there are not too many comments in the file" do
        podspec = "# some comment\n" * 30
        path = SpecHelper.temporary_directory + 'BananaLib.podspec'
        FileUtils.cp @podspec_path, path
        File.open(path, 'a') {|f| f.puts(podspec) }
        linter = Specification::Linter.new(path)
        linter.lint
        linter.results.count.should == 1
        linter.results.first.message.should.match /Comments must be deleted./
      end

      it "should not count #define's as comments" do
        podspec = "#define\n" * 30
        path = SpecHelper.temporary_directory + 'BananaLib.podspec'
        FileUtils.cp @podspec_path, path
        File.open(path, 'a') {|f| f.puts(podspec) }
        linter = Specification::Linter.new(path)
        linter.lint
        linter.results.count.should == 0
      end

      #------------------#

      it "checks the description for the example value" do
        @spec.stubs(:description).returns('An optional longer description of.')
        message_should_include('description', 'meaningful')
      end

      it "checks the description punctuation" do
        @spec.stubs(:description).returns('sample ' * 100)
        message_should_include('description', 'punctuation')
      end

      it "checks if the description is equal to the summary" do
        @spec.stubs(:description).returns(@linter.spec.summary)
        message_should_include('description', 'equal', 'summary')
      end

      it "checks if the description is shorter than the summary" do
        @spec.stubs(:description).returns('sample.')
        message_should_include('description', 'shorter', 'summary')
      end

      #------------------#

      it "checks whether the license type" do
        @spec.stubs(:license).returns({ :file => 'License' })
        message_should_include('license', 'type')
      end

      it "checks the license type for the sample value" do
        @spec.stubs(:license).returns({:type => '(example)'})
        message_should_include('license', 'type')
      end

      it "checks whether the license type is empty" do
        @spec.stubs(:license).returns({:type => ' '})
        message_should_include('license', 'type')
      end

      #------------------#

      it "checks for the example source" do
        @spec.stubs(:source).returns({:git => 'http://EXAMPLE.git', :tag => '1.0'})
        message_should_include('source', 'example')
      end

      it "checks that the commit is not specified as `HEAD`" do
        @spec.stubs(:version).returns(Version.new '0.0.1')
        @spec.stubs(:source).returns({:git => 'http://repo.git', :commit => 'HEAD'})
        message_should_include('source', 'HEAD')
      end

      it "checks that the version is included in the git tag" do
        @spec.stubs(:version).returns(Version.new '1.0.1')
        @spec.stubs(:source).returns({:git => 'http://repo.git', :tag => '1.0'})
        message_should_include('git', 'version', 'tag')
      end

      it "checks that Github repositories use the `https` form (for compatibility)" do
        @spec.stubs(:source).returns({:git => 'http://github.com/repo.git', :tag => '1.0'})
        message_should_include('Github', 'https')
      end

      it "checks that Github repositories end in .git (for compatibility)" do
        @spec.stubs(:source).returns({:git => 'https://github.com/repo', :tag => '1.0'})
        message_should_include('Github', '.git')
      end

      it "checks the source of 0.0.1 specifications for commit or a tag" do
        @spec.stubs(:version).returns(Version.new '0.0.1')
        @spec.stubs(:source).returns({:git => 'www.banana-empire.git'})
        message_should_include('sources', 'either', 'tag', 'commit')
      end

      it "checks the source of a non 0.0.1 specifications for a tag" do
        @spec.stubs(:version).returns(Version.new '1.0.1')
        @spec.stubs(:source).returns({:git => 'www.banana-empire.git'})
        message_should_include('sources', 'specify a tag.')
      end
    end

    #--------------------------------------#

    describe 'File patterns & Build settings' do

      before do
        fixture_path = 'spec-repos/test_repo/BananaLib/1.0/BananaLib.podspec'
        podspec_path = fixture(fixture_path)
        @linter = Specification::Linter.new(podspec_path)
        @spec = @linter.spec
      end

      it "checks if the compiler flags disable warnings" do
        @spec.compiler_flags = '-some_flag', '-another -Wno_flags'
        @linter.lint
        message = @linter.results.first.message
        message.should.include('Warnings')
        message.should.include('disabled')
      end

      it "checks if any file patterns is absolute" do
        @spec.source_files = '/Classes'
        @linter.lint
        message = @linter.results.first.message
        message.should.include('patterns')
        message.should.include('relative')
        message.should.include('source_files')
      end

      it "announces deprecations for the Rake::FileList [TEMPORARY]" do
        @spec.source_files = ::Rake::FileList.new('FileList-Classes')
        @linter.lint
        message = @linter.results.first.message
        message.should.include('FileList')
        message.should.include('deprecated')
        message.should.include('source_files')
      end

      it "checks if a specification is empty" do
        consumer = Specification::Consumer
        consumer.any_instance.stubs(:source_files).returns([])
        consumer.any_instance.stubs(:resources).returns({})
        consumer.any_instance.stubs(:preserve_paths).returns([])
        consumer.any_instance.stubs(:subspecs).returns([])
        @linter.lint
        message = @linter.results.first.message
        message.should.include('appears to be empty')
      end

      it "requires that the require_arc value is specified until the switch to a true default" do
        consumer = Specification::Consumer
        consumer.any_instance.stubs(:requires_arc).returns(nil)
        @linter.lint
        message = @linter.results.first.message
        message.should.include('`requires_arc` should be specified')
      end
    end

  end

  #---------------------------------------------------------------------------#

  describe Specification::Linter::Result do
    before do
      @result = Specification::Linter::Result.new(:error, 'This is a sample error.')
    end

    it "returns the type" do
      @result.type.should == :error
    end

    it "returns the message" do
      @result.message.should == 'This is a sample error.'
    end

    it "can store the platforms that generated the result" do
      @result.platforms << :ios
      @result.platforms.should == [:ios]
    end

    it "returns a string representation suitable for UI" do
      @result.to_s.should == '[ERROR] This is a sample error.'
      @result.platforms << :ios
      @result.to_s.should == '[ERROR] This is a sample error. [iOS]'
    end
  end
end
