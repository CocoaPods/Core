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
    require File.expand_path('../lib/cocoapods', __FILE__)
    Pod::VERSION
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
        $stderr.puts "[!] A tag for version `#{gem_version}' already exists. Change the version in lib/cocoapods.rb"
        exit 1
      end

      puts "You are about to release `#{gem_version}', is that correct? [y/n]"
      exit if $stdin.gets.strip.downcase != 'y'

      diff_lines = `git diff --name-only`.strip.split("\n")

      if diff_lines.size == 0
        $stderr.puts "[!] Change the version number yourself in lib/cocoapods.rb"
        exit 1
      end

      diff_lines.delete('Gemfile.lock')
      diff_lines.delete('CHANGELOG.md')
      if diff_lines != ['lib/cocoapods.rb']
        $stderr.puts "[!] Only change the version number in a release commit!"
        # exit 1
      end
    end

    require 'date'

    # First check if the required Xcodeproj gem has ben pushed
    gem_spec = eval(File.read(File.expand_path('../cocoapods.gemspec', __FILE__)))
    xcodeproj = gem_spec.dependencies.find { |d| d.name == 'xcodeproj' }
    required_xcodeproj_version = xcodeproj.requirement.requirements.first.last.to_s

    puts "* Checking if xcodeproj #{required_xcodeproj_version} exists on the gem host"
    search_result = silent_sh("gem search --pre --remote xcodeproj")
    remote_xcodeproj_versions = search_result.match(/xcodeproj \((.*)\)/m)[1].split(', ')
    unless remote_xcodeproj_versions.include?(required_xcodeproj_version)
      $stderr.puts "[!] The Xcodeproj version `#{required_xcodeproj_version}' required by " \
                   "this version of CocoaPods does not exist on the gem host. " \
                   "Either push that first, or fix the version requirement."
      exit 1
    end

    # Ensure that the branches are up to date with the remote
    sh "git pull"

    puts "* Running specs"
    silent_sh('rake spec:all')

    puts "* Checking compatibility with the master repo"
    silent_sh('rake spec:repo')

    tmp = File.expand_path('../tmp', __FILE__)
    tmp_gems = File.join(tmp, 'gems')

    Rake::Task['gem:build'].invoke

    puts "* Testing gem installation (tmp/gems)"
    silent_sh "rm -rf '#{tmp}'"
    silent_sh "gem install --install-dir='#{tmp_gems}' #{gem_filename}"

    # puts "* Building examples from gem (tmp/gems)"
    # ENV['GEM_HOME'] = ENV['GEM_PATH'] = tmp_gems
    # ENV['PATH']     = "#{tmp_gems}/bin:#{ENV['PATH']}"
    # ENV['FROM_GEM'] = '1'
    # silent_sh "rake examples:build"

    # Then release
    sh "git commit lib/cocoapods.rb Gemfile.lock CHANGELOG.md -m 'Release #{gem_version}'"
    sh "git tag -a #{gem_version} -m 'Release #{gem_version}'"
    sh "git push origin master"
    sh "git push origin --tags"
    sh "gem push #{gem_filename}"

    # Update the last version in CocoaPods-version.yml
    puts "* Updating last known version in Specs repo"
    specs_branch = 'master'
    Dir.chdir('../Specs') do
      puts Dir.pwd
      sh "git checkout #{specs_branch}"
      sh "git pull"

      yaml_file  = 'CocoaPods-version.yml'
      unless File.exist?(yaml_file)
        $stderr.puts "[!] Unable to find #{yaml_file}!"
        exit 1
      end
      require 'yaml'
      cocoapods_version = YAML.load_file(yaml_file)
      cocoapods_version['last'] = gem_version
      File.open(yaml_file, "w") do |f|
        f.write(cocoapods_version.to_yaml)
      end

      sh "git commit #{yaml_file} -m 'CocoaPods release #{gem_version}'"
      sh "git push"
    end
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
    sh "bundle exec bacon #{specs('**')}"
  end

  desc "Checks that the gem is campable of loading all the specs of the master repo."
  task :repo do
    puts "Checking compatibility with master repo"
    require 'pathname'
    ROOT = Pathname.new(File.expand_path('../', __FILE__))
    $:.unshift((ROOT + 'lib').to_s)
    require 'cocoapods-core'

    glob_pattern = (ROOT + "spec/fixtures/spec-repos/master/**/*.podspec").to_s
    total_count = 0
    incompatible_count = 0
    Dir.glob(glob_pattern).each do |filename|
      Pathname(filename)
      begin
        total_count += 1
        Pod::Specification.from_file(Pathname(filename))
      rescue Exception => e
        incompatible_count += 1
        puts "\n\e[1;33m"
        puts e.class
        puts "\e[0m\n"
        puts e.message
        puts
        puts e.backtrace
        clean = FALSE
      end
    end
    puts
    if incompatible_count.zero?
      message = "#{total_count} podspecs analyzed. All compatible."
      puts "\e[1;32m#{message}\e[0m" # Print in green
    else
      message = "#{incompatible_count} podspecs out of #{total_count} are NOT compatible with the master repo."
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
