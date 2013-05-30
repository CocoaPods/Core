# Travis support

def rvm_ruby_dir
  @rvm_ruby_dir ||= File.expand_path('../..', `which ruby`.strip)
end

namespace :travis do
  task :setup do
    sh "git submodule update --init"
    sh "env CFLAGS='-I#{rvm_ruby_dir}/include' bundle install --without debugging documentation"
  end
end

namespace :gem do
  def gem_version
    require File.expand_path('../lib/cocoapods-core/gem_version', __FILE__)
    Pod::CORE_VERSION
  end

  def gem_filename
    "cocoapods-core-#{gem_version}.gem"
  end

  desc "Build a gem for the current version"
  task :build do
    sh "gem build cocoapods-core.gemspec"
  end

  desc "Install a gem version of the current code"
  task :install => :build do
    sh "gem install #{gem_filename}"
  end

  def silent_sh(command)
    output = `#{command} 2>&1`
    unless $?.success?
      puts output
      exit 1
    end
    output
  end

  desc "Run all specs, build and install gem, commit version change, tag version change, and push everything"
  task :release do

    unless ENV['SKIP_CHECKS']
      if `git symbolic-ref HEAD 2>/dev/null`.strip.split('/').last != 'master'
        $stderr.puts "[!] You need to be on the `master' branch in order to be able to do a release."
        exit 1
      end

      if `git tag`.strip.split("\n").include?(gem_version)
        $stderr.puts "[!] A tag for version `#{gem_version}' already exists. Change the version in lib/cocoapods-core/.rb"
        exit 1
      end

      puts "You are about to release `#{gem_version}', is that correct? [y/n]"
      exit if $stdin.gets.strip.downcase != 'y'

      diff_lines = `git diff --name-only`.strip.split("\n")

      if diff_lines.size == 0
        $stderr.puts "[!] Change the version number yourself in lib/cocoapods-core/gem_version.rb"
        exit 1
      end

      diff_lines.delete('Gemfile.lock')
      if diff_lines != ['lib/cocoapods-core/gem_version.rb']
        $stderr.puts "[!] Only change the version number in a release commit!"
        $stderr.puts diff_lines
        exit 1
      end
    end

    require 'date'

    # Ensure that the branches are up to date with the remote
    sh "git pull"

    puts "* Updating Bundler"
    silent_sh('bundle update')

    puts "* Running specs"
    silent_sh('rake spec:all')

    # puts "* Checking compatibility with the master repo"
    # silent_sh('rake spec:repo')

    tmp = File.expand_path('../tmp', __FILE__)
    tmp_gems = File.join(tmp, 'gems')

    Rake::Task['gem:build'].invoke

    puts "* Testing gem installation (tmp/gems)"
    silent_sh "rm -rf '#{tmp}'"
    silent_sh "gem install --install-dir='#{tmp_gems}' #{gem_filename}"

    # Then release
    sh "git commit lib/cocoapods-core/gem_version.rb -m 'Release #{gem_version}'"
    sh "git tag -a #{gem_version} -m 'Release #{gem_version}'"
    sh "git push origin master"
    sh "git push origin --tags"
    sh "gem push #{gem_filename}"

  end
end

namespace :spec do
  def specs(dir)
    FileList["spec/#{dir}/*_spec.rb"].shuffle.join(' ')
  end

  desc "Automatically run specs for updated files"
  task :kick do
    exec "bundle exec kicker -c"
  end

  task :all do
    ENV['GENERATE_COVERAGE'] = 'true'
    sh "bundle exec bacon #{specs('**')}"
  end

  desc "Checks that the gem is campable of loading all the specs of the master repo."
  task :repo do
    puts "Checking compatibility with master repo"
    require 'pathname'
    root = Pathname.new(File.expand_path('../', __FILE__))
    $:.unshift((root + 'lib').to_s)
    require 'cocoapods-core'

    master_repo_path       =  ENV['HOME'] + "/.cocoapods/master"
    glob_pattern           =  (master_repo_path + "/**/*.podspec").to_s
    total_count            =  0
    incompatible_count     =  0
    spec_with_errors_count =  0
    specs                  =  []

    Dir.glob(glob_pattern).each do |filename|
      Pathname(filename)
      begin
        total_count += 1
        specs << Pod::Specification.from_file(Pathname(filename))
      rescue Exception => e
        incompatible_count += 1
        puts "\n\e[1;33m"
        puts e.class
        puts "\e[0m\n"
        puts e.message
        puts
        puts e.backtrace.reject { |l| !l.include?(Dir.pwd) || l.include?('/Rakefile')}
        FALSE
      end
    end

    puts "\n\n---\n"
    specs.each do |s|
      linter = Pod::Specification::Linter.new(s)
      linter.lint
      unless linter.errors.empty?
        spec_with_errors_count += 1
        puts "\n#{s.name} #{s.version}"
        results = linter.errors.map do |r|
          if r.type == :error then "\e[1;33m  #{r.to_s}\e[0m"
          else "  " + r.to_s end
        end
        puts results * "\n"
      end
    end

    puts
    if incompatible_count.zero? && spec_with_errors_count.zero?
      message = "#{total_count} podspecs analyzed. All compatible."
      puts "\e[1;32m#{message}\e[0m" # Print in green
    else
      message = "#{incompatible_count} podspecs out of #{total_count} did fail to load."
      message << "\n#{spec_with_errors_count} podspecs presents errors."
      STDERR.puts "\e[1;31m#{message}\e[0m" # Print in red
      exit 1
    end
  end
end

desc "Initializes your working copy to run the specs"
task :bootstrap do
  puts "Updating submodules..."
  `git submodule update --init --recursive`

  puts "Installing gems"
  `bundle install`
end


desc "Run all specs"
task :spec => 'spec:all'

task :default => :spec
