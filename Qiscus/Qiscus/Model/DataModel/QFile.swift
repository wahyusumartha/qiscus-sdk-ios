//
//  QFile.swift
//  Example
//
//  Created by Ahmad Athaullah on 7/6/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import Foundation
import RealmSwift

@objc public enum QiscusFileType:Int{
    case image
    case video
    case audio
    case file
}

public class QFile:Object{
    public dynamic var id:String = ""
    public dynamic var url:String = ""
    public dynamic var localPath:String = ""
    public dynamic var localThumbPath:String = ""
    public dynamic var localMiniThumbPath:String = ""
    public dynamic var roomId:String = ""
    public dynamic var mimeType:String = ""
    public dynamic var senderEmail:String = ""
    
    var uploadProgress:Double = 0
    var downloadProgress:Double = 0
    
    // MARK: - Getter Variable
    public var thumbURL:String{
        get{
            var thumbURL = self.url.replacingOccurrences(of: "/upload/", with: "/upload/w_30,c_scale/").replacingOccurrences(of: " ", with: "%20")
            let thumbUrlArr = thumbURL.split(separator: ".")
            
            var newThumbURL = ""
            var i = 0
            for thumbComponent in thumbUrlArr{
                if i == 0{
                    newThumbURL += String(thumbComponent)
                }else if i < (thumbUrlArr.count - 1){
                    newThumbURL += ".\(String(thumbComponent))"
                }else{
                    newThumbURL += ".jpg"
                }
                i += 1
            }
            thumbURL = newThumbURL
            return thumbURL
        }
    }
    public var sender:QUser? {
        get{
            return QUser.user(withEmail: self.senderEmail)
        }
    }
    public var filename:String {
        get {
            var mediaURL:URL?
            var fileName:String = ""
            if(self.localPath == ""){
                let remoteURL = self.url.replacingOccurrences(of: " ", with: "%20")
                mediaURL = URL(string: remoteURL)!
                fileName = mediaURL!.lastPathComponent.replacingOccurrences(of: "%20", with: "_")
            }else if self.localPath.range(of: "/") == nil{
                fileName = self.localPath as String
            }else{
                fileName = String(self.localPath.split(separator: "/").last!)
            }
            return fileName
        }
    }
    public var ext:String {
        get{
            var ext = ""
            if self.filename.range(of: ".") != nil{
                let fileNameArr = self.filename.split(separator: ".")
                ext = String(fileNameArr.last!).lowercased()
            }
            return ext
        }
    }
    public var type:QiscusFileType {
        get{
            let ext = self.ext
            switch ext {
            case "jpg","jpg_","png","png_","gif","gif_":
                return .image
            case "mov","mov_","mp4","mp4_":
                return .video
            case "m4a","m4a_","aac","aac_","mp3","mp3_":
                return .audio
            default:
                return .file
            }
        }
    }
    
    
    // MARK: - Primary key
    override open class func primaryKey() -> String {
        return "id"
    }
    public class func file(withURL url:String) -> QFile?{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        var file:QFile? = nil
        let data =  realm.objects(QFile.self).filter("url == '\(url)'")
        
        if data.count > 0{
            file = data.first!
        }
        return file
    }
    public class func createThumbImage(_ image:UIImage, fillImageSize:UIImage? = nil)->UIImage{
        let inputImage = image
        
        if fillImageSize == nil{
            var smallPart:CGFloat = inputImage.size.height
            
            if(inputImage.size.width > inputImage.size.height){
                smallPart = inputImage.size.width
            }
            let ratio:CGFloat = CGFloat(396.0/smallPart)
            let newSize = CGSize(width: (inputImage.size.width * ratio),height: (inputImage.size.height * ratio))
            
            UIGraphicsBeginImageContext(newSize)
            inputImage.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return newImage!
        }else{
            let newImage = UIImage.resizeImage(inputImage, toFillOnImage: fillImageSize!)
            return newImage
        }
    }
    public class func saveFile(_ fileData: Data, fileName: String) -> String {
        let path = QFileManager.saveFile(withData: fileData, fileName: fileName, type: .comment)
        
        return path
    }
    public class func getURL(fromString text:String) -> String{
        let component1 = text.components(separatedBy: "[file]")
        let component2 = component1.last!.components(separatedBy: "[/file]")
        let mediaUrlString = component2.first?.trimmingCharacters(in: CharacterSet.whitespaces)
        return mediaUrlString!.replacingOccurrences(of: " ", with: "%20")
    }
    internal func updateLocalPath(path:String){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        try! realm.write {
            self.localPath = localPath
        }
    }
    public func saveFile(withData data:Data)->String{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let localPath = QFileManager.saveFile(withData: data, fileName: self.filename, type: .comment)
        try! realm.write {
            self.localPath = localPath
        }
        return localPath
    }
    public func saveThumbImage(withImage image:UIImage){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        var data = Data()
        if let imageData = UIImagePNGRepresentation(image){
            data = imageData
        }else{
            data = UIImageJPEGRepresentation(image, 1)!
        }
        let localPath = QFileManager.saveFile(withData: data, fileName: "thumb-\(self.filename)", type: .comment)
        try! realm.write {
            self.localThumbPath = localPath
        }
    }
    public func saveMiniThumbImage(withImage image:UIImage){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        var data = Data()
        if let imageData = UIImagePNGRepresentation(image){
            data = imageData
        }else{
            data = UIImageJPEGRepresentation(image, 1)!
        }
        let localPath = QFileManager.saveFile(withData: data, fileName: "minithumb-\(self.filename)", type: .comment)
        try! realm.write {
            self.localMiniThumbPath = localPath
        }
    }
    internal func update(fileURL:String){
        if self.url != fileURL {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            try! realm.write {
                self.url = fileURL
            }
        }
    }
}
