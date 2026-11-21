Pod::Spec.new do |s|
  s.name             = 'ferret_bonjour'
  s.version          = '0.0.1'
  s.summary          = 'Tells whether iOS lets Ferret on the local network.'
  s.description      = <<-DESC
Browses Ferret's Bonjour service for a moment to learn whether the Local Network switch is off.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'ferret_bonjour/Sources/ferret_bonjour/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'
  s.frameworks = 'Network'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
