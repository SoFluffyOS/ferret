Pod::Spec.new do |s|
  s.name             = 'ferret_photos'
  s.version          = '0.0.1'
  s.summary          = 'Lists recent photos and screenshots with PhotoKit.'
  s.description      = <<-DESC
Lists recent photos and screenshots, makes thumbnails, exports a photo and watches for new screenshots.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'ferret_photos/Sources/ferret_photos/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'
  s.frameworks = 'Photos'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
