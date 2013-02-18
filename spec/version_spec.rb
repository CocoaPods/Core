require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe Version do
    describe "In general" do

      it "returns whether it is a `head` version" do
        version = Version.new('1.2.3')
        version.should.not.be.head
        version.head = true
        version.should.be.head
      end

      it "initializes from a string" do
        version = Version.new('1.2.3')
        version.should.not.be.head
      end

      it "initializes from a string containing head information" do
        version = Version.new('HEAD based on 1.2.3')
        version.should.be.head
      end

      it "initializes from another version containing head information" do
        head_version = Version.new('HEAD based on 1.2.3')
        version = Version.new(head_version)
        version.should.be.head
      end

      it "serializes to a string" do
        version = Version.new('1.2.3')
        version.to_s.should == '1.2.3'
      end

      it "preserves head information when serializing to a string" do
        version = Version.new('1.2.3')
        version.head = true
        version.to_s.should == 'HEAD based on 1.2.3'
      end

      it "supports the previous way that a HEAD version was described" do
        version = Version.new('HEAD from 1.2.3')
        version.should.be.head
        version.to_s.should == 'HEAD based on 1.2.3'
      end
      
      it "identifies release versions" do
        version = Version.new('1.0.0')
        version.should.not.be.prerelease
      end
    
      it "matches Semantic Version pre-release versions" do
        version = Version.new('1.0.0a1')
        version.should.be.prerelease
        version = Version.new('1.0.0-alpha')
        version.should.be.prerelease
        version = Version.new('1.0.0-alpha.1')
        version.should.be.prerelease
        version = Version.new('1.0.0-0.3.7')
        version.should.be.prerelease
        version = Version.new('1.0.0-x.7.z.92')
        version.should.be.prerelease
      end
    end
  end
end
