require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Source::HealthReporter do

    before do
      WebMock::API.stub_request(:head, /banana-corp.local/).to_return(:status => 200)
      WebMock::API.stub_request(:head, /github.com/).to_return(:status => 200)
      @repo = fixture('spec-repos/test_repo')
      @subject = Source::HealthReporter.new(@repo)
    end

    #-------------------------------------------------------------------------#

    describe 'In general' do

      it 'can store an option callback which is called before analyzing each specification' do
        names = []
        @subject.pre_check do |name, version|
          names << name
        end
        @subject.analyze
        names.should.include?('BananaLib')
      end

      it 'analyzes all the specifications of a repo' do
        @subject.analyze
        @subject.report.analyzed_paths.count.should == 10
      end

      it 'is robust against malformed specifications' do
        @subject.analyze
        errors = @subject.report.pods_by_error.keys.join(' - ')
        errors.should.match /Faulty_spec.podspec.*could not be loaded/
      end

      it 'lints the specifications' do
        @subject.analyze
        errors = @subject.report.pods_by_error.keys.join(' - ')
        errors.should.match /Missing required attribute/
      end

      it 'checks the path of the specifications' do
        @subject.analyze
        errors = @subject.report.pods_by_error.keys.join("\n")
        errors.should.match /Incorrect path/
      end

      it 'checks for any stray specifications' do
        @subject.analyze
        errors = @subject.report.pods_by_error.keys.join("\n")
        errors.should.match /Stray spec/
      end
    end

    #-------------------------------------------------------------------------#

  end
end
