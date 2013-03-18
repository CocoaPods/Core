require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Source::HealthReporter do

    before do
      @repo = fixture('spec-repos/test_repo')
      @sut = Source::HealthReporter.new(@repo)
    end

    #-------------------------------------------------------------------------#

    describe 'In general' do

      it "can store an option callback which is called before analyzing each specification" do
        names = []
        @sut.pre_check do |name, version|
          names << name
        end
        @sut.analyze
        names.should.include?("BananaLib")
      end

      it "analyzes all the specifications of a repo" do
        @sut.analyze
        @sut.report.analyzed_paths.count.should == 8
      end

      it "is robust against malformed specifications" do
        @sut.analyze
        errors = @sut.report.pods_by_error.keys.join(' - ')
        errors.should.match /Faulty_spec.podspec.*could not be loaded/
      end

      it "lints the specifications" do
        @sut.analyze
        errors = @sut.report.pods_by_error.keys.join(' - ')
        errors.should.match /Missing required attribute/
      end

      it "checks the path of the specifications" do
        @sut.analyze
        errors = @sut.report.pods_by_error.keys.join("\n")
        errors.should.match /Incorrect path/
      end

      it "checks for any stray specifications" do
        @sut.analyze
        errors = @sut.report.pods_by_error.keys.join("\n")
        errors.should.match /Stray spec/
      end
    end

    #-------------------------------------------------------------------------#

  end
end
