require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Specification::RootAttributesAccessors do
    before do
      @spec = Spec.new do |s|
        s.name = 'Pod'
        s.version = '1.0'
        s.requires_arc = true
        s.subspec 'Subspec' do
        end
      end
    end

    it 'returns the name of the specification' do
      expect(@spec.name).to eq('Pod')
      expect(@spec.subspecs.first.name).to eq('Pod/Subspec')
    end

    it 'returns the base name of the specification' do
      expect(@spec.base_name).to eq('Pod')
      expect(@spec.subspecs.first.base_name).to eq('Subspec')
    end

    it 'returns the version of the specification' do
      expect(@spec.version).to eq(Version.new('1.0'))
    end

    it 'return the single swift version of the specification' do
      @spec.swift_versions = '3.2'
      expect(@spec.swift_versions.map(&:to_s)).to eq(['3.2'])
    end

    it 'return multiple swift versions of the specification' do
      @spec.swift_versions = %w(4.0 3.2 3.2)
      expect(@spec.swift_versions.map(&:to_s)).to eq(%w(3.2 4.0))
    end

    it 'return uniq and sorted swift versions of the specification' do
      @spec.swift_versions = %w(4.0 3.2 3.2)
      expect(@spec.swift_versions.map(&:to_s)).to eq(%w(3.2 4.0))
    end

    it 'return swift version of the specification' do
      @spec.swift_versions = %w(3.2 4.0)
      expect(@spec.swift_version).to eq(Version.new('4.0'))
    end

    it 'returns the cocoapods version requirement of the specification' do
      @spec.cocoapods_version = '>= 0.36'
      expect(@spec.cocoapods_version).to eq(Requirement.new('>= 0.36'))
    end

    it 'memoizes the version to allow to set it to head' do
      expect(@spec.version).to be(@spec.version)
    end

    it 'returns the version version of the root specification for subspecs' do
      expect(@spec.subspecs.first.version).to eq(Version.new('1.0'))
    end

    it 'returns the authors' do
      hash = { 'Darth Vader' => 'darthvader@darkside.com',
               'Wookiee' => 'wookiee@aggrrttaaggrrt.com' }
      @spec.authors = hash
      expect(@spec.authors).to eq(hash)
    end

    it 'supports the author attribute specified as an array' do
      @spec.authors = 'Darth Vader', 'Wookiee'
      expect(@spec.authors).to eq({ 'Darth Vader' => nil, 'Wookiee' => nil })
    end

    it 'supports the author attribute specified as a string' do
      @spec.authors = 'Darth Vader'
      expect(@spec.authors).to eq({ 'Darth Vader' => nil })
    end

    it 'supports the author attribute specified as an array of strings and hashes' do
      @spec.authors = ['Darth Vader',
                       { 'Wookiee' => 'wookiee@aggrrttaaggrrt.com' }]
      expect(@spec.authors).to eq({
        'Darth Vader' => nil,
        'Wookiee' => 'wookiee@aggrrttaaggrrt.com',
      })
    end

    it 'returns the social media url' do
      @spec.social_media_url = 'www.example.com'
      expect(@spec.social_media_url).to eq('www.example.com')
    end

    it 'returns the readme' do
      @spec.readme = 'www.example.com'
      expect(@spec.readme).to eq('www.example.com')
    end

    it 'returns the changelog' do
      @spec.changelog = 'www.example.com'
      expect(@spec.changelog).to eq('www.example.com')
    end

    it 'supports the license attribute specified as a string' do
      @spec.license = 'MIT'
      expect(@spec.license).to eq({ :type => 'MIT' })
    end

    it 'supports the license attribute specified as a hash' do
      @spec.license = { 'type' => 'MIT', 'file' => 'MIT-LICENSE' }
      expect(@spec.license).to eq({ :type => 'MIT', :file => 'MIT-LICENSE' })
    end

    it 'strips indentation from the license text' do
      text = <<-DOC
        Line1
        Line2
      DOC
      @spec.license = { 'type' => 'MIT', 'text' => text }
      expect(@spec.license[:text]).to eq("Line1\nLine2\n")
    end

    it 'returns the empty hash if not license information has been specified' do
      expect(@spec.license).to eq({})
    end

    it 'returns the homepage' do
      @spec.homepage = 'www.example.com'
      expect(@spec.homepage).to eq('www.example.com')
    end

    it 'returns the source' do
      @spec.source = { :git => 'www.example.com/repo.git' }
      expect(@spec.source).to eq({ :git => 'www.example.com/repo.git' })
    end

    it 'returns the summary' do
      @spec.summary = 'A library that describes the meaning of life.'
      expect(@spec.summary).to eq('A library that describes the meaning of life.')
    end

    it 'returns the summary stripping indentation' do
      summary = <<-DESC
        A quick brown fox.
      DESC
      @spec.summary = summary
      expect(@spec.summary).to eq('A quick brown fox.')
    end

    it 'returns the description stripping indentation' do
      desc = <<-DESC
        Line1
        Line2
      DESC
      @spec.description = desc
      expect(@spec.description).to eq("Line1\nLine2")
    end

    it 'returns the screenshots' do
      @spec.screenshots = ['www.example.com/img1.png', 'www.example.com/img2.png']
      expect(@spec.screenshots).to eq(['www.example.com/img1.png', 'www.example.com/img2.png'])
    end

    it 'support the specification of the attribute as a string' do
      @spec.screenshot = 'www.example.com/img1.png'
      expect(@spec.screenshots).to eq(['www.example.com/img1.png'])
    end

    it 'returns the prepare command stripping the indentation' do
      command = <<-DESC
        ruby prepare_script.rb
      DESC
      @spec.prepare_command = command
      expect(@spec.prepare_command).to eq('ruby prepare_script.rb')
    end

    it 'returns whether the Pod should build a static framework' do
      @spec.static_framework = true
      expect(@spec.static_framework).to eq(true)
    end

    it 'returns whether the Pod has been deprecated' do
      @spec.deprecated = true
      expect(@spec.deprecated).to eq(true)
    end

    it 'returns the name of the Pod that this one has been deprecated in favor of' do
      @spec.deprecated_in_favor_of = 'NewMoreAwesomePod'
      expect(@spec.deprecated_in_favor_of).to eq('NewMoreAwesomePod')
    end

    it 'it returns wether it is deprecated either by deprecated or deprecated_in_favor_of' do
      @spec.deprecated = true
      expect(@spec.deprecated?).to eq(true)
      @spec.deprecated = false

      @spec.deprecated_in_favor_of = 'NewMoreAwesomePod'
      expect(@spec.deprecated?).to eq(true)
      @spec.deprecated_in_favor_of = nil

      expect(@spec.deprecated?).to eq(false)
    end

    it 'returns the custom module map file, if specified' do
      @spec.module_map = 'module.modulemap'
      expect(@spec.module_map).to eq('module.modulemap')
    end

    it 'returns the correct requires_arc value, if specified' do
      expect(@spec.requires_arc).to eq(true)
    end
  end
end
