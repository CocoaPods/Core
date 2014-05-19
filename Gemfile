source 'http://rubygems.org'

gemspec

# Ruby 1.8.7
gem 'mime-types', '< 2.0'
gem 'activesupport', '< 4'

group :development do
  # Simplecov is affecting bacon exit code
  gem 'mocha', '~> 0.11.4'
  gem 'bacon'
  gem 'mocha-on-bacon'
  gem 'rake'
  gem 'prettybacon'
  gem 'vcr'
  gem 'webmock', '< 1.16'

  if RUBY_VERSION >= '1.9.3'
    gem 'rubocop'

    gem 'codeclimate-test-reporter', :require => nil
    # Bug: https://github.com/colszowka/simplecov/issues/281
    gem 'simplecov', '0.7.1'
  end
end

group :debugging do
  gem 'rb-fsevent'
  gem 'kicker'
  gem 'awesome_print'
  gem 'pry'
end

group :documentation do
  gem 'yard'
  gem 'redcarpet'
  gem 'github-markup'
  gem 'pygments.rb'
end
