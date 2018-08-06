Pod::Spec.new do |s|

s.name         = "Qiscus"
s.version      = "2.9.1"
s.summary      = "Qiscus SDK for iOS"
s.description  = <<-DESC
Qiscus SDK for iOS contains Qiscus public Model.
DESC
s.homepage     = "https://qisc.us"
s.license      = "MIT"
s.author       = "Qiscus"
s.source       = { :git => "https://github.com/qiscus/qiscus-sdk-ios.git", :tag => "#{s.version}" }
s.source_files  = "Qiscus/**/*.{swift}"
s.resource_bundles = {
    'Qiscus' => ['Qiscus/**/*.{xcassets,imageset}']
}
s.platform      = :ios, "9.0"
s.dependency 'QiscusCore'
s.dependency 'QiscusUI'

end
