Pod::Spec.new do |s|

s.name         = "Qiscus"
s.version      = "2.2.14"
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
    'Qiscus' => ['Qiscus/**/*.{storyboard,xib,xcassets,json,imageset,png}']
}

s.platform      = :ios, "9.0"

s.dependency 'Alamofire', '~> 4.4.0'
s.dependency 'AlamofireImage', '~> 3.2.0'
s.dependency 'RealmSwift', '~> 2.5.0'
s.dependency 'SwiftyJSON', '~> 3.1.4'
s.dependency 'ImageViewer', '4.0'
s.dependency 'CocoaMQTT', '1.0.11'

end
