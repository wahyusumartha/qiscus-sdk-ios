//
//  QiscusRoom.swift
//  LinkDokter
//
//  Created by Qiscus on 2/24/16.
//  Copyright © 2016 qiscus. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftyJSON
import Alamofire

open class QiscusRoom: Object {
    open dynamic var localId:Int = 0
    open dynamic var roomId:Int = 0
    open dynamic var roomName:String = ""
    open dynamic var roomAvatarURL:String = ""
    open dynamic var roomAvatarLocalPath:String = ""
    open dynamic var roomChannel:String = ""
    open dynamic var roomLastCommentId:Int = 0
    open dynamic var roomLastCommentMessage:String = ""
    open dynamic var roomLastCommentSender:String = ""
    open dynamic var roomLastCommentTopicId:Int = 0
    open dynamic var roomLastCommentTopicTitle:String = ""
    open dynamic var roomCountNotif:Int = 0
    open dynamic var roomSecretCode:String = ""
    open dynamic var roomSecretCodeEnabled:Bool = false
    open dynamic var roomSecretCodeURL:String = ""
    open dynamic var roomIsDeleted:Bool = false
    open dynamic var desc:String = ""
    open dynamic var optionalData:String = ""
    open dynamic var distinctId:String = ""
    open dynamic var user:String = ""
    
    open var isAvatarExist:Bool{
        get{
            var check:Bool = false
            if QiscusHelper.isFileExist(inLocalPath: self.roomAvatarLocalPath){
                check = true
            }
            return check
        }
    }
    open var avatarImage:UIImage?{
        get{
            if isAvatarExist{
                if let image = UIImage.init(contentsOfFile: self.roomAvatarLocalPath){
                    return image
                }else{
                    return nil
                }
            }else{
                return nil
            }
        }
    }
    
    // MARK: - Primary Key
    override open class func primaryKey() -> String {
        return "localId"
    }
    
    
    // MARK: - Getter Methode
    open class func getRoomById(_ roomId:Int)->QiscusRoom?{ //USED
        let realm = try! Realm()
        
        let searchQuery:NSPredicate = NSPredicate(format: "roomId == %d",roomId)
        let roomData = realm.objects(QiscusRoom.self).filter(searchQuery)
        
        if(roomData.count > 0){
            return roomData.first
        }else{
            return nil
        }
    }
    open class func getRoom(_ withDistinctId:String, andUserEmail:String)->QiscusRoom?{ //USED
        let realm = try! Realm()
        
        let searchQuery:NSPredicate = NSPredicate(format: "distinctId == %@ AND user == %@",withDistinctId, andUserEmail)
        let roomData = realm.objects(QiscusRoom.self).filter(searchQuery)
        
        if(roomData.count > 0){
            return roomData.first
        }else{
            return nil
        }
    }
    open class func getRoom(withLastTopicId topicId:Int)->QiscusRoom?{ //USED
        let realm = try! Realm()
        
        let searchQuery:NSPredicate = NSPredicate(format: "roomLastCommentTopicId == %d",topicId)
        let roomData = realm.objects(QiscusRoom.self).filter(searchQuery)
        
        if(roomData.count > 0){
            return roomData.first
        }else{
            return nil
        }
    }
    open class func getLastId() -> Int{
        let realm = try! Realm()
        let RetNext = realm.objects(QiscusRoom.self).sorted(byProperty: "localId")
        
        if RetNext.count > 0 {
            let last = RetNext.last!
            return last.localId
        } else {
            return 0
        }
    }
    
    open class func getRoom(_ fromJSON:JSON)->QiscusRoom{
        let room = QiscusRoom()
        if let id = fromJSON["id"].int {  room.roomId = id  }
        if let commentId = fromJSON["last_comment_id"].int {room.roomLastCommentId = commentId}
        if let lastMessage = fromJSON["last_comment_message"].string {
            room.roomLastCommentMessage = lastMessage
        }
        if let topicId = fromJSON["last_topic_id"].int { room.roomLastCommentTopicId = topicId}
        if let option = fromJSON["options"].string {
            if option != "" && option != "<null>" {
                room.optionalData = option
            }
        }
        if let distinctId = fromJSON["distinct_id"].string { room.distinctId = distinctId}
        if let roomName = fromJSON["room_name"].string { room.roomName = roomName}
        if let roomAvatar = fromJSON["avatar_url"].string {room.roomAvatarURL = roomAvatar}
        
