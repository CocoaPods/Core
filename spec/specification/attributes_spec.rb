require File.expand_path('../../spec_helper', __FILE__)

describe Pod::Specification::Attributes do

  describe "In general" do

    before do
      class TestClass
        def self.attributes
          @attributes
        end
        @attributes = []
        extend Pod::Specification::Attributes
        attribute :name, { :type => String }
      end
      @spec = TestClass.new
    end

    xit "stores the list of the attributes" do
      TestClass.attributes.map(&:name).should == [ :name ]
    end

    xit "defines reader and setter methods for an attribute" do
      @spec.name = 'name'
      @spec.name.should == 'name'
    end
  end
end
