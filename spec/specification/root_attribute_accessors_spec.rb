require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Specification::RootAttributesAccessors do

    before do
      @spec = Spec.new do |s|
        s.name = "Pod"
        s.version = '1.0'
        s.subspec 'Subspec' do
        end
      end
    end

    it "returns the name of the specification" do
      @spec.name.should == 'Pod'
      @spec.subspecs.first.name.should == 'Pod/Subspec'
    end

    it "returns the base name of the specification" do
      @spec.base_name.should == 'Pod'
      @spec.subspecs.first.base_name.should == 'Subspec'
    end

    it "returns the version of the specification" do
      @spec.version.should == Version.new('1.0')
    end

    it "returns the version version of the root specification for subspecs" do
      @spec.subspecs.first.version.should == Version.new('1.0')
    end

    it "returns the authors" do
      hash = { 'Darth Vader' => 'darthvader@darkside.com',
               'Wookiee' => 'wookiee@aggrrttaaggrrt.com' }
      @spec.authors = hash
      @spec.authors.should == hash
    end

    it "supports the author attribute specified as an array" do
      @spec.authors = 'Darth Vader', 'Wookiee'
      @spec.authors.should == { 'Darth Vader' => nil, 'Wookiee' => nil }
    end

    it "supports the author attribute specified as a string" do
      @spec.authors = 'Darth Vader'
      @spec.authors.should == { 'Darth Vader' => nil }
    end

    it "supports the author attribute specified as an array of strings and hashes" do
      @spec.authors = [ 'Darth Vader',
                        { 'Wookiee' => 'wookiee@aggrrttaaggrrt.com' } ]
      @spec.authors.should == {
        'Darth Vader' => nil,
        'Wookiee' => 'wookiee@aggrrttaaggrrt.com'
      }
    end

    it "supports the license attribute specified as a string" do
      @spec.license = 'MIT'
      @spec.license.should == { :type => 'MIT' }
    end

    it "supports the license attribute specified as a hash" do
      @spec.license = { "type" => 'MIT', "file" => 'MIT-LICENSE' }
      @spec.license.should == { :type => 'MIT', :file => 'MIT-LICENSE' }
    end

    it "strips indenetation from the license text" do
      text = <<-DOC
        Line1
        Line2
      DOC
      @spec.license = { "type" => 'MIT', "text" => text }
      @spec.license[:text].should == "Line1\nLine2\n"
    end

    it "returns the homepage" do
      @spec.homepage = 'www.example.com'
      @spec.homepage.should == 'www.example.com'
    end

    it "returns the source" do
      @spec.source = { :git => 'www.example.com/repo.git' }
      @spec.source.should == { :git => 'www.example.com/repo.git' }
    end

    it "returns the summary" do
      @spec.summary = 'A library that describes the meaning of life.'
      @spec.summary.should == 'A library that describes the meaning of life.'
    end

    it "returns the descriptions stripping indentation" do
      desc = <<-DESC
        Line1
        Line2
      DESC
      @spec.description = desc
      @spec.description.should == "Line1\nLine2\n"
    end

    it "returns the screenshots" do
      @spec.screenshots = ['www.example.com/img1.png', 'www.example.com/img2.png']
      @spec.screenshots.should == ['www.example.com/img1.png', 'www.example.com/img2.png']
    end

    it "support the specification of the attribute as a string" do
      @spec.screenshot = 'www.example.com/img1.png'
      @spec.screenshots.should == ['www.example.com/img1.png']
    end

    it "returns any setting to pass to the appledoc tool" do
      settings =  { :appledoc => ['--no-repeat-first-par', '--no-warn-invalid-crossref'] }
      @spec.documentation = settings
      @spec.documentation.should == settings
    end
  end
end
