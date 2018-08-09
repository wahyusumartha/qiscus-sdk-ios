//
//  QComment.swift
//  Alamofire
//
//  Created by asharijuang on 07/08/18.
//

import Foundation
import QiscusCore
import SwiftyJSON

@objc public enum QCommentType:Int {
    case text
    case image
    case video
    case audio
    case file
    case postback
    case account
    case reply
    case system
    case card
    case contact
    case location
    case custom
    case document
    case carousel
    
    static let all = [text.name(), image.name(), video.name(), audio.name(),file.name(),postback.name(),account.name(), reply.name(), system.name(), card.name(), contact.name(), location.name(), custom.name()]
    
    func name() -> String{
        switch self {
        case .text      : return "text"
        case .image     : return "image"
        case .video     : return "video"
        case .audio     : return "audio"
        case .file      : return "file"
        case .postback  : return "postback"
        case .account   : return "account"
        case .reply     : return "reply"
        case .system    : return "system"
        case .card      : return "card"
        case .contact   : return "contact_person"
        case .location  : return "location"
        case .custom    : return "custom"
        case .document  : return "document"
        case .carousel  : return "carousel"
        }
    }
    init(name:String) {
        switch name {
        case "text","button_postback_response"     : self = .text ; break
        case "image"            : self = .image ; break
        case "video"            : self = .video ; break
        case "audio"            : self = .audio ; break
        case "file"             : self = .file ; break
        case "postback"         : self = .postback ; break
        case "account"          : self = .account ; break
        case "reply"            : self = .reply ; break
        case "system"           : self = .system ; break
        case "card"             : self = .card ; break
        case "contact_person"   : self = .contact ; break
        case "location"         : self = .location; break
        case "document"         : self = .document; break
        case "carousel"         : self = .carousel; break
        default                 : self = .custom ; break
        }
    }
}

public class QComment: CommentModel {
    
    public var senderName : String{
        get{
            return username
        }
    }
    
    public var text : String{
        get{
            return message
        }
    }
    
    public var createdAt : Int{
        get{
            return unixTimestamp
        }
    }
    
    public var senderEmail: String{
        get{
            return email
        }
    }
    
    //need room name from QComment
    public var roomName : String{
        get{
            return "room name harcode"
        }
    }
    
    //need payload string from QComment
    public var payloadData : String{
        get{
            return "need to be implement payloadData"
        }
    }
    
    //need extras string from QComment
    public var extrasData : String {
        get{
            return "need to be implement extra"
        }
    }
    
    public var typeMessage: QCommentType{
        get{
            return QCommentType.init(name: type)
        }
    }
    
    public var date: String {
        get {
            let date = Date(timeIntervalSince1970: TimeInterval(self.createdAt))
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d MMMM yyyy"
            let dateString = dateFormatter.string(from: date)
            
            return dateString
        }
    }
    
    //Todo search comment from local
    internal class func comments(searchQuery: String) -> [QComment] {
//        if Thread.isMainThread {
//            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
//            realm.refresh()
//            
//            let comments = realm.objects(QComment.self).filter({ (comment) -> Bool in
//                return comment.text.lowercased().contains(searchQuery.lowercased())
//            })
//            
//            return Array(comments)
//        }
//        
        return [QComment]()
    }
    
    //Todo call resendPendingMessage
    internal class func resendPendingMessage(){
        
    }
    
     //Todo get model comment
    internal class func tempComment(fromJSON json:JSON)->QComment?{
        return nil
    }
    
    public class func decodeDictionary(data:[AnyHashable : Any]) -> QComment? {
        if let isQiscusdata = data["qiscus_commentdata"] as? Bool{
            if isQiscusdata {
                let temp = QComment()
                if let uniqueId = data["qiscus_uniqueId"] as? String{
                    temp.uniqueTempId = uniqueId
                }
                if let id = data["qiscus_id"] as? String {
                    temp.id = id
                }
                if let roomId = data["qiscus_roomId"] as? Int {
                    temp.roomId = roomId
                }
                if let beforeId = data["qiscus_beforeId"] as? Int {
                    temp.commentBeforeId = beforeId
                }
                if let text = data["qiscus_text"] as? String {
                    temp.message = text
                }
                if let createdAt = data["qiscus_createdAt"] as? Int{
                    temp.unixTimestamp = createdAt
                }
                if let email = data["qiscus_senderEmail"] as? String{
                    temp.email = email
                }
                if let name = data["qiscus_senderName"] as? String{
                    temp.username = name
                }
                if let statusRaw = data["qiscus_statusRaw"] as? String {
                    temp.status = statusRaw
                }
                if let typeRaw = data["qiscus_typeRaw"] as? String {
                    temp.type = typeRaw
                }
                if let payload = data["qiscus_data"] as? String {
                    //temp.payloadData = payload
                }
                
                return temp
            }
        }
        return nil
    }
    
