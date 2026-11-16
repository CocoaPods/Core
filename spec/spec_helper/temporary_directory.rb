require 'fileutils'

module SpecHelper
  def self.temporary_directory
    TemporaryDirectory.temporary_directory
  end

  module TemporaryDirectory
    module_function

    def temporary_directory
      ROOT + 'tmp'
    end

    def setup_temporary_directory
      temporary_directory.mkpath
    end

    def teardown_temporary_directory
      temporary_directory.rmtree if temporary_directory.exist?
    end

    # Extending an example group wipes the temporary directory before each
    # example and makes these helpers available inside examples.
    def self.extended(base)
      base.include(self)
      base.before do
        TemporaryDirectory.teardown_temporary_directory
        TemporaryDirectory.setup_temporary_directory
      end
    end
  end
end
