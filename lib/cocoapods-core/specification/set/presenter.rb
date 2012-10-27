require 'active_support/core_ext/array/conversions'

module Pod
  class Specification
    class Set

      # Provides support for presenting a Pod described by a {Set} in a
      # consistent way across clients of CocoaPods-Core.
      #
      class Presenter

        # @return   [Set] the set that should be presented.
        #
        attr_accessor :set

        # @param    [Set] set @see #set.
        #
        def initialize(set)
          @set = set
        end

        #-----------------------------------------------------------------------#

        # @!group Set Information

        # @return   [String] the name of the Pod.
        #
        def name
          @set.name
        end

        # @return   [Version] the highest version of available for the Pod.
        #
        def version
          @set.versions.first
        end

        # @return   [Array<Version>] all the versions available sorted
        #           ascendingly.
        #
        def versions
          @set.versions.sort.reverse
        end

        # @return   [String] all the versions available sorted from the highest
        #           to the lowest.
        #
        # @example  Return example
        #
        #           "1.5pre, 1.4 [master repo] - 1.4 [test_repo repo]"
        #
        def verions_by_source
          result = []
          @set.versions_by_source.each do |source, versions|
            result << "#{versions.map(&:to_s) * ', '} [#{source.name} repo]"
          end
          result * ' - '
        end

        # @return [Array<String>] The name of the sources that contain the Pod
        #         sorted alphabetically.
        #
        def sources
          @set.sources.map(&:name).sort
        end

        #-----------------------------------------------------------------------#

        # @!group Specification Information

        # @return [Specification] the specification of the {Set}. If no
        #         versions requirements where passed to the set it returns the
        #         highest available version.
        #
        def spec
          @set.specification
        end

        # @return [String] the list of the authors of the Pod in sentence
        #         format.
        #
        # @example
        #
        #   "Author 1, Author 2 and Author 3"
        #
        def authors
          spec.authors ? spec.authors.keys.to_sentence : ''
        end

        # @return [String] the homepage of the pod.
        #
        def homepage
          spec.homepage
        end

        # @return [String] the description of the Pod, if no description is
        #         available the summary is returned.
        #
        # TODO: the specification logic should me moved here.
        #
        def description
          spec.description
        end

        # @return [String] a short description, expected to be 140 characters
        #         long of the Pod.
        #
        def summary
          spec.summary
        end

        # @return [String] the URL of the source of the Pod.
        #
        # TODO: improve support for non git sources.
        #
        def source_url
          spec.source.reject {|k,_| k == :commit || k == :tag }.values.first
        end

        # @return [String] the platforms supported by the Pod.
        #
        # @example
        #
        #   "iOS"
        #   "iOS - OS X"
        #
        def platform
          spec.available_platforms.sort { |a,b| a.to_s.downcase <=> b.to_s.downcase }.join(' - ')
        end

        # @return [String] the type of the license of the Pod.
        #
        # @example
        #
        #   "MIT"
        #
        def license
          spec.license[:type] if spec.license
        end

        # @return [Array] an array containing all the subspecs of the Pod.
        #
        def subspecs
          (spec.recursive_subspecs.any? && spec.recursive_subspecs) || nil
        end

        #-----------------------------------------------------------------------#

        # @!group Statistics

        # @return [Time] the creation date of the first known `podspec` of the
        #         Pod.
        #
        def creation_date
          Pod::Specification::Statistics.instance.creation_date(@set)
        end

        # @return [Integer] the GitHub likes of the repo of the Pod.
        #
        def github_watchers
          Pod::Specification::Statistics.instance.github_watchers(@set)
        end

        # @return [Integer] the GitHub forks of the repo of the Pod.
        #
        def github_forks
          Pod::Specification::Statistics.instance.github_forks(@set)
        end

        # @return [String] the relative time of the last push of the repo the Pod.
        #
        def github_last_activity
          distance_from_now_in_words(Pod::Specification::Statistics.instance.github_pushed_at(@set))
        end

        #-----------------------------------------------------------------------#

        def ==(other)
          self.class === other && @set == other.set
        end

        def eql?(other)
          self.class === other && name.eql?(other.name)
        end

        def hash
          name.hash
        end

        private

        # Computes the distance of time
        #
        # @param    [Time]
        #
        # @example  Output examples
        #
        #           "less than a week ago"
        #           "15 days ago"
        #           "1 month ago"
        #           "more than a year ago"
        #
        # @return   [String] the dis
        #
        def distance_from_now_in_words(from_time)
          return nil unless from_time
          from_time = Time.parse(from_time)
          to_time = Time.now
          distance_in_days = (((to_time - from_time).abs)/60/60/24).round

          case distance_in_days
          when 0..7
            "less than a week ago"
          when 8..29
            "#{distance_in_days} days ago"
          when 30..45
            "1 month ago"
          when 46..365
            "#{(distance_in_days.to_f / 30).round} months ago"
          else
            "more than a year ago"
          end
        end
      end
    end
  end
end

