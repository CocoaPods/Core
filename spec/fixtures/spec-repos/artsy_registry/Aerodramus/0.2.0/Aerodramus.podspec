Pod::Spec.new do |s|
  s.name             = "Aerodramus"
  s.version          = "0.2.0"
  s.summary          = "Echo Communication Tools"
  s.description      = "Allows connection to the Echo API server."
  s.homepage         = "https://github.com/Artsy/Aerodramus"
  s.license          = 'MIT'
  s.author           = { "Orta Therox" => "orta.therox@gmail.com" }
  s.source           = { :git => "https://github.com/Artsy/Aerodramus.git", :tag => s.version.to_s }
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files = 'Pod/Classes/**/*'
  s.dependency 'ISO8601DateFormatter'
end
