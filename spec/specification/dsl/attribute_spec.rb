require File.expand_path('../../../spec_helper', __FILE__)

module Pod
  describe Attribute = Specification::DSL::Attribute do

    describe "In general" do
      it "returns the name" do
        attr = Attribute.new('name', {})
        attr.name.should == 'name'
      end

      it "raises for not recognized options" do
        opts = {:unrecognized => true}
        lambda { Attribute.new('name', opts) }.should.raise StandardError
      end

      it "returns a string representation suitable for UI" do
        s = "Specification attribute `name`"
        Attribute.new('name', {}).to_s.should == s
      end

      it "returns the accepted classes for the value of the attribute" do
        opts = {:types => [String], :container => Array}
        Attribute.new('name', opts).supported_types.should == [String, Array]
      end
    end

    #-------------------------------------------------------------------------#

    describe "Defaults" do
      before do
        @attr = Attribute.new('name', {})
      end

      it "is multi platform by default" do
        @attr.should.be.multi_platform
      end

      it "is inherited by default" do
        @attr.should.be.inherited
      end

      it "is not root only by default" do
        @attr.should.not.be.root_only
      end

      it "is not required by default" do
        @attr.should.not.be.required
      end

      it "doesn't want a singular form by default" do
        @attr.should.not.be.required
      end

      it "is not a file pattern by default" do
        @attr.should.not.be.file_patterns
      end

      it "doesn't specifies a container by default" do
        @attr.container.should.be.nil
      end

      it "doesn't specifies accepted keys for a hash container by default" do
        @attr.keys.should.be.nil
      end

      it "doesn't specifies a default value by default (multi platform)" do
        @attr.default_value.should.be == {:ios => nil, :osx => nil}
      end

      it "doesn't specifies a default value by default (no multi platform)" do
        @attr = Attribute.new('name', {:multi_platform => false})
        @attr.default_value.should.be.nil
      end

      it "doesn't specifies that it is accessor are already defined (`defined_as` option)" do
        @attr.should.not.skip_definitions
      end

      it "specifies `String` as the default type" do
        @attr.types.should == [String]
      end

      #--------------------------------------#

      before do
        @attr = Attribute.new('name', {:root_only => true})
      end

      it "is not multi platform if it is root only" do
        @attr.should.not.be.multi_platform
      end

      it "is not inherited if it is root only" do
        @attr.should.not.be.inherited
      end
    end

    #-------------------------------------------------------------------------#

    describe "Instance variable" do
      before do
        @attr = Attribute.new(:frameworks, :container => Array, :singularize => true)
      end

      it "returns the name of the ivar" do
        @attr.ivar.should == '@frameworks'
      end

      it "can initialize the instance variable of a given specification" do
        opts = {:container => Array, :multi_platform => false}
        @attr = Attribute.new('custom_attrb', opts)
        spec = Spec.new
        @attr.initialize_spec_ivar(spec)
        spec.instance_variable_get('@custom_attrb').should == []
      end

      it "can initialize the instance variable of a given specification" do
        spec = Spec.new
        @attr.initialize_spec_ivar(spec)
        spec.instance_variable_get('@frameworks').should == {:osx=>[], :ios=>[]}
      end

      it "does NOT initialize the instance variable with the default value" do
        opts = {:container => Array, :multi_platform => false, :default_value => 'default' }
        @attr = Attribute.new('custom_attrb', opts)
        spec = Spec.new
        @attr.initialize_spec_ivar(spec)
        spec.instance_variable_get('@custom_attrb').should.not == ['default']
        spec.instance_variable_get('@custom_attrb').should == []
      end
    end

    #-------------------------------------------------------------------------#

    describe "Reader method support" do
      it "returns the name of the reader method" do
        attr = Attribute.new(:frameworks, {})
        attr.reader_name.should == :frameworks
      end

      it "returns the default value" do
        attr = Attribute.new(:frameworks, :multi_platform => false)
        attr.default_value.should.be.nil?
        attr = Attribute.new(:frameworks, :multi_platform => false, :default_value => ['Cocoa'] )
        attr.default_value.should == ['Cocoa']
      end

      it "returns the default value for multi platform attributes" do
        attr = Attribute.new(:frameworks, :default_value => ['CoreGraphics'] )
        attr.default_value.should == {:osx=>["CoreGraphics"], :ios=>["CoreGraphics"]}
      end
    end

    #-------------------------------------------------------------------------#

    describe "Inheritance support" do
      it "computes the value that the reader method should return taking into account inheritance" do
        attr = Attribute.new(:frameworks, :container => Array)
        spec = Spec.new do |s|
          s.frameworks = ['a_framework']
          s.subspec 'sub' do end
        end
        spec.activate_platform(:ios)
        attr.value_with_inheritance(spec.subspecs.first, nil).should == ['a_framework']
      end

      it "doesn't inherits value of the parent if the attribute is not inherited" do
        attr = Attribute.new(:default_subspec, :inherited => false)
        spec = Spec.new do |s|
          s.default_subspec = '_sub_'
          s.subspec 'sub' do end
        end
        spec.activate_platform(:ios)
        attr.value_with_inheritance(spec, '_sub_').should == '_sub_'
        attr.value_with_inheritance(spec.subspecs.first, nil).should.be.nil
      end

      it "concatenates the values of attributes contained in an array" do
        attr = Attribute.new(:frameworks, :container => Array)
        spec = Spec.new do |s|
          s.frameworks = 'CoreGraphics'
          s.subspec 'sub' do |sp|
            sp.frameworks = 'CoreData'
          end
        end
        spec.activate_platform(:ios)
        spec_value = attr.value_with_inheritance(spec, ['CoreGraphics'])
        sub_spec_value = attr.value_with_inheritance(spec.subspecs.first, ['CoreData'])
        spec_value.should == ['CoreGraphics']
        sub_spec_value.should == ['CoreGraphics', 'CoreData']
      end

      it "merges the values of attributes contained in a hash" do
        attr = Attribute.new(:xcconfig, :container => Hash)
        spec = Spec.new do |s|
          s.xcconfig = {'OTHER_LDFLAGS' => '-lObjC'}
          s.subspec 'sub' do |sp|
            sp.xcconfig = {'OTHER_LDFLAGS' => '-framework SystemConfiguration'}
          end
        end
        spec.activate_platform(:ios)
        spec_value = attr.value_with_inheritance(spec, {'OTHER_LDFLAGS' => '-lObjC'})
        sub_spec_value = attr.value_with_inheritance(spec.subspecs.first, {'OTHER_LDFLAGS' => '-framework SystemConfiguration'})
        spec_value.should == {'OTHER_LDFLAGS' => '-lObjC'}
        sub_spec_value.should == {'OTHER_LDFLAGS' => '-lObjC -framework SystemConfiguration'}
      end

      it "returns the value or the value of the parent if the attribute has no container" do
        attr = Attribute.new(:header_dir, :container => nil)
        spec = Spec.new do |s|
          s.header_dir = 'dir'
          s.subspec 'sub' do |sp|
            sp.header_dir = 'sub_dir'
          end
        end
        spec.activate_platform(:ios)
        attr.value_with_inheritance(spec, 'dir').should == 'dir'
        attr.value_with_inheritance(spec.subspecs.first, 'sub_dir').should == 'sub_dir'
        attr.value_with_inheritance(spec, nil).should == nil
        attr.value_with_inheritance(spec.subspecs.first, nil).should == 'dir'
      end
    end

    #-------------------------------------------------------------------------#

    describe "Writer method support" do
      it "returns the name of the writer method" do
        attr = Attribute.new(:frameworks, {:singularize => true})
        attr.writer_name.should == 'frameworks='
      end

      it "returns the singular form of the writer method" do
        attr = Attribute.new(:frameworks, {:singularize => true})
        attr.writer_singular_form.should == 'framework='
      end

      it "returns the name of the hook that the extended class can use to prepare a value before storing it" do
        attr = Attribute.new(:frameworks, {:singularize => true})
        attr.prepare_hook_name.should == '_prepare_frameworks'
      end

      it "validates a value to check whether it is compatible with the accepted types" do
        attr = Attribute.new(:frameworks, {:types => [String], :container => Array})
        lambda { attr.validate_type('a string') }.should.not.raise
        lambda { attr.validate_type(['with container']) }.should.not.raise
        lambda { attr.validate_type(:non_accepted) }.should.raise StandardError
      end

      it "validates root only values before writing" do
        attr = Attribute.new(:summary, :root_only => true)
        spec = Spec.new do |s|
          s.subspec 'sub' do |sp| end
        end
        subspec = spec.subspecs.first

        lambda { attr.validate_for_writing(spec, 'a string') }.should.not.raise
        lambda { attr.validate_for_writing(subspec, 'a string') }.should.raise StandardError
      end

      it "validates the allowed keys for hashes before writing" do
        attr = Attribute.new(:source, :keys => [:git])
        spec = Spec.new
        lambda { attr.validate_for_writing(spec, {:git => 'repo'}) }.should.not.raise
        lambda { attr.validate_for_writing(spec, {:snail_mail => 'repo'}) }.should.raise StandardError
      end

      it "returns the allowed keys" do
        attr = Attribute.new(:source, :keys => [:git, :svn])
        attr.allowed_keys.should == [:git, :svn]
      end

      it "returns the allowed keys flattening keys specified in a hash" do
        attr = Attribute.new(:source, :keys => {:git => [:tag, :commit], :http => nil})
        attr.allowed_keys.map(&:to_s).sort.should == %w[commit git http tag]
      end
    end
  end

  #---------------------------------------------------------------------------#

  describe Specification::DSL::Attributes do

    # Simulates the Specification class
    #
    class TestClass
      @attributes = []
      attr_accessor :active_platform;

      attr_accessor :parent

      def root;     root? ? self : parent.root;  end
      def root?;    parent.nil?;  end
      def subspec?; !parent.nil?; end

      attr_accessor :define_for_platforms

      def initialize
        self.class.attributes.each { |a| a.initialize_spec_ivar(self) }
        @define_for_platforms = [ :ios, :osx ]
      end

      def subspec
        s = self.class.new
        s.parent = self
        s
      end

      extend  Pod::Specification::DSL::Attributes
      include Pod::Specification::DSL::AttributeSupport
      def self.attributes
        @attributes
      end

      attribute :name,            { :types => [String],  :root_only => true }
      attribute :singularized,    { :types => [String],  :root_only => true, :singularize => true }
      attribute :inherited,       { :container => Array, :multi_platform => false }
      attribute :multi_platform,  { :container => Array, :multi_platform => true }
      attribute :hash_attrb,      { :container => Hash, :multi_platform => true }
      attribute :default_value,   { :default_value => 'kiwis', :multi_platform => false }
    end

    describe "In general" do
      before do
        @test = TestClass.new
      end

      it "stores the list of the attributes" do
        attributes = TestClass.attributes.map(&:name)
        attributes.should.include?(:name)
        attributes.should.include?(:singularized)
      end

      it "defines reader and writer methods for an attribute" do
        @test.name = 'name'
        @test.name.should == 'name'
      end

      it "defines the singularize writer for an attribute" do
        @test.singularized = 'value'
        @test.singularized.should == 'value'
      end
    end

    #-------------------------------------------------------------------------#

    describe "Reader method" do
      before do
        @test = TestClass.new
        @subspec = @test.subspec
      end

      it "forwards request to the root for root only attributes" do
        @test.name = 'name'
        @subspec.name.should == 'name'
      end

      it "returns the value taking into account inheritance" do
        @test.inherited = 'value_1'
        @subspec.inherited = 'value_2'
        @subspec.inherited.sort.should == ['value_1', 'value_2']
      end

      it "checks that a platform has been activated for multi platform attributes" do
        @test.multi_platform = 'value_1'
        lambda { @test.multi_platform }.should.raise StandardError
        @test.active_platform = :ios
        lambda { @test.multi_platform }.should.not.raise
      end

      it "returns the value for the active platform" do
        ivar = @test.instance_variable_get("@multi_platform")
        ivar[:ios] = 'ios_value'
        ivar[:osx] = 'osx_value'
        @test.active_platform = :ios
        @test.multi_platform.should == 'ios_value'
        @test.active_platform = :osx
        @test.multi_platform.should == 'osx_value'
      end

      it "returns the default value of the attribute is value is defined" do
        @test.default_value.should == 'kiwis'
        @test.default_value = 'a_value'
        @test.default_value.should == 'a_value'
      end
    end

    #-------------------------------------------------------------------------#

    describe "Writer method" do
      before do
        @test = TestClass.new
      end

      it "validates the type of the value" do
        # name accepts only strings
        lambda {@test.name = 'string'}.should.not.raise
        lambda {@test.name = ['array']}.should.raise StandardError
      end

      it "allows the attribute to prepare the value before storing it" do
        # inherited is contained in an Array
        @test.inherited = 'string'
        @test.inherited.class.should == Array
        @test.inherited.should == ['string']
      end

      it "ask the attribute to validate the assignment before storing it" do
        # name is root only
        lambda {@test.name = 'string'}.should.not.raise
        lambda {@test.subspec.name = 'string'}.should.raise StandardError
      end

      it "merges array values for multi platform attributes" do
        @test.multi_platform = 'general_value'
        @test.define_for_platforms = [:ios]
        @test.multi_platform = 'ios_value'

        @test.active_platform = :ios
        # the order is not part of the spec but it is better to have
        # the values of the parents in the front.
        @test.multi_platform.should == ['general_value', 'ios_value']
        @test.active_platform = :osx
        @test.multi_platform.should == ['general_value']
      end

      it "merges hashes values for multi platform attributes" do
        @test.hash_attrb = {:key => 'general_value', :arraykey => ['1']}
        @test.define_for_platforms = [:ios]
        @test.hash_attrb = {:key => 'ios_value', :arraykey => ['2']}

        @test.active_platform = :ios
        # the order is not part of the spec but it is better to have
        # the values of the parents in the front.
        @test.hash_attrb.should == {:key => 'general_value ios_value', :arraykey => ['1','2']}
        @test.active_platform = :osx
        @test.hash_attrb.should == {:key => 'general_value', :arraykey => ['1']}
      end

    end
  end
end
