require File.expand_path('../../../spec_helper', __FILE__)
module Pod
  describe Specification::Linter::Result do
    before do
      @result = Specification::Linter::Result.new(:error, 'This is a sample error.')
    end

    it 'returns the type' do
      @result.type.should == :error
    end

    it 'returns the message' do
      @result.message.should == 'This is a sample error.'
    end

    it 'can store the platforms that generated the result' do
      @result.platforms << :ios
      @result.platforms.should == [:ios]
    end

    it 'returns a string representation suitable for UI' do
      @result.to_s.should == '[ERROR] This is a sample error.'
      @result.platforms << :ios
      @result.to_s.should == '[ERROR] This is a sample error. [iOS]'
    end
  end
end
