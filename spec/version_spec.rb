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

    #-------------------------------------------------------------------------#

    describe "Semantic Versioning" do

      it "reports a version as semantic" do
        Version.new("1.9.0").should.be.semantic
        Version.new("1.10.0").should.be.semantic
      end

      it "leniently reports version with two segments version a semantic" do
        Version.new("1.0").should.be.semantic
      end

      it "leniently reports version with one segment version a semantic" do
        Version.new("1").should.be.semantic
      end

      it "reports a pre-release version as semantic" do
        Version.new("1.0.0-alpha").should.be.semantic
        Version.new("1.0.0-alpha.1").should.be.semantic
        Version.new("1.0.0-0.3.7").should.be.semantic
        Version.new("1.0.0-x.7.z.92").should.be.semantic
      end

      it "reports version with more than 3 segments not separated by a dash as non semantic" do
        Version.new("1.0.2.3").should.not.be.semantic
      end

      it "reports version with a dash without the X.Y.Z format as non semantic" do
        Version.new("1.0-alpha").should.not.be.semantic
      end

      it "returns the major identifier" do
        Version.new("1.9.0").major.should == 1
        Version.new("1.0.0-alpha").major.should == 1
      end

      it "returns the minor identifier" do
        Version.new("1.9.0").minor.should == 9
        Version.new("1.0.0-alpha").minor.should == 0
        Version.new("1").minor.should == 0
      end

      it "returns the patch identifier" do
        Version.new("1.9.0").patch.should == 0
        Version.new("1.0.1-alpha").patch.should == 1
        Version.new("1").patch.should == 0
      end

    end

    #-------------------------------------------------------------------------#

  end
end
