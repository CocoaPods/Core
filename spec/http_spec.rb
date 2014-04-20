require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe HTTP do

    describe 'In general' do
      it 'can resolve redirects' do
        WebMock::API.stub_request(:head, /redirect/).to_return(
          :status => 301, :headers => { 'Location' => 'http://NEW-URL/' })
        WebMock::API.stub_request(:head, /new-url/).to_return(:status => 200)

        resolved_url = HTTP.get_actual_url('http://SOME-URL/redirect/')
        resolved_url.should == 'http://NEW-URL/'
      end

      it 'can resolve relative redirects' do
        WebMock::API.stub_request(:head, /redirect/).to_return(
          :status => 301, :headers => { 'Location' => '/foo' })
        WebMock::API.stub_request(:head, /foo/).to_return(:status => 200)

        resolved_url = HTTP.get_actual_url('http://SOME-URL/redirect')
        resolved_url.should == 'http://SOME-URL/redirect/foo'
      end

      it 'can successfully validate URLs' do
        WebMock::API.stub_request(:head, /foo/).to_return(:status => 200)

        response = HTTP.validate_url('http://SOME-URL/foo')
        response.success?.should.be.true
      end

      it 'is resilient to HEAD errros' do
        WebMock::API.stub_request(:head, /foo/).to_return(:status => 404)
        WebMock::API.stub_request(:get, /foo/).to_return(:status => 200)

        response = HTTP.validate_url('http://SOME-URL/foo')
        response.success?.should.be.true
      end

      it 'reports failures when validating URLs' do
        WebMock::API.stub_request(:head, /foo/).to_return(:status => 404)
        WebMock::API.stub_request(:get, /foo/).to_return(:status => 404)

        response = HTTP.validate_url('http://SOME-URL/foo')
        response.success?.should.be.false
      end

      it 'is resilient against exceptions during validation of URLs' do
        response = HTTP.validate_url('%&/(foo)')
        response.should.be.nil
      end

    end

    #-------------------------------------------------------------------------#
  end
end
