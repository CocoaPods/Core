require 'pathname'
ROOT = Pathname.new(File.expand_path('../../', __FILE__))
$:.unshift((ROOT + 'lib').to_s)
require 'cocoapods-core'


#-----------------------------------------------------------------------------#

# TODO: how `header_dir` and `header_mappings_dir` needs proper explanation.
# TODO: `requires_arc` should default to true
# TODO: Add a single dedicated tab for the labels?
# TODO: Requires ARC should default to true
# TODO: Inheritance and merge polices should be explained.
#     - When a subspec inherits an attribute as first defined?
#     - When a subspec inherits an attribute by merging?
#     - When a platform value is merged with the general one and when it
#       replaces it?

# TODO: Add the Podfile DSL.

#-----------------------------------------------------------------------------#

module Pod
  module Doc
    class Base
      attr_reader :source_file

      def initialize(source_file)
        @source_file = source_file
      end

      def sections
        %w{ Podfile Specification Commands }
      end

      def name
        self.class.name.split('::').last
      end

      def render(output_file)
        require 'erb'
        template = ERB.new(File.read(ROOT + 'doc/template.erb'))
        File.open(output_file, 'w') { |f| f.puts(template.result(binding)) }
      end

      # Helpers

      def markdown(input)
        @markdown ||= Redcarpet::Markdown.new(Class.new(Redcarpet::Render::HTML) do
          def block_code(code, lang)
            lang ||= 'ruby'
            Pod::Doc::DSL.syntax_highlight(code, lang)
          end
        end)
        @markdown.render(input)
      end

      def syntax_highlight(code)
        self.class.syntax_highlight(code)
      end

      def self.syntax_highlight(code, lang = 'ruby')
        Pygments.highlight(code, :lexer => lang, :options => { :encoding => 'utf-8' })
      end
    end

    class DSL < Base

      #------------------------------------------------------------------------#

      class Group
        attr_reader :methods

        def initialize(yard_group)
          @yard_group = yard_group
          @methods = []
        end

        def name
          @name ||= @yard_group.lines.first.chomp.gsub('DSL: ','').gsub(' attributes','')
        end

        def to_param
          "#{name.parameterize}-group"
        end

        def description
          @yard_group.lines.drop(1).join
        end

        def add_method(yard_method)
          method = Method.new(self, yard_method)
          @methods << method unless @methods.find { |m| m.name == method.name }
        end
      end

      #------------------------------------------------------------------------#

      class Method
        attr_accessor :group

        def initialize(group, yard_method)
          @group, @yard_method = group, yard_method
        end

        def name
          @name ||= @yard_method.name.to_s.sub('=','')
        end

        def to_param
          name
        end

        def description
          @yard_method.docstring
        end

        def examples
          @yard_method.docstring.tags(:example).map { |e| e.text.strip }
        end

        def default_values
          return [] unless attribute
          r = []
          r << "spec.#{attribute.writer_name.gsub('=',' =')} #{attribute.default_value.inspect}" if attribute.default_value
          r << "spec.ios.#{attribute.writer_name.gsub('=',' =')} #{attribute.ios_default.inspect}" if attribute.ios_default
          r << "spec.osx.#{attribute.writer_name.gsub('=',' =')} #{attribute.osx_default.inspect}" if attribute.osx_default
          r
        end

        def keys
          keys = attribute.keys if attribute
          keys ||= []
          if keys.is_a?(Hash)
            new_keys = []
            keys.each do |key, subkeys|
              if subkeys && !subkeys.empty?
                subkeys = subkeys.map { |key| "`:#{key.to_s}`" }
                new_keys << "`:#{key.to_s}` #{subkeys * " "}"
              else
                new_keys << "`:#{key.to_s}`"
              end
            end
            keys = new_keys
          else
            keys = keys.map { |key| "`:#{key.to_s}`" }
          end
          keys
        end

        def required?
          attribute.required? if attribute
        end

        def multi_platform?
          attribute.multi_platform? if attribute
        end

        # Might return `nil` in case this is a normal method, not an attribute.
        #
        # TODO fix for Podfile
        def attribute
          @attribute ||= Pod::Specification.attributes.find { |attr| attr.reader_name.to_s == name }
        end
      end

      #------------------------------------------------------------------------#

      def description
        yard_registry.at("Pod::#{name}").docstring
      end

      def group_sort_order
        []
      end

      def columns
        group_sort_order.map do |column|
          column.map do |group_name|
            if group = groups.find { |g| g.name == group_name }
              group
            else
              raise "Unable to find group with name: #{group_name}"
            end
          end
        end
      end

      def groups
        unless @groups
          @groups = []

          yard_registry.all(:method).each do |yard_method|
            group = Group.new(yard_method.group)
            if existing = @groups.find { |g| g.name == group.name }
              group = existing
            else
              @groups << group
            end
            method = group.add_method(yard_method)
          end
        end
        @groups
      end

      private

      def yard_registry
        @registry ||= begin
          YARD::Registry.load([@source_file], true)
          YARD::Registry
        end
      end
    end

    class Podfile < DSL
    end

    class Specification < DSL
      def group_sort_order
        [
          ['Root specification'],
          ['File pattern', 'Dependencies & Subspecs'],
          ['Regular'],
          ['Platform', 'Multi-Platform support', 'Hooks']
        ]
      end
    end

    class Commands < Base
    end
  end
