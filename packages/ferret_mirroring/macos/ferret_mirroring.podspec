#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint ferret_mirroring.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'ferret_mirroring'
  s.version          = '0.0.1'
  s.summary          = 'Decodes a mirrored screen for Ferret screen mirroring.'
  s.description      = <<-DESC
Decodes H.264 with VideoToolbox into a Flutter texture.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files = 'ferret_mirroring/Sources/ferret_mirroring/**/*'

  # If your plugin requires a privacy manifest, for example if it collects user
  # data, update the PrivacyInfo.xcprivacy file to describe your plugin's
  # privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'ferret_mirroring_privacy' => ['ferret_mirroring/Sources/ferret_mirroring/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'
  s.dependency 'sofluffy_texture'
  s.frameworks = 'VideoToolbox', 'CoreMedia', 'CoreVideo'
  s.weak_frameworks = 'ScreenCaptureKit'

  s.platform = :osx, '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
