Pod::Spec.new do |s|
  s.name             = "Artsy+UIColors"
  s.version          = "3.0.0"
  s.summary          = "UIColors for Artsy Apps."
  s.summary          = "UIColors for Artsy Apps. Probably not too useful if you're not in Artsy."
  s.homepage         = "http://github.com/Artsy/Artsy-UIColors"
  s.license          = 'MIT'
  s.author           = { "Orta" => "orta.therox@gmail.com" }
  s.source           = { :git => "https://github.com/Artsy/Artsy-UIColors.git" }
  s.social_media_url = 'https://twitter.com/artsy'

  s.platform     = :ios, '7.0'
  s.source_files = 'Classes'
  s.frameworks = 'UIKit'
end
 