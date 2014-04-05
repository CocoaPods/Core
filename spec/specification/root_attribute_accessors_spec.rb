require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Specification::RootAttributesAccessors do

    before do
      @spec = Spec.new do |s|
        s.name = 'Pod'
        s.version = '1.0'
        s.subspec 'Subspec' do
        end
      end
    end

    it 'returns the name of the specification' do
      @spec.name.should == 'Pod'
      @spec.subspecs.first.name.should == 'Pod/Subspec'
    end

    it 'returns the base name of the specification' do
      @spec.base_name.should == 'Pod'
      @spec.subspecs.first.base_name.should == 'Subspec'
    end

    it 'returns the version of the specification' do
      @spec.version.should == Version.new('1.0')
    end

    it 'memoizes the version to allow to set it to head' do
      @spec.version.should.equal? @spec.version
    end

    it 'returns the version version of the root specification for subspecs' do
      @spec.subspecs.first.version.should == Version.new('1.0')
    end

    it 'returns the authors' do
      hash = { 'Darth Vader' => 'darthvader@darkside.com',
               'Wookiee' => 'wookiee@aggrrttaaggrrt.com' }
      @spec.authors = hash
      @spec.authors.should == hash
    end

    it 'supports the author attribute specified as an array' do
      @spec.authors = 'Darth Vader', 'Wookiee'
      @spec.authors.should == { 'Darth Vader' => nil, 'Wookiee' => nil }
    end

    it 'supports the author attribute specified as a string' do
      @spec.authors = 'Darth Vader'
      @spec.authors.should == { 'Darth Vader' => nil }
    end

    it 'supports the author attribute specified as an array of strings and hashes' do
      @spec.authors = ['Darth Vader',
                       { 'Wookiee' => 'wookiee@aggrrttaaggrrt.com' }]
      @spec.authors.should == {
        'Darth Vader' => nil,
        'Wookiee' => 'wookiee@aggrrttaaggrrt.com'
      }
    end

    it 'returns the social media url' do
      @spec.social_media_url = 'www.example.com'
      @spec.social_media_url.should == 'www.example.com'
    end

    it 'returns the docset url' do
      @spec.docset_url = 'http://example.org/KFData/1.0.0/xcode-docset.atom'
      @spec.docset_url.should == 'http://example.org/KFData/1.0.0/xcode-docset.atom'
    end

    it 'supports the license attribute specified as a string' do
      @spec.license = 'MIT'
      @spec.license.should == { :type => 'MIT' }
    end

    it 'supports the license attribute specified as a hash' do
      @spec.license = { 'type' => 'MIT', 'file' => 'MIT-LICENSE' }
      @spec.license.should == { :type => 'MIT', :file => 'MIT-LICENSE' }
    end

    it 'strips indentation from the license text' do
      text = <<-DOC
        Line1
        Line2
      DOC
      @spec.license = { 'type' => 'MIT', 'text' => text }
      @spec.license[:text].should == "Line1\nLine2\n"
    end

    it 'returns the empty hash if not license information has been specified' do
      @spec.license.should == {}
    end

    it 'returns the homepage' do
      @spec.homepage = 'www.example.com'
      @spec.homepage.should == 'www.example.com'
    end

    it 'returns the source' do
      @spec.source = { :git => 'www.example.com/repo.git' }
      @spec.source.should == { :git => 'www.example.com/repo.git' }
    end

    it 'returns the summary' do
      @spec.summary = 'A library that describes the meaning of life.'
      @spec.summary.should == 'A library that describes the meaning of life.'
    end

    it 'returns the descriptions stripping indentation' do
      desc = <<-DESC
        Line1
        Line2
      DESC
      @spec.description = desc
      @spec.description.should == "Line1\nLine2"
    end

    it 'returns the screenshots' do
      @spec.screenshots = ['www.example.com/img1.png', 'www.example.com/img2.png']
      @spec.screenshots.should == ['www.example.com/img1.png', 'www.example.com/img2.png']
    end

    it 'support the specification of the attribute as a string' do
      @spec.screenshot = 'www.example.com/img1.png'
      @spec.screenshots.should == ['www.example.com/img1.png']
    end

    it 'returns the prepare command stripping the indentation' do
      command = <<-DESC
        ruby prepare_script.rb
      DESC
      @spec.prepare_command = command
      @spec.prepare_command.should == 'ruby prepare_script.rb'
    end

    it 'returns whether the Pod has been deprecated' do
      @spec.deprecated = true
      @spec.deprecated.should == true
    end

    it 'returns the name of the Pod that this one has been deprecated in favor of' do
      @spec.deprecated_in_favor_of = 'NewMoreAwesomePod'
      @spec.deprecated_in_favor_of.should == 'NewMoreAwesomePod'
    end

  end
end
