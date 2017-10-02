# Uncomment this line to define a global platform for your project
platform :ios, '9.0'

target 'Example' do
    use_frameworks!
    
    pod 'Alamofire', '~> 4.4.0'
    pod 'AlamofireImage', '~> 3.2.0'
    pod 'RealmSwift', '2.7.0'
    pod 'SwiftyJSON', '~> 3.1.4'
    pod 'ImageViewer', '4.0'
    pod 'CocoaMQTT', '1.0.19'
end

target 'Qiscus' do
    use_frameworks!

    pod 'Alamofire', '~> 4.4.0'
    pod 'AlamofireImage', '~> 3.2.0'
    pod 'RealmSwift', '2.7.0'
    pod 'SwiftyJSON', '~> 3.1.4'
    pod 'ImageViewer', '4.0'
    pod 'CocoaMQTT', '1.0.19'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'YES'
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end
