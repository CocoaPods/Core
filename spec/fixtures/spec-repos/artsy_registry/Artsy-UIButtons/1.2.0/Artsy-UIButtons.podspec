#
# Be sure to run `pod lib lint Artsy-UIButtons.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "Artsy-UIButtons"
  s.version          = "1.2.0"
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
