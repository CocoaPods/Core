source 'https://rubygems.org'

gemspec

# This is the version that ships with OS X 10.10, so be sure we test against it.
# At the same time, the 1.7.7 version won't install cleanly on Ruby > 2.2,
# so we use a fork that makes a trivial change to a macro invocation.
gem 'json', :git => 'https://github.com/segiddins/json.git', :branch => 'seg-1.7.7-ruby-2.2'

group :development do
  gem 'activesupport', '>= 4.0.2', '< 5' # Pinned < 5 to ensure we're speccing 4.x.x
  gem 'public_suffix', '>= 2.0.5', '< 3' # pinned since 3+ drops support for Ruby 2.0
  gem 'minitest', '5.12.0' # Pinned since > 5.12.0+ drops support for Ruby 2.0
  gem 'bacon'
  gem 'mocha'
  gem 'mocha-on-bacon'
  gem 'prettybacon'
  gem 'rake'
  gem 'vcr'
  gem 'webmock'

  gem 'codeclimate-test-reporter', '~> 0.4.1', :require => nil
  gem 'rubocop', '~> 0.38.0'
end

group :debugging do
  gem 'awesome_print'
  gem 'kicker'
  gem 'pry'
  gem 'rb-fsevent'
end
