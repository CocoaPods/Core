require 'pathname'
ROOT = Pathname.new(File.expand_path('../../', __FILE__))
$:.unshift((ROOT + 'lib').to_s)
require 'cocoapods-core'
require 'active_support'
namespace :doc do
  task :load do
    unless (ROOT + 'rakelib/doc').exist?
      Dir.chdir(ROOT + 'rakelib') do
        sh "git clone git@github.com:CocoaPods/cocoapods.github.com.git doc"
      end
    end
    require ROOT + 'rakelib/doc/lib/doc'
  end

  desc 'Update vendor doc repo'
  task :update do
    Dir.chdir(ROOT + 'rakelib/doc') do
      sh "git checkout **/*.html"
      sh "git pull"
    end
  end

  desc 'Generate docs and push to remote'
  task :release => [:update, :generate] do
    Dir.chdir(ROOT + 'rakelib/doc') do
      sh "git add **/*.html"
      sh "git commit -m 'Update CocoaPods-Core Docs.'"
      sh "git push"
    end
  end

  task :dsl => :load do
    module Pod
      module Doc

        class Specification < DSL
          def group_sort_order
            [
              ['Root specification'],
              ['File patterns', 'Dependencies'],
              ['Build configuration'],
              ['Platform', 'Multi-Platform support', 'Hooks']
            ]
          end
        end

        class Podfile < DSL
          def group_sort_order
            [
              ['Dependencies'],
              ['Target configuration'],
              ['Workspace'],
              ['Hooks'],
            ]
          end
        end

      end
    end

    # Specification
    dsl_file = (ROOT + 'lib/cocoapods-core/specification/dsl.rb').to_s
    generator = Pod::Doc::Specification.new(dsl_file)
    generator.render

    # Podfile
    dsl_file = (ROOT + 'lib/cocoapods-core/podfile/dsl.rb').to_s
    generator = Pod::Doc::Podfile.new(dsl_file)
    generator.render
  end

  task :gem => :load do
    generator = Pod::Doc::Gem.new(ROOT + 'cocoapods-core.gemspec')
    generator.github_name = 'Core'
    generator.root_module = 'Pod'
    generator.render
  end

  task :generate => [:dsl, :gem]
end

desc "Genereates the documentation"
task :doc => 'doc:generate' do
  sh 'open rakelib/doc/index.html'
end
