require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe DSLError do
    before do
      @dsl_path = fixture('spec-repos/master/Three20/1.0.11/Three20.podspec')
      backtrace = [
        "#{@dsl_path}:2:in `error line'",
        "#{@dsl_path}:127:in `block (2 levels) in _eval_podspec'",
        "lib/cocoapods-core/specification.rb:41:in `initialize'",
      ]
      description = 'Invalid podspec.'
      @err = DSLError.new(description, @dsl_path, backtrace)

      lines = ['first line', 'error line', 'last line']
      File.stubs(:readlines).returns(lines)
    end

    it "includes the given description in the message" do
      @err.message.should.include?("Invalid podspec.")
    end

    it "includes the path of the dsl file in the message" do
      @err.message.should.include?("from #{@dsl_path}")
    end

    it "includes in the message the contents of the line that raised the exception" do
      @err.message.should.include?("error line")
    end

    it "is robust against a nil backtrace" do
      @err.stubs(:backtrace => nil)
      lambda { @err.message }.should.not.raise
    end

    it "is robust against a backtrace non including the path of the dsl file" do
      @err.stubs(:backtrace).returns [
        "lib/cocoapods-core/specification.rb:41:in `initialize'",
      ]
      lambda { @err.message }.should.not.raise
    end

    it "is robust against a backtrace that doesn't include the line number of the dsl file that originated the error" do
      @err.stubs(:backtrace).returns [ @dsl_path.to_s ]
      lambda { @err.message }.should.not.raise
    end

    it "is against a nil path of the dsl file" do
      @err.stubs(:dsl_path => nil)
      lambda { @err.message }.should.not.raise
    end

    it "is robust against non existing paths" do
      @err.stubs(:dsl_path => 'find_me_baby')
      lambda { @err.message }.should.not.raise
    end

    it "can handle the first line of the dsl file" do
      @err.stubs(:backtrace).returns [ "#{@dsl_path}:1", ]
      lambda { @err.message }.should.not.raise
      @err.message.should.include?("first line")
      @err.message.should.not.include?("last line")
    end

    it "can handle the last line of the dsl file" do
      @err.stubs(:backtrace).returns [ "#{@dsl_path}:3", ]
      lambda { @err.message }.should.not.raise
      @err.message.should.not.include?("first line")
      @err.message.should.include?("last line")
    end
  end
end
