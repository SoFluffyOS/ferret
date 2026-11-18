Pod::Spec.new do |s|
  s.name             = 'ferret_system'
  s.version          = '0.1.0'
  s.summary          = 'System hooks Ferret needs: network changes and wake from sleep.'
  s.description      = <<-DESC
Reports network changes and wake from sleep so Ferret reconnects right away.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files = 'ferret_system/Sources/ferret_system/**/*.swift'

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
