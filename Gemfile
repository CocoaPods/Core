source 'http://rubygems.org'

gemspec

group :development do
  gem 'bacon'
  gem 'mocha'
  gem 'mocha-on-bacon'
  gem 'prettybacon'
  gem 'rake'
  gem 'vcr'
  gem 'webmock'

  if RUBY_VERSION >= '1.9.3'
    gem 'codeclimate-test-reporter', :require => nil
    gem 'rubocop'
  end
end

group :debugging do
  gem 'awesome_print'
  gem 'kicker'
  gem 'pry'
  gem 'rb-fsevent'
end

group :ruby_1_8_7 do
  gem 'activesupport', '< 4'
  gem 'mime-types', '< 2.0'
end