    public func encodeDictionary()->[AnyHashable : Any]{
        var data = [AnyHashable : Any]()
        
        data["qiscus_commentdata"] = true
        data["qiscus_uniqueId"] = self.uniqueTempId
        data["qiscus_id"] = self.id
        data["qiscus_roomId"] = self.roomId
        data["qiscus_beforeId"] = self.commentBeforeId
        data["qiscus_text"] = self.text
        data["qiscus_createdAt"] = self.createdAt
        data["qiscus_senderEmail"] = self.senderEmail
        data["qiscus_senderName"] = self.senderName
        data["qiscus_statusRaw"] = self.status
        data["qiscus_typeRaw"] = self.type
        data["qiscus_data"] = self.payloadData
        
        return data
    }
    
    public class QCommentInfo: NSObject {
        public var comment:QComment?
        public var deliveredUser = [QParticipant]()
        public var readUser = [QParticipant]()
        public var undeliveredUser = [QParticipant]()
    }
    
    //TODO Need To be implement
    public var statusInfo:QCommentInfo? {
        get{
//            if let room = QRoom.room(withId: self.roomId) {
//                let commentInfo = QCommentInfo()
//                commentInfo.comment = self
//                commentInfo.deliveredUser = [QParticipant]()
//                commentInfo.readUser = [QParticipant]()
//                commentInfo.undeliveredUser = [QParticipant]()
//                for participant in room.participants {
//                    if participant.email != Qiscus.client.email{
//                        if participant.lastReadCommentId >= self.id {
//                            commentInfo.readUser.append(participant)
//                        }else if participant.lastDeliveredCommentId >= self.id{
//                            commentInfo.deliveredUser.append(participant)
//                        }else{
//                            commentInfo.undeliveredUser.append(participant)
//                        }
//                    }
//                }
//                return commentInfo
//            }
            return nil
        }
    }
    
    //Todo Need Tobe Implement
    public func forward(toRoomWithId roomId: String){
//        let comment = QComment()
//        let time = Double(Date().timeIntervalSince1970)
//        let timeToken = UInt64(time * 10000)
//        let uniqueID = "ios-\(timeToken)"
//
//        comment.uniqueId = uniqueID
//        comment.roomId = roomId
//        comment.text = self.text
//        comment.createdAt = Double(Date().timeIntervalSince1970)
//        comment.senderEmail = Qiscus.client.email
//        comment.senderName = Qiscus.client.userName
//        comment.statusRaw = QCommentStatus.sending.rawValue
//        comment.data = self.data
//        comment.typeRaw = self.type.name()
//        comment.rawExtra = self.rawExtra
//
//        if self.type == .reply {
//            comment.typeRaw = QCommentType.text.name()
//        }
//
//        var file:QFile? = nil
//
//        if let fileRef = self.file {
//            file = QFile()
//            file!.id = uniqueID
//            file!.roomId = roomId
//            file!.url = fileRef.url
//            file!.filename = fileRef.filename
//            file!.senderEmail = Qiscus.client.email
//            file!.localPath = fileRef.localPath
//            file!.mimeType = fileRef.mimeType
//            file!.localThumbPath = fileRef.localThumbPath
//            file!.localMiniThumbPath = fileRef.localMiniThumbPath
//            file!.pages = fileRef.pages
//            file!.size = fileRef.size
//        }
//
//        if let room = QRoom.room(withId: roomId){
//            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
//            realm.refresh()
//            if file != nil {
//                try! realm.write {
//                    realm.add(file!, update:true)
//                }
//            }
//            room.addComment(newComment: comment)
//            room.post(comment: comment, onSuccess: {
//
//            }, onError: { (error) in
//                Qiscus.printLog(text: "error \(error)")
//            })
//        }
        
    }
    
}
