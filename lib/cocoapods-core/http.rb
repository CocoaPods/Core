module Pod
  # Handles HTTP requests
  #
  module HTTP

    # Resolve potential redirects and return the final URL.
    #
    # @return [string]
    #
    def self.get_actual_url(url)
      redirects = 0

      loop do
        response = perform_head_request(url)

        if [301, 302, 303, 307, 308].include? response.status_code
          location = response.headers['location'].first

          if location =~ /:\/\//
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
    def self.validate_url(url)
      if not url =~ /^#{URI.regexp}$/
        return nil
      end

      begin
        url = get_actual_url(url)
        resp = perform_head_request(url)
      rescue SocketError
        resp = nil
      end

      resp
    end

    #-------------------------------------------------------------------------#

    private

    # Does a HEAD request and in case of any errors a GET request
    #
    # @return [REST::response]
    #
    def self.perform_head_request(url)
      require 'rest'

      resp = ::REST.head(url)

      if resp.status_code >= 400
        resp = ::REST.get(url)
      end

      resp
    end

    MAX_HTTP_REDIRECTS = 3

    #-------------------------------------------------------------------------#
  end
end
