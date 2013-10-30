# The Pod modules name-spaces all the classes of CocoaPods.
#
module Pod

  require 'cocoapods-core/gem_version'

  # Indicates a runtime error **not** caused by a bug.
  #
  class PlainInformative < StandardError; end

  # Indicates an user error.
  #
  class Informative < PlainInformative; end

  require 'pathname'
  require 'cocoapods-core/vendor'

  autoload :Version,        'cocoapods-core/version'
  autoload :Requirement,    'cocoapods-core/requirement'
  autoload :Dependency,     'cocoapods-core/dependency'

  autoload :CoreUI,         'cocoapods-core/core_ui'
  autoload :DSLError,       'cocoapods-core/standard_error'
  autoload :GitHub,         'cocoapods-core/github'
  autoload :Lockfile,       'cocoapods-core/lockfile'
  autoload :Platform,       'cocoapods-core/platform'
  autoload :Podfile,        'cocoapods-core/podfile'
  autoload :Source,         'cocoapods-core/source'
  autoload :Specification,  'cocoapods-core/specification'
  autoload :StandardError,  'cocoapods-core/standard_error'
  autoload :YAMLConverter,  'cocoapods-core/yaml_converter'

  # TODO: Fix
  #
  Spec = Specification

end
