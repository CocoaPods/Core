# -*- encoding: utf-8 -*-
$:.unshift File.expand_path('../lib', __FILE__)
require 'version'

Gem::Specification.new do |s|
  s.name     = "cocoapods-core"
  s.version  = Pod::VERSION
  s.date     = Date.today
  s.license  = "MIT"
  s.email    = ["eloy.de.enige@gmail.com", "fabiopelosin@gmail.com"]
  s.homepage = "https://github.com/CocoaPods/CocoaPods"
  s.authors  = ["Eloy Duran", "Fabio Pelosin"]

  s.summary     = "The models of CocoaPods"
  # s.description = "CocoaPods manages library dependencies for your Xcode project.\n\n"     \
  #                 "You specify the dependencies for your project in one easy text file. "  \
  #                 "CocoaPods resolves dependencies between libraries, fetches source "     \
  #                 "code for the dependencies, and creates and maintains an Xcode "         \
  #                 "workspace to build your project.\n\n"                                   \
  #                 "Ultimately, the goal is to improve discoverability of, and engagement " \
  #                 "in, third party open-source libraries, by creating a more centralized " \
  #                 "ecosystem."

  s.files = Dir["lib/**/*.rb"] + %w{ README.md LICENSE }

  s.require_paths = %w{ lib }

  s.add_runtime_dependency 'activesupport', '~> 3.2.6'
  s.add_runtime_dependency 'faraday',       '~> 0.8.1'
  s.add_runtime_dependency 'octokit',       '~> 1.7'

  s.add_development_dependency 'bacon', '~> 1.1'

  ## Make sure you can build the gem on older versions of RubyGems too:
  s.rubygems_version = "1.6.2"
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.specification_version = 3 if s.respond_to? :specification_version
end
