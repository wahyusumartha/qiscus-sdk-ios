//
//  QiscusLinkData.swift
//  Example
//
//  Created by Ahmad Athaullah on 1/17/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
import RealmSwift
import Alamofire
import SwiftyJSON

open class QiscusLinkData: Object {
    open dynamic var localId:Int = 0
    open dynamic var linkURL:String = ""
    open dynamic var linkTitle:String = ""
    open dynamic var linkDescription: String = ""
    open dynamic var linkImageURL: String = ""
    open dynamic var linkImageThumbURL: String = ""
    
    open var isLocalThumbExist:Bool{
        get{
            var check:Bool = false
            if QiscusHelper.isFileExist(inLocalPath: self.linkImageThumbURL){
                check = true
            }
            return check
        }
    }
    open var thumbImage:UIImage?{
        get{
            if isLocalThumbExist{
                if let image = UIImage.init(contentsOfFile: self.linkImageThumbURL){
                    return image
                }else{
                    return nil
                }
            }else{
                return nil
            }
        }
    }
    
    // MARK: - Set Primary Key
    override open class func primaryKey() -> String {
        return "localId"
    }
    open class var LastId:Int{
        get{
            let realm = try! Realm()
            let RetNext = realm.objects(QiscusLinkData.self).sorted(byProperty: "localId")
            
            if RetNext.count > 0 {
                let last = RetNext.last!
                return last.localId
            } else {
                return 0
            }
        }
    }
    open class func getLinkData(fromURL url: String)->QiscusLinkData?{
        let realm = try! Realm()
        let searchQuery:NSPredicate = NSPredicate(format: "linkURL == '\(url)'")
        let RetNext = realm.objects(QiscusLinkData.self).filter(searchQuery)
        
        if RetNext.count > 0 {
            let data = RetNext.first!
            return data
        }else{
            return nil
        }
    }
    open func saveLink(){ // USED
        let realm = try! Realm()
        let searchQuery = NSPredicate(format: "linkURL == '\(self.linkURL)'")
        
        let linkData = realm.objects(QiscusLinkData.self).filter(searchQuery)
        
        if(self.localId == 0){
            self.localId = QiscusLinkData.LastId + 1
        }
        if linkData.count == 0{
            try! realm.write {
                realm.add(self)
            }
            if self.linkImageThumbURL == "" {
                // download image here
                self.downloadThumbImage()
            }
        }
    }
    open func updateThumbURL(url:String){
        let realm = try! Realm()
        try! realm.write {
            self.linkImageThumbURL = url
        }
    }
    open func updateLinkImageURL(url:String){
        let realm = try! Realm()
        try! realm.write {
            self.linkImageURL = url
        }
    }
    fileprivate func createThumbLink(_ image:UIImage)->UIImage{
        var smallPart:CGFloat = image.size.height
        
        if(image.size.width > image.size.height){
            smallPart = image.size.width
        }
        let ratio:CGFloat = CGFloat(100.0/smallPart)
        let newSize = CGSize(width: (image.size.width * ratio),height: (image.size.height * ratio))
        
        UIGraphicsBeginImageContext(newSize)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    open func downloadThumbImage(){
        if self.linkImageURL != ""{
            let manager = Alamofire.SessionManager.default
            Qiscus.printLog(text: "Downloading image for link \(self.linkURL)")
            manager.request(self.linkImageURL, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil)
                .responseData(completionHandler: { response in
                    Qiscus.printLog(text: "download linkImage result: \(response)")
                    if let data = response.data {
                        if let image = UIImage(data: data) {
                            var thumbImage = UIImage()
                            let time = Double(Date().timeIntervalSince1970)
                            let timeToken = UInt64(time * 10000)
                            
                            let fileExt = QiscusFile.getExtension(fromURL: self.linkImageURL)
                            let fileName = "ios-link-\(timeToken).\(fileExt)"
                            
                            if fileExt == "jpg" || fileExt == "jpg_" || fileExt == "png" || fileExt == "png_" {
                                thumbImage = self.createThumbLink(image)
                                
                                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
                                let directoryPath = "\(documentsPath)/Qiscus"
                                if !FileManager.default.fileExists(atPath: directoryPath){
                                    do {
                                        try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: false, attributes: nil)
                                    } catch let error as NSError {
                                        Qiscus.printLog(text: error.localizedDescription);
                                    }
                                }
                                let thumbPath = "\(directoryPath)/\(fileName)"
                                
                                if fileExt == "png" || fileExt == "png_" {
                                    try? UIImagePNGRepresentation(thumbImage)!.write(to: URL(fileURLWithPath: thumbPath), options: [.atomic])
                                } else if fileExt == "jpg" || fileExt == "jpg_"{
                                    try? UIImageJPEGRepresentation(thumbImage, 1.0)!.write(to: URL(fileURLWithPath: thumbPath), options: [.atomic])
                                }
                                DispatchQueue.main.async(execute: {
                                    self.updateThumbURL(url: thumbPath)
                                })
                            }else{
                                self.updateLinkImageURL(url: "")
                            }
                        }
                    }
                }).downloadProgress(closure: { progressData in
                    let progress = CGFloat(progressData.fractionCompleted)
                    DispatchQueue.main.async(execute: {
                        Qiscus.printLog(text: "Download link image progress: \(progress)")
                    })
                })
        }
    }
}
