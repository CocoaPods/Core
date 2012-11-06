require 'pathname'
ROOT = Pathname.new(File.expand_path('../../', __FILE__))
$:.unshift((ROOT + 'lib').to_s)
require 'cocoapods-core'

namespace :doc do
  task :load do
    unless (ROOT + 'rakelib/doc').exist?
      Dir.chdir(ROOT + 'rakelib') do
        sh "git clone https://github.com/CocoaPods/cocoapods.github.com doc"
      end
    end
    require ROOT + 'rakelib/doc/lib/doc'
  end

  desc 'Update vendor doc repo'
  task :update do
    Dir.chdir(ROOT + 'rakelib/doc') do
      sh "git checkout *.html"
      sh "git pull"
    end
  end

  desc 'Generate docs and push to remote'
  task :release => [:update, :generate] do
    Dir.chdir(ROOT + 'rakelib/doc') do
      sh "git add *.html"
      sh "git commit -m 'Update specification.html'"
      sh "git push"
    end
  end

  task :generate => :load do
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

      end
    end

    dsl_file = (ROOT + 'lib/cocoapods-core/specification/dsl.rb').to_s
    generator = Pod::Doc::Specification.new(dsl_file)
    generator.render
    sh "open '#{generator.output_file}'"
  end
end

desc "Genereates the documentation"
task :doc => 'doc:generate'
