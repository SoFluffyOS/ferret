Pod::Spec.new do |s|
  s.name             = 'ferret_handoff'
  s.version          = '0.0.1'
  s.summary          = "Platform code for Ferret's handoff feature."
  s.description      = <<-DESC
Takes links and text from Ferret's iOS Share extension for Ferret's handoff feature.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'ferret_handoff/Sources/ferret_handoff/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
