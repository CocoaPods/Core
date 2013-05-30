
# Set up coverage analysis
#-----------------------------------------------------------------------------#

if ENV['CI'] || ENV['GENERATE_COVERAGE']
  require 'simplecov'
  require 'coveralls'

  if ENV['CI']
    SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  elsif ENV['GENERATE_COVERAGE']
    SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
  end
  SimpleCov.start do
    add_filter "/spec_helper/"
    add_filter "vendor"
  end
end

# Set up
#-----------------------------------------------------------------------------#

require 'pathname'
ROOT = Pathname.new(File.expand_path('../../', __FILE__))
$:.unshift((ROOT + 'lib').to_s)
$:.unshift((ROOT + 'spec').to_s)

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
