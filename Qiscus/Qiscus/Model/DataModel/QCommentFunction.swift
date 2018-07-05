//
//  QCommentFunction.swift
//  Qiscus
//
//  Created by Qiscus on 05/07/18.
//

import UIKit
import RealmSwift
import SwiftyJSON

// MARK: Internal
extension QComment {
    
    internal class func comments(searchQuery: String) -> [QComment] {
        if Thread.isMainThread {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            realm.refresh()
            
            let comments = realm.objects(QComment.self).filter({ (comment) -> Bool in
                return comment.text.lowercased().contains(searchQuery.lowercased())
            })
            
            return Array(comments)
        }
        
        return [QComment]()
    }
    
    internal class func countComments(afterId id:Int, roomId:String)->Int{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        let data =  realm.objects(QComment.self).filter("id > \(id) AND roomId = \'(roomId)'").sorted(byKeyPath: "createdAt", ascending: true)
        
        return data.count
    }
    
    internal class func tempComment(fromJSON json:JSON)->QComment{
        let temp = QComment()
        
        let commentId = json["id"].intValue
        let commentUniqueId = json["unique_temp_id"].stringValue
        var commentText = json["message"].stringValue
        let commentSenderName = json["username"].stringValue
        let commentSenderAvatarURL = json["user_avatar_url"].stringValue
        let commentCreatedAt = json["unix_timestamp"].doubleValue
        let commentBeforeId = json["comment_before_id"].intValue
        let senderEmail = json["email"].stringValue
        let commentType = json["type"].stringValue
        let roomId = "\(json["room_id"])"
        let commentExtras = "\(json["extras"])"
        
        if commentType == "reply" || commentType == "buttons" {
            commentText = json["payload"]["text"].stringValue
        }
        
        let avatarURL = json["user_avatar_url"].stringValue
        
        let _ = QUser.saveUser(withEmail: senderEmail, fullname: commentSenderName, avatarURL: avatarURL)
        
        temp.uniqueId = commentUniqueId
        temp.id = commentId
        temp.roomId = roomId
        temp.text = commentText
        temp.senderName = commentSenderName
        temp.senderAvatarURL = commentSenderAvatarURL
        temp.createdAt = commentCreatedAt
        temp.beforeId = commentBeforeId
        temp.senderEmail = senderEmail
        temp.cellPosRaw = QCellPosition.single.rawValue
        temp.rawExtra = commentExtras
        temp.statusRaw = QCommentStatus.sent.rawValue
        
        if let roomName = json["room_name"].string {
            temp.roomName = roomName
        }
        if let chatType = json["chat_type"].string {
            if chatType == "group" {
                temp.roomTypeRaw = QRoomType.group.rawValue
            }else{
                temp.roomTypeRaw = QRoomType.single.rawValue
            }
        }
        if let roomAvatar = json["room_avatar"].string {
            temp.roomAvatar = roomAvatar
        }
        
