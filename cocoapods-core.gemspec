# -*- encoding: utf-8 -*-
$:.unshift File.expand_path('../lib', __FILE__)
require 'version'

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

  s.add_runtime_dependency 'activesupport', '~> 3.2.6'
  s.add_runtime_dependency 'faraday',       '~> 0.8.1'
  s.add_runtime_dependency 'octokit',       '~> 1.7'

  s.add_development_dependency 'bacon', '~> 1.1'

  ## Make sure you can build the gem on older versions of RubyGems too:
  s.rubygems_version = "1.6.2"
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.specification_version = 3 if s.respond_to? :specification_version
end
