require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Source::Acceptor do

    before do
      @spec_path =  fixture('BananaLib.podspec')
      @spec = Specification.from_file(@spec_path)
      Specification.any_instance.stubs(:dependencies).returns([])
      @repo = fixture('spec-repos/test_repo')
      @sut = Source::Acceptor.new(@repo)
    end

    #-------------------------------------------------------------------------#

    describe 'In general' do

      it "returns the source that should accept the podspecs" do
        @sut.source.name.should == 'test_repo'
      end

      it "accepts a valid specification" do
        errors = @sut.analyze(@spec)
        errors.should == []
      end

      it "accepts a given path with a valid specification" do
        errors = @sut.analyze_path(@spec_path)
        errors.should == []
      end

      it "handles gracefully malformed specifications" do
        File.any_instance.stubs(:read).returns('raise')
        errors = @sut.analyze_path(@spec_path)
        errors.should == ["Unable to load the specification."]
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Analysis' do

      it "checks if the source of the specification did change" do
        @spec.source = { :git => 'http://EVIL-GORILLA-FORK/banana-lib.git', :tag => 'v1.0' }
        errors = @sut.analyze(@spec).join("\n")
        errors.should.match /The source of the spec doesn't match/
      end

      it "rejects a Git based specification without tag if there is at least one tagged version" do
        @spec.source = { :git => 'http://banana-corp.local/banana-lib.git', :commit => 'SHA' }
        errors = @sut.analyze(@spec).join("\n")
        errors.should.match /There is already at least one versioned specification/
      end

      it "checks if there is an attempt to change the commit of an untagged version" do
        repo = 'http://banana-corp.local/banana-lib.git'
        previous_spec = Specification.new
        previous_spec.version = '0.0.1'
        previous_spec.source  = { :git => repo, :commit => 'SHA_1' }
        @spec.version = '0.0.1'
        @spec.source = { :git => repo, :commit => 'SHA_2' }
        @sut.stubs(:related_specifications).returns(nil)
        errors = @sut.analyze(@spec, previous_spec).join("\n")
        errors.should.match /Attempt to rewrite the commit/
      end

      it "checks that the dependencies of the specification are available" do
        Specification.any_instance.unstub(:dependencies)
        errors = @sut.analyze(@spec).join("\n")
        errors.should.match /Unable to find a specification for the.*monkey.*dependency/
      end

    end
  end
end
