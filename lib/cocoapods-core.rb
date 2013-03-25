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

  require 'cocoapods-core/version'
  require 'cocoapods-core/requirement'
  require 'cocoapods-core/dependency'

  require 'cocoapods-core/core_ui'
  require 'cocoapods-core/lockfile'
  require 'cocoapods-core/platform'
  require 'cocoapods-core/podfile'
  require 'cocoapods-core/source'
  require 'cocoapods-core/specification'
  require 'cocoapods-core/standard_error'
  require 'cocoapods-core/yaml_converter'

  # TODO: Temporary support for FileList
  #
  require 'rake'
  FileList = Rake::FileList
end


