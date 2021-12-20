# This is used for TelenavSDK
plugin 'cocoapods-art', :sources => [
  'telenav-cocoapods',
  'telenav-cocoapods-preprod-local'
]
# This is used for Alamofire, also can be changed to https://github.com/CocoaPods/Specs
source 'https://cdn.cocoapods.org/'

platform :ios, '12.0'

target 'TelenavDemo' do
  use_frameworks!

  if ENV['NAVIGATION_VERSION']
    pod 'VividNavigationSDK', ENV['NAVIGATION_VERSION']
  else
    pod 'VividNavigationSDK', '0.2.16-beta5'
  end

  if ENV['SEARCH_ENTITY_VERSION']
    pod 'TelenavEntitySDK', ENV["SEARCH_ENTITY_VERSION"]
  else
    pod 'TelenavEntitySDK', '1.0.0'
  end
  
  # Pods for TelenavDemo
  pod 'CocoaLumberjack', '3.7.2'

end
