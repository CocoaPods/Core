Pod::Spec.new do |s|
  s.name             = "Artsy+Authentication"
  s.version          = "1.7.0"
  s.summary          = "Authentication for Artsy Services."
  s.description      = "Authentication for Artsy Cocoa libraries. Yawn, boring."
  s.homepage         = "https://github.com/artsy/Artsy_Authentication"
  s.license          = 'MIT'
  s.author           = { "Orta Therox" => "orta@artsymail.com" }
  s.source           = { :git => "https://github.com/artsy/Artsy_Authentication.git", :tag => "#{s.version}" }
  s.social_media_url = 'https://twitter.com/artsyopensource'

  s.ios.deployment_target = '7.0'
  s.tvos.deployment_target = '9.0'

  # Twitter/FB/Email
  s.subspec "everything" do |ss|
    # Does not work with tvOS
    ss.tvos.deployment_target = "100.0"
    ss.ios.deployment_target = '7.0'

    ss.source_files = 'Pod/Classes'
    ss.private_header_files = 'Pod/Classes/*Private.h'

    ss.frameworks = 'Foundation', 'Social', 'Accounts'
    ss.dependency 'ISO8601DateFormatter'
    ss.dependency 'NSURL+QueryDictionary'
    ss.dependency 'LVTwitterOAuthClient'
  end

  # Email
  s.subspec "email" do |ss|
    ss.source_files = 'Pod/Classes'
    ss.private_header_files = 'Pod/Classes/*Private.h'
    ss.exclude_files = ['Pod/Classes/*Facebook.{h,m}', 'Pod/Classes/*Twitter.{h,m}']
    ss.tvos.exclude_files = ['Pod/Classes/*Facebook.{h,m}', 'Pod/Classes/*Twitter.{h,m}', 'Pod/Classes/*Accounts.{h,m}']
    ss.dependency 'ISO8601DateFormatter'
    ss.dependency 'NSURL+QueryDictionary'
    ss.frameworks = 'Foundation'
  end

  s.default_subspec = "everything"
end
