require File.expand_path('../../../spec_helper', __FILE__)
module Pod
  describe Specification::Linter::Results::Result do
    before do
      @result =
          Specification::Linter::Results::Result.new(:error,
                                                     'test_attribute',
                                                     'This is an error')
    end

    it 'returns the type' do
      expect(@result.type).to eq(:error)
    end

    it 'returns the attribute name' do
      expect(@result.attribute_name).to eq('test_attribute')
    end

    it 'returns the message' do
      expect(@result.message).to eq('This is an error')
    end

    it 'can store the platforms that generated the result' do
      @result.platforms << :ios
      expect(@result.platforms).to eq([:ios])
    end

    it 'returns a string representation suitable for UI' do
      expect(@result.to_s).to eq('[ERROR] [test_attribute] This is an error')
      @result.platforms << :ios
      expect(@result.to_s).to eq('[ERROR] [test_attribute] This is an error [iOS]')
    end
  end

  describe Specification::Linter::Results do
    before do
      @results = Specification::Linter::Results.new
    end

    it 'creates an error result' do
      @results.add_error('attribute', 'This is an error')
      expect(@results.count).to eq(1)
      expect(@results.first.type).to eq(:error)
    end

    it 'creates a warning result' do
      @results.add_warning('attribute', 'This is a warning')
      expect(@results.count).to eq(1)
      expect(@results.first.type).to eq(:warning)
    end

    it 'prevents duplicate results with the same attribute' do
      @results.add_warning('attribute', 'I have duplicate warnings')
      @results.add_warning('attribute', 'I have duplicate warnings')
      expect(@results.count).to eq(1)
    end

    it 'does not prevent duplicate results with different attributes' do
      @results.add_warning('attribute1', 'I have duplicate warnings')
      @results.add_warning('attribute2', 'I have duplicate warnings')
      expect(@results.count).to eq(2)
    end

    it 'specifies the platform on the result when there is a consumer' do
      fixture_path = 'spec-repos/test_repo/Specs/BananaLib/1.0/BananaLib.podspec'
      podspec_path = fixture(fixture_path)
      linter = Specification::Linter.new(podspec_path)
      @results.consumer = Specification::Consumer.new(linter.spec, :ios)
      @results.add_warning('attribute', 'bad')
      expect(@results.first.platforms.first).to eq(:ios)
    end

    it 'specifies no platform when there is no consumer' do
      @results.consumer = nil
      @results.add_warning('attribute', 'bad')
      expect(@results.first.platforms).to eq([])
    end
  end
end
