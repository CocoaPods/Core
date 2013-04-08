require File.expand_path('../spec_helper', __FILE__)

module Pod

  class Sample
    extend SpecHelper::Fixture

    def self.yaml
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
          :podspec: path/JSONKit.podspec

      SPEC CHECKSUMS:
        BananaLib: 439d9f683377ecf4a27de43e8cf3bce6be4df97b
        JSONKit: 92ae5f71b77c8dec0cd8d0744adab79d38560949

      COCOAPODS: #{CORE_VERSION}
      LOCKFILE
    end

    def self.podfile
      Podfile.new do
        platform :ios
        pod 'BananaLib', '~>1.0'
        pod 'JSONKit', :podspec => 'path/JSONKit.podspec'
      end
    end

    def self.specs
      repo_path      = 'spec-repos/test_repo/'
      bananalib_path = repo_path + 'Specs/BananaLib/1.0/BananaLib.podspec'
      jsonkit_path   = repo_path + 'Specs/JSONKit/1.4/JSONKit.podspec'

      specs = [
        Specification.from_file(fixture(bananalib_path)),
        Specification.from_file(fixture(jsonkit_path)),
        Specification.new do |s|
          s.name = "monkey"
          s.version = "1.0.8"
        end
      ]
      specs
    end
  end

  #---------------------------------------------------------------------------#

  describe Lockfile do
    describe "In general" do
      extend SpecHelper::TemporaryDirectory

      before do
        @tmp_path = temporary_directory + 'Podfile.lock'
      end

      it "stores the initialization hash" do
        lockfile = Lockfile.new(YAML.load(Sample.yaml))
        lockfile.internal_data.should == YAML.load(Sample.yaml)
      end

      it "loads from a file" do
        File.open(@tmp_path, 'w') {|f| f.write(Sample.yaml) }
        lockfile = Lockfile.from_file(@tmp_path)
        lockfile.internal_data.should == YAML.load(Sample.yaml)
      end

      it "returns nil if it can't find the initialization file" do
        lockfile = Lockfile.from_file(temporary_directory + 'Podfile.lock_not_existing')
        lockfile.should == nil
      end

      it "returns the file in which is defined" do
        File.open(@tmp_path, 'w') {|f| f.write(Sample.yaml) }
        lockfile = Lockfile.from_file(@tmp_path)
        lockfile.defined_in_file.should == @tmp_path
      end

      it "raises if the provided YAML doesn't returns a hash" do
        File.open(@tmp_path, 'w') {|f| f.write("value") }
        should.raise Informative do
          Lockfile.from_file(@tmp_path)
        end.message.should.match /Invalid Lockfile/
      end

      #--------------------------------------#

      before do
        @lockfile = Lockfile.generate(Sample.podfile, Sample.specs)
      end

      it "returns whether it is equal to another" do
        podfile = Podfile.new do
          platform :ios
          pod 'BananaLib', '~>1.0'
        end
        @lockfile.should == @lockfile
        @lockfile.should.not == Lockfile.generate(podfile, Sample.specs)
      end

      it "returns the list of the names of the  installed pods" do
        @lockfile.pod_names.should == %w| BananaLib JSONKit monkey |
      end

      it "returns the versions of a given pod" do
        @lockfile.version("BananaLib").should == Version.new("1.0")
        @lockfile.version("JSONKit").should == Version.new("1.4")
        @lockfile.version("monkey").should == Version.new("1.0.8")
      end

      it "returns the versions of a given pod handling the case in which the root spec was not stored" do
        @lockfile.stubs(:pod_versions).returns({"BananaLib/Subspec"=>Version.new(1.0)})
        @lockfile.version("BananaLib").should == Version.new("1.0")
      end

      it "returns the checksum for the given Pod" do
        @lockfile.checksum('BananaLib').should == '439d9f683377ecf4a27de43e8cf3bce6be4df97b'
      end

      it "returns the dependencies used for the last installation" do
        json_dep = Dependency.new('JSONKit')
        json_dep.external_source = { :podspec => 'path/JSONKit.podspec' }
        @lockfile.dependencies.should == [
          Dependency.new('BananaLib', '~>1.0'),
          json_dep
        ]
      end

      it "includes the external source information in the generated dependencies" do
        dep = @lockfile.dependencies.find { |d| d.name == 'JSONKit' }
        dep.external_source.should == { :podspec => 'path/JSONKit.podspec' }
      end

      it "returns the dependency that locks the pod with the given name to the installed version" do
        json_dep = Dependency.new('JSONKit', '1.4')
        json_dep.external_source = { :podspec => 'path/JSONKit.podspec' }
        @lockfile.dependency_to_lock_pod_named('JSONKit').should == json_dep
      end

      it "raises if there is a request for a locking dependency for a not stored Pod" do
        should.raise StandardError do
          @lockfile.dependency_to_lock_pod_named('Missing')
        end.message.should.match /without an known dependency/
      end
    end

    #-------------------------------------------------------------------------#

    describe "Comparison with a Podfile" do
      before do
        @podfile = Podfile.new do
          platform :ios
          pod 'BlocksKit'
          pod 'JSONKit'
        end
        @specs = [
          Specification.new do |s|
            s.name = "BlocksKit"
            s.version = "1.0.0"
          end,
          Specification.new do |s|
            s.name = "JSONKit"
            s.version = "1.4"
          end ]
        @lockfile = Lockfile.generate(@podfile, @specs)
      end

      it "detects an added Pod" do
        podfile = Podfile.new do
          platform :ios
          pod 'BlocksKit'
          pod 'JSONKit'
          pod 'TTTAttributedLabel'
        end
        @lockfile.detect_changes_with_podfile(podfile).should == {
          :changed=>[],
          :removed=>[],
          :unchanged=>["BlocksKit", "JSONKit"],
          :added=>["TTTAttributedLabel"]
        }
      end

      it "detects an removed Pod" do
        podfile = Podfile.new do
          platform :ios
          pod 'BlocksKit'
        end
        @lockfile.detect_changes_with_podfile(podfile).should == {
          :changed=>[],
          :removed=>["JSONKit"],
          :unchanged=>["BlocksKit"],
          :added=>[]
        }
      end

      it "detects Pods whose version changed" do
        podfile = Podfile.new do
          platform :ios
          pod 'BlocksKit'
          pod 'JSONKit', "> 1.4"
        end
        @lockfile.detect_changes_with_podfile(podfile).should == {
          :changed=>["JSONKit"],
          :removed=>[],
          :unchanged=>["BlocksKit"],
          :added=>[]
        }
      end

      it "it doesn't mark as changed Pods whose version changed but is still compatible with the Podfile" do
        podfile = Podfile.new do
          platform :ios
          pod 'BlocksKit'
          pod 'JSONKit', "> 1.0"
        end
        @lockfile.detect_changes_with_podfile(podfile).should == {
          :changed=>[],
          :removed=>[],
          :unchanged=>["BlocksKit", "JSONKit"],
          :added=>[]
        }
      end

      it "detects Pods whose external source changed" do
        podfile = Podfile.new do
          platform :ios
          pod 'BlocksKit'
          pod 'JSONKit', :git => "example1.com"
        end
        @lockfile.detect_changes_with_podfile(podfile).should == {
          :changed=>["JSONKit"],
          :removed=>[],
          :unchanged=>["BlocksKit"],
          :added=>[]
        }
        @lockfile = Lockfile.generate(podfile, @specs)
        podfile = Podfile.new do
          platform :ios
          pod 'BlocksKit'
          pod 'JSONKit', :git => "example2.com"
        end
        @lockfile.detect_changes_with_podfile(podfile).should == {
          :changed=>["JSONKit"],
          :removed=>[],
          :unchanged=>["BlocksKit"],
          :added=>[]
        }
      end

      it "detects Pods whose head state changed" do
        podfile = Podfile.new do
          platform :ios
          pod 'BlocksKit'
          pod 'JSONKit', :head
        end
        @lockfile.detect_changes_with_podfile(podfile).should == {
          :changed=>["JSONKit"],
          :removed=>[],
          :unchanged=>["BlocksKit"],
          :added=>[]
        }
        @specs = [
          Specification.new do |s|
            s.name = "BlocksKit"
            s.version = "1.0.0"
          end,
          Specification.new do |s|
            s.name = "JSONKit"
            s.version = "1.4"
            s.version.head = true
          end ]
        @lockfile = Lockfile.generate(podfile, @specs)
        podfile = Podfile.new do
          platform :ios
          pod 'BlocksKit'
          pod 'JSONKit'
        end

        @lockfile.detect_changes_with_podfile(podfile).should == {
          :changed=>["JSONKit"],
          :removed=>[],
          :unchanged=>["BlocksKit"],
          :added=>[]
        }
      end
    end

    #-------------------------------------------------------------------------#

    describe "Serialization" do
      before do
        @lockfile = Lockfile.generate(Sample.podfile, Sample.specs)
      end

      it "can be store itself at the given path" do
        path = SpecHelper.temporary_directory + 'Podfile.lock'
        @lockfile.write_to_disk(path)
        loaded = Lockfile.from_file(path)
        loaded.should == @lockfile
      end

      it "generates a hash representation" do
        hash = @lockfile.to_hash
        hash.delete("COCOAPODS")
        hash.should == {
          "PODS"=> [
            {"BananaLib (1.0)" => ["monkey (< 1.0.9, ~> 1.0.1)"]},
            "JSONKit (1.4)", "monkey (1.0.8)"],
          "DEPENDENCIES"=>["BananaLib (~> 1.0)", "JSONKit (from `path/JSONKit.podspec`)"],
          "EXTERNAL SOURCES"=>{"JSONKit"=>{:podspec=>"path/JSONKit.podspec"}},
          "SPEC CHECKSUMS"=>{"BananaLib"=>"439d9f683377ecf4a27de43e8cf3bce6be4df97b", "JSONKit"=>"92ae5f71b77c8dec0cd8d0744adab79d38560949"},
          }
      end

      it "generates an ordered YAML representation" do
        @lockfile.to_yaml.should == Sample.yaml
      end

      it "generates a valid YAML representation" do
        YAML.load(@lockfile.to_yaml).should == YAML.load(Sample.yaml)
      end

      it "serializes correctly `:head' dependencies" do
        podfile = Podfile.new do
          platform :ios
          pod 'BananaLib', :head
        end
        specs = [
          Specification.new do |s|
            s.name = "BananaLib"
            s.version = "1.0"
          end,
          Specification.new do |s|
            s.name = "monkey"
            s.version = "1.0.8"
          end
        ]
        lockfile = Lockfile.generate(podfile, specs)
        lockfile.internal_data["DEPENDENCIES"][0].should == "BananaLib (HEAD)"
      end

      it "serializes correctly external dependencies" do
        podfile = Podfile.new do
          platform :ios
          pod 'BananaLib', { :git => "www.example.com", :tag => '1.0' }
        end
        specs = [
          Specification.new do |s|
            s.name = "BananaLib"
            s.version = "1.0"
          end,
          Specification.new do |s|
            s.name = "monkey"
            s.version = "1.0.8"
          end
        ]
        lockfile = Lockfile.generate(podfile, specs)
        lockfile.internal_data["DEPENDENCIES"][0].should == "BananaLib (from `www.example.com`, tag `1.0`)"
        lockfile.internal_data["EXTERNAL SOURCES"]["BananaLib"].should == { :git => "www.example.com", :tag => '1.0' }
      end

    end

    #-------------------------------------------------------------------------#

    describe "Generation from a Podfile" do
      before do
        @lockfile = Lockfile.generate(Sample.podfile, Sample.specs)
      end

      it "stores the information of the installed pods and of their dependencies" do
        @lockfile.internal_data['PODS'].should == [
          {"BananaLib (1.0)"=>["monkey (< 1.0.9, ~> 1.0.1)"]},
          "JSONKit (1.4)",
          "monkey (1.0.8)"
        ]
      end

      it "stores the information of the dependencies of the Podfile" do
        @lockfile.internal_data['DEPENDENCIES'].should == [
          "BananaLib (~> 1.0)", "JSONKit (from `path/JSONKit.podspec`)"
        ]
      end

      it "stores the information of the external sources" do
        @lockfile.internal_data['EXTERNAL SOURCES'].should == {
          "JSONKit"=>{:podspec=>"path/JSONKit.podspec"}
        }
      end

      it "stores the checksum of the specifications" do
        @lockfile.internal_data['SPEC CHECKSUMS'].should == {
          "BananaLib"=>"439d9f683377ecf4a27de43e8cf3bce6be4df97b",
          "JSONKit"=>"92ae5f71b77c8dec0cd8d0744adab79d38560949"
        }
      end

      it "store the version of the CocoaPods Core gem" do
        @lockfile.internal_data['COCOAPODS'].should == CORE_VERSION
      end

      it "it includes all the information that it is expected to store" do
        @lockfile.internal_data.should == YAML.load(Sample.yaml)
      end
    end

    #-------------------------------------------------------------------------#

    describe "Private helpers" do

      describe "#generate_pods_data" do
        it "groups multiple dependencies for the same pod" do
        specs = [
          Specification.new do |s|
            s.name = "BananaLib"
            s.version = "1.0"
            s.dependency 'monkey', '< 1.0.9'
          end,
          Specification.new do |s|
            s.name = "BananaLib"
            s.version = "1.0"
            s.dependency 'tree', '~> 1.0.1'
          end
        ]
          pods_data = Lockfile.send(:generate_pods_data, specs)
          pods_data.should == [{
            "BananaLib (1.0)" => ["monkey (< 1.0.9)", "tree (~> 1.0.1)"]
          }]
        end
      end

    end
  end
end
