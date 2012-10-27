module Pod

  # The {Version} class stores information about the version of a
  # {Specification} . It is based on the RubyGems class
  # (http://rubygems.rubyforge.org/rubygems-update/Gem/Version.html) with minor
  # adaptations for CocoaPods.
  #
  class Version < Gem::Version

    # @return [Bool] whether the version represents the `head` of repository.
    #
    attr_accessor :head
    alias_method  :head?, :head

    # @return [String] a string representation that indicates if the version is
    #         head.
    #
    def to_s
      head? ? "HEAD based on #{super}" : super
    end

    # Initializes a version from a string obtained from the {Version#to_s}
    # method.
    #
    # @todo   The `from` part of the regular expression should be remove in
    #         CocoaPods 1.0.0.
    #
    # @return [Version] a new version.
    #
    def self.from_string(string)
      if string =~ /HEAD (based on|from) (.*)/
        v = Version.new($2)
        v.head = true
        v
      else
        Version.new(string)
      end
    end
  end
end

