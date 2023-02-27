source 'https://rubygems.org'

gemspec

# We still support Ruby 2.6 in CI for Core. ActiveSupport > 7 is Ruby 2.7.x.
gem 'activesupport', '>= 5.0', '< 7'

group :development do
  gem 'bacon'
  gem 'mocha', '< 1.5'
  gem 'mocha-on-bacon'
  gem 'prettybacon'
  gem 'rake', '~> 12.0'
  gem 'rexml', '~> 3.2.5'
  gem 'vcr'
  gem 'webmock'
  gem 'webrick', '~> 1.7.0'

  gem 'rubocop', '~> 1.8', :require => false
  gem 'rubocop-performance', :require => false
end

group :debugging do
  gem 'awesome_print'
  gem 'kicker'
  gem 'pry'
  gem 'rb-fsevent'
end
