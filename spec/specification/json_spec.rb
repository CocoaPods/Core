require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Specification::JSONSupport do

    describe "JSON support" do
      it "returns the json representation" do
        sut = Specification.new(nil, "BananaLib")
        sut.version = "1.0"
        expected = <<-DOC.strip_heredoc
        {
          "name": "BananaLib",
          "version": "1.0"
        }
        DOC
        sut.to_json.should == expected.chomp
      end

      it "allows to specify multi-platform attributes" do
        json = <<-DOC.strip_heredoc
        {
          "name": "BananaLib",
          "ios": {
            "source_files": "Files"
          }
        }
        DOC
        spec = Specification.from_json(json)
        consumer = Specification::Consumer.new(spec, :ios)
        consumer.source_files.should == ["Files"]
      end
    end

    #-------------------------------------------------------------------------#

    describe "Hash conversion" do
      before do
        path = fixture('BananaLib.podspec')
        @sut = Spec.from_file(path)
      end

      it "can be converted to a hash" do
        hash = @sut.to_hash
        hash["name"].should == "BananaLib"
        hash["version"].should == "1.0"
      end

      it "handles subspecs when converted to a hash" do
        hash = @sut.to_hash
        hash["subspecs"].should == [{
          "name" => "GreenBanana",
          "source_files" => "GreenBanana"
        }]
      end

      it "can be loaded from an hash" do
        hash = {
          "name" => "BananaLib",
          "version" => "1.0"
        }
        result = Specification.from_hash(hash)
        result.name.should == "BananaLib"
        result.version.to_s.should == "1.0"
      end

      it "can be safely converted back and forth to a hash" do
        result = Specification.from_hash(@sut.to_hash)
        result.should == @sut
      end

      it "returns whether it safe to convert a specification to hash" do
        @sut.safe_to_hash?.should.be.true
      end

      it "returns that it is not safe to convert a specification to a hash if there is hook defined" do
        @sut.pre_install do; end
        @sut.safe_to_hash?.should.be.false
      end
    end

    #-------------------------------------------------------------------------#

  end
end
