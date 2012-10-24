require 'rubygems'
require 'bundler/setup'

require 'bacon'
require 'mocha-on-bacon'
Bacon.summary_at_exit

require 'pathname'
ROOT = Pathname.new(File.expand_path('../../', __FILE__))

$:.unshift((ROOT + 'lib').to_s)
require 'cocoapods'

$:.unshift((ROOT + 'spec').to_s)
require 'spec_helper/bacon'
require 'spec_helper/fixture'
require 'spec_helper/temporary_directory'
require 'spec_helper/temporary_repos'

require 'tmpdir'

module Bacon
  class Context
    include SpecHelper::Fixture
  end
end

def fixture_spec(name)
  file = SpecHelper::Fixture.fixture(name)
  Pod::Specification.from_file(file)
end

def copy_fixture_to_pod(name, pod)
  path = SpecHelper::Fixture.fixture(name)
  FileUtils.cp_r(path, pod.root)
end

SpecHelper::Fixture.fixture('banana-lib') # ensure it exists

require 'vcr'
require 'webmock'

VCR.configure do |c|
  # Namespace the fixture by the Ruby version, because different Ruby versions
  # can lead to different ways the data is interpreted.
  c.cassette_library_dir = (ROOT + "spec/fixtures/vcr/#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}").to_s
  c.hook_into :webmock # or :fakeweb
  c.allow_http_connections_when_no_cassette = true
end

