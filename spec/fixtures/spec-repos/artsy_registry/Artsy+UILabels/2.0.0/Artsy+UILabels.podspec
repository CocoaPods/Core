Pod::Spec.new do |s|
  s.name             = "Artsy+UILabels"
  s.version          = "2.0.0"
  s.summary          = "UILabels subclasses and related categories."
  s.homepage         = "https://github.com/artsy/Artsy-UILabels"
  s.license          = 'MIT'
  s.author           = { "Orta" => "orta.therox@gmail.com" }
  s.source           = { :git => "https://github.com/artsy/Artsy-UILabels.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/artsyopensource'

  s.platform     = :ios, '7.0'

  s.source_files = 'Pod/Classes'
  s.resources = 'Pod/Assets/*.png'

  s.frameworks = 'UIKit'
  s.dependency 'Artsy+UIColors', '~> 3.0'
end