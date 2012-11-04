
class DSLMethod
  attr_accessor :name
  attr_accessor :description
  attr_accessor :examples
  attr_accessor :group
  attr_accessor :group_description
  attr_accessor :attribute
end

class DSLGroup
  attr_accessor :name
  attr_accessor :description
  attr_accessor :methods
end

require 'pathname'
ROOT = Pathname.new(File.expand_path('../../', __FILE__))
$:.unshift((ROOT + 'lib').to_s)
require 'cocoapods-core'
require 'yard'
require 'redcarpet'

#-----------------------------------------------------------------------------#

  # TODO: the header needs better stacking
  # TODO: some methods should be moved out of the dsl.rb class
  # TODO: not all attribute readers could have been filtered
  # TODO: show default values
  # TODO: indicate if the attribute is multi-platform
  # TODO: indicate if the attribute is required

#-----------------------------------------------------------------------------#

desc "Genereates the documentation"
task :doc do

  attributes = Pod::Specification.attributes

  #-----------------------------------------------------------------------------#

  dsl_file = (ROOT + 'lib/cocoapods-core/specification/dsl.rb').to_s
  YARD::Registry.load([dsl_file], true)

  yard_methods = YARD::Registry.all(:method)
  attributes = Pod::Specification.attributes
  markdown   = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  groups     = []
  methods    = []

  yard_methods.each do |yard_method|
    group_name = yard_method.group.lines.first.chomp.gsub('DSL: ','').gsub(' attributes','')
    group = groups.find { |g| g.name == group_name }
    unless group
      groups << group = DSLGroup.new
      group.methods = []
      group.name = group_name
      group.description = markdown.render(yard_method.group.lines.drop(1) * "\n")
    end

    # filter attribute readers
    name = yard_method.name.to_s.gsub('=','')
    unless methods.find {|m| m.name == name }
      methods << method = DSLMethod.new
      group.methods << method
      method.name        = name
      method.group       = group
      method.description = markdown.render(yard_method.docstring)
      method.examples    = yard_method.docstring.tags(:example).map {|e| e.text.strip }
      method.attribute   = attributes.find { |a| a.writer_name == yard_method.name }
    end
  end

  groups.unshift(groups.delete(groups.find { |g| g.name == 'Regular' }))
  groups.unshift(groups.delete(groups.find { |g| g.name == 'Root specification' }))

  cocoapods_core_version = Pod::CORE_VERSION

  #-----------------------------------------------------------------------------#

  require 'erb'
  html_file = ROOT + 'doc/specification.html'
  template  = ERB.new(File.open(ROOT + 'doc/template.erb', 'rb').read)
  File.open(html_file, 'w+') { |f| f.puts(template.result(binding)) }
  `open #{html_file}`

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
