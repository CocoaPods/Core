require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Specification::Linter::Analyzer do

    describe 'File patterns & Build settings' do
      before do
        fixture_path = 'spec-repos/test_repo/Specs/BananaLib/1.0/BananaLib.podspec'
        podspec_path = fixture(fixture_path)
        linter = Specification::Linter.new(podspec_path)
        @spec = linter.spec
        @subject = Specification::Linter::Analyzer.new(@spec.consumer(:ios))
      end

      #----------------------------------------#

      describe 'File Patterns' do
        it 'checks if any file patterns is absolute' do
          @spec.source_files = '/Classes'
          @subject.analyze
          @subject.results.count.should.be.equal(1)
          expected = 'patterns must be relative'
          @subject.results.first.message.should.include?(expected)
        end

        it 'checks if a specification is empty' do
          consumer = Specification::Consumer
          consumer.any_instance.stubs(:source_files).returns([])
          consumer.any_instance.stubs(:resources).returns({})
          consumer.any_instance.stubs(:resource_bundles).returns([])
          consumer.any_instance.stubs(:preserve_paths).returns([])
          consumer.any_instance.stubs(:subspecs).returns([])
          consumer.any_instance.stubs(:dependencies).returns([])
          consumer.any_instance.stubs(:vendored_libraries).returns([])
          consumer.any_instance.stubs(:vendored_frameworks).returns([])
          @subject.analyze
          @subject.results.count.should.be.equal(1)
          @subject.results.first.message.should.include?('spec is empty')
        end
      end

      #----------------------------------------#

      describe 'Requires ARC' do
        it 'that the attribute is not nil' do
          @spec.requires_arc = nil
          @subject.analyze
          @subject.results.count.should.be.equal(1)
          expected = '`requires_arc` should be specified'
          @subject.results.first.message.should.include?(expected)
        end

        it 'supports the declaration of the attribute per platform' do
          @spec.ios.requires_arc = true
          @subject.analyze
          @subject.results.should.be.empty?
        end

        it 'supports the declaration of the attribute in the parent' do
          @spec = Spec.new do |s|
            s.requires_arc = true
            s.subspec 'SubSpec' do |sp|
            end
          end
          consumer = @spec.consumer(:ios)
          @subject = Specification::Linter::Analyzer.new(consumer)
          @subject.analyze
          @subject.results.should.be.empty?
        end
      end

      #----------------------------------------#

      describe 'Hooks' do
        it 'checks if the pre install hook has been defined' do
          @spec.pre_install {}
          @subject.analyze
          @subject.results.count.should.be.equal(1)
          expected = 'pre install hook has been deprecated'
          @subject.results.first.message.should.include?(expected)
        end

        it 'checks if the post install hook has been defined' do
          @spec.post_install {}
          @subject.analyze
          @subject.results.count.should.be.equal(1)
          expected = 'post install hook has been deprecated'
          @subject.results.first.message.should.include?(expected)
        end
      end
    end
  end
end
