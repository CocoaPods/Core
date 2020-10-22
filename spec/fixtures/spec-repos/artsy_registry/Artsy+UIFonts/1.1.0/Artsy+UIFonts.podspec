Pod::Spec.new do |s|
  s.name             = "Artsy+UIFonts"
  s.version          = "1.1.0"
  s.summary          = "The fonts for Artsy apps + UIFont categories."
  s.homepage         = "https://github.com/artsy/Artsy-UIFonts"
  s.license          = 'Proprietary'
  s.author           = { "Orta" => "orta.therox@gmail.com" }
  s.source           = { :git => "https://github.com/artsy/Artsy-UIFonts.git", :tag => s.version }
  s.social_media_url = 'https://twitter.com/artsy'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'
  s.resources = 'Pod/Assets/*'

  s.frameworks = 'UIKit', 'CoreText'
end
