source "http://rubygems.org"

gemspec

# Ruby 1.8.7
gem "mime-types", "< 2.0"

group :development do
  gem 'coveralls', :require => false
  gem "mocha", "~> 0.11.4"
  gem "bacon"
  gem "mocha-on-bacon"
  gem "rake"
  gem 'prettybacon', :git => 'https://github.com/irrationalfab/PrettyBacon.git', :branch => 'master'
  gem 'rubocop'
end

group :debugging do
  gem "rb-fsevent"
  gem "kicker", :git => "https://github.com/alloy/kicker.git", :branch => "3.0.0"
  gem "awesome_print"
  gem "pry"
end

group :documentation do
  gem 'yard'
  gem 'redcarpet'
  gem 'github-markup'
  gem 'pygments.rb'
end
