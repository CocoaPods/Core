# -*- encoding: utf-8 -*-
require File.expand_path('../lib/cocoapods-core/gem_version', __FILE__)
require 'date'

Gem::Specification.new do |s|
  s.name          =  "cocoapods-core"
  s.version       =  Pod::CORE_VERSION
  s.date          =  Date.today
  s.license       =  "MIT"
  s.email         =  ["eloy.de.enige@gmail.com", "fabiopelosin@gmail.com"]
  s.homepage      =  "https://github.com/CocoaPods/CocoaPods"
  s.authors       =  ["Eloy Duran", "Fabio Pelosin"]
  s.summary       =  "The models of CocoaPods"
  s.description   = "The CocoaPods-Core gem provides support to work with the models of "    \
                    "CocoaPods.\n\n "                                                        \
                    "It is intended to be used in place of the CocoaPods when the the "      \
                    "installation of the dependencies is not needed."                        \

  s.files         =  Dir["lib/**/*.rb"] + %w{ README.md LICENSE }
  s.require_paths =  %w{ lib }

  # 6.0 requires Ruby 2.5.0
  s.add_runtime_dependency 'activesupport', '> 5.0', '< 6'
  s.add_runtime_dependency 'nap', '~> 1.0'
  s.add_runtime_dependency 'fuzzy_match', '~> 2.0.4'
  s.add_runtime_dependency 'algoliasearch', '~> 1.0'
  s.add_runtime_dependency 'concurrent-ruby', '~> 1.1'
  s.add_runtime_dependency 'net-http2', '~> 0.18'
  s.add_runtime_dependency 'netrc', '~> 0.11'
  s.add_runtime_dependency "addressable", '~> 2.6'
  s.add_runtime_dependency "public_suffix"

  s.add_development_dependency 'bacon', '~> 1.1'

  ## Make sure you can build the gem on older versions of RubyGems too:
  s.rubygems_version = "1.6.2"
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.required_ruby_version = '>= 2.3.3'
  s.specification_version = 3 if s.respond_to? :specification_version
end
