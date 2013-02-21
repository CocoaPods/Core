require File.expand_path('../spec_helper', __FILE__)

def sample_yaml
  text = <<-LOCKFILE.strip_heredoc
      PODS:
        - BananaLib (1.0):
          - monkey (< 1.0.9, ~> 1.0.1)
        - JSONKit (1.4)
        - monkey (1.0.8)

      DEPENDENCIES:
        - BananaLib (~> 1.0)
        - JSONKit (from `path/JSONKit.podspec`)

      EXTERNAL SOURCES:
        JSONKit:
          podspec: path/JSONKit.podspec

      SPEC CHECKSUMS:
        BananaLib: 439d9f683377ecf4a27de43e8cf3bce6be4df97b
        JSONKit: 92ae5f71b77c8dec0cd8d0744adab79d38560949

      COCOAPODS: 1.0.0
  LOCKFILE
end


#-----------------------------------------------------------------------------#

module Pod
  describe "In general" do

    describe YAMLConverter do

      it "converts a string" do
        value = "Value"
        result = YAMLConverter.convert(value)
        result.should == "Value\n"
      end

      it "converts a symbol" do
        value = :value
        result = YAMLConverter.convert(value)
        result.should == ":value\n"
      end

      it "converts the true class" do
        result = YAMLConverter.convert(true)
        result.should == "true\n"
      end

      it "converts the false class" do
        result = YAMLConverter.convert(false)
        result.should == "false\n"
      end

      it "converts an array" do
        value = ["Value_1", "Value_2"]
        result = YAMLConverter.convert(value)
        result.should == "- Value_1\n- Value_2\n"
      end

      it "converts an hash" do
        value = {"Key" => "Value"}
        result = YAMLConverter.convert(value)
        result.should == "Key: Value\n"
      end

      it "converts an hash which contains and array as one of the values" do
        value = {"Key" => ["Value_1", "Value_2"] }
        result = YAMLConverter.convert(value)
        result.should == <<-EOT.strip_heredoc
        Key:
          - Value_1
          - Value_2
        EOT
      end

      it "converts an hash which contains and array as one of the values" do
        value = {"Key" => {"Subkey" => ["Value_1", "Value_2"] } }
        result = YAMLConverter.convert(value)
        result.should == <<-EOT.strip_heredoc
        Key:
          Subkey:
            - Value_1
            - Value_2
        EOT
      end
    end

    #-------------------------------------------------------------------------#

    describe "Private Helpers" do

      it "sorts an array according to its string representation" do
        values = ["JSONKit", "BananaLib"]
        result = YAMLConverter.send(:sorted_array, values)
        result.should == ["BananaLib", "JSONKit"]
      end

      it "sorts an array containing strings and hashes according to its string representation" do
        values = ["JSONKit", "BananaLib", { "c_hash_key" => "a_value" }]
        result = YAMLConverter.send(:sorted_array, values)
        result.should == ["BananaLib", {"c_hash_key"=>"a_value"}, "JSONKit"]
      end

      it "sorts an array with a given hint" do
        values = ["non-hinted", "second", "first"]
        hint = ["first", "second", "hinted-missing"]
        result = YAMLConverter.send(:sorted_array_with_hint, values, hint)
        result.should == ["first", "second", "non-hinted"]
      end

      it "sorts an array with a given nil hin" do
        values = ["JSONKit", "BananaLib"]
        hint = nil
        result = YAMLConverter.send(:sorted_array_with_hint, values, hint)
        result.should == ["BananaLib", "JSONKit"]
      end

    end

    #-------------------------------------------------------------------------#

    describe "Lockfile generation" do

      it "converts a complex file" do
        value = YAML.load(sample_yaml)
        sorted_keys = ["PODS", "DEPENDENCIES", "EXTERNAL SOURCES", "SPEC CHECKSUMS", "COCOAPODS"]
        result = YAMLConverter.convert_hash(value, sorted_keys, "\n\n")
        YAML.load(result).should == value
        result.should == sample_yaml
      end
    end

    #-------------------------------------------------------------------------#

  end
end
