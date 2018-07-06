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
    case document
    case file
}

public class QFile:Object{
    @objc public dynamic var id:String = ""
    @objc public dynamic var url:String = ""
    @objc public dynamic var localPath:String = ""
    @objc public dynamic var localThumbPath:String = ""
    @objc public dynamic var localMiniThumbPath:String = ""
    @objc public dynamic var roomId:String = ""
    @objc public dynamic var mimeType:String = ""
    @objc public dynamic var senderEmail:String = ""
    @objc public dynamic var size:Double = 0
    @objc public dynamic var pages:Int = 0
    @objc public dynamic var filename:String = ""
    
    var uploadProgress:Double = 0
    var downloadProgress:Double = 0
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    override public static func ignoredProperties() -> [String] {
        return ["uploadProgress","downloadProgress"]
    }
    
    // MARK: - Getter Variable
    public var sizeString:String{
        get{
            if self.size > Double(1024 * 1024) {
                var count = self.size / (Double(1024 * 1024))
                count = Double(round(100 * count)/100)

                return "\(count) MB"
            }else if self.size > Double(1024) {
                var count = self.size / (Double(1024))
                count = Double(round(100 * count)/100)
                
                return "\(count) KB"
            }else if self.size > Double(0){
                
                return "\(self.size) Byte"
            }else{
                return ""
            }
        }
    }
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
            case "jpg","jpg_","png","png_","gif","gif_", "heic":
                return .image
            case "mov","mov_","mp4","mp4_":
                return .video
            case "m4a","m4a_","aac","aac_","mp3","mp3_":
                return .audio
            case "pdf","pdf_":
                return .document
            default:
                return .file
            }
        }
    }
}
