require 'uri'
require 'net/http'
require 'openssl'
require 'zlib'

module Pod
  # Handles HTTP requests
  #
  module HTTP
    # The response to a request made with {perform}.
    #
    # `headers` maps lowercase header names to arrays of values.
    #
    Response = Struct.new(:status_code, :headers, :body) do
      # @return [Boolean] whether the status code is 200.
      #
      def ok?
        status_code == 200
      end

      # @return [Boolean] whether the status code is in the 2xx range.
      #
      def success?
        (200..299).cover?(status_code)
      end
    end

    # Errors that can be raised while making a request.
    #
    NETWORK_ERRORS = [
      SocketError, SystemCallError, EOFError, Timeout::Error,
      OpenSSL::SSL::SSLError, Net::HTTPBadResponse,
      Net::HTTPHeaderSyntaxError, Net::ProtocolError, Zlib::GzipFile::Error
    ].freeze

    # Performs a request with Net::HTTP. Server certificates are verified
    # against the system trust store. The proxy is looked up from the URL, so
    # `https_proxy` and `no_proxy` apply; Net::HTTP's own lookup only reads
    # `http_proxy`.
    #
    # @param  [Symbol] verb
    #         The HTTP method, for example `:get` or `:head`.
    #
    # @param  [String] url
    #         The URL to request.
    #
    # @param  [Hash{String=>String}] headers
    #         The request headers.
    #
    # @raise  [URI::InvalidURIError] if the URL is not an HTTP or HTTPS URL.
    #
    # @return [Response]
    #
    def self.perform(verb, url, headers = {})
      uri = URI.parse(url)
      raise URI::InvalidURIError, "Not an HTTP URL: #{url}" unless uri.is_a?(URI::HTTP)
      request = Net::HTTP.const_get(verb.to_s.capitalize, false).new(uri.request_uri, headers)
      proxy = uri.find_proxy
      http = Net::HTTP.new(uri.host, uri.port, proxy&.host, proxy&.port, proxy&.user, proxy&.password)
      http.use_ssl = uri.scheme == 'https'
      response = http.start { |h| h.request(request) }
      Response.new(response.code.to_i, response.to_hash, response.body)
    end

    # Resolve potential redirects and return the final URL.
    #
    # @return [string]
    #
    def self.get_actual_url(url, user_agent = nil)
      redirects = 0

      loop do
        response = perform_head_request(url, user_agent)

        if [301, 302, 303, 307, 308].include? response.status_code
          location = response.headers['location'].first

          if location =~ %r{://}
            url = location
          else
            url = URI.join(url, location).to_s
          end

          redirects += 1
        else
          break
        end

        break unless redirects < MAX_HTTP_REDIRECTS
      end

      url
    end

    # Performs validation of a URL
    #
    # @return [Response]
    #
    def self.validate_url(url, user_agent = nil)
      return nil unless url =~ /^#{URI.regexp}$/

      begin
        url = get_actual_url(url, user_agent)
        resp = perform_head_request(url, user_agent)
      rescue URI::InvalidURIError, *NETWORK_ERRORS
        resp = nil
      end

      resp
    end

    #-------------------------------------------------------------------------#

    private

    # Does a HEAD request and in case of any errors a GET request
    #
    # @return [Response]
    #
    def self.perform_head_request(url, user_agent)
      user_agent ||= USER_AGENT

      resp = perform(:head, url, 'User-Agent' => user_agent)

      if resp.status_code >= 400
        resp = perform(:get, url, 'User-Agent' => user_agent,
                                  'Range' => 'bytes=0-0')

        if resp.status_code >= 400
          resp = perform(:get, url, 'User-Agent' => user_agent)
        end
      end

      resp
    end

    MAX_HTTP_REDIRECTS = 3
    USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10) AppleWebKit/538.43.40 (KHTML, like Gecko) Version/8.0 Safari/538.43.40'

    #-------------------------------------------------------------------------#
  end
end
