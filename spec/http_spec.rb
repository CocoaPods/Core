require File.expand_path('../spec_helper', __FILE__)

module Pod
  describe HTTP do
    after do
      WebMock.reset!
    end

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
        resolved_url.should == 'http://SOME-URL/foo'
      end

      it 'can successfully validate URLs' do
        WebMock::API.stub_request(:head, /foo/).to_return(:status => 200)

        response = HTTP.validate_url('http://SOME-URL/foo')
        response.success?.should.be.true
      end

      it 'is resilient to HEAD errors' do
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

      it 'uses a browser user-agent to validate URLs' do
        WebMock::API.stub_request(:head, /foo/).to_return(:status => 404)
        WebMock::API.stub_request(:get, /foo/).
          with(:headers => { :user_agent => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10) AppleWebKit/538.43.40 (KHTML, like Gecko) Version/8.0 Safari/538.43.40' }).
          to_return(:status => 200, :body => '')

        response = HTTP.validate_url('http://SOME-URL/foo')
        response.success?.should.be.true
      end

      it 'uses GET with Range of 1 byte' do
        WebMock::API.stub_request(:head, /foo/).to_return(:status => 404)
        WebMock::API.stub_request(:get, /foo/).
            with(:headers => { :range => 'bytes=0-0' }).
            to_return(:status => 200, :body => ' ')

        response = HTTP.validate_url('http://SOME-URL/foo')
        response.success?.should.be.true
      end

      it 'uses GET without Range if server rejects Range' do
        WebMock::API.stub_request(:head, /foo/).to_return(:status => 404)
        WebMock::API.stub_request(:get, /foo/).
            with(:headers => { :range => 'bytes=0-0' }).
            to_return(:status => 500)
        WebMock::API.stub_request(:get, /foo/).
            with { |request| request.headers.nil? || !request.headers.key?('Range') }.
            to_return(:status => 200, :body => '')

        response = HTTP.validate_url('http://SOME-URL/foo')
        response.success?.should.be.true
      end

      it 'returns nil for URLs that are not HTTP URLs' do
        HTTP.validate_url('ftp://example.com/foo').should.be.nil
        HTTP.validate_url('mailto:pods@example.com').should.be.nil
      end

      it 'returns nil when a network error occurs during validation' do
        WebMock::API.stub_request(:head, /foo/).to_raise(OpenSSL::SSL::SSLError)

        HTTP.validate_url('https://SOME-URL/foo').should.be.nil
      end
    end

    describe 'Performing requests' do
      it 'rejects a server certificate that is not trusted' do
        key = OpenSSL::PKey::RSA.new(2048)
        cert = OpenSSL::X509::Certificate.new
        cert.version = 2
        cert.serial = 1
        cert.subject = cert.issuer = OpenSSL::X509::Name.parse('/CN=127.0.0.1')
        cert.public_key = key.public_key
        cert.not_before = Time.now - 60
        cert.not_after = Time.now + 60
        cert.sign(key, OpenSSL::Digest.new('SHA256'))

        context = OpenSSL::SSL::SSLContext.new
        context.cert = cert
        context.key = key
        tcp_server = TCPServer.new('127.0.0.1', 0)
        server = OpenSSL::SSL::SSLServer.new(tcp_server, context)
        thread = Thread.new do
          begin
            server.accept.close
          rescue OpenSSL::SSL::SSLError
            nil
          end
        end

        WebMock.disable!
        begin
          url = "https://127.0.0.1:#{tcp_server.addr[1]}/"
          exception = should.raise(OpenSSL::SSL::SSLError) do
            HTTP.perform(:get, url)
          end
          exception.message.should.include 'certificate verify failed'
        ensure
          WebMock.enable!
          thread.kill
          thread.join
          server.close
        end
      end

      it 'uses the proxy configured for https' do
        proxy_env = %w(https_proxy HTTPS_PROXY no_proxy NO_PROXY).map { |k| [k, ENV.delete(k)] }
        ENV['https_proxy'] = 'http://user:pass@proxy.example:8080'
        Net::HTTP.expects(:new).
          with('example.com', 443, 'proxy.example', 8080, 'user', 'pass').
          raises(SocketError)

        begin
          should.raise(SocketError) do
            HTTP.perform(:get, 'https://example.com/')
          end
        ensure
          proxy_env.each { |k, v| v ? ENV[k] = v : ENV.delete(k) }
        end
      end
    end

    #-------------------------------------------------------------------------#
  end
end
