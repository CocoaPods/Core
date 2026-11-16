# Bootstrap
#-----------------------------------------------------------------------------#

desc 'Initializes your working copy to run the specs'
task :bootstrap do
  puts 'Updating submodules...'
  `git submodule update --init --recursive`

  if system('which bundle')
    puts 'Installing gems'
    `bundle install`
  else
    $stderr.puts "\033[0;31m" \
      "[!] Please install the bundler gem manually:\n" \
      '    $ [sudo] gem install bundler' \
      "\e[0m"
    exit 1
  end
end

begin

  require 'bundler/gem_tasks'

  # Travis support
  #-----------------------------------------------------------------------------#

  def rvm_ruby_dir
    @rvm_ruby_dir ||= File.expand_path('../..', `which ruby`.strip)
  end

  namespace :travis do
    task :setup do
      sh 'git submodule update --init'
      sh "env CFLAGS='-I#{rvm_ruby_dir}/include' bundle install --without debugging documentation"
    end
  end

  # Spec
  #-----------------------------------------------------------------------------#

  namespace :spec do
    desc 'Automatically run specs for updated files'
    task :kick do
      exec 'bundle exec kicker -c'
    end

    task :all do
      puts "\033[0;32mUsing #{`ruby --version`}\033[0m"

      title 'Running Unit Tests'
      sh 'bundle exec rspec'

      title 'Checking code style...'
      Rake::Task['rubocop'].invoke if RUBY_VERSION >= '1.9.3'
    end
  end

  desc 'Run all specs'
  task :spec => 'spec:all'

  #-- RuboCop ----------------------------------------------------------------#

  if RUBY_VERSION >= '1.9.3'
    require 'rubocop/rake_task'
    RuboCop::RakeTask.new
  end

  #---------------------------------------------------------------------------#

  task :default => :spec

rescue LoadError
  $stderr.puts "\033[0;31m" \
    '[!] Some Rake tasks haven been disabled because the environment' \
    ' couldn’t be loaded. Be sure to run `rake bootstrap` first.' \
    "\e[0m"
end

# Helpers
#-----------------------------------------------------------------------------#

def title(title)
  cyan_title = "\033[0;36m#{title}\033[0m"
  puts
  puts '-' * 80
  puts cyan_title
  puts '-' * 80
  puts
end