        switch commentType {
        case "contact":
            temp.data = "\(json["payload"])"
            temp.typeRaw = QCommentType.contact.name()
            break
        case "buttons":
            temp.data = "\(json["payload"]["buttons"])"
            temp.typeRaw = QCommentType.postback.name()
            break
        case "account_linking":
            temp.data = "\(json["payload"])"
            temp.typeRaw = QCommentType.account.name()
            break
        case "reply":
            temp.data = "\(json["payload"])"
            temp.typeRaw = QCommentType.reply.name()
            break
        case "system_event":
            temp.data = "\(json["payload"])"
            temp.typeRaw = QCommentType.system.name()
            break
        case "card":
            temp.data = "\(json["payload"])"
            temp.typeRaw = QCommentType.card.name()
            break
        case "button_postback_response" :
            temp.data = "\(json["payload"])"
            temp.typeRaw = QCommentType.text.name()
            break
        case "location":
            temp.data = "\(json["payload"])"
            temp.typeRaw = QCommentType.location.name()
            break
        case "custom":
            temp.data = "\(json["payload"])"
            temp.typeRaw = json["payload"]["type"].stringValue
            break
        case "file_attachment":
            temp.data = "\(json["payload"])"
            var type = QiscusFileType.file
            let fileURL = json["payload"]["url"].stringValue
            var filename = temp.fileName(text: fileURL)
            
            if filename.contains("-"){
                let nameArr = filename.split(separator: "-")
                var i = 0
                for comp in nameArr {
                    switch i {
                    case 0 : filename = "" ; break
                    case 1 : filename = "\(String(comp))"
                    default: filename = "\(filename)-\(comp)"
                    }
                    i += 1
                }
            }
            if temp.file == nil {
                let file = QFile()
                file.id = temp.uniqueId
                file.url = fileURL
                file.filename = filename
                file.senderEmail = temp.senderEmail
                type = file.type
            }
            switch type {
            case .image:
                temp.typeRaw = QCommentType.image.name()
                break
            case .video:
                temp.typeRaw = QCommentType.video.name()
                break
            case .audio:
                temp.typeRaw = QCommentType.audio.name()
                break
            case .document:
                temp.typeRaw = QCommentType.document.name()
                break
            default:
                temp.typeRaw = QCommentType.file.name()
                break
            }
            break
        case "text":
            if temp.text.hasPrefix("[file]"){
                var type = QiscusFileType.file
                let fileURL = QFile.getURL(fromString: temp.text)
                var filename = temp.fileName(text: fileURL)
                
                if filename.contains("-"){
                    let nameArr = filename.split(separator: "-")
                    var i = 0
                    for comp in nameArr {
                        switch i {
                        case 0 : filename = "" ; break
                        case 1 : filename = "\(String(comp))"
                        default: filename = "\(filename)-\(comp)"
                        }
                        i += 1
                    }
                }
                if temp.file == nil {
                    let file = QFile()
                    file.id = temp.uniqueId
                    file.url = fileURL
                    file.senderEmail = temp.senderEmail
                    file.filename = filename
                    type = file.type
                }
                switch type {
                case .image:
                    temp.typeRaw = QCommentType.image.name()
                    break
                case .video:
                    temp.typeRaw = QCommentType.video.name()
                    break
                case .audio:
                    temp.typeRaw = QCommentType.audio.name()
                    break
                case .document:
                    temp.typeRaw = QCommentType.document.name()
                    break
                default:
                    temp.typeRaw = QCommentType.file.name()
                    break
                }
            }else{
                temp.typeRaw = QCommentType.text.name()
            }
            break
        default:
            temp.data = "\(json["payload"])"
            temp.typeRaw = commentType
            break
        }
        return temp
    }
    internal func update(commentId:Int, beforeId:Int){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        try! realm.write {
            self.id = commentId
            self.beforeId = beforeId
        }
    }
    internal func update(text:String){
        if self.text != text {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            realm.refresh()
            try! realm.write {
                self.text = text
            }
        }
    }
    internal func update(data:String){
        if self.data != data {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            realm.refresh()
            try! realm.write {
                self.data = data
            }
        }
    }
    
    internal func cacheAll(){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        let data = realm.objects(QComment.self)
        let comments = [QComment]()
        
        for comment in comments{
            comment.cacheObject()
        }
    }
    
    internal func cacheObject(){
        if Thread.isMainThread {
            if QComment.cache[self.uniqueId] == nil {
                QComment.cache[self.uniqueId] = self
            }
        }
    }
    
    internal class func resendPendingMessage(){
        QiscusDBThread.async {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            realm.refresh()
            let data = realm.objects(QComment.self).filter("statusRaw == 1")
            
            if let comment = data.first {
                if Thread.isMainThread {
                    if let room = QRoom.room(withId: comment.roomId){
                        room.updateCommentStatus(inComment: comment, status: .sending)
                        room.post(comment: comment) {
                            self.resendPendingMessage()
                        }
                    }
                }else{
                    let commentTS = ThreadSafeReference(to: comment)
                    DispatchQueue.main.sync {
                        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                        realm.refresh()
                        guard let c = realm.resolve(commentTS) else { return }
                        if let room = QRoom.room(withId: c.roomId){
                            room.updateCommentStatus(inComment: c, status: .sending)
                            room.post(comment: c) {
                                self.resendPendingMessage()
                            }
                        }
                    }
                }
            }
        }
    }
}
