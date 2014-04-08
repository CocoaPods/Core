require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Source::FileSystemDataProvider do

    before do
      path = fixture('spec-repos/test_repo')
      @subject = Source::FileSystemDataProvider.new(path)
    end

    #-------------------------------------------------------------------------#

    describe 'In general' do
      it 'returns its name' do
        @subject.name.should == 'test_repo'
      end
    end

    #-------------------------------------------------------------------------#

    describe '#pods' do
      it 'returns the available Pods' do
        @subject.pods.should == %w(BananaLib Faulty_spec IncorrectPath JSONKit JSONSpec)
      end

      it 'returns nil if no Pods could be found' do
        path = fixture('spec-repos/non_existing')
        @subject = Source::FileSystemDataProvider.new(path)
        @subject.pods.should.be.nil
      end

      it "doesn't include the `.` and the `..` dir entries" do
        @subject.pods.should.not.include?('.')
        @subject.pods.should.not.include?('..')
      end

      it 'only consider directories' do
        File.stubs(:directory?).returns(false)
        @subject.pods.should == []
      end

      it 'uses the `Specs` dir if it is present' do
        @subject.send(:specs_dir).to_s.should.end_with('test_repo/Specs')
      end

      it 'uses the root of the repo as the specs dir if the `Specs` folder is not present' do
        repo = fixture('spec-repos/master')
        @subject = Source::FileSystemDataProvider.new(repo)
        @subject.send(:specs_dir).to_s.should.end_with('master')
      end
    end

    #-------------------------------------------------------------------------#

    describe '#versions' do
      it 'returns the versions for the given Pod' do
        @subject.versions('JSONKit').should == ['999.999.999', '1.4']
      end

      it 'returns nil the Pod is unknown' do
        @subject.versions('Unknown_Pod').should.be.nil
      end

      it 'raises if the name of the Pod is not provided' do
        should.raise ArgumentError do
          @subject.versions(nil)
        end.message.should.match /No name/
      end
    end

    #-------------------------------------------------------------------------#

    describe '#specification' do
      it 'returns the specification for the given version of a Pod' do
        spec = @subject.specification('JSONKit', '1.4')
        spec.name.should == 'JSONKit'
        spec.version.to_s.should == '1.4'
      end

      it 'returns nil if the Pod is unknown' do
        spec = @subject.specification('Unknown_Pod', '1.4')
        spec.should.be.nil
      end

      it "returns nil if the version of the Pod doesn't exists" do
        spec = @subject.specification('JSONKit', '0.99.0')
        spec.should.be.nil
      end

      it 'raises if the name of the Pod is not provided' do
        should.raise ArgumentError do
          @subject.specification(nil, '1.4')
        end.message.should.match /No name/
      end

      it 'raises if the name of the Pod is not provided' do
        should.raise ArgumentError do
          @subject.specification('JSONKit', nil)
        end.message.should.match /No version/
      end
    end

    #-------------------------------------------------------------------------#

    describe '#specification_path' do
      it 'returns the path of a specification' do
        path = @subject.specification_path('JSONKit', '1.4')
        path.to_s.should.end_with?('test_repo/Specs/JSONKit/1.4/JSONKit.podspec')
      end

      it 'prefers JSON podspecs if one exists' do
        Pathname.any_instance.stubs(:exist?).returns(true)
        path = @subject.specification_path('JSONSpec', '0.9')
        path.to_s.should.end_with?('Specs/JSONSpec/0.9/JSONSpec.podspec.json')
      end

      it 'raises if the name of the Pod is not provided' do
        should.raise ArgumentError do
          @subject.specification_path(nil, '1.4')
        end.message.should.match /No name/
      end

      it 'raises if the name of the Pod is not provided' do
        should.raise ArgumentError do
          @subject.specification_path('JSONKit', nil)
        end.message.should.match /No version/
      end
    end

    #-------------------------------------------------------------------------#

    describe '#specification_contents' do
      it 'returns the specification given the name and the version' do
        spec = @subject.specification_contents('JSONKit', '1.4')
        spec.should.match /s.name += 'JSONKit'\n +s.version += '1.4'/
      end

      it 'returns nil if the Pod is unknown' do
        spec = @subject.specification_contents('Unknown_Pod', '1.4')
        spec.should.be.nil
      end

      it "returns nil if the version of the Pod doesn't exists" do
        spec = @subject.specification_contents('JSONKit', '0.99.0')
        spec.should.be.nil
      end

      it 'raises if the name of the Pod is not provided' do
        should.raise ArgumentError do
          @subject.specification_contents(nil, '1.4')
        end.message.should.match /No name/
      end

      it 'raises if the name of the Pod is not provided' do
        should.raise ArgumentError do
          @subject.specification_contents('JSONKit', nil)
        end.message.should.match /No version/
      end
    end

    #-------------------------------------------------------------------------#

  end
end
