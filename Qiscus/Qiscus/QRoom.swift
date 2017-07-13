//
//  QRoom.swift
//  Example
//
//  Created by Ahmad Athaullah on 7/5/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftyJSON

@objc public enum QRoomType:Int{
    case single
    case group
}
public protocol QRoomDelegate {
    func room(didChangeName room:QRoom)
    func room(didChangeAvatar room:QRoom)
    func room(didChangeParticipant room:QRoom)
    func room(didChangeGroupComment section:Int)
    func room(didChangeComment section:Int, row:Int)
    func room(didFinishSync room:QRoom)
    func room(gotNewGroupComment onIndex:Int)
    func room(gotNewCommentOn groupIndex:Int, withCommentIndex index:Int)
    func room(didFailUpdate error:String)
}
public class QRoom:Object {
    public dynamic var id:Int = 0
    public dynamic var uniqueId:String = ""
    public dynamic var name:String = ""
    public dynamic var avatarURL:String = ""
    public dynamic var avatarLocalPath:String = ""
    public dynamic var data:String = ""
    public dynamic var distinctId:String = ""
    public dynamic var typeRaw:Int = QRoomType.single.rawValue
    public dynamic var singleUser:String = ""
    
    public let comments = List<QCommentGroup>()
    public let participants = List<QParticipant>()
    
    // MARK: - Getter variable
    public var type:QRoomType {
        get{
            return QRoomType(rawValue: self.typeRaw)!
        }
    }
    public var delegate:QRoomDelegate?
    
    // MARK: - Primary Key
    override public class func primaryKey() -> String {
        return "id"
    }
    
    var service:QRoomService?
    
    // MARK: - Class method
    public class func room(withId id:Int) -> QRoom? {
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        return realm.object(ofType: QRoom.self, forPrimaryKey: id)
    }
    public class func room(withUniqueId uniqueId:String) -> QRoom? {
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        var room:QRoom? = nil
        let data =  realm.objects(QRoom.self).filter("uniqueId == \(uniqueId)")
        
        if data.count > 0{
            room = data.first!
        }
        return room
    }
    public class func room(withUser user:String) -> QRoom? {
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        var room:QRoom? = nil
        let data =  realm.objects(QRoom.self).filter("singleUser == \(user)")
        
