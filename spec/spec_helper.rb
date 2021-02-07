
# Set up
#-----------------------------------------------------------------------------#

require 'pathname'
ROOT = Pathname.new(File.expand_path('../../', __FILE__))
$LOAD_PATH.unshift((ROOT + 'lib').to_s)
$LOAD_PATH.unshift((ROOT + 'spec').to_s)

require 'bundler/setup'
require 'bacon'
require 'mocha-on-bacon'
require 'pretty_bacon'
require 'cocoapods-core'

# Helpers
#-----------------------------------------------------------------------------#

require 'spec_helper/fixture'
require 'spec_helper/temporary_directory'

def fixture_spec(name)
  file = SpecHelper::Fixture.fixture(name)
  Pod::Specification.from_file(file)
end

def copy_fixture_to_pod(name, pod)
  path = SpecHelper::Fixture.fixture(name)
  FileUtils.cp_r(path, pod.root)
end

# VCR
#--------------------------------------#

require 'vcr'
VCR.configure do |c|
  c.cassette_library_dir = ROOT + 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.ignore_hosts 'codeclimate.com', 'localhost', 'cdn.cocoapods.org', 'raw.githubusercontent.com'
end

# CDN repo
#--------------------------------------#

require 'webrick'
CDN_MOCK_SERVER = WEBrick::HTTPServer.new(:BindAddress => '0.0.0.0',
                                          :Port => 4321,
                                          :DocumentRoot => ROOT + 'spec/fixtures/mock_cdn_repo_remote',
                                          :Logger => ENV['WEBRICK_DEBUG'].nil? ? WEBrick::Log.new('/dev/null') : nil,
                                          :AccessLog => ENV['WEBRICK_DEBUG'].nil? ? [] : nil,
                                         )
Thread.new do
  CDN_MOCK_SERVER.start
  Thread.current.exit
end

# Force CDNSource uses HTTP1, because WebMock doesn't support HTTP 2 yet
#--------------------------------------#

silence_warnings do
  Pod::CDNSource::FORCE_HTTP2 = false
end

# Silence the output
#--------------------------------------#

module Pod
  module CoreUI
    @output = ''
    @warnings = ''

    class << self
      attr_accessor :output
      attr_accessor :warnings
    end

    def self.puts(message)
      @output << message << "\n"
    end

    def self.print(message)
      @output << message
    end

    def self.warn(message)
      @warnings << message
    end
  end
end

# Configure Bacon
#--------------------------------------#

Bacon.summary_at_exit

module Bacon
  class Context
    include SpecHelper::Fixture

    old_run_requirement = instance_method(:run_requirement)
    define_method(:run_requirement) do |description, spec|
      ::Pod::CoreUI.output = ''
      ::Pod::CoreUI.warnings = ''
      old_run_requirement.bind(self).call(description, spec)
    end
  end
end

Mocha::Configuration.prevent(:stubbing_non_existent_method)
