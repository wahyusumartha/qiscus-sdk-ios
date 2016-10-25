Pod::Spec.new do |s|

s.name         = "Qiscus"
s.version      = "0.5.10"
s.summary      = "Qiscus SDK for iOS"

s.description  = <<-DESC
Qiscus SDK for iOS contains Qiscus public Model.
DESC

s.homepage     = "https://qisc.us"

s.license      = "MIT"
s.author       = "Ahmad Athaullah"

s.source       = { :git => "https://github.com/a-athaullah/Qiscus.git", :tag => "#{s.version}" }


s.source_files  = "Qiscus/**/*.{swift}"
s.resource_bundles = {
    'Qiscus' => ['Qiscus/**/*.{storyboard,xib,xcassets,json,imageset,png}']
}

s.platform      = :ios, "8.3"

s.dependency 'Alamofire'
s.dependency 'AlamofireImage'
s.dependency 'PusherSwift'
s.dependency 'RealmSwift'
s.dependency 'SwiftyJSON'
s.dependency 'QToasterSwift'
s.dependency 'SJProgressHUD'
s.dependency 'ImageViewer'

end
