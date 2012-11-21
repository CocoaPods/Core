require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Source::Validator do
    describe 'In general' do
      before do
        @repo = fixture('spec-repos/test_repo')
        @validator = Source::Validator.new(@repo)
        @spec_path =  fixture('BananaLib.podspec')
        @spec = Specification.from_file(@spec_path)
        @validator.stubs(:spec).returns(@spec)

        @spec.stubs(:external_dependencies).returns([])
      end

      it "returns the source that should accept the podspecs" do
        @validator.source.name.should == 'test_repo'
      end

      it "accepts a valid podspec" do
        @validator.check(@spec_path)
        @validator.check(@spec_path).should.be.true
      end

      def check_error(*values)
        @validator.check(@spec_path).should.be.false
        @validator.errors.values.count.should == 1
        message = @validator.errors.values.first.first
        values.each do |value|
          message.should.include(value)
        end
      end

      it "lints the specification" do
        Specification.any_instance.stubs(:license).returns(nil)
        check_error('Linter failed')
      end

      # xit "checks the path of the specification" do
      #   @spec.stubs(:name).returns('Name')
      #   Specification::Linter.any_instance.stubs(:lint).returns(true)
      #   check_error('Incorrect path', '`Name/2.0.1/Name.podspec`')
      # end

      it "checks if the source of the specification did change" do
        source = { :git => 'http://EVIL-GORILLA-FORK/banana-lib.git', :tag => 'v1.0' }
         @spec.stubs(:source).returns(source)
        check_error('change', 'source', 'banana-corp.local/banana-lib.git')
      end

      it "rejects a Git based specification without tag if there are already tagged ones" do
        source = { :git => 'http://banana-corp.local/banana-lib.git', :commit => 'SHA' }
        @spec.stubs(:source).returns(source)
        check_error('untagged versions cannot be added')
      end

      # xit "rejects a Git based specification without tag if it is not marked as 0.0.1" do
      #   @validator.source.stubs(:versions).returns([Version.new('0.0.1')])
      #   source = { :git => 'http://banana-corp.local/banana-lib.git', :commit => 'SHA' }
      #   @spec.stubs(:source).returns(source)
      #   @validator.stubs(:reference_spec)
      #   check_error('Untagged', '0.0.1')
      # end

      # xit "checks if there an attempt to change the commit of an untagged version" do
      #   @validator.source.stubs(:versions).returns([Version.new('0.0.1')])
      #   source = { :git => 'http://banana-corp.local/banana-lib.git', :commit => 'SHA2' }
      #   @spec.stubs(:version).returns(Version.new '0.0.1')
      #   @spec.stubs(:source).returns(source)
      #   check_error('rewrite', 'commit', '0.0.1')
      # end

      it "checks that the dependencies of the specification are available" do
        dep = Dependency.new('find_me', '~>1.0')
        @spec.stubs(:external_dependencies).returns([dep])
        @validator.stubs(:reference_spec)
        check_error('specification', 'find_me (~> 1.0)', 'dependency')
      end

    end
  end
end
