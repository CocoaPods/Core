Pod::Spec.new do |s|
  s.name         = "Extraction"
  s.version      = "1.1.0"
  s.summary      = "UI components shared between Eigen and Emission."
  s.homepage     = "https://github.com/artsy/extraction"
  s.license      = "MIT"
  s.author       = { "Eloy Durán" => "eloy.de.enige@gmail.com" }

  s.source       = { :git => "https://github.com/artsy/extraction.git", :tag => s.version.to_s }
  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.subspec 'ARSwitchView' do |ss|
    ss.source_files = 'Extraction/Classes/ARSwitchView.{h,m}'
    ss.dependency 'Artsy+UIFonts', '>= 1.1.0'
    ss.dependency 'Artsy+UIColors'
    ss.dependency 'FLKAutoLayout'
    ss.dependency 'UIView+BooleanAnimations'
  end

  s.subspec 'ARSpinner' do |ss|
    ss.source_files = 'Extraction/Classes/ARSpinner.{h,m}'
    ss.dependency 'Extraction/UIView+ARSpinner'
    ss.dependency 'UIView+BooleanAnimations'
  end

  s.subspec 'UIView+ARSpinner' do |ss|
    ss.source_files = 'Extraction/Classes/UIView+ARSpinner.{h,m}'
    ss.dependency 'Extraction/ARAnimationContinuation'
  end

  s.subspec 'ARAnimationContinuation' do |ss|
    ss.source_files = 'Extraction/Classes/ARAnimationContinuation.{h,m}'
  end
end
