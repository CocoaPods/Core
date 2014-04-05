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

def yaml_with_merge_conflict
  text = <<-LOCKFILE.strip_heredoc
    PODS:
      - Kiwi (2.2)
      - ObjectiveSugar (1.1.1)

    DEPENDENCIES:
      - Kiwi
      - ObjectiveSugar (from `../`)

    EXTERNAL SOURCES:
      ObjectiveSugar:
        :path: ../

    SPEC CHECKSUMS:
    <<<<<<< HEAD
      Kiwi: 05f988748c5136c6daed8dab3563eca929399a72
      ObjectiveSugar: 7377622e35ec89ce893b05dd0af4bede211b01a4
    =======
      Kiwi: db174bba4ee8068b15d7122f1b22fb64b7c1d378
      ObjectiveSugar: 27c680bb74f0b0415e9e743d5d61d77bc3292d3f
    >>>>>>> b65623cbf5e105acbc3e2dec48f8024fa82003ce

    COCOAPODS: 0.29.0
  LOCKFILE
end

def bad_yaml
  text = <<-LOCKFILE.strip_heredoc
    PODS:
      - Kiwi (2.2)
      SOME BAD TEXT
      
    DEPENDENCIES:
      - Kiwi
      - ObjectiveSugar (from `../`)
      
    COCOAPODS: 0.29.0
  LOCKFILE
end

#-----------------------------------------------------------------------------#

module Pod
  describe 'In general' do

    describe YAMLHelper do

      it 'converts a string' do
        value = 'Value'
        result = YAMLHelper.convert(value)
        result.should == "Value\n"
      end

      it 'converts a symbol' do
        value = :value
        result = YAMLHelper.convert(value)
        result.should == ":value\n"
      end

      it 'converts the true class' do
        result = YAMLHelper.convert(true)
        result.should == "true\n"
      end

      it 'converts the false class' do
        result = YAMLHelper.convert(false)
        result.should == "false\n"
      end

      it 'converts an array' do
        value = %w(Value_1 Value_2)
        result = YAMLHelper.convert(value)
        result.should == "- Value_1\n- Value_2\n"
      end

      it 'converts an hash' do
        value = { 'Key' => 'Value' }
        result = YAMLHelper.convert(value)
        result.should == "Key: Value\n"
      end

      it 'converts an hash which contains and array as one of the values' do
        value = { 'Key' => %w(Value_1 Value_2) }
        result = YAMLHelper.convert(value)
        result.should == <<-EOT.strip_heredoc
        Key:
          - Value_1
          - Value_2
        EOT
      end

      it 'converts an hash which contains and array as one of the values' do
        value = { 'Key' => { 'Subkey' => %w(Value_1 Value_2) } }
        result = YAMLHelper.convert(value)
        result.should == <<-EOT.strip_heredoc
        Key:
          Subkey:
            - Value_1
            - Value_2
        EOT
      end

      it "raises if it can't handle the class of the given object" do
        value = Pathname.new('a-path')
        should.raise StandardError do
          YAMLHelper.convert(value)
        end.message.should.match /Unsupported class/
      end      
    end
    
    #-------------------------------------------------------------------------#
    
    describe 'Loading' do
      it "raises an Informative error when it encounters a merge conflict" do
        should.raise Informative do
          YAMLHelper.load(yaml_with_merge_conflict)
        end.message.should.match /Merge conflict\(s\) detected/
      end
      
      it "raises another error when it encounters an error that is not a merge conflict" do
        should.raise Exception do
          YAMLHelper.load(bad_yaml)
        end
      end

      it "should not raise when there is no merge conflict" do
        should.not.raise do
          YAMLHelper.load(sample_yaml)
        end
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Private Helpers' do

      describe '#sorted_array_with_hint' do
        it 'sorts an array according to its string representation' do
          values = %w(JSONKit BananaLib)
          result = YAMLHelper.send(:sorted_array, values)
          result.should == %w(BananaLib JSONKit)
        end

        it 'sorts an array containing strings and hashes according to its string representation' do
          values = ['JSONKit', 'BananaLib', { 'c_hash_key' => 'a_value' }]
          result = YAMLHelper.send(:sorted_array, values)
          result.should == ['BananaLib', { 'c_hash_key' => 'a_value' }, 'JSONKit']
        end

        it 'sorts an array with a given hint' do
          values = %w(non-hinted second first)
          hint = %w(first second hinted-missing)
          result = YAMLHelper.send(:sorted_array_with_hint, values, hint)
          result.should == %w(first second non-hinted)
        end

        it 'sorts an array with a given nil hint' do
          values = %w(JSONKit BananaLib)
          hint = nil
          result = YAMLHelper.send(:sorted_array_with_hint, values, hint)
          result.should == %w(BananaLib JSONKit)
        end
      end

      describe '#sorting_string' do

        it 'returns the empty string if a nil value is passed' do
          value = nil
          result = YAMLHelper.send(:sorting_string, value)
          result.should == ''
        end

        it 'sorts strings ignoring case' do
          value = 'String'
          result = YAMLHelper.send(:sorting_string, value)
          result.should == 'string'
        end

        it 'sorts symbols ignoring case' do
          value = :Symbol
          result = YAMLHelper.send(:sorting_string, value)
          result.should == 'symbol'
        end

        it 'sorts arrays using the first element ignoring case' do
          value = %w(String_2 String_1)
          result = YAMLHelper.send(:sorting_string, value)
          result.should == 'string_2'
        end

        it 'sorts a hash using first key in alphabetical order' do
          value = {
            :key_2 => 'a_value',
            :key_1 => 'a_value',
          }
          result = YAMLHelper.send(:sorting_string, value)
          result.should == 'key_1'
        end
      end
    end

    #-------------------------------------------------------------------------#

    describe 'Lockfile generation' do

      it 'converts a complex file' do
        value = YAMLHelper.load(sample_yaml)
        sorted_keys = ['PODS', 'DEPENDENCIES', 'EXTERNAL SOURCES', 'SPEC CHECKSUMS', 'COCOAPODS']
        result = YAMLHelper.convert_hash(value, sorted_keys, "\n\n")
        YAMLHelper.load(result).should == value
        result.should == sample_yaml
      end
    end

    #-------------------------------------------------------------------------#

  end
end
