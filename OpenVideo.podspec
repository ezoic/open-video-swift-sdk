Pod::Spec.new do |s|
  s.name             = 'OpenVideo'
  s.version          = '0.1.0'
  s.summary          = 'Open Video player for publisher iOS apps.'
  s.description      = 'Shows the shipped Open Video player. Ads and pixels stay in the native core.'
  s.homepage         = 'https://github.com/ezoic/open-video-swift-sdk'
  s.license          = { :type => 'Proprietary', :file => 'LICENSE' }
  s.author           = { 'Ezoic Inc' => 'support@ezoic.com' }
  s.source           = { :git => 'git@github.com:ezoic/open-video-swift-sdk.git', :tag => 'v0.1.0' }
  s.source_files     = 'Sources/OpenVideoCore/**/*.swift', 'Sources/OpenVideo/**/*.swift'
  s.platform         = :ios, '15.0'
  s.swift_version    = '5.9'
  s.dependency 'EzoicAdsSDK', '~> 1.11.0'
  s.dependency 'GoogleAds-IMA-iOS-SDK', '>= 3.23', '< 3.28'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
