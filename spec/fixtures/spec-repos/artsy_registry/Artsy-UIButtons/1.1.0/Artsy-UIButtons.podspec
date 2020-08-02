Pod::Spec.new do |s|
  s.name             = "Artsy-UIButtons"
  s.version          = "1.1.0"
  s.summary          = "Artsy's UIButton subclasses."
  s.homepage         = "https://github.com/artsy/Artsy-UIButtons"
  s.license          = 'MIT'
  s.author           = { "Laura Brown" => "laurabrown1113@gmail.com" }
  s.source           = { :git => "https://github.com/artsy/Artsy-UIButtons.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/artsy'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'
  s.resources = 'Pod/Assets/*'

  s.frameworks = 'UIKit'
  s.dependencies = ['Artsy+UIColors']
end
