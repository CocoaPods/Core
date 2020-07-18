require 'cocoapods-core/source'
require 'rest'
require 'concurrent'
require 'netrc'
require 'addressable'
require 'net-http2'
require 'uri'

module Pod
  # Reactor helper class to access CDN-based Specs repositories
  #
  class CDNHostReactor
    include Concurrent

    def initialize(uri)
      @client = NetHttp2::Client.new(uri, :connect_timeout => 10)
      @executor = Concurrent::SingleThreadExecutor.new
      @stream_count = 0
      @executor.post do
        loop do
          @client.join
          sleep 0.05
        end
      end
    end

    def get(uri, etag, resolve_executor)
      request = @client.prepare_request(
        :get,
        URI(uri).path,
        :headers => etag.nil? ? {} : { 'If-None-Match' => etag },
        :timeout => 10,
      )

      future = Promises.resolvable_future_on(resolve_executor)

      begin
        while @stream_count >= @client.remote_settings[:settings_max_concurrent_streams]
          sleep 0.05
        end

        @stream_count += 1
        @client.call_async(request)

        headers = {}
        body = ''
        request.on(:headers) { |h| headers.merge!(h) }
        request.on(:body_chunk) { |chunk| body << chunk }
        request.on(:close) do
          @stream_count -= 1
          future.fulfill(NetHttp2::Response.new(:headers => headers, :body => body))
        end
      end

      # This `Future` should never reject, network errors are exposed on `Typhoeus::Response`
      future
    end
  end
end