end

desc "Genereates the documentation"
task :doc do
  require 'yard'
  require 'redcarpet'
  require 'pygments'

  dsl_file = (ROOT + 'lib/cocoapods-core/specification/dsl.rb').to_s
  html_file = ROOT + 'doc/specification.html'
  Pod::Doc::Specification.new(dsl_file).render(html_file)
  sh "open #{html_file}"
end

#-------------------------------------------------------------------------------#


# Generates markdown files for the documentation of the DSLs.
#
# Currently only the Specification DSL is supported.
#
# This task uses the comments and the attributes for genenarting the markdown.
#
# desc "Genereates the documentation"
# task :doc do
  # require 'pathname'
  # ROOT = Pathname.new(File.expand_path('../', __FILE__))
  # $:.unshift((ROOT + 'lib').to_s)
  # require 'cocoapods-core'
  # attributes = Pod::Specification.attributes

  # require 'yard'
  # YARD::Registry.load(['lib/cocoapods-core/specification/dsl.rb'], true)

  # markdown = []
  # attributes = Pod::Specification.attributes
  # root_spec_attributes = attributes.select { |a| a.root_only }
  # subspec_attributes   = attributes - root_spec_attributes

  # attributes_by_type = {}
  # attributes.each do |attrb|
  #   yard_object = YARD::Registry.at("Pod::Specification##{attrb.writer_name}")
  #   if yard_object
  #     group = yard_object.group.gsub('DSL: ','')
  #     attributes_by_type[group] ||= []
  #     attributes_by_type[group] << attrb
  #   end
  # end

  # # attributes_by_type = {
  # #   "Root specification attributes" => root_spec_attributes,
  # #   "Regular attributes" => subspec_attributes,
  # # }

  # markdown << "\n# Podspec attributes"

  # # Overview
  # markdown << "\n## Overview"
  # attributes_by_type.each do |type, attributes|
  #   markdown << "\n#### #{type}\n"
  #   markdown << "<table>"
  #   markdown << "  <tr>"
  #   attributes.each_with_index do |attrb, idx|
  #     markdown << "    <td><a href='##{attrb.name}'>#{attrb.name}</a></td>"
  #     markdown << "  </tr>\n  <tr>" if (idx + 1)% 3 == 0
  #   end
  #   markdown << "  </tr>"
  #   markdown << "</table>"
  # end

  # # Attributes details
  # attributes_by_type.each do |type, attributes|
  #   markdown << "\n## #{type}"
  #   attributes.each do |attrb|
  #     yard_object = YARD::Registry.at("Pod::Specification##{attrb.writer_name}")
  #     if yard_object
  #       description = yard_object.docstring
  #       examples = yard_object.docstring.tags(:example)
  #       markdown << "#### #{attrb.name.to_s.gsub('_', '\_')}"
  #       desc = attrb.required ? "[Required] " : " "
  #       markdown << desc + "#{description}\n"

  #       markdown << "This attribute supports multi-platform values.\n" if attrb.multi_platform
  #       if attrb.keys.is_a?(Array)
  #         markdown << "This attribute supports the following keys: `#{attrb.keys * '`, `'}`.\n"
  #       elsif attrb.keys.is_a?(Hash)
  #         string = "This attribute supports the following keys: "
  #         attrb.keys.each do |key, subkeys|
  #           string << "\n- `#{key}`"
  #           string << ": `#{subkeys * '`, `'}`\n" if subkeys
  #         end
  #         markdown << string
  #       end

  #       # markdown << "###### Default Value\n"

  #       markdown << "###### Examples\n"
  #       examples.each do |example|
  #         markdown << "```ruby"
  #         markdown << example.text.strip
  #         markdown << "```\n"
  #       end
  #     else
  #       puts "Unable to find documentation for `Pod::Specification##{attrb.writer_name}`"
  #     end
  #   end
  # end

  # doc = markdown * "\n"
  # File.open('doc/specification.md', 'w') {|f| f.write(doc) }
# end
