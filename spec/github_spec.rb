require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe GitHub do

    describe "In general" do
      it "returns the information of a user" do
        user = GitHub.user("CocoaPods")
        user['login'].should == 'CocoaPods'
      end

      it "returns the information of a repo" do
        repo = GitHub.fetch_github_repo_data("https://github.com/CocoaPods/CocoaPods")
        repo['name'].should == 'CocoaPods'
      end

      it "returns the tags of a repo" do
        tags = GitHub.tags("https://github.com/CocoaPods/CocoaPods")
        tags.find { |t| t["name"] == "0.20.2" }.should.not.be.nil
      end

      it "returns the branches of a repo" do
        branches = GitHub.branches("https://github.com/CocoaPods/CocoaPods")
        branches.find { |t| t["name"] == "master" }.should.not.be.nil
      end
    end

    #-------------------------------------------------------------------------#

    describe "Private helpers" do

      it "returns the repo id from a given github URL" do
        id = GitHub.send(:repo_id_from_url, "https://github.com/CocoaPods/CocoaPods")
        id.should == "CocoaPods/CocoaPods"
      end

    end

    #-------------------------------------------------------------------------#

  end
end
