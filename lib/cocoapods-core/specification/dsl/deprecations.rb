module Pod
  class Specification
    module DSL
      # Provides warning and errors for the deprecated attributes of the DSL.
      #
      module Deprecations
        def preferred_dependency=(name)
          self.default_subspecs = [name]
          CoreUI.warn "[#{self}] `preferred_dependency` has been renamed "\
            'to `default_subspecs`.'
        end

        def xcconfig=(value)
          self.pod_target_xcconfig = value
          CoreUI.warn "[#{self}] `xcconfig` has been renamed to "\
            '`pod_target_xcconfig`. See also the new introduced '\
            '`user_target_xcconfig`.'
        end
      end
    end
  end
end
