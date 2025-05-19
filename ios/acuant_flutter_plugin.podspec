Pod::Spec.new do |s|
  s.name             = 'acuant_flutter_plugin'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin for Acuant iOS SDK'
  s.description      = <<-DESC
A Flutter plugin that provides access to Acuant iOS SDK functionality.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'AcuantiOSSDKV11', '~> 11.6.5'
  s.platform = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end 