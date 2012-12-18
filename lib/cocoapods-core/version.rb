module Pod

  # The Version class stores information about the version of a
  # {Specification}.
  #
  # It is based on the RubyGems
  # [Gem::Version](https://github.com/rubygems/rubygems/blob/master/lib/rubygems/version.rb)
  # [docs](http://rubygems.rubyforge.org/rubygems-update/Gem/Version.html)
  # adapted to support head information.
  #
  # ### From RubyGems:
  #
  # The Version class processes string versions into comparable
  # values. A version string should normally be a series of numbers
  # separated by periods. Each part (digits separated by periods) is
  # considered its own number, and these are used for sorting. So for
  # instance, 3.10 sorts higher than 3.2 because ten is greater than
  # two.
  #
  # If any part contains letters (currently only a-z are supported) then
  # that version is considered prerelease. Versions with a prerelease
  # part in the Nth part sort less than versions with N-1
  # parts. Prerelease parts are sorted alphabetically using the normal
  # Ruby string sorting rules. If a prerelease part contains both
  # letters and numbers, it will be broken into multiple parts to
  # provide expected sort behavior (1.0.a10 becomes 1.0.a.10, and is
  # greater than 1.0.a9).
  #
  # Prereleases sort between real releases (newest to oldest):
  #
  # 1. 1.0
  # 2. 1.0.b1
  # 3. 1.0.a.2
  # 4. 0.9
  #
  class Version < Gem::Version

    # @return [Bool] whether the version represents the `head` of repository.
    #
    attr_accessor :head
    alias_method  :head?, :head

    # @param  [String,Version] version
    #         A string reppresenting a version, or another version.
    #
    # @todo   The `from` part of the regular expression should be remove in
    #         CocoaPods 1.0.0.
    #
    def initialize version
      if version.is_a?(Version) && version.head?
        version = version.version
        @head = true
      elsif version.is_a?(String) && version =~ /HEAD (based on|from) (.*)/
        version = $2
        @head = true
      end
      super(version)
    end

    # @return [String] a string representation that indicates if the version is
    #         head.
    #
    # @note   The raw version string is still accessible with the {#version}
    #         method.
    #
    def to_s
      head? ? "HEAD based on #{super}" : super
    end

    # @return [String] a string representation suitable for debugging.
    #
    def inspect
      "<#{self.class} version=#{self.version}>"
    end
  end
end

