require 'cocoapods-core/source'
require 'rest'
require 'netrc'
require 'base64'
require 'zlib'
require 'async'
require 'async/barrier'
require 'async/http'
require 'async/http/internet'
require 'addressable'

module Pod
  # Subclass of Pod::Source to provide support for CDN-based Specs repositories
  #
  class CDNSource < Source
    FORCE_HTTP2 = true
    MAX_NUMBER_OF_RETRIES = (ENV['COCOAPODS_CDN_MAX_NUMBER_OF_RETRIES'] || 5).to_i
    REQUEST_TIMEOUT = (ENV['COCOAPODS_CDN_REQUEST_TIMEOUT'] || 10).to_i

    # @param [String] repo The name of the repository
    #
    def initialize(repo)
      @check_existing_files_for_update = false
      # Optimization: we initialize startup_time when the source is first initialized
      # and then test file modification dates against it. Any file that was touched
      # after the source was initialized, is considered fresh enough.
      @startup_time = Time.new

      @version_arrays_by_fragment_by_name = {}

      super(repo)
    end

    # @return [Async::HTTP::Internet] The async HTTP client.
    #
    def http_client
      @http_client ||=
        begin
          options = {
            :retries => 0,
          }
          options[:protocol] = Async::HTTP::Protocol::HTTP2 if FORCE_HTTP2

          Async::HTTP::Internet.new(**options)
        end
    end

    # @return [String] The URL of the source.
    #
    def url
      @url ||= File.read(repo.join('.url')).chomp.chomp('/') + '/'
    end

    # @return [String] The type of the source.
    #
    def type
      'CDN'
    end

    def refresh_metadata
      if metadata.nil?
        unless repo.exist?
          debug "CDN: Repo #{name} does not exist!"
          return
        end

        specs_dir.mkpath
        download_file('CocoaPods-version.yml')
      end

      super
    end

    def preheat_existing_files
      files_to_update = files_definitely_to_update + deprecated_local_podspecs - ['deprecated_podspecs.txt']
      debug "CDN: #{name} Going to update #{files_to_update.count} files"

      concurrent_requests_catching_errors do |task|
        # Queue all tasks first
        files_to_update.each do |file|
          task.async do
            download_file_async(file)
          end
        end
      end
    ensure
      http_client.close
    end

    def files_definitely_to_update
      Pathname.glob(repo.join('**/*.{txt,yml}')).map { |f| f.relative_path_from(repo).to_s }
    end

    def deprecated_local_podspecs
      download_file('deprecated_podspecs.txt')
      local_file('deprecated_podspecs.txt', &:to_a).
        map { |f| Pathname.new(f.chomp) }.
        select { |f| repo.join(f).exist? }
    end

    # @return [Pathname] The directory where the specs are stored.
    #
    def specs_dir
      @specs_dir ||= repo + 'Specs'
    end

    # @!group Querying the source
    #-------------------------------------------------------------------------#

    # @return [Array<String>] the list of the name of all the Pods.
    #
    def pods
      download_file('all_pods.txt')
      local_file('all_pods.txt', &:to_a).map(&:chomp)
    end

    # @return [Array<Version>] all the available versions for the Pod, sorted
    #         from highest to lowest.
    #
    # @param  [String] name
    #         the name of the Pod.
    #
    def versions(name)
      return nil unless specs_dir
      raise ArgumentError, 'No name' unless name

      fragment = pod_shard_fragment(name)

      ensure_versions_file_loaded(fragment)

      return @versions_by_name[name] unless @versions_by_name[name].nil?

      pod_path_actual = pod_path(name)
      pod_path_relative = relative_pod_path(name)

      return nil if @version_arrays_by_fragment_by_name[fragment][name].nil?

      concurrent_requests_catching_errors do |task|
        @version_arrays_by_fragment_by_name[fragment][name].each do |version|
          # Optimization: ensure all the podspec files at least exist. The correct one will get refreshed
          # in #specification_path regardless.
          podspec_version_path_relative = Pathname.new(version).join("#{name}.podspec.json")

          unless pod_path_actual.join(podspec_version_path_relative).exist?
            # Queue all podspec download tasks first
            task.async do
              download_file_async(pod_path_relative.join(podspec_version_path_relative).to_s)
            end
          end
        end
      end

      @versions_by_name[name] ||= @version_arrays_by_fragment_by_name[fragment][name].map do |version|
        Version.new(version) if version[0, 1] != '.'
      rescue ArgumentError
        raise Informative, 'An unexpected version directory ' \
          "`#{version}` was encountered for the " \
          "`#{pod_path_actual}` Pod in the `#{name}` repository."
      end.compact.sort.reverse
    ensure
      http_client.close
    end

    # Returns the path of the specification with the given name and version.
    #
    # @param  [String] name
    #         the name of the Pod.
    #
    # @param  [Version,String] version
    #         the version for the specification.
    #
    # @return [Pathname] The path of the specification.
    #
    def specification_path(name, version)
      raise ArgumentError, 'No name' unless name
      raise ArgumentError, 'No version' unless version
      unless versions(name).include?(Version.new(version))
        raise StandardError, "Unable to find the specification #{name} " \
          "(#{version}) in the #{self.name} source."
      end

      podspec_version_path_relative = Pathname.new(version.to_s).join("#{name}.podspec.json")
      relative_podspec = relative_pod_path(name).join(podspec_version_path_relative).to_s
      download_file(relative_podspec)
      pod_path(name).join(podspec_version_path_relative)
    end

    # @return [Array<Specification>] all the specifications contained by the
    #         source.
    #
    def all_specs
      raise Informative, "Can't retrieve all the specs for a CDN-backed source, it will take forever"
    end

    # @return [Array<Sets>] the sets of all the Pods.
    #
    def pod_sets
      raise Informative, "Can't retrieve all the pod sets for a CDN-backed source, it will take forever"
    end

    # @!group Searching the source
    #-------------------------------------------------------------------------#

    # @return [Set] a set for a given dependency. The set is identified by the
    #               name of the dependency and takes into account subspecs.
    #
    # @note   This method is optimized for fast lookups by name, i.e. it does
    #         *not* require iterating through {#pod_sets}
    #
    # @todo   Rename to #load_set
    #
    def search(query)
      unless specs_dir
        raise Informative, "Unable to find a source named: `#{name}`"
      end
      if query.is_a?(Dependency)
        query = query.root_name
      end

      fragment = pod_shard_fragment(query)

      ensure_versions_file_loaded(fragment)

      version_arrays_by_name = @version_arrays_by_fragment_by_name[fragment] || {}

      found = version_arrays_by_name[query].nil? ? nil : query

      if found
        set = set(query)
        set if set.specification_name == query
      end
    end

    # @return [Array<Set>] The list of the sets that contain the search term.
    #
    # @param  [String] query
    #         the search term. Can be a regular expression.
    #
    # @param  [Bool] full_text_search
    #         performed using Algolia
    #
    # @note   full text search requires to load the specification for each pod,
    #         and therefore not supported.
    #
    def search_by_name(query, full_text_search = false)
      if full_text_search
        require 'algoliasearch'
        begin
          algolia_result = algolia_search_index.search(query, :attributesToRetrieve => 'name')
          names = algolia_result['hits'].map { |r| r['name'] }
          names.map { |n| set(n) }.reject { |s| s.versions.compact.empty? }
        rescue Algolia::AlgoliaError => e
          raise Informative, "CDN: #{name} - Cannot perform full-text search because Algolia returned an error: #{e}"
        end
      else
        super(query)
      end
    end

    # Check update dates for all existing files.
    # Does not download non-existing specs, since CDN-backed repo is updated live.
    #
    # @param  [Bool] show_output
    #
    # @return  [Array<String>] Always returns empty array, as it cannot know
    #          everything that actually changed.
    #
    def update(_show_output)
      @check_existing_files_for_update = true
      begin
        preheat_existing_files
      ensure
        @check_existing_files_for_update = false
      end
      []
    end

    def updateable?
      true
    end

    def git?
      false
    end

    def indexable?
      false
    end

    private

    def ensure_versions_file_loaded(fragment)
      return if !@version_arrays_by_fragment_by_name[fragment].nil? && !@check_existing_files_for_update

      # Index file that contains all the versions for all the pods in the shard.
      # We use those because you can't get a directory listing from a CDN.
      index_file_name = index_file_name_for_fragment(fragment)
      download_file(index_file_name)
      versions_raw = local_file(index_file_name, &:to_a).map(&:chomp)
      @version_arrays_by_fragment_by_name[fragment] = versions_raw.reduce({}) do |hash, row|
        row = row.split('/')
        pod = row.shift
        versions = row

        hash[pod] = versions
        hash
      end
    end

    def algolia_search_index
      @index ||= begin
        require 'algoliasearch'

        raise Informative, "Cannot perform full-text search in repo #{name} because it's missing Algolia config" if download_file('AlgoliaSearch.yml').nil?
        algolia_config = YAMLHelper.load_string(local_file('AlgoliaSearch.yml', &:read))

        client = Algolia::Client.new(:application_id => algolia_config['application_id'], :api_key => algolia_config['api_key'])
        Algolia::Index.new(algolia_config['index'], client)
      end
    end

    def index_file_name_for_fragment(fragment)
      fragment_joined = fragment.join('_')
      fragment_joined = '_' + fragment_joined unless fragment.empty?
      "all_pods_versions#{fragment_joined}.txt"
    end

    def pod_shard_fragment(pod_name)
      metadata.path_fragment(pod_name)[0..-2]
    end

    def local_file_okay?(partial_url)
      file_path = repo.join(partial_url)
      File.exist?(file_path) && File.size(file_path) > 0
    end

    def local_file(partial_url)
      file_path = repo.join(partial_url)
      File.open(file_path) do |file|
        yield file if block_given?
      end
    end

    def relative_pod_path(pod_name)
      pod_path(pod_name).relative_path_from(repo)
    end

    def download_file(partial_url)
      Sync do
        download_file_async(partial_url)
      end

      partial_url
    ensure
      http_client.close
    end

    def download_file_async(partial_url)
      file_remote_url = Addressable::URI.encode(url + partial_url.to_s)
      path = repo + partial_url

      file_okay = local_file_okay?(partial_url)
      if file_okay
        if @startup_time < File.mtime(path)
          debug "CDN: #{name} Relative path: #{partial_url} modified during this run! Returning local"
          return
        end

        unless @check_existing_files_for_update
          debug "CDN: #{name} Relative path: #{partial_url} exists! Returning local because checking is only performed in repo update"
          return
        end
      end

      path.dirname.mkpath

      etag_path = path.sub_ext(path.extname + '.etag')

      etag = file_okay && File.exist?(etag_path) ? File.read(etag_path) : nil
      debug "CDN: #{name} Relative path: #{partial_url}, has ETag? #{etag}" unless etag.nil?

      download_and_save_with_retries_async(partial_url, file_remote_url, etag)
    end

    def download_and_save_with_retries_async(partial_url, file_remote_url, etag, retries = MAX_NUMBER_OF_RETRIES)
      path = repo + partial_url
      etag_path = path.sub_ext(path.extname + '.etag')

      response =
        begin
          Async::Task.current.with_timeout(REQUEST_TIMEOUT) do
            make_download(file_remote_url, etag)
          end
        rescue Async::TimeoutError, Async::HTTP::Protocol::RequestFailed, SocketError, StandardError => e
          message =
            case e
            when Async::TimeoutError
              "CDN: #{name} URL couldn't be downloaded: #{file_remote_url} Response: Request timeout"
            when SocketError
              "CDN: #{name} URL couldn't be downloaded: #{file_remote_url} Response: Couldn't connect to server"
            else
              "CDN: #{name} URL couldn't be downloaded: #{file_remote_url} Response: #{e.message}"
            end

          if retries <= 1
            raise Informative, message
          else
            debug message + ", retries: #{retries - 1}"
            make_sleep backoff_time(retries)
            download_and_save_with_retries_async(partial_url, file_remote_url, etag, retries - 1)
            return
          end
        end

      body = response.read
      case response.status
      when 301
        redirect_location = response.headers['location']
        debug "CDN: #{name} Redirecting from #{file_remote_url} to #{redirect_location}"
        download_and_save_with_retries_async(partial_url, redirect_location, etag)
      when 304
        debug "CDN: #{name} Relative path not modified: #{partial_url}"
        # We need to update the file modification date, as it is later used for freshness
        # optimization. See #initialize for more information.
        FileUtils.touch path
      when 200
        File.open(path, 'w') do |f|
          encoding = response.headers['content-encoding'].to_s
          if encoding.present?
            case encoding
            when 'gzip'
              body = Zlib::GzipReader.wrap(StringIO.new(body), &:read)
            else
              raise Informative, "CDN: #{name} URL couldn't be saved: #{file_remote_url} Content encoding: #{response.headers['content-encoding']}"
            end
          end

          f.write(body&.force_encoding('UTF-8'))
        end

        etag_new = response.headers['etag']
        debug "CDN: #{name} Relative path downloaded: #{partial_url}, save ETag: #{etag_new}"
        File.open(etag_path, 'w') { |f| f.write(etag_new) } unless etag_new.nil?
      when 404
        debug "CDN: #{name} Relative path couldn't be downloaded: #{partial_url} Response: #{response.status}"
        nil
      when 502, 503, 504
        # Retryable HTTP errors, usually related to server overloading
        message = "CDN: #{name} URL couldn't be downloaded: #{file_remote_url} Response: #{response.status} #{body}"
        if retries <= 1
          raise Informative, message
        else
          debug message + ", retries: #{retries - 1}"
          make_sleep backoff_time(retries)
          download_and_save_with_retries_async(partial_url, file_remote_url, etag, retries - 1)
        end
      else
        raise Informative, "CDN: #{name} URL couldn't be downloaded: #{file_remote_url} Response: #{response.status} #{body}"
      end
    end

    def make_download(file_remote_url, etag = nil)
      headers = [
        %w[Accept-Encoding gzip],
      ]

      unless etag.nil?
        headers << ['If-None-Match', etag]
      end

      begin
        netrc_info = Netrc.read
        netrc_host = URI.parse(file_remote_url).host
        credentials = netrc_info[netrc_host]
        if credentials
          user, pass = credentials
          headers << ['Authorization', Protocol::HTTP::Header::Authorization.basic(user, pass)]
        end
      rescue Netrc::Error => e
        raise Informative, "CDN: #{e.message}"
      end

      http_client.get file_remote_url, headers
    end

    def make_sleep(retries)
      Async::Task.current.sleep backoff_time(retries)
    end

    def backoff_time(retries)
      current_retry = MAX_NUMBER_OF_RETRIES - retries
      4 * 2**current_retry
    end

    def debug(message)
      if defined?(Pod::UI)
        Pod::UI.message(message)
      else
        CoreUI.puts(message)
      end
    end

    def concurrent_requests_catching_errors
      errors = []
      results = []

      Sync do |task|
        barrier = Async::Barrier.new(:parent => task)

        yield barrier

        barrier.tasks.each do |child|
          results << child.result
        rescue ::StandardError => e
          errors << e
        end
      end

      if errors.any?      
        raise Informative, "CDN: #{name} Repo update failed - #{errors.size} error(s):\n#{errors.join("\n")}"
      end

      results
    end
  end
end
