module Pod

  # A Requirement is a set of one or more version restrictions of a
  # {Dependency}.
  #
  # It is based on the RubyGems class adapted to support CocoaPods specific
  # information.
  #
  # @todo Move support about external sources and head information here from
  #       the Dependency class.
  #
  class Requirement < Pod::Vendor::Gem::Requirement
  end

end
