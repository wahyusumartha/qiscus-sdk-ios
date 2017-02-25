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
public enum QiscusRoomType {
    case single,group
}
open class QiscusRoom: Object {
    open dynamic var localId:Int = 0
    open dynamic var roomId:Int = 0
    open dynamic var roomName:String = ""
    open dynamic var roomAvatarURL:String = ""
    open dynamic var roomAvatarLocalPath:String = ""
    open dynamic var roomLastCommentTopicId:Int = 0

    open dynamic var optionalData:String = ""
    open dynamic var distinctId:String = ""
    open dynamic var user:String = ""
    open dynamic var isGroup:Bool = false
    open dynamic var hasLoadMore:Bool = true{
        didSet{
            let id = self.localId
            let value = self.hasLoadMore
            Qiscus.dbThread.async {
                let realm = try! Realm()
                let searchQuery:NSPredicate = NSPredicate(format: "localId == \(id)")
                let roomData = realm.objects(QiscusRoom.self).filter(searchQuery)
                
                if roomData.count > 0{
                    let room = roomData.first!
                    if value != room.hasLoadMore{
                        try! realm.write {
                            room.hasLoadMore = value
                        }
                    }
                }
            }
        }
    }
    class func copyRoom(room:QiscusRoom)->QiscusRoom{
        let roomCopy = QiscusRoom()
        roomCopy.localId = room.localId
        roomCopy.roomId = room.roomId
        roomCopy.roomName = room.roomName
        roomCopy.roomAvatarURL = room.roomAvatarURL
        roomCopy.roomAvatarLocalPath = room.roomAvatarLocalPath
        roomCopy.roomLastCommentTopicId = room.roomLastCommentTopicId
        roomCopy.optionalData = room.optionalData
        roomCopy.distinctId = room.distinctId
        roomCopy.user = room.user
        roomCopy.isGroup = room.isGroup
        return roomCopy
    }
    public var roomUnreadMessage:[QiscusComment]{
        get{
            return QiscusComment.getUnreadComments(inTopic: roomLastCommentTopicId)
        }
    }
    public var roomLastComment:QiscusComment?{
        get{
            if let lastComment = QiscusComment.getLastComment(inTopicId: self.roomLastCommentTopicId){
                return lastComment
            }
            return nil
        }
    }
    public var firstComment:QiscusComment?{
        get{
            return QiscusComment.getFirstComment(inTopic: self.roomLastCommentTopicId)
        }
    }
    public var roomType:QiscusRoomType{
        get{
            if !isGroup{
                return QiscusRoomType.single
            }else{
                return QiscusRoomType.group
            }
        }
    }
    open var isAvatarExist:Bool{
        get{
            var check:Bool = false
            if QiscusHelper.isFileExist(inLocalPath: self.roomAvatarLocalPath){
                check = true
            }
            return check
        }
    }
    open var participants:[QiscusParticipant]{
        get{
            return QiscusParticipant.getParticipant(onRoomId: roomId)
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
    private class func roomWithId(_ roomId:Int)->QiscusRoom?{ //
        let realm = try! Realm()
        
        let searchQuery:NSPredicate = NSPredicate(format: "roomId == %d",roomId)
        let roomData = realm.objects(QiscusRoom.self).filter(searchQuery)
        
        if(roomData.count > 0){
            return roomData.first
        }else{
            return nil
        }
    }
    open class func getRoomById(_ roomId:Int)->QiscusRoom?{ // 
        if let room = QiscusRoom.roomWithId(roomId){
            return QiscusRoom.copyRoom(room: room)
        }
        return nil
    }
    open class func getRoom(_ withDistinctId:String, andUserEmail:String)->QiscusRoom?{ // 
        let realm = try! Realm()
        
        let searchQuery:NSPredicate = NSPredicate(format: "distinctId == '\(withDistinctId)' AND user == '\(andUserEmail)'")
        let roomData = realm.objects(QiscusRoom.self).filter(searchQuery)
        
        if(roomData.count > 0){
            return QiscusRoom.copyRoom(room: roomData.first!)
        }else{
            return nil
        }
    }
    open class func getRoom(withLastTopicId topicId:Int)->QiscusRoom?{ // 
        let realm = try! Realm()
        
        let searchQuery:NSPredicate = NSPredicate(format: "roomLastCommentTopicId == %d",topicId)
        let roomData = realm.objects(QiscusRoom.self).filter(searchQuery)
        
        if(roomData.count > 0){
            return QiscusRoom.copyRoom(room: roomData.first!)
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

        if let topicId = fromJSON["last_topic_id"].int { room.roomLastCommentTopicId = topicId}
        if let option = fromJSON["options"].string {
            if option != "" && option != "<null>" {
                room.optionalData = option
            }
        }
        if let chatType = fromJSON["chat_type"].string{
            if chatType == "single"{
                room.isGroup = false
            }else{
                room.isGroup = true
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
    open func updateRoomAvatar(_ avatarURL:String){
        let realm = try! Realm()
        let searchQuery:NSPredicate = NSPredicate(format: "roomId == %d", self.roomId)
        let roomData = realm.objects(QiscusRoom.self).filter(searchQuery)
        
        if roomData.count > 0 {
            let room = roomData.first!
            if room.roomAvatarURL != avatarURL{
                try! realm.write {
                    room.roomAvatarURL = avatarURL
                    room.roomAvatarLocalPath = ""
                }
                room.downloadThumbAvatar()
            }
        }
    }
    open func updateRoomName(_ name:String){
        let realm = try! Realm()
        let searchQuery:NSPredicate = NSPredicate(format: "roomId == %d", self.roomId)
        let roomData = realm.objects(QiscusRoom.self).filter(searchQuery)
        
        if roomData.count > 0 {
            let room = roomData.first!
            if room.roomName != name{
                try! realm.write {
                    room.roomName = name
                }
            }
        }
    }
    open class func getAllRoom() -> [QiscusRoom]{
        var allRoom = [QiscusRoom]()
        let realm = try! Realm()
        
        let roomData = realm.objects(QiscusRoom.self)
        
        if(roomData.count > 0){
            for room in roomData{
                allRoom.append(QiscusRoom.copyRoom(room: room))
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

                if roomAvatarURL != self.roomAvatarURL{
                    needDownloadAvatar = true
                }
                room.roomAvatarURL = self.roomAvatarURL
                room.roomLastCommentTopicId = self.roomLastCommentTopicId
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
        let chatRoom = QiscusRoom.copyRoom(room: self)
        if chatRoom.roomAvatarURL != ""{
            if !Qiscus.qiscusDownload.contains("\(chatRoom.roomAvatarURL):room:\(chatRoom.roomId)"){
                let manager = Alamofire.SessionManager.default
                Qiscus.printLog(text: "Downloading avatar for roomName: \(chatRoom.roomName)")
                let checkURL = "\(chatRoom.roomAvatarURL):room:\(chatRoom.roomId)"
                Qiscus.qiscusDownload.append(checkURL)
                manager.request(chatRoom.roomAvatarURL, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil)
                    .responseData(completionHandler: { response in
                        Qiscus.printLog(text: "download linkImage result: \(response)")
                        if let data = response.data {
                            if let image = UIImage(data: data) {
                                var thumbImage = UIImage()
                                let time = Double(Date().timeIntervalSince1970)
                                let timeToken = UInt64(time * 10000)
                                
                                let fileExt = QiscusFile.getExtension(fromURL: chatRoom.roomAvatarURL)
                                let fileName = "ios-roomAvatar-\(timeToken).\(fileExt)"
                                
                                if fileExt == "jpg" || fileExt == "jpg_" || fileExt == "png" || fileExt == "png_" {
                                    thumbImage = chatRoom.createThumbLink(image)
                                    
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
                                        chatRoom.updateThumbURL(url: thumbPath)
                                    })
                                    var i = 0
                                    var index:Int?
                                    for downloadURL in Qiscus.qiscusDownload{
                                        if downloadURL == checkURL{
                                            index = i
                                            break
                                        }
                                        i += 1
                                    }
                                    if index != nil{
                                        Qiscus.qiscusDownload.remove(at: index!)
                                    }
                                }else{
                                    Qiscus.printLog(text: "failed to save room avatar on room: \(chatRoom.roomName) with id: \(chatRoom.roomId)")
                                    var i = 0
                                    var index:Int?
                                    for downloadURL in Qiscus.qiscusDownload{
                                        if downloadURL == checkURL{
                                            index = i
                                            break
                                        }
                                        i += 1
                                    }
                                    if index != nil{
                                        Qiscus.qiscusDownload.remove(at: index!)
                                    }
                                }
                            }
                        }
                    }).downloadProgress(closure: { progressData in
                        let progress = CGFloat(progressData.fractionCompleted)
                        
                        Qiscus.printLog(text: "Download room (\(chatRoom.roomId)) avatar image progress: \(progress)")
                    })
            }
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
        let searchQuery:NSPredicate = NSPredicate(format: "roomId == %d", self.roomId)
        let roomData = realm.objects(QiscusRoom.self).filter(searchQuery)
        
        if roomData.count > 0 {
            let room = roomData.first!
            if room.roomAvatarLocalPath != url{
                try! realm.write {
                    room.roomAvatarLocalPath = url
                }
                if let presenterDelegate = QiscusDataPresenter.shared.delegate{
                    let copyRoom = QiscusRoom.copyRoom(room: room)
                    presenterDelegate.dataPresenter(didChangeRoom: copyRoom, onRoomWithId: copyRoom.roomId)
                }
            }
        }
    }
}
