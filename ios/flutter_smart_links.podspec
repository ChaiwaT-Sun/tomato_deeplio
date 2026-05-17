Pod::Spec.new do |s|
  s.name             = 'flutter_smart_links'
  s.version          = '1.0.0'
  s.summary          = 'App Links, Universal Links, Deep Links, and Deferred Deep Links for Flutter.'
  s.description      = <<-DESC
    A production-ready Flutter plugin for App Links, Universal Links,
    Deep Links, Deferred Deep Links, and dynamic routing.
    A modern self-hosted replacement for Firebase Dynamic Links.
    GitHub: https://github.com/ChaiwaT-Sun/flutter_smart_links
  DESC
  s.homepage         = 'https://github.com/ChaiwaT-Sun/flutter_smart_links'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'ChaiwaT-Sun' => 'https://github.com/ChaiwaT-Sun' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version    = '5.0'
end
