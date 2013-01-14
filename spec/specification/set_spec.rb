require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Specification::Set do

    describe "In general" do
      before do
        @source = Source.new(fixture('spec-repos/master'))
        @set = Spec::Set.new('CocoaLumberjack', @source)
      end

      it "returns the name of the pod" do
        @set.name.should == 'CocoaLumberjack'
      end


      it "returns the versions available for this pod ordered from highest to lowest" do
        @set.versions.should == %w[1.6 1.3.3 1.3.2 1.3.1 1.3 1.2.3 1.2.2 1.2.1 1.2 1.1 1.0].map { |v| Version.new(v) }
      end

      it "checks if the dependency of the specification is compatible with existing requirements" do
        @set.required_by(Dependency.new('CocoaLumberjack', '1.2'), 'Spec')
        @set.required_by(Dependency.new('CocoaLumberjack', '< 1.2.1'), 'Spec')
        @set.required_by(Dependency.new('CocoaLumberjack', '> 1.1'), 'Spec')
        @set.required_by(Dependency.new('CocoaLumberjack', '~> 1.2.0'), 'Spec')
        @set.required_by(Dependency.new('CocoaLumberjack'), 'Spec')
        lambda {
          @set.required_by(Dependency.new('CocoaLumberjack', '< 1.0' ), 'Spec')
        }.should.raise StandardError
      end

      it "raises if the required version doesn't exist" do
        @set.required_by(Dependency.new('CocoaLumberjack', '< 1.0'), 'Spec')
        lambda { @set.required_version }.should.raise StandardError
      end

      it "can test if it is equal to another set" do
        @set.should == Spec::Set.new('CocoaLumberjack', @source)
        @set.should.not == Spec::Set.new('RestKit', @source)
      end

      #--------------------------------------#

      before do
        @set.required_by(Dependency.new('CocoaLumberjack', '< 1.2.1'), 'Spec')
      end

      it "returns the version required for the dependency" do
        @set.required_version.should == Version.new('1.2')
      end

      it "returns the specification for the required version" do
        @set.specification.name.should == 'CocoaLumberjack'
        @set.specification.version.should == Version.new('1.2')
      end

      it "ignores dotfiles when getting the version directories" do
        `touch #{fixture('spec-repos/master/CocoaLumberjack/.DS_Store')}`
        lambda { @set.versions }.should.not.raise
      end

      it "raises if a version is incompatible with the activated version" do
        spec = Dependency.new('CocoaLumberjack', '1.2.1')
        lambda { @set.required_by(spec, 'Spec') }.should.raise StandardError
      end
    end

    describe "Concerning multiple sources" do

      before do
        # JSONKit is in test repo has version 1.4 (duplicated) and the 999.999.999.
        @set = Source::Aggregate.new(fixture('spec-repos')).search_by_name('JSONKit').first
      end

      it "returns the sources where a podspec is available" do
        @set.sources.map(&:name).should == %w| master test_repo |
      end

      it "returns all the available versions sorted from biggest to lowest" do
        @set.versions.map(&:to_s).should == %w| 999.999.999 1.5pre 1.4 |
      end

      it "returns all the available versions by source sorted from biggest to lowest" do
        hash = {}
        @set.versions_by_source.each { |source, versions| hash[source.name] = versions.map(&:to_s) }
        hash['master'].should == %w| 1.5pre 1.4 |
        hash['test_repo'].should == %w| 999.999.999 1.4 |
        hash.keys.sort.should == %w| master test_repo |
      end

      it "returns the specification from the `master` source for the required version" do
        dep = Dependency.new('JSONKit', '1.5pre')
        @set.required_by(dep, 'Spec')
        spec = @set.specification
        spec.name.should == 'JSONKit'
        spec.version.to_s.should == '1.5pre'
        spec.defined_in_file.should == fixture('spec-repos/master/JSONKit/1.5pre/JSONKit.podspec')
      end

      it "returns the specification from `test_repo` source for the required version" do
        dep = Dependency.new('JSONKit', '999.999.999')
        @set.required_by(dep, 'Spec')
        spec = @set.specification
        spec.name.should == 'JSONKit'
        spec.version.to_s.should == '999.999.999'
        spec.defined_in_file.should == fixture('spec-repos/test_repo/JSONKit/999.999.999/JSONKit.podspec')
      end

      it "prefers sources by alphabetical order" do
        dep = Dependency.new('JSONKit', '1.4')
        @set.required_by(dep, 'Spec')
        spec = @set.specification
        spec.name.should == 'JSONKit'
        spec.version.to_s.should == '1.4'
        spec.defined_in_file.should ==  fixture('spec-repos/master/JSONKit/1.4/JSONKit.podspec')
      end
    end
  end

  describe Specification::Set::External do
    before do
      @spec = Spec.from_file(fixture('BananaLib.podspec'))
      @set = Spec::Set::External.new(@spec)
    end

    it "returns the specification" do
      @set.specification.should == @spec
    end

    it "returns the name" do
      @set.name.should == 'BananaLib'
    end

    it "returns whether it is equal to another set" do
      @set.should == Spec::Set::External.new(@spec)
    end

    it "returns the version of the specification" do
      @set.versions.map(&:to_s).should == ['1.0']
    end

    it "doesn't nil the initialization specification on #required_by" do
      @set.required_by(Dependency.new('BananaLib', '1.0'), 'Spec')
      @set.specification.should == @spec
    end

    it "raises if the required version doesn't match the specification" do
      @set.required_by(Dependency.new('BananaLib', '< 1.0'), 'Spec')
      lambda { @set.required_version }.should.raise StandardError
    end
  end
end
