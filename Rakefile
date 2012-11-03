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
end

desc "Initializes your working copy to run the specs"
task :bootstrap do
  puts "Updating submodules..."
  `git submodule update --init --recursive`

  puts "Installing gems"
  `bundle install`
end

# Generates markdown files for the documentation of the DSLs.
#
# Currently only the Specification DSL is supported.
#
# This task uses the comments and the attributes for genenarting the markdown.
#
desc "Genereates the documentation"
task :doc do
  require 'pathname'
  ROOT = Pathname.new(File.expand_path('../', __FILE__))
  $:.unshift((ROOT + 'lib').to_s)
  require 'cocoapods-core'
  attributes = Pod::Specification.attributes

  require 'yard'
  YARD::Registry.load(['lib/cocoapods-core/specification/dsl.rb'], true)

  markdown = []
  attributes = Pod::Specification.attributes
  root_spec_attributes = attributes.select { |a| a.root_only }
  subspec_attributes   = attributes - root_spec_attributes

  attributes_by_type = {}
  attributes.each do |attrb|
    yard_object = YARD::Registry.at("Pod::Specification##{attrb.writer_name}")
    if yard_object
      group = yard_object.group.gsub('DSL: ','')
      attributes_by_type[group] ||= []
      attributes_by_type[group] << attrb
    end
  end

  # attributes_by_type = {
  #   "Root specification attributes" => root_spec_attributes,
  #   "Regular attributes" => subspec_attributes,
  # }

  markdown << "\n# Podspec attributes"

  # Overview
  markdown << "\n## Overview"
  attributes_by_type.each do |type, attributes|
    markdown << "\n#### #{type}\n"
    markdown << "<table>"
    markdown << "  <tr>"
    attributes.each_with_index do |attrb, idx|
      markdown << "    <td><a href='##{attrb.name}'>#{attrb.name}</a></td>"
      markdown << "  </tr>\n  <tr>" if (idx + 1)% 3 == 0
    end
    markdown << "  </tr>"
    markdown << "</table>"
  end

  # Attributes details
  attributes_by_type.each do |type, attributes|
    markdown << "\n## #{type}"
    attributes.each do |attrb|
      yard_object = YARD::Registry.at("Pod::Specification##{attrb.writer_name}")
      if yard_object
        description = yard_object.docstring
        examples = yard_object.docstring.tags(:example)
        markdown << "#### #{attrb.name.to_s.gsub('_', '\_')}"
        desc = attrb.required ? "[Required] " : " "
        markdown << desc + "#{description}\n"

        markdown << "This attribute supports multi-platform values.\n" if attrb.multi_platform
        if attrb.keys.is_a?(Array)
          markdown << "This attribute supports the following keys: `#{attrb.keys * '`, `'}`.\n"
        elsif attrb.keys.is_a?(Hash)
          string = "This attribute supports the following keys: "
          attrb.keys.each do |key, subkeys|
            string << "\n- `#{key}`"
            string << ": `#{subkeys * '`, `'}`\n" if subkeys
          end
          markdown << string
        end

        # markdown << "###### Default Value\n"

        markdown << "###### Examples\n"
        examples.each do |example|
          markdown << "```"
          indent = "\n" << " " * (attrb.writer_name.length + 4)
          example_text = example.text.gsub("\n", indent)
          writer_name = attrb.writer_name.to_s.gsub('=', ' =')
          on_platform = ''
          on_platform = 'ios.' if example.name.include?('iOS')
          on_platform = 'osx.' if example.name.include?('OS X')
          markdown << "s.#{on_platform}#{writer_name} #{example_text}"
          markdown << "```\n"
        end
      else
        puts "Unable to find documentation for `Pod::Specification##{attrb.writer_name}`"
      end
    end
  end

  doc = markdown * "\n"
  File.open('doc/specification.md', 'w') {|f| f.write(doc) }
end

desc "Run all specs"
task :spec => 'spec:all'

task :default => :spec