        room.saveRoom()
        return room
    }
    open func updateUser(_ user:String){
        let realm = try! Realm()
        try! realm.write {
            self.user = user
        }
    }
    open func updateDistinctId(_ distinctId:String){
        let realm = try! Realm()
        try! realm.write {
            self.distinctId = distinctId
        }
    }
    open func updateDesc(_ desc:String){
        let realm = try! Realm()
        try! realm.write {
            self.desc = desc
        }
    }
    open func updateRoomName(_ name:String){
        let realm = try! Realm()
        try! realm.write {
            self.roomName = name
        }
    }
    open class func getAllRoom() -> [QiscusRoom]{
        var allRoom = [QiscusRoom]()
        let realm = try! Realm()
        
        let searchQuery:NSPredicate = NSPredicate(format: "roomIsDeleted == false")
        let roomData = realm.objects(QiscusRoom.self).filter(searchQuery).sorted(byProperty: "roomLastCommentId", ascending: false)
        
        if(roomData.count > 0){
            for room in roomData{
                allRoom.append(room)
            }
        }
        return allRoom
    }

    // MARK: - Save Room
    open func saveRoom(){
        let realm = try! Realm()
        
        let searchQuery:NSPredicate = NSPredicate(format: "roomId == %d", self.roomId)
        let roomData = realm.objects(QiscusRoom.self).filter(searchQuery)
        
        if(self.localId == 0){
            self.localId = QiscusRoom.getLastId() + 1
        }
        if(roomData.count == 0){
            try! realm.write {
                realm.add(self)
            }
            if self.roomAvatarLocalPath == "" {
                self.downloadThumbAvatar()
            }
        }else{
            let room = roomData.first!
            var needDownloadAvatar = false
            if room.roomAvatarLocalPath == "" {
                needDownloadAvatar = true
            }
            try! realm.write {
                room.roomId = self.roomId
                if room.roomName != "" { room.roomName = self.roomName }
                if room.roomChannel != "" { room.roomChannel = self.roomChannel }
                if room.roomLastCommentId != 0 { room.roomLastCommentId = self.roomLastCommentId }
                if room.roomLastCommentMessage != "" {
                    room.roomLastCommentMessage = self.roomLastCommentMessage
                }
                if roomAvatarURL != self.roomAvatarURL{
                    needDownloadAvatar = true
                }
                room.roomAvatarURL = self.roomAvatarURL
                room.roomLastCommentSender = self.roomLastCommentSender
                room.roomLastCommentTopicId = self.roomLastCommentTopicId
                room.roomLastCommentTopicTitle = self.roomLastCommentTopicTitle
                room.roomCountNotif = self.roomCountNotif
                room.roomSecretCode = self.roomSecretCode
                room.roomSecretCodeEnabled = self.roomSecretCodeEnabled
                room.roomSecretCodeURL = self.roomSecretCodeURL
                room.roomIsDeleted = self.roomIsDeleted
                if room.optionalData != "" { room.optionalData = self.optionalData }
                if room.distinctId != "" {room.distinctId = self.distinctId}
            }
            if needDownloadAvatar {
                room.downloadThumbAvatar()
            }
        }
    }
    
    // MARK: - Download Room Avatar
    open func downloadThumbAvatar(){
        if self.roomAvatarURL != ""{
            let manager = Alamofire.SessionManager.default
            Qiscus.printLog(text: "Downloading avatar for roomName: \(self.roomName)")
            manager.request(self.roomAvatarURL, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil)
                .responseData(completionHandler: { response in
                    Qiscus.printLog(text: "download linkImage result: \(response)")
                    if let data = response.data {
                        if let image = UIImage(data: data) {
                            var thumbImage = UIImage()
                            let time = Double(Date().timeIntervalSince1970)
                            let timeToken = UInt64(time * 10000)
                            
                            let fileExt = QiscusFile.getExtension(fromURL: self.roomAvatarURL)
                            let fileName = "ios-roomAvatar-\(timeToken).\(fileExt)"
                            
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
                                Qiscus.printLog(text: "failed to save room avatar on room: \(self.roomName) with id: \(self.roomId)")
                            }
                        }
                    }
                }).downloadProgress(closure: { progressData in
                    let progress = CGFloat(progressData.fractionCompleted)
                    DispatchQueue.main.async(execute: {
                        Qiscus.printLog(text: "Download room (\(self.roomId)) avatar image progress: \(progress)")
                    })
                })
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
    open func updateThumbURL(url:String){
        let realm = try! Realm()
        try! realm.write {
            self.roomAvatarLocalPath = url
        }
    }
}