        if data.count > 0{
            room = data.first!
        }
        return room
    }
    public class func addRoom(fromJSON json:JSON)->QRoom{
        let room = QRoom()
        if let id = json["id"].int {
            room.id = id
            if let option = json["options"].string {
                if option != "" && option != "<null>" {
                    room.data = option
                }
            }
            if let roomUniqueId = json["unique_id"].string {
                room.uniqueId = roomUniqueId
            }
            if let chatType = json["chat_type"].string{
                switch chatType {
                case "single":
                    room.typeRaw = QRoomType.single.rawValue
                    break
                default:
                    room.typeRaw = QRoomType.group.rawValue
                    break
                }
            }
            if let distinctId = json["distinct_id"].string {
                room.distinctId = distinctId
            }
            if let roomName = json["room_name"].string {
                room.name = roomName
            }
            if let roomAvatar = json["avatar_url"].string {
                room.avatarURL = roomAvatar
            }
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            
            try! realm.write {
                realm.add(room, update: true)
            }
            
            // get the participants and save it
            var participantString = [String]()
            for participantJSON in json["participants"].arrayValue {
                let participantEmail = participantJSON["email"].stringValue
                //save or update user first
                var savedUser = QUser.user(withEmail: participantEmail)
                if savedUser == nil {
                    savedUser = QUser()
                    savedUser?.email = participantEmail
                    savedUser?.fullname = participantJSON["username"].stringValue
                    savedUser?.avatarURL = participantJSON["avatar_url"].stringValue
                    try! realm.write {
                        realm.add(savedUser!, update: true)
                    }
                }else{
                    try! realm.write {
                        savedUser!.fullname = participantJSON["username"].stringValue
                        savedUser!.avatarURL = participantJSON["avatar_url"].stringValue
                    }
                }
                if room.type == .single {
                    if participantEmail != QiscusMe.sharedInstance.email {
                        try! realm.write {
                            room.singleUser = participantEmail
                        }
                    }
                }
                //then save participants
                if QParticipant.participant(inRoomWithId: room.id, andEmail: participantEmail) == nil{
                    let newParticipant = QParticipant()
                    newParticipant.localId = "\(room.id)_\(participantEmail)"
                    newParticipant.email = participantEmail
                    try! realm.write {
                        room.participants.append(newParticipant)
                    }
                }
                participantString.append(participantEmail)
            }
            var index = 0
            for participant in room.participants{
                if !participantString.contains(participant.email){
                    room.participants.remove(objectAtIndex: index)
                }
                index += 1
            }
            
        }
        return room
    }
    public func syncRoomData(withJSON json:JSON){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        if let option = json["options"].string {
            if option != "" && option != "<null>" && option != self.data{
                try! realm.write {
                    self.data = option
                }
            }
        }
        if let roomUniqueId = json["unique_id"].string {
            if roomUniqueId != self.uniqueId {
                try! realm.write {
                    self.uniqueId = roomUniqueId
                }
            }
        }

        if let roomName = json["room_name"].string {
            if roomName != self.name {
                try! realm.write {
                    self.name = roomName
                }
                self.delegate?.room(didChangeName: self)
            }
        }
        if let roomAvatar = json["avatar_url"].string {
            if roomAvatar != self.avatarURL {
                try! realm.write {
                    self.avatarURL = roomAvatar
                    self.avatarLocalPath = ""
                }
                self.delegate?.room(didChangeAvatar: self)
            }
        }
        
        
        // get the participants and save it
        var participantString = [String]()
        var participantChanged = false
        for participantJSON in json["participants"].arrayValue {
            let participantEmail = participantJSON["email"].stringValue
            //save or update user first
            var savedUser = QUser.user(withEmail: participantEmail)
            if savedUser == nil {
                savedUser = QUser()
                savedUser?.email = participantEmail
                savedUser?.fullname = participantJSON["username"].stringValue
                savedUser?.avatarURL = participantJSON["avatar_url"].stringValue
                try! realm.write {
                    realm.add(savedUser!, update: true)
                }
            }else{
                let fullname = participantJSON["username"].stringValue
                let avatarURL = participantJSON["avatar_url"].stringValue
                if savedUser!.fullname != fullname {
                    try! realm.write {
                        savedUser!.fullname = fullname
                    }
                    participantChanged = true
                    
                }
                if savedUser!.avatarURL != avatarURL {
                    try! realm.write {
                        savedUser!.avatarURL = avatarURL
                        savedUser!.avatarLocalPath = ""
                    }
                    participantChanged = true
                }
                if participantChanged {
                    var section = 0
                    for commentGroup in self.comments {
                        if commentGroup.senderEmail == savedUser!.email {
                            self.delegate?.room(didChangeGroupComment: section)
                        }
                        section += 1
                    }
                }
            }
            //then save participants
            if QParticipant.participant(inRoomWithId: self.id, andEmail: participantEmail) == nil{
                let newParticipant = QParticipant()
                newParticipant.localId = "\(self.id)_\(participantEmail)"
                newParticipant.email = participantEmail
                try! realm.write {
                    self.participants.append(newParticipant)
                }
                participantChanged = true
            }
            participantString.append(participantEmail)
        }
        var index = 0
        for participant in self.participants{
            if !participantString.contains(participant.email){
                try! realm.write {
                    self.participants.remove(objectAtIndex: index)
                }
                participantChanged = true
            }
            index += 1
        }
        if participantChanged {
            self.delegate?.room(didChangeParticipant: self)
        }
    }
    public func saveNewComment(fromJSON json:JSON){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let commentId = json["id"].intValue
        let commentUniqueId = json["unique_temp_id"].stringValue
        let commentText = json["message"].stringValue
        let commentSenderName = json["username"].stringValue
        let commentCreatedAt = json["unix_timestamp"].doubleValue
        let commentBeforeId = json["comment_before_id"].intValue
        let senderEmail = json["email"].stringValue
        
        //Check sender
        if QUser.user(withEmail: senderEmail) == nil{
            let user = QUser()
            user.email = senderEmail
            user.avatarURL = json["user_avatar_url"].stringValue
            user.fullname = commentSenderName
            try! realm.write {
                realm.add(user)
            }
        }
        if let oldComment = QComment.comment(withUniqueId: commentUniqueId) {
            // it should be on realm
            try! realm.write {
                oldComment.id = commentId
                oldComment.text = commentText
                oldComment.senderName = commentSenderName
                oldComment.createdAt = commentCreatedAt
                oldComment.beforeId = commentBeforeId
            }
            if oldComment.statusRaw < QCommentStatus.sent.rawValue{
                try! realm.write {
                    oldComment.statusRaw = QCommentStatus.sent.rawValue
                }
                var section = 0
                for commentGroup in self.comments{
                    var row = 0
                    for commentTarget in commentGroup.comments{
                        if commentTarget.uniqueId == oldComment.uniqueId{
                            self.delegate?.room(didChangeComment: section, row: row)
                            break
                        }
                        row += 1
                    }
                    section += 1
                }
            }
        }else{
            let newComment = QComment()
            newComment.uniqueId = commentUniqueId
            newComment.id = commentId
            newComment.text = commentText
            newComment.senderName = commentSenderName
            newComment.createdAt = commentCreatedAt
            newComment.beforeId = commentBeforeId
            newComment.senderEmail = senderEmail
            
            let commentType = json["type"].stringValue
            
            switch commentType {
            case "buttons":
                newComment.text = json["payload"]["text"].stringValue
                newComment.data = "\(json["payload"]["buttons"])"
                newComment.typeRaw = QCommentType.postback.rawValue
                break
            case "account_linking":
                newComment.data = "\(json["payload"])"
                newComment.typeRaw = QCommentType.account.rawValue
                break
            case "reply":
                newComment.data = "\(json["payload"])"
                newComment.typeRaw = QCommentType.account.rawValue
                break
            case "system_event":
                newComment.data = "\(json["payload"])"
                newComment.typeRaw = QCommentType.system.rawValue
                break
            default:
                if newComment.text.hasPrefix("[file]"){
                    var type = QiscusFileType.file
                    let fileURL = QFile.getURL(fromString: newComment.text)
                    if newComment.file == nil {
                        let file = QFile()
                        file.id = newComment.uniqueId
                        file.url = fileURL
                        file.senderEmail = newComment.senderEmail
                        try! realm.write {
                            realm.add(file)
                        }
                        type = file.type
                    }else{
                        try! realm.write {
                            newComment.file!.url = QFile.getURL(fromString: newComment.text)
                        }
                        type = newComment.file!.type
                    }
                    switch type {
                    case .image:
                        newComment.typeRaw = QCommentType.image.rawValue
                        break
                    case .video:
                        newComment.typeRaw = QCommentType.video.rawValue
                        break
                    case .audio:
                        newComment.typeRaw = QCommentType.audio.rawValue
                        break
                    default:
                        newComment.typeRaw = QCommentType.file.rawValue
                        break
                    }
                }else{
                    newComment.typeRaw = QCommentType.text.rawValue
                }
                break
            }
            if self.comments.count == 0 {
                let commentGroup = QCommentGroup()
                commentGroup.senderEmail = newComment.senderEmail
                commentGroup.senderName = newComment.senderName
                commentGroup.createdAt = newComment.createdAt
                commentGroup.id = "\(self.id):::\(newComment.date):::\(newComment.senderEmail)"
                commentGroup.comments.append(newComment)
                try! realm.write {
                    self.comments.append(commentGroup)
                }
                self.delegate?.room(gotNewGroupComment: 0)
            }else{
                if let commentGroup = QCommentGroup.commentGroup(onRoomWithId: self.id, senderEmail: newComment.senderEmail, date: newComment.date){
                    try! realm.write {
                        commentGroup.comments.append(newComment)
                    }
                    var section = self.comments.count - 1
                    let row = commentGroup.comments.count - 1
                    for commentGroupCheck in self.comments.reversed() {
                        if commentGroup.id == commentGroupCheck.id {
                            self.delegate?.room(gotNewCommentOn: section, withCommentIndex: row)
                            break
                        }
                        section -= 1
                    }
                }else{
                    let commentGroup = QCommentGroup()
                    commentGroup.senderEmail = newComment.senderEmail
                    commentGroup.senderName = newComment.senderName
                    commentGroup.createdAt = newComment.createdAt
                    commentGroup.id = "\(self.id):::\(newComment.date):::\(newComment.senderEmail)"
                    commentGroup.comments.append(newComment)
                    try! realm.write {
                        self.comments.append(commentGroup)
                    }
                    self.delegate?.room(gotNewGroupComment: self.comments.count - 1)
                }
                
            }
        }
        // TODO: - check for update last read/delivered on participant
        if let participant = QParticipant.participant(inRoomWithId: self.id, andEmail: senderEmail) {
            if participant.lastReadCommentId < commentId {
                try! realm.write {
                    participant.lastReadCommentId = commentId
                    participant.lastDeliveredCommentId = commentId
                }
            }else if participant.lastDeliveredCommentId < commentId{
                try! realm.write {
                    participant.lastDeliveredCommentId = commentId
                }
            }
        }
    }
    public func saveOldComment(fromJSON json:JSON){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let commentId = json["id"].intValue
        let commentUniqueId = json["unique_temp_id"].stringValue
        let commentText = json["message"].stringValue
        let commentSenderName = json["username"].stringValue
        let commentCreatedAt = json["unix_timestamp"].doubleValue
        let commentBeforeId = json["comment_before_id"].intValue
        let senderEmail = json["email"].stringValue
        
        //Check sender
        if QUser.user(withEmail: senderEmail) == nil{
            let user = QUser()
            user.email = senderEmail
            user.avatarURL = json["user_avatar_url"].stringValue
            user.fullname = commentSenderName
            try! realm.write {
                realm.add(user)
            }
        }
        if let oldComment = QComment.comment(withUniqueId: commentUniqueId) {
            try! realm.write {
                oldComment.id = commentId
                oldComment.text = commentText
                oldComment.senderName = commentSenderName
                oldComment.createdAt = commentCreatedAt
                oldComment.beforeId = commentBeforeId
            }
            if oldComment.statusRaw < QCommentStatus.sent.rawValue{
                try! realm.write {
                    oldComment.statusRaw = QCommentStatus.sent.rawValue
                }
                var section = 0
                for commentGroup in self.comments{
                    var row = 0
                    for commentTarget in commentGroup.comments{
                        if commentTarget.uniqueId == oldComment.uniqueId{
                            self.delegate?.room(didChangeComment: section, row: row)
                            break
                        }
                        row += 1
                    }
                    section += 1
                }
            }
        }else{
            let newComment = QComment()
            newComment.uniqueId = commentUniqueId
            newComment.id = commentId
            newComment.text = commentText
            newComment.senderName = commentSenderName
            newComment.createdAt = commentCreatedAt
            newComment.beforeId = commentBeforeId
            newComment.senderEmail = senderEmail
            
            let commentType = json["type"].stringValue
            
            switch commentType {
            case "buttons":
                newComment.text = json["payload"]["text"].stringValue
                newComment.data = "\(json["payload"]["buttons"])"
                newComment.typeRaw = QCommentType.postback.rawValue
                break
            case "account_linking":
                newComment.data = "\(json["payload"])"
                newComment.typeRaw = QCommentType.account.rawValue
                break
            case "reply":
                newComment.data = "\(json["payload"])"
                newComment.typeRaw = QCommentType.account.rawValue
                break
            case "system_event":
                newComment.data = "\(json["payload"])"
                newComment.typeRaw = QCommentType.system.rawValue
                break
            default:
                if newComment.text.hasPrefix("[file]"){
                    var type = QiscusFileType.file
                    let fileURL = QFile.getURL(fromString: newComment.text)
                    if newComment.file == nil {
                        let file = QFile()
                        file.id = newComment.uniqueId
                        file.url = fileURL
                        file.senderEmail = newComment.senderEmail
                        try! realm.write {
                            realm.add(file)
                        }
                        type = file.type
                    }else{
                        try! realm.write {
                            newComment.file!.url = QFile.getURL(fromString: newComment.text)
                        }
                        type = newComment.file!.type
                    }
                    switch type {
                    case .image:
                        newComment.typeRaw = QCommentType.image.rawValue
                        break
                    case .video:
                        newComment.typeRaw = QCommentType.video.rawValue
                        break
                    case .audio:
                        newComment.typeRaw = QCommentType.audio.rawValue
                        break
                    default:
                        newComment.typeRaw = QCommentType.file.rawValue
                        break
                    }
                }else{
                    newComment.typeRaw = QCommentType.text.rawValue
                }
                break
            }
            if self.comments.count == 0 {
                let commentGroup = QCommentGroup()
                commentGroup.senderEmail = newComment.senderEmail
                commentGroup.senderName = newComment.senderName
                commentGroup.createdAt = newComment.createdAt
                commentGroup.id = "\(self.id):::\(newComment.date):::\(newComment.senderEmail)"
                commentGroup.comments.append(newComment)
                try! realm.write {
                    self.comments.append(commentGroup)
                }
                self.delegate?.room(gotNewGroupComment: 0)
            }else{
                if let commentGroup = QCommentGroup.commentGroup(onRoomWithId: self.id, senderEmail: newComment.senderEmail, date: newComment.date){
                    try! realm.write {
                        commentGroup.createdAt = newComment.createdAt
                        commentGroup.senderName = newComment.senderName
                        commentGroup.comments.insert(newComment, at: 0)
                    }
                    var section = 0
                    for commentGroupCheck in self.comments {
                        if commentGroup.id == commentGroupCheck.id {
                            self.delegate?.room(gotNewCommentOn: section, withCommentIndex: 0)
                            break
                        }
                        section += 1
                    }
                }else{
                    let commentGroup = QCommentGroup()
                    commentGroup.senderEmail = newComment.senderEmail
                    commentGroup.senderName = newComment.senderName
                    commentGroup.createdAt = newComment.createdAt
                    commentGroup.id = "\(self.id):::\(newComment.date):::\(newComment.senderEmail)"
                    commentGroup.comments.append(newComment)
                    try! realm.write {
                        self.comments.insert(commentGroup, at: 0)
                    }
                    self.delegate?.room(gotNewGroupComment: 0)
                }
                
            }
        }
        // TODO: - check for update last read/delivered on participant
        if let participant = QParticipant.participant(inRoomWithId: self.id, andEmail: senderEmail) {
            if participant.lastReadCommentId < commentId {
                try! realm.write {
                    participant.lastReadCommentId = commentId
                    participant.lastDeliveredCommentId = commentId
                }
            }else if participant.lastDeliveredCommentId < commentId{
                try! realm.write {
                    participant.lastDeliveredCommentId = commentId
                }
            }
        }
    }
    
    public func sync(){
        if self.service == nil {
            self.service = QRoomService()
        }
        self.service?.sync(onRoom: self)
    }
    public func loadMore(){
        if self.service == nil {
            self.service = QRoomService()
        }
        self.service?.loadMore(onRoom: self)
    }
    
    // MARK: - Updater method
    public func update(name:String? = nil, avatarURL:String? = nil, data:String? = nil){
        if self.service == nil {
            self.service = QRoomService()
        }
        self.service?.updateRoom(onRoom: self, roomName: name, roomAvatarURL: avatarURL, roomOptions: data)
    }
    public func publishCommentStatus(withStatus status:QCommentStatus){
        if self.service == nil {
            self.service = QRoomService()
        }
        self.service?.publisComentStatus(onRoom: self, status: status)
    }
}
