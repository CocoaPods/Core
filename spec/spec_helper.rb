
# Set up coverage analysis
#-----------------------------------------------------------------------------#

require 'simplecov'
require 'coveralls'

if ENV['CI']
  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
else
  SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
end
SimpleCov.start do
  add_filter "/spec_helper/"
  add_filter "vendor"
end

# Set up
#-----------------------------------------------------------------------------#

require 'pathname'
ROOT = Pathname.new(File.expand_path('../../', __FILE__))
$:.unshift((ROOT + 'lib').to_s)
$:.unshift((ROOT + 'spec').to_s)

require 'rubygems'
require 'bundler/setup'
require 'bacon'
require 'mocha-on-bacon'
require 'cocoapods-core'

# Helpers
#-----------------------------------------------------------------------------#

require 'spec_helper/bacon'
require 'spec_helper/fixture'
require 'spec_helper/temporary_directory'
require 'tmpdir'

Bacon.summary_at_exit

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
