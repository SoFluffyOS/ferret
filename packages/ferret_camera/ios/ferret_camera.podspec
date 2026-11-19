Pod::Spec.new do |s|
  s.name             = 'ferret_camera'
  s.version          = '0.0.1'
  s.summary          = 'Takes one photo or scans a document with the iPhone camera.'
  s.description      = <<-DESC
Opens the iPhone camera for one photo, or VisionKit's document scanner, and hands back a file.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'ferret_camera/Sources/ferret_camera/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'
  s.frameworks = 'VisionKit', 'AVFoundation'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
