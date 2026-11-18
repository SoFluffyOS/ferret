#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint ferret_iphone.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'ferret_iphone'
  s.version          = '0.0.1'
  s.summary          = 'A Bluetooth LE client for an iPhone\'s ANCS and AMS services.'
  s.description      = <<-DESC
Reads an iPhone's notifications and media over the Bluetooth LE services it offers bonded devices.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files = 'ferret_iphone/Sources/ferret_iphone/**/*'

  # If your plugin requires a privacy manifest, for example if it collects user
  # data, update the PrivacyInfo.xcprivacy file to describe your plugin's
  # privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'ferret_iphone_privacy' => ['ferret_iphone/Sources/ferret_iphone/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
