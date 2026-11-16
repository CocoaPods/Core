require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Attribute = Specification::DSL::Attribute do
    describe 'In general' do
      it 'returns the name' do
        attr = Attribute.new('name', {})
        expect(attr.name).to eq('name')
      end

      it 'raises for not recognized options' do
        opts = { :unrecognized => true }
        expect { Attribute.new('name', opts) }.to raise_error(StandardError)
      end

      it 'returns a string representation suitable for UI' do
        s = 'Specification attribute `name`'
        expect(Attribute.new('name', {}).to_s).to eq(s)
      end

      it 'returns the accepted classes for the value of the attribute' do
        opts = { :types => [String], :container => Array }
        expect(Attribute.new('name', opts).supported_types).to eq([String, Array])
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Options' do
      before do
        @attr = Attribute.new('name', {})
      end

      it 'is multi platform by default' do
        expect(@attr).to be_multi_platform
      end

      it 'is not inherited by default' do
        expect(@attr).not_to be_inherited
      end

      it 'is not root only by default' do
        expect(@attr).not_to be_root_only
      end

      it 'is not required by default' do
        expect(@attr).not_to be_required
      end

      it "doesn't want a singular form by default" do
        expect(@attr).not_to be_required
      end

      it 'is not a file pattern by default' do
        expect(@attr).not_to be_file_patterns
      end

      it "doesn't specifies a container by default" do
        expect(@attr.container).to be_nil
      end

      it "doesn't specifies accepted keys for a hash container by default" do
        expect(@attr.keys).to be_nil
      end

      it "doesn't specifies a default value by default (multi platform)" do
        expect(@attr.default_value).to be_nil
      end

      it "doesn't specifies a default value by default (no multi platform)" do
        @attr = Attribute.new('name', :multi_platform => false)
        expect(@attr.default_value).to be_nil
      end

      it 'specifies `String` as the default type' do
        expect(@attr.types).to eq([String])
      end

      it 'is inherited by default if it is root only' do
        attr = Attribute.new('name', :root_only => true)
        expect(attr).to be_inherited
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Accessors support' do
      it 'returns the default value' do
        attr1 = Attribute.new(:frameworks, :multi_platform => false)
        expect(attr1.default).to be_nil
        attr2 = Attribute.new(:frameworks, :multi_platform => false, :default_value => ['Cocoa'])
        expect(attr2.default).to eq(['Cocoa'])
      end

      it 'returns the default value for a platform' do
        attr = Attribute.new(:frameworks, :default_value => ['CoreGraphics'])
        expect(attr.default(:ios)).to eq(['CoreGraphics'])
      end

      it 'allows to specify the default value per platform' do
        attr = Attribute.new(:frameworks, :ios_default => ['CoreGraphics'])
        expect(attr.default(:ios)).to eq(['CoreGraphics'])
        expect(attr.default(:osx)).to be_nil
      end

      it 'returns the name of the writer method' do
        attr = Attribute.new(:frameworks, :singularize => true)
        expect(attr.writer_name).to eq('frameworks=')
      end

      it 'returns the singular form of the writer method' do
        attr = Attribute.new(:frameworks,  :singularize => true)
        expect(attr.writer_singular_form).to eq('framework=')
      end
    end
  end
end
