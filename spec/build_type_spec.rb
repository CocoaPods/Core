require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe BuildType do
    describe '#initialize' do
      it 'returns static library by default' do
        expect(BuildType.new).to eq(BuildType.static_library)
      end

      it 'allows specifying linkage' do
        expect(BuildType.new(:linkage => :dynamic)).to eq(BuildType.dynamic_library)
      end

      it 'allows specifying packaging' do
        expect(BuildType.new(:packaging => :framework)).to eq(BuildType.static_framework)
      end

      it 'raises when given an unknown linkage' do
        expect { BuildType.new(:linkage => :foo) }.to raise_error(ArgumentError, a_string_including('Invalid linkage option :foo, valid options are [:static, :dynamic]'))
      end
    end

    describe 'convenience factory methods' do
      it '#dynamic_library' do
        expect(BuildType.dynamic_library).to eq(BuildType.new(:linkage => :dynamic, :packaging => :library))
      end

      it '#static_library' do
        expect(BuildType.static_library).to eq(BuildType.new(:linkage => :static, :packaging => :library))
      end

      it '#dynamic_framework' do
        expect(BuildType.dynamic_framework).to eq(BuildType.new(:linkage => :dynamic, :packaging => :framework))
      end

      it '#static_framework' do
        expect(BuildType.static_framework).to eq(BuildType.new(:linkage => :static, :packaging => :framework))
      end
    end

    describe '#==' do
      it 'compares equal build types as equal' do
        expect(BuildType.new(:linkage => :dynamic, :packaging => :library)).to eq(BuildType.new(:linkage => :dynamic, :packaging => :library))
      end

      it 'compares unequal build types as unequal' do
        expect(BuildType.new(:linkage => :dynamic, :packaging => :framework)).not_to eq(BuildType.new(:linkage => :dynamic, :packaging => :library))
        expect(BuildType.new(:linkage => :static, :packaging => :library)).not_to eq(BuildType.new(:linkage => :dynamic, :packaging => :library))
      end
    end

    describe '#to_s' do
      it 'returns a readable representation' do
        expect(BuildType.static_framework.to_s).to eq('static framework')
      end
    end
  end
end
