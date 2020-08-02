Pod::Spec.new do |s|
  s.name             = "Artsy-UIButtons"
  s.version          = "2.3.1"
  s.summary          = "Artsy's UIButton subclasses."
  s.homepage         = "https://github.com/artsy/Artsy-UIButtons"
  s.license          = 'MIT'
  s.author           = { "Laura Brown" => "laurabrown1113@gmail.com" }
  s.source           = { :git => "https://github.com/artsy/Artsy-UIButtons.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/artsy'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'

  s.frameworks = 'UIKit'
  s.dependency 'Artsy+UIColors', '~> 3.0'
  s.dependency 'Artsy+UIFonts'
  s.dependency 'UIView+BooleanAnimations'
end
