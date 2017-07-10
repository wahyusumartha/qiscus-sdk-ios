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
    public dynamic var thumbURL:String = ""
    public dynamic var localPath:String = ""
    public dynamic var localThumbPath:String = ""
    public dynamic var roomId:Int = 0
    public dynamic var mimeType:String = ""
    public dynamic var senderEmail:String = ""
    
    var uploadProgress:Double = 0
    var downloadProgress:Double = 0
    
    // MARK: - Getter Variable
    public var sender:QUser? {
        get{
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            return realm.object(ofType: QUser.self, forPrimaryKey: self.senderEmail)
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
                fileName = String(self.localPath.characters.split(separator: "/").last!)
            }
            return fileName
        }
    }
    public var ext:String {
        get{
            var ext = ""
            if self.filename.range(of: ".") != nil{
                let fileNameArr = self.filename.characters.split(separator: ".")
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
    
    public class func getURL(fromString text:String) -> String{
        let component1 = text.components(separatedBy: "[file]")
        let component2 = component1.last!.components(separatedBy: "[/file]")
        let mediaUrlString = component2.first?.trimmingCharacters(in: CharacterSet.whitespaces)
        return mediaUrlString!.replacingOccurrences(of: " ", with: "%20")
    }
    
}
