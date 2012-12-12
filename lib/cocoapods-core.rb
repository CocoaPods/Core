# The Pod modules name-spaces all the classes of CocoaPods.
#
module Pod
end

require 'rubygems'

# Better to fail early and clearly than during installation of pods.
#
# RubyGems 1.3.6 (which ships with OS X >= 10.7) up to 1.4.0 have a couple of
# bugs related to the comparison of pre-release versions.
#
# As the user needs to update, anyway, the 1.6 version is required which
# includes already includes `Dependency#merge`
#
# E.g. https://github.com/CocoaPods/CocoaPods/issues/398
#
unless Gem::Version::Requirement.new('>= 1.6.0').satisfied_by?(Gem::Version.new(Gem::VERSION))
  message = "Your RubyGems version (#{Gem::VERSION}) is too old, please update with: `gem update --system`"
  STDERR.puts "\e[1;31m#{message}\e[0m" # Print in red
  exit 1
end

require 'version'
require 'pathname'

require 'cocoapods-core/standard_error'
require 'cocoapods-core/version'
require 'cocoapods-core/dependency'
require 'cocoapods-core/platform'
require 'cocoapods-core/source'
require 'cocoapods-core/specification'
require 'cocoapods-core/podfile'
require 'cocoapods-core/lockfile'
