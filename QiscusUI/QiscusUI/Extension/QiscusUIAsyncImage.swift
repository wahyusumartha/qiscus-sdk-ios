//
//  QiscusUIAsyncImage.swift
//  QiscusUI
//
//  Created by Rahardyan Bisma on 25/05/18.
//

import Foundation

var cache = NSCache<NSString,UIImage>()
var QAsyncThread = DispatchQueue(label: "com.QiscusUI.asyncImage", attributes: .concurrent)
open class QiscusUIAyncImage: UIImageView {
    
    
}
public extension UIImageView {
    public func loadAsync(url:String, placeholderImage:UIImage? = nil, header : [String : String] = [String : String](), useCache:Bool = true, onLoaded: (()->Void)? = nil){
        var returnImage = UIImage()
        if placeholderImage != nil {
            returnImage = placeholderImage!
            self.image = returnImage
        }
        imageForUrl(url: url, header: header, useCache: useCache, completionHandler:{(image: UIImage?, url: String) in
            if let returnImage = image{
                self.image = returnImage
                if let completion = onLoaded{
                    completion()
                }
            }
        })
    }
    public func loadAsync(fromLocalPath localPath:String, placeholderImage:UIImage? = nil,onLoaded: (()->Void)? = nil){
        var returnImage = UIImage()
        if placeholderImage != nil {
            returnImage = placeholderImage!
            self.image = returnImage
        }
        QAsyncThread.async { autoreleasepool{
            if let image = UIImage(contentsOfFile: localPath){
                DispatchQueue.main.async { autoreleasepool{
                    self.image = image
                    if let completion = onLoaded{
                        completion()
                    }
                    }}
            }
            }}
    }
    public func loadAsync(url:String, onLoaded: @escaping ((UIImage,AnyObject?)->Void), optionalData:AnyObject? = nil){
        imageForUrl(url: url, completionHandler:{(image: UIImage?, url: String) in
            if let returnImage = image{
                DispatchQueue.main.async { autoreleasepool{
                    onLoaded(returnImage,optionalData)
                    }}
            }
        })
    }
    public func loadAsync(fromLocalPath localPath:String, onLoaded: @escaping ((UIImage,AnyObject?)->Void), optionalData:AnyObject? = nil){
        QAsyncThread.async {autoreleasepool{
            if let cachedImage = cache.object(forKey: localPath as NSString) {
                DispatchQueue.main.async {autoreleasepool{
                    onLoaded(cachedImage,optionalData)
                    }}
            }else if let image = UIImage(contentsOfFile: localPath){
                DispatchQueue.main.async {autoreleasepool{
                    if cache.object(forKey: localPath as NSString) == nil {
                        cache.setObject(image, forKey: localPath as NSString)
                    }
                    onLoaded(image,optionalData)
                    }}
            }
            }}
    }
    // func imageForUrl
    //  Modified from ImageLoader.swift Created by Nate Lyman on 7/5/14.
    //              git: https://github.com/natelyman/SwiftImageLoader
    //              Copyright (c) 2014 NateLyman.com. All rights reserved.
    //
    func imageForUrl(url urlString: String, header: [String : String] = [String : String](), useCache:Bool = true, completionHandler:@escaping (_ image: UIImage?, _ url: String) -> ()) {
        
        QAsyncThread.async {autoreleasepool{
            
            let image = cache.object(forKey: urlString as NSString)
            
            
            if useCache && (image != nil) {
                DispatchQueue.main.async(execute: {() in
                    completionHandler(image, urlString)
                })
                return
            }else{
                if let url = URL(string: urlString){
                    var urlRequest = URLRequest(url: url)
                    
                    for (key, value) in header {
                        urlRequest.addValue(value, forHTTPHeaderField: key)
                    }
                    
                    let downloadTask = URLSession.shared.dataTask(with: urlRequest, completionHandler: {(data: Data?, response: URLResponse?, error: Error?) -> Void in
                        
                        if (error != nil) {
                            completionHandler(nil, urlString)
                            return
                        }
                        
                        if let data = data {
                            if let image = UIImage(data: data) {
                                if useCache{
                                    if cache.object(forKey: urlString as NSString) == nil {
                                        cache.setObject(image, forKey: urlString as NSString)
                                    }
                                }else{
                                    cache.removeObject(forKey: urlString as NSString)
                                }
                                DispatchQueue.main.async(execute: {() in
                                    completionHandler(image, urlString)
                                })
                            }else{
                                DispatchQueue.main.async(execute: {() in
                                    completionHandler(nil, urlString)
                                })
                            }
                            return
                        }
                        return ()
                        
                    })
                    downloadTask.resume()
                }
            }
            }}
    }
}
public extension UIImage {
    public class func clearAllCache(){
        cache.removeAllObjects()
    }
    public class func clearCachedImageForURL(_ urlString:String){
        cache.removeObject(forKey: urlString as NSString)
    }
    public class func cachedImage(withPath path:String)->UIImage?{
        return cache.object(forKey: path as NSString)
    }
    public class func resizeImage(_ image: UIImage, toFillOnImage: UIImage) -> UIImage {
        
        var scale:CGFloat = 1
        var newSize:CGSize = toFillOnImage.size
        
        if image.size.width > image.size.height{
            scale = image.size.width / image.size.height
            newSize.width = toFillOnImage.size.width
            newSize.height = toFillOnImage.size.height / scale
        }else{
            scale = image.size.height / image.size.width
            newSize.height = toFillOnImage.size.height
            newSize.width = toFillOnImage.size.width / scale
        }
        
        var scaleFactor = newSize.width / image.size.width
        
        
        if (image.size.height * scaleFactor) < toFillOnImage.size.height{
            scaleFactor = scaleFactor * (toFillOnImage.size.height / (image.size.height * scaleFactor))
        }
        if (image.size.width * scaleFactor) < toFillOnImage.size.width{
            scaleFactor = scaleFactor * (toFillOnImage.size.width / (image.size.width * scaleFactor))
        }
        
        UIGraphicsBeginImageContextWithOptions(toFillOnImage.size, false, scaleFactor)
        
        var xPos:CGFloat = 0
        if (image.size.width * scaleFactor) > toFillOnImage.size.width {
            xPos = ((image.size.width * scaleFactor) - toFillOnImage.size.width) / 2
        }
        var yPos:CGFloat = 0
        if (image.size.height * scale) > toFillOnImage.size.height{
            yPos = ((image.size.height * scaleFactor) - toFillOnImage.size.height) / 2
        }
        image.draw(in: CGRect(x: 0 - xPos,y: 0 - yPos, width: image.size.width * scaleFactor, height: image.size.height * scaleFactor))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
}
