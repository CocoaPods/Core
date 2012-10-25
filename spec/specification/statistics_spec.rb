require File.expand_path('../../spec_helper', __FILE__)

describe Pod::Specification::Statistics do
  before do
    fixture('banana-lib') # ensure the archive is unpacked
    @spec = Pod::Specification.from_file(fixture('banana-lib/BananaLib.podspec'))
  end
end

