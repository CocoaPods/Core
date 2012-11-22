require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Specification::YAMLSupport do

    describe "In general" do
      before do
        @path = fixture('BananaLib.podspec')
        @spec = Spec.from_file(@path)
      end

      it "serializes to a hash" do
        expected = {
          'name'=>"BananaLib",
          'version'=>"1.0",
          'authors'=>{"Banana Corp"=>nil, "Monkey Boy"=>"monkey@banana-corp.local"},
          'license'=>{
            :type=>"MIT",
            :file=>"LICENSE",
            :text=>"Permission is hereby granted ..."
          },
          'homepage'=>"http://banana-corp.local/banana-lib.html",
          'source'=>{ :git=>"http://banana-corp.local/banana-lib.git", :tag=>"v1.0"},
          'summary'=>"Chunky bananas!",
          'description'=>"Full of chunky bananas.",
          'documentation'=>{
            :html=>"http://banana-corp.local/banana-lib/docs.html",
            :appledoc=>["--project-company", "Banana Corp", "--company-id", "com.banana"]
          },
          'xcconfig'=>{
            :osx=>{"OTHER_LDFLAGS"=>"-framework SystemConfiguration"},
            :ios=>{"OTHER_LDFLAGS"=>"-framework SystemConfiguration"}},
          'prefix_header_file'=>{
              :osx=>"Classes/BananaLib.pch",
              :ios=>"Classes/BananaLib.pch"},
          'source_files'=>{
            :osx=>["Classes/*.{h,m}", "Vendor"],
            :ios=>["Classes/*.{h,m}", "Vendor"]
          },
          'resources'=>{
            :osx=>{:resources=>["Resources/*.png"]},
            :ios=>{:resources=>["Resources/*.png"]}
          },
          'dependencies' => {
            :osx=>["monkey (< 1.0.9, ~> 1.0.1)"],
            :ios=>["monkey (< 1.0.9, ~> 1.0.1)"]
          },
        }

        computed = @spec.to_hash
        (computed.keys - expected.keys).should == []
        (expected.keys - computed.keys).should == []
        (computed.values - expected.values).should == []
        (expected.values - computed.values).should == []
        computed.should == expected
      end

      it "stores subspecs" do
        spec = Spec.new do |s|
          s.name = 'level_0'
          s.subspec 'level_1' do |sp|
            sp.source_files = 'level_1'
            sp.ios.source_files = 'level_1_ios'
            sp.subspec 'level_2' do |ssp|
              ssp.platform = :ios, '6.0'
              ssp.source_files = 'level_2'
            end
          end
        end
        expected = {
          "name" => "level_0",
          "subspecs" => [
            {
              "name" => "level_1",
              "source_files" => { :ios => ["level_1", "level_1_ios"], :osx => ["level_1"] },
              "subspecs" => [
                {
                  "name"=>"level_2",
                  "platform"=>[:ios, "6.0"],
                  "source_files"=>{ :ios=>["level_2"], :osx=>["level_2" ]}
                }
              ]
            }
          ]
        }

        computed = spec.to_hash
        (computed.keys - expected.keys).should == []
        (expected.keys - computed.keys).should == []
        (computed.values - expected.values).should == []
        (expected.values - computed.values).should == []
        computed.should == expected
      end

      it "returns the yaml reppresentation" do
        yaml = @spec.to_yaml
        yaml.should.include('BananaLib')
        yaml.should.include('1.0')
        yaml.should.include('Banana Corp')
      end
    end
  end
end
