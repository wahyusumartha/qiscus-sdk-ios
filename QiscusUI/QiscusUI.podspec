Pod::Spec.new do |s|

s.name         = "QiscusUI"
s.version      = "0.0.1"
s.summary      = "Qiscus SDK UI for iOS"

s.description  = <<-DESC
QiscusUI SDK for iOS contains Chat User Interface.
DESC

s.homepage     = "https://qisc.us"

s.license      = "MIT"
s.author       = "Qiscus"

s.source       = { :git => "https://github.com/qiscus/qiscus-sdk-ios.git", :tag => "#{s.version}" }


s.source_files  = "QiscusUI/**/*.{swift}"
s.resource_bundles = {
'QiscusUI' => ['QiscusUI/**/*.{storyboard,xib,xcassets,json,imageset,png,gif,strings}']
}

s.platform      = :ios, "9.0"

s.dependency 'Qiscus'
s.dependency 'ImageSlideshow'

end

