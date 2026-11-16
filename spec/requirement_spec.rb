require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe Requirement do
    describe 'In general' do
      it 'can be initialized with a string' do
        requirement = Requirement.new('<= 1.0')
        expect(requirement.to_s).to eq('<= 1.0')
      end

      it 'defaults to the equality operator on initialization' do
        requirement = Requirement.new('1.0')
        expect(requirement.to_s).to eq('= 1.0')
      end

      it 'can be initialized with an array of versions' do
        requirement = Requirement.new([Version.new('1.0'), Version.new('2.0')])
        expect(requirement.to_s).to eq('= 1.0, = 2.0')
      end

      it 'can be initialized with a pre-release version' do
        requirement = Requirement.new(Version.new('1.0-beta'))
        expect(requirement.to_s).to eq('= 1.0-beta')
      end

      it 'raises if initialized with an invalid input' do
        expect do
          Requirement.new(Version.new('1.0!beta'))
        end.to raise_error(ArgumentError)
      end

      it 'returns the default requirement' do
        expect(Requirement.default.to_s).to eq('>= 0')
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Create factory method' do
      it 'can be created with a requirement' do
        req = Requirement.new('<= 1.0')
        requirement = Requirement.create(req)
        expect(requirement).to eq(req)
      end

      it 'can be created with a version' do
        requirement = Requirement.create(Version.new('1.0'))
        expect(requirement.to_s).to eq('= 1.0')
      end

      it 'can be created with an array of versions' do
        requirement = Requirement.create([Version.new('1.0'), Version.new('2.0')])
        expect(requirement.to_s).to eq('= 1.0, = 2.0')
      end

      it 'can be created with a string' do
        requirement = Requirement.create('1.0')
        expect(requirement.to_s).to eq('= 1.0')
      end

      it 'can be created with a nil input' do
        requirement = Requirement.create(nil)
        expect(requirement.to_s).to eq('>= 0')
      end
    end

    #-------------------------------------------------------------------------#
  end
end
