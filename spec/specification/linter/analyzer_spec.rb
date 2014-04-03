require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Specification::Linter::Analyzer do

    describe 'File patterns & Build settings' do

      before do
        fixture_path = 'spec-repos/test_repo/Specs/BananaLib/1.0/BananaLib.podspec'
        podspec_path = fixture(fixture_path)
        linter = Specification::Linter.new(podspec_path)
        @spec = linter.spec
        @analyzer = Specification::Linter::Analyzer.new(@spec.consumer(:ios))
      end

      def message_should_include(*values)
        @analyzer.analyze
        results = @analyzer.results
        results.should.not.be.nil

        matched = results.select do |result|
          values.all? do |value|
            result.message.downcase.include?(value.downcase)
          end
        end

        matched.size.should == 1
      end

      it "checks if any file patterns is absolute" do
        @spec.source_files = '/Classes'
        @analyzer.analyze
        message_should_include('patterns', 'relative', 'source_files')
      end

      it "checks if a specification is empty" do
        consumer = Specification::Consumer
        consumer.any_instance.stubs(:source_files).returns([])
        consumer.any_instance.stubs(:resources).returns({})
        consumer.any_instance.stubs(:preserve_paths).returns([])
        consumer.any_instance.stubs(:subspecs).returns([])
        consumer.any_instance.stubs(:dependencies).returns([])
        consumer.any_instance.stubs(:vendored_libraries).returns([])
        consumer.any_instance.stubs(:vendored_frameworks).returns([])
        @analyzer.analyze
        message_should_include('spec', 'empty')
      end

      #----------------------------------------#

      describe 'File patterns & Build settings' do
        it "that the attribute is not nil" do
          @spec.requires_arc = nil
          @analyzer.analyze
          @analyzer.results.should.not.be.empty?
          @analyzer.results.first.message.should.include?('`requires_arc` should be specified')
        end

        it "supports the declaration of the attribute per platform" do
          @spec.ios.requires_arc = true
          @analyzer.analyze
          @analyzer.results.should.be.empty?
        end

        it "supports the declaration of the attribute in the parent" do
          @spec = Spec.new do |s|
            s.requires_arc = true
            s.subspec 'SubSpec' do |sp|
            end
          end
          @analyzer = Specification::Linter::Analyzer.new(@spec.consumer(:ios))
          @analyzer.analyze
          @analyzer.results.should.be.empty?
        end
      end

      #----------------------------------------#


      it "checks if the pre install hook has been defined" do
        @spec.pre_install {}
        @analyzer.analyze
        message_should_include('pre install hook', 'deprecated')
      end

      it "checks if the post install hook has been defined" do
        @spec.post_install {}
        @analyzer.analyze
        message_should_include('post install hook', 'deprecated')
      end
    end
  end
end
