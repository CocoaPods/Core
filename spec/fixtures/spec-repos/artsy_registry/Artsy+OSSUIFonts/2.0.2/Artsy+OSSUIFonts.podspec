Pod::Spec.new do |s|
  s.name             = "Artsy+OSSUIFonts"
  s.version          = "2.0.2"
  s.summary          = "The open source fonts for Artsy apps + UIFont categories."
  s.homepage         = "https://github.com/artsy/Artsy-OSSUIFonts"
  s.license          = 'Code is MIT, then custom font licenses.'
  s.author           = { "Orta" => "orta@artsymail.com" }
  s.source           = { :git => "https://github.com/artsy/Artsy-OSSUIFonts.git", :tag => s.version }
  s.social_media_url = 'https://twitter.com/artsyopensource'

  s.ios.deployment_target = '7.0'
  s.tvos.deployment_target = '9.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'
  s.resources = 'Pod/Assets/*'

  s.frameworks = 'UIKit', 'CoreText'
  s.module_name = 'Artsy_UIFonts'
end
