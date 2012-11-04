require 'pathname'
ROOT = Pathname.new(File.expand_path('../../', __FILE__))
$:.unshift((ROOT + 'lib').to_s)
require 'cocoapods-core'


#-----------------------------------------------------------------------------#

  # TODO: the header needs better stacking
  # TODO: some methods should be moved out of the dsl.rb class
  # TODO: not all attribute readers could have been filtered
  # TODO: show default values
  # TODO: indicate if the attribute is multi-platform
  # TODO: indicate if the attribute is required

#-----------------------------------------------------------------------------#

module Pod
  module Doc
    class DSL
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

        def required?
          attribute.required? if attribute
        end

        def multi_platform?
          attribute.multi_platform? if attribute
        end

        # Might return `nil` in case this is a normal method, not an attribute.
        def attribute
          @attribute ||= Pod::Specification.attributes.find { |attr| attr.reader_name.to_s == name }
        end
      end

      attr_reader :source_file

      def initialize(source_file)
        @source_file = source_file
      end

      def description
        yard_registry.at('Pod::Specification').docstring
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

          @groups.unshift(@groups.delete(@groups.find { |g| g.name == 'Regular' }))
          @groups.unshift(@groups.delete(@groups.find { |g| g.name == 'Root specification' }))
        end
        @groups
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

      private

      def yard_registry
        @registry ||= begin
          YARD::Registry.load([@source_file], true)
          YARD::Registry
        end
      end
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
  Pod::Doc::DSL.new(dsl_file).render(html_file)
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
