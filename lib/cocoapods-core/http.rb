require 'netrc'
require 'rest'
require 'uri'

module Pod
  # Handles HTTP requests
  #
  module HTTP
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
    # @return [REST::response]
    #
    def self.validate_url(url, user_agent = nil)
      return nil unless url =~ /^#{URI.regexp}$/

      begin
        url = get_actual_url(url, user_agent)
        resp = perform_head_request(url, user_agent)
      rescue SocketError, URI::InvalidURIError, REST::Error, REST::Error::Connection
        resp = nil
      end

      resp
    end

    # Performs GET request
    # @param file_remote_url The URL.
    # @param headers The request headers hash.
    # @param options The request options hash.
    # @param auto_login The flag to use ~/.netrc file for autologin into restricted sources.
    #
    # @return [REST::response]
    #
    def self.download(file_remote_url, headers = {}, options = {}, auto_login = true)
      if auto_login
        # disabling mandatory 600 access mode. Safe one because no write functionality.
        Netrc.configure do |config|
          config[:allow_permissive_netrc_file] = true
        end
        netrc_content = Netrc.read
        unless netrc_content.nil?
          user, pass = netrc_content[URI(file_remote_url).host]
          unless user.nil? || pass.nil?
            options = { :username => user, :password => pass }
          end
        end
      end
      REST.get(file_remote_url, headers, options)
    end

    #-------------------------------------------------------------------------#

    private

    # Does a HEAD request and in case of any errors a GET request
    #
    # @return [REST::response]
    #
    def self.perform_head_request(url, user_agent)
      user_agent ||= USER_AGENT

      resp = ::REST.head(url, 'User-Agent' => user_agent)

      if resp.status_code >= 400
        resp = ::REST.get(url, 'User-Agent' => user_agent,
                               'Range' => 'bytes=0-0')

        if resp.status_code >= 400
          resp = ::REST.get(url, 'User-Agent' => user_agent)
        end

        if resp.status_code == 401
          resp = download(url, 'User-Agent' => user_agent)
        end
      end

      resp
    end

    MAX_HTTP_REDIRECTS = 3
    USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10) AppleWebKit/538.43.40 (KHTML, like Gecko) Version/8.0 Safari/538.43.40'

    #-------------------------------------------------------------------------#
  end
end
