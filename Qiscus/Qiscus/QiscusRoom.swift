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
public class QiscusRoom: NSObject {
    public var localId:Int = 0
    public var roomId:Int = 0 {
        didSet{
            if !self.copyProcess {
                if let roomDB = QiscusRoomDB.roomDB(withLocalId: self.localId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        roomDB.roomId = self.roomId
                    }
                }
            }
        }
    }
    public var roomName:String = ""{
        didSet{
            if !self.copyProcess {
                if let roomDB = QiscusRoomDB.roomDB(withLocalId: self.localId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        roomDB.roomName = self.roomName
                    }
                }
            }
        }
    }
    public var roomAvatarURL:String = ""{
        didSet{
            if !self.copyProcess {
                if let roomDB = QiscusRoomDB.roomDB(withLocalId: self.localId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    
                    if roomDB.roomAvatarURL != self.roomAvatarURL{
                        try! realm.write {
                            roomDB.roomAvatarURL = self.roomAvatarURL
                            roomDB.roomAvatarLocalPath = ""
                        }
                        if self.needDownload {
                            self.downloadThumbAvatar()
                        }
                    }
                }
            }
        }
    }
    public var roomAvatarLocalPath:String = ""{
        didSet{
            if !self.copyProcess {
                if let roomDB = QiscusRoomDB.roomDB(withLocalId: self.localId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        roomDB.roomAvatarLocalPath = self.roomAvatarLocalPath
                    }
                }
            }
        }
    }
    public var roomLastCommentTopicId:Int = 0{
        didSet{
            if !self.copyProcess {
                if let roomDB = QiscusRoomDB.roomDB(withLocalId: self.localId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        roomDB.roomLastCommentTopicId = self.roomLastCommentTopicId
                    }
                }
            }
        }
    }
    public var optionalData:String = ""{
        didSet{
            if !self.copyProcess {
                if let roomDB = QiscusRoomDB.roomDB(withLocalId: self.localId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        roomDB.optionalData = self.optionalData
                    }
                }
            }
        }
    }
    public var distinctId:String = ""{
        didSet{
            if !self.copyProcess {
                if let roomDB = QiscusRoomDB.roomDB(withLocalId: self.localId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        roomDB.distinctId = self.distinctId
                    }
                }
            }
        }
    }
    public var user:String = ""{
        didSet{
            if !self.copyProcess {
                if let roomDB = QiscusRoomDB.roomDB(withLocalId: self.localId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        roomDB.user = self.user
                    }
                }
            }
        }
    }
    public var isGroup:Bool = false{
        didSet{
            if !self.copyProcess {
                if let roomDB = QiscusRoomDB.roomDB(withLocalId: self.localId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        roomDB.isGroup = self.isGroup
                    }
                }
            }
        }
    }
    public var hasLoadMore:Bool = true{
        didSet{
            if !self.copyProcess {
                if let roomDB = QiscusRoomDB.roomDB(withLocalId: self.localId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        roomDB.hasLoadMore = self.hasLoadMore
                    }
                }
            }
        }
    }
    // MARK: - process flag
    public var copyProcess = false
    public var needDownload = true
    
    public var roomUnreadMessage:[QiscusComment]{
        get{
            return QiscusCommentDB.unreadComments(inTopic: self.roomLastCommentTopicId)
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

    public var roomType:QiscusRoomType{
        get{
            if !isGroup{
                return QiscusRoomType.single
            }else{
                return QiscusRoomType.group
            }
        }
    }
    public var isAvatarExist:Bool{
        get{
            var check:Bool = false
            if QiscusHelper.isFileExist(inLocalPath: self.roomAvatarLocalPath){
                check = true
            }
            return check
        }
    }
    public var participants:[QiscusParticipant]{
        get{
            return QiscusParticipant.getParticipant(onRoomId: roomId)
        }
    }
    
    public var avatarImage:UIImage?{
        get{
            if isAvatarExist{
                if let image = UIImage.init(contentsOfFile: self.roomAvatarLocalPath){
                    return image
                }else{
                    self.downloadThumbAvatar()
                    return nil
                }
            }else{
                self.downloadThumbAvatar()
                return nil
            }
        }
    }
    // MARK: - New Data
    public class func newRoom()->QiscusRoom{
        let roomDB = QiscusRoomDB.newRoomDB()
        return roomDB.room()
    }
    
    // MARK: - Getter Methode
    public class func room(withId roomId:Int)->QiscusRoom?{ //
        if let roomDB = QiscusRoomDB.roomDB(withId: roomId){
            return roomDB.room()
        }else{
            return nil
        }
    }
    public class func room(withDistinctId distinctId:String, andUserEmail email:String)->QiscusRoom?{ //
        if let roomDB = QiscusRoomDB.roomDB(withDistinctId: distinctId, andUserEmail: email){
            return roomDB.room()
        }else{
            return nil
        }
    }
    public class func room(withLastTopicId topicId:Int)->QiscusRoom?{ //
        if let roomDB = QiscusRoomDB.roomDB(withLastTopicId: topicId) {
            return roomDB.room()
        }else{
            return nil
        }
    }
    public class func room(fromJSON json:JSON)->QiscusRoom{
        var room = QiscusRoom()
        if let id = json["id"].int {
            if let roomDB = QiscusRoomDB.roomDB(withId: id){
                room = roomDB.room()
            }else{
                room = QiscusRoomDB.newRoomDB().room()
                room.roomId = id
            }
            if let topicId = json["last_topic_id"].int {
                room.roomLastCommentTopicId = topicId
            }
            if let option = json["options"].string {
                if option != "" && option != "<null>" {
                    room.optionalData = option
                }
            }
            if let chatType = json["chat_type"].string{
                if chatType == "single"{
                    room.isGroup = false
                }else{
                    room.isGroup = true
                }
            }
            if let distinctId = json["distinct_id"].string {
                room.distinctId = distinctId
            }
            if let roomName = json["room_name"].string {
                room.roomName = roomName
            }
            if let roomAvatar = json["avatar_url"].string {
                room.roomAvatarURL = roomAvatar
            }
        }
        return room
    }
    
    public func updateRoomAvatar(_ avatarURL:String, avatarImage:UIImage? = nil){
        if let image = avatarImage {
            self.needDownload = false
            self.roomAvatarURL = avatarURL
            self.needDownload = true
            self.updateAvatar(image: image)
        }else{
            self.roomAvatarURL = avatarURL
        }
    }
    
    // MARK: - [QiscusRoom]
    public class func all() -> [QiscusRoom]{
        return QiscusRoomDB.all()
    }

    // MARK: - Download Room Avatar
    public func updateAvatar(image:UIImage){
        Qiscus.logicThread.async {
            let time = Double(Date().timeIntervalSince1970)
            let timeToken = UInt64(time * 10000)
            let fileExt = QiscusFile.getExtension(fromURL: self.roomAvatarURL)
            let fileName = "ios-roomAvatar-\(timeToken).\(fileExt)"
            
            if fileExt == "jpg" || fileExt == "jpg_" || fileExt == "png" || fileExt == "png_" {
                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
                let directoryPath = "\(documentsPath)/Qiscus"
                
                if !FileManager.default.fileExists(atPath: directoryPath){
                    do {
                        try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: false, attributes: nil)
                    } catch let error as NSError {
                        Qiscus.printLog(text: error.localizedDescription);
                    }
                }
                
                let path = "\(directoryPath)/\(fileName)"
                if fileExt == "png" || fileExt == "png_" {
                    try? UIImagePNGRepresentation(image)!.write(to: URL(fileURLWithPath: path), options: [.atomic])
                }
                else if fileExt == "jpg" || fileExt == "jpg_"{
                    try? UIImageJPEGRepresentation(image, 1.0)!.write(to: URL(fileURLWithPath: path), options: [.atomic])
                }
                
                self.roomAvatarLocalPath = path
                
                if let presenterDelegate = QiscusDataPresenter.shared.delegate{
                    presenterDelegate.dataPresenter(didChangeRoom: self, onRoomWithId: self.roomId)
                }
                
            }
        }
    }
    
    public func downloadThumbAvatar(){
        Qiscus.logicThread.async {
            if self.roomAvatarURL != ""{
                let url = self.roomAvatarURL
                let checkURL = "\(self.roomAvatarURL):room:\(self.roomId)"
                if !Qiscus.qiscusDownload.contains(checkURL){
                    Qiscus.printLog(text: "Downloading avatar for room: \(self.roomName)")
                    Qiscus.qiscusDownload.append(checkURL)
                    
                    Alamofire.request(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil)
                        .responseData(completionHandler: { response in
                            Qiscus.printLog(text: "download avatar result: \(response)")
                            if let data = response.data {
                                if let image = UIImage(data: data) {
                                    let fileExt = QiscusFile.getExtension(fromURL: url)
                                    let fileName = "ios-roomAvatar-\(self.roomId).\(fileExt)"
                                    
                                    if fileExt == "jpg" || fileExt == "jpg_" || fileExt == "png" || fileExt == "png_" {
                                        
                                        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
                                        let directoryPath = "\(documentsPath)/Qiscus"
                                        if !FileManager.default.fileExists(atPath: directoryPath){
                                            do {
                                                try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: false, attributes: nil)
                                            } catch let error as NSError {
                                                Qiscus.printLog(text: error.localizedDescription);
                                            }
                                        }
                                        
                                        let path = "\(directoryPath)/\(fileName)"
                                        
                                        if fileExt == "png" || fileExt == "png_" {
                                            try? UIImagePNGRepresentation(image)!.write(to: URL(fileURLWithPath: path), options: [.atomic])
                                        } else if fileExt == "jpg" || fileExt == "jpg_"{
                                            try? UIImageJPEGRepresentation(image, 1.0)!.write(to: URL(fileURLWithPath: path), options: [.atomic])
                                        }
                                        
                                        self.roomAvatarLocalPath = path
                                        
                                        if let presenterDelegate = QiscusDataPresenter.shared.delegate{
                                            presenterDelegate.dataPresenter(didChangeRoom: self, onRoomWithId: self.roomId)
                                        }
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
                                        Qiscus.printLog(text: "failed to save room avatar on room: \(self.roomName) with id: \(self.roomId)")
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
                            
                            Qiscus.printLog(text: "Download room (\(self.roomId)) avatar image progress: \(progress)")
                        })
                }
            }
        }
    }
}
