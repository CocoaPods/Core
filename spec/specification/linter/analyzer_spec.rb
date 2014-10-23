require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Specification::Linter::Analyzer do

    describe 'File patterns & Build settings' do
      before do
        fixture_path = 'spec-repos/test_repo/Specs/BananaLib/1.0/BananaLib.podspec'
        podspec_path = fixture(fixture_path)
        linter = Specification::Linter.new(podspec_path)
        @spec = linter.spec
        results = Specification::Linter::Results.new
        @subject = Specification::Linter::Analyzer.new(@spec.consumer(:ios),
                                                       results)
      end

      #----------------------------------------#

      describe 'Unknown keys check' do

        it 'validates a spec with valid keys' do
          results = @subject.analyze
          results.should.be.empty?
        end

        it 'validates a spec with multi-platform attributes' do
          @spec.ios.requires_arc = true
          results = @subject.analyze
          results.should.be.empty?
        end

        it 'fails a spec with unknown keys' do
          @spec.attributes_hash['unknown_key'] = true
          results = @subject.analyze
          results.count.should.be.equal(1)
          expected = 'Unrecognized `unknown_key` key'
          results.first.message.should.include?(expected)
        end

        it 'fails a spec with unknown multi-platform key' do
          @spec.attributes_hash['ios'] = { 'unknown_key' => true }
          results = @subject.analyze
          results.count.should.be.equal(1)
          expected = 'Unrecognized `unknown_key` key'
          results.first.message.should.include?(expected)
        end

        it 'validates a spec with valid sub-keys' do
          @spec.license = { :type => 'MIT' }
          results = @subject.analyze
          results.should.be.empty?
        end

        it 'fails a spec with unknown sub-keys' do
          @spec.license = { :is_safe_for_work => true }
          results = @subject.analyze
          results.count.should.be.equal(1)
          expected = 'Unrecognized `is_safe_for_work` key'
          results.first.message.should.include?(expected)
        end

        it 'validates a spec with valid minor sub-keys' do
          @spec.source = { :git => 'example.com', :branch => 'master' }
          results = @subject.analyze
          results.should.be.empty?
        end

        it 'fails a spec with a missing primary sub-keys' do
          @spec.source = { :branch => 'example.com', :commit => 'MyLib' }
          results = @subject.analyze
          results.count.should.be.equal(1)
          expected = 'Missing primary key for `source` attribute.'
          results.first.message.should.include?(expected)
        end

        it 'fails a spec with invalid secondary sub-keys' do
          @spec.source = { :git => 'example.com', :folder => 'MyLib' }
          results = @subject.analyze
          results.count.should.be.equal(1)
          expected = 'Incompatible `folder` key(s) with `git`'
          results.first.message.should.include?(expected)
        end

        it 'fails a spec with multiple primary keys' do
          @spec.source = { :git => 'example.com', :http => 'example.com' }
          results = @subject.analyze
          results.count.should.be.equal(1)
          expected = 'Incompatible `git, http` keys'
          results.first.message.should.include?(expected)
        end

        it 'fails a spec invalid secondary sub-keys when no sub-keys are supported' do
          @spec.source = { :http => 'example.com', :unsupported => true }
          results = @subject.analyze
          results.count.should.be.equal(1)
          expected = 'Incompatible `unsupported` key(s) with `http`'
          results.first.message.should.include?(expected)
        end
      end

      #----------------------------------------#

      describe 'File Patterns' do
        it 'checks if any file patterns is absolute' do
          @spec.source_files = '/Classes'
          results = @subject.analyze
          results.count.should.be.equal(1)
          expected = 'patterns must be relative'
          results.first.message.should.include?(expected)
          results.first.message.should.include?('File Patterns')
        end

        it 'checks if a specification is empty' do
          consumer = Specification::Consumer
          consumer.any_instance.stubs(:source_files).returns([])
          consumer.any_instance.stubs(:resources).returns({})
          consumer.any_instance.stubs(:resource_bundles).returns([])
          consumer.any_instance.stubs(:preserve_paths).returns([])
          consumer.any_instance.stubs(:dependencies).returns([])
          consumer.any_instance.stubs(:vendored_libraries).returns([])
          consumer.any_instance.stubs(:vendored_frameworks).returns([])

          results = @subject.analyze
          results.count.should.be.equal(1)
          results.first.message.should.include?('spec is empty')
          results.first.message.should.include?('File Patterns')
        end
      end

      #----------------------------------------#

      describe 'Requires ARC' do
        it 'supports the declaration of the attribute per platform' do
          results = @subject.analyze
          results.should.be.empty?
        end

        it 'supports the declaration of the attribute in the parent' do
          @spec = Spec.new do |s|
            s.subspec 'SubSpec' do |_sp|
            end
          end
          consumer = @spec.consumer(:ios)
          results = Specification::Linter::Results.new
          @subject = Specification::Linter::Analyzer.new(consumer, results)
          results = @subject.analyze
          results.should.be.empty?
        end
      end
    end
  end
end
