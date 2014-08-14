source 'http://rubygems.org'

gemspec

group :development do
  gem 'mocha'
  gem 'bacon'
  gem 'mocha-on-bacon'
  gem 'rake'
  gem 'prettybacon'
  gem 'vcr'
  gem 'webmock', '< 1.16'

  if RUBY_VERSION >= '1.9.3'
    gem 'rubocop'
    gem 'codeclimate-test-reporter', :require => nil
    gem 'simplecov'
  end
end

group :debugging do
  gem 'rb-fsevent'
  gem 'kicker'
  gem 'awesome_print'
  gem 'pry'
end

group :ruby_1_8_7 do
  gem 'mime-types', '< 2.0'
  gem 'activesupport', '< 4'
end
