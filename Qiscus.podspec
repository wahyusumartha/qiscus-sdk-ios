Pod::Spec.new do |s|

s.name         = "Qiscus"
s.version      = "2.6.2"
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
    'Qiscus' => ['Qiscus/**/*.{storyboard,xib,xcassets,json,imageset,png,gif}']
}

s.platform      = :ios, "9.0"

s.dependency 'Alamofire', '~> 4.5.1'
s.dependency 'AlamofireImage', '~> 3.3.0'
s.dependency 'RealmSwift', '~> 2.10.2'
s.dependency 'SwiftyJSON', '~> 3.1.4'
s.dependency 'ImageViewer', '4.0'
s.dependency 'CocoaMQTT', '1.0.19'

end
