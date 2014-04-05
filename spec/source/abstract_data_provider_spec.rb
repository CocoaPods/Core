require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Source::AbstractDataProvider do

    before do
      @sut = Source::AbstractDataProvider.new
    end

    #-------------------------------------------------------------------------#

    describe 'Optional methods' do
      it 'raises for the #name method' do
        should.raise StandardError do
          @sut.name
        end.message.should.match /Abstract method/
      end

      it 'raises for the #type method' do
        should.raise StandardError do
          @sut.type
        end.message.should.match /Abstract method/
      end

      it 'raises for the #pods method' do
        should.raise StandardError do
          @sut.pods
        end.message.should.match /Abstract method/
      end

      it 'raises for the #versions method' do
        should.raise StandardError do
          @sut.versions('Pod')
        end.message.should.match /Abstract method/
      end

      it 'raises for the #specification method' do
        should.raise StandardError do
          @sut.specification('Pod', '0.1.0')
        end.message.should.match /Abstract method/
      end

      it 'raises for the #specification_contents method' do
        should.raise StandardError do
          @sut.specification_contents('Pod', '0.1.0')
        end.message.should.match /Abstract method/
      end
    end

    #-------------------------------------------------------------------------#

  end
end
