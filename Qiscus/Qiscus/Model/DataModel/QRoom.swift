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
import AVFoundation

@objc public enum QRoomType:Int{
    case single
    case group
}
@objc public protocol QRoomDelegate {
    func room(didChangeName room:QRoom)
    func room(didChangeAvatar room:QRoom)
    func room(didChangeParticipant room:QRoom)
    func room(didChangeGroupComment section:Int)
    func room(didChangeComment section:Int, row:Int, action:String)
    func room(didDeleteComment section:Int, row:Int)
    func room(didDeleteGroupComment section:Int)
    
    func room(didChangeUser room:QRoom, user:QUser)
    func room(didFinishSync room:QRoom)
    @objc optional func room(gotNewGroupComment onIndex:Int)
    @objc optional func room(gotNewCommentOn groupIndex:Int, withCommentIndex index:Int)
    @objc optional func room(gotNewComment comment:QComment)
    func room(didFailUpdate error:String)
    
    func room(userDidTyping userEmail:String)
    func room(didFinishLoadMore inRoom:QRoom, success:Bool, gotNewComment:Bool)
    func room(didChangeUnread lastReadCommentId:Int, unreadCount:Int)
}
public class QRoom:Object {
    public dynamic var id:String = ""
    public dynamic var uniqueId:String = ""
    private dynamic var storedName:String = ""
    private dynamic var definedname:String = ""
    public dynamic var avatarURL:String = ""
    public dynamic var avatarLocalPath:String = ""
    public dynamic var data:String = ""
    public dynamic var distinctId:String = ""
    public dynamic var typeRaw:Int = QRoomType.single.rawValue
    public dynamic var singleUser:String = ""
    public dynamic var typingUser:String = ""
    public dynamic var lastReadCommentId: Int = 0
    public dynamic var isLocked:Bool = false
    
    internal dynamic var unreadCommentCount:Int = 0
    public dynamic var unreadCount:Int = 0
    private dynamic var pinned:Double = 0
    
    // MARK: - lastComment variable
    private dynamic var lastCommentId:Int = 0
    private dynamic var lastCommentText:String = ""
    private dynamic var lastCommentUniqueId: String = ""
    private dynamic var lastCommentBeforeId:Int = 0
    private dynamic var lastCommentCreatedAt: Double = 0
    private dynamic var lastCommentSenderEmail:String = ""
    private dynamic var lastCommentSenderName:String = ""
    private dynamic var lastCommentStatusRaw:Int = QCommentStatus.sending.rawValue
    private dynamic var lastCommentTypeRaw:String = QCommentType.text.name()
    private dynamic var lastCommentData:String = ""
    private dynamic var lastCommentRawExtras:String = ""
    
    
    // MARK: private method
    private dynamic var lastParticipantsReadId:Int = 0
    private dynamic var lastParticipantsDeliveredId:Int = 0
    private dynamic var roomVersion005:Bool = true
    
    public let comments = List<QCommentGroup>()
    public let participants = List<QParticipant>()
    
    public var delegate:QRoomDelegate?
    private var typingTimer:Timer?
    private var selfTypingTimer:Timer?
    
    public var isPinned:Bool {
        get{
            return self.pinned != 0
        }
    }
    
    // MARK: - Unstored properties
    override public static func ignoredProperties() -> [String] {
        return ["typingTimer","delegate"]
    }
    
    // MARK: - Getter variable
    public var name:String{
        if self.definedname != "" {
            return self.definedname
        }else{
            return self.storedName
        }
    }
    public var lastCommentGroup:QCommentGroup?{
        get{
            if let group = self.comments.last {
                return QCommentGroup.commentGroup(withId: group.id)
            }else{
                return nil
            }
        }
    }
    public var lastComment:QComment?{
        get{
            if let comment = QComment.comment(withUniqueId: self.lastCommentUniqueId){
                return comment
            }else{
                if self.lastCommentId > 0 {
                    let comment = QComment()
                    comment.id = self.lastCommentId
                    comment.uniqueId = self.lastCommentUniqueId
                    comment.roomId = self.id
                    comment.text = self.lastCommentText
                    comment.senderName = self.lastCommentSenderName
                    comment.createdAt = self.lastCommentCreatedAt
                    comment.beforeId = self.lastCommentBeforeId
                    comment.senderEmail = self.lastCommentSenderName
                    comment.roomName = self.name
                    comment.cellPosRaw = QCellPosition.single.rawValue
                    comment.typeRaw = self.lastCommentTypeRaw
                    comment.data = self.lastCommentData
                    comment.rawExtra = self.lastCommentRawExtras
                    return comment
                }
            }
            return nil
        }
    }
    public var commentsGroupCount:Int{
        return self.comments.count
    }
    public var type:QRoomType {
        get{
            return QRoomType(rawValue: self.typeRaw)!
        }
    }
    
    public var listComment:[QComment]{
        get{
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            var comments = [QComment]()
            let data =  realm.objects(QComment.self).filter("roomId == '\(self.id)'").sorted(byKeyPath: "createdAt", ascending: true)
            for comment in data {
                let data = QComment.comment(withUniqueId: comment.uniqueId)!
                comments.append(data)
            }
            return comments
        }
    }
    
    // MARK: - Primary Key
    override public class func primaryKey() -> String {
        return "id"
    }
    
    // MARK: - Class method
    public class func all() -> [QRoom]{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let data = realm.objects(QRoom.self).sorted(byKeyPath: "pinned", ascending: false).sorted(byKeyPath: "lastCommentCreatedAt", ascending: false)
        
        if data.count > 0 {
            return Array(data)
        }else{
            return [QRoom]()
        }
    }
    public func pin(){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        try! realm.write {
            self.pinned = Double(Date().timeIntervalSince1970)
        }
    }
    public func unpin(){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        try! realm.write {
            self.pinned = 0
        }
    }
    public class func unpinAll(){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let data = realm.objects(QRoom.self).filter(("pinned > 0"))
        
        for room in data {
            room.unpin()
        }
    }
    internal class func cacheAll(){
        let rooms = QRoom.all()
        for room in rooms{
            room.cache()
        }
    }
    internal class func threadSaveRoom(withId id:String) -> QRoom? {
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let room = realm.object(ofType: QRoom.self, forPrimaryKey: id)
        if room != nil {
            return room
        }
        return nil
    }
    public class func room(withId id:String) -> QRoom? {
        if let cache = Qiscus.chatRooms[id] {
            if !cache.isInvalidated {
                return cache
            }else{
                Qiscus.chatRooms[id] == nil
            }
        }
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let room = realm.object(ofType: QRoom.self, forPrimaryKey: id)
        if room != nil {
            room?.resetRoomComment()
            Qiscus.chatRooms[room!.id] = room!
            if Qiscus.shared.chatViews[room!.id] ==  nil{
                let chatView = QiscusChatVC()
                chatView.chatRoom = Qiscus.chatRooms[room!.id]
                Qiscus.shared.chatViews[room!.id] = chatView
            }
            return room
        }
        return nil
    }
    public class func room(withUniqueId uniqueId:String) -> QRoom? {
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let data =  realm.objects(QRoom.self).filter("uniqueId == '\(uniqueId)'")
        
        if data.count > 0{
            let room = data.first!
            if let cachedRoom = Qiscus.chatRooms[room.id] {
                return cachedRoom
            }else{
                room.resetRoomComment()
                Qiscus.chatRooms[room.id] = room
                if Qiscus.shared.chatViews[room.id] ==  nil{
                    let chatView = QiscusChatVC()
                    chatView.chatRoom = Qiscus.chatRooms[room.id]
                    Qiscus.shared.chatViews[room.id] = chatView
                }
                Qiscus.sharedInstance.RealtimeConnect()
                return room
            }
        }
        return nil
    }
    public class func room(withUser user:String) -> QRoom? {
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let data =  realm.objects(QRoom.self).filter("singleUser == '\(user)'")
        
        if data.count > 0{
            let room = data.first!
            if let cachedRoom = Qiscus.chatRooms[room.id] {
                return cachedRoom
            }else{
                room.resetRoomComment()
                Qiscus.chatRooms[room.id] = room
                if Qiscus.shared.chatViews[room.id] ==  nil{
                    let chatView = QiscusChatVC()
                    chatView.chatRoom = Qiscus.chatRooms[room.id]
                    Qiscus.shared.chatViews[room.id] = chatView
                }
                Qiscus.sharedInstance.RealtimeConnect()
                return room
            }
        }
        return nil
    }
    
    public class func addRoom(fromJSON json:JSON)->QRoom{
        let room = QRoom()
        if json["id"] != JSON.null {
            room.id = "\(json["id"])"
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
                room.storedName = roomName
            }
            if let roomAvatar = json["avatar_url"].string {
                room.avatarURL = roomAvatar
            }
            if json["last_comment"] != JSON.null {
                let commentData = json["last_comment"]
                let comment = QComment.tempComment(fromJSON: commentData)
                
                room.lastCommentId = comment.id
                room.lastCommentText = comment.text
                room.lastCommentUniqueId = comment.uniqueId
                room.lastCommentBeforeId = comment.beforeId
                room.lastCommentCreatedAt = comment.createdAt
                room.lastCommentSenderEmail = comment.senderEmail
                room.lastCommentSenderName = comment.senderName
                room.lastCommentStatusRaw = comment.statusRaw
                room.lastCommentTypeRaw = comment.typeRaw
                room.lastCommentData = comment.data
            }else{
                if let lastMessage = json["last_comment_message"].string{
                    room.lastCommentText = lastMessage
                }
                if let lastMessageTime = json["last_comment_timestamp_unix"].double{
                    room.lastCommentCreatedAt = lastMessageTime
                }
                if let lastCommentId = json["last_comment_id"].int{
                    room.lastCommentId = lastCommentId
                }
            }
            
            if let unread = json["unread_count"].int {
                room.unreadCount = unread
            }
            
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            
            try! realm.write {
                realm.add(room, update: true)
            }
            
            // get the participants and save it
            if let participants = json["participants"].array{
                var participantString = [String]()
                for participantJSON in participants {
                    let participantEmail = participantJSON["email"].stringValue
                    let fullname = participantJSON["username"].stringValue
                    let avatarURL = participantJSON["avatar_url"].stringValue
                    let lastReadId = participantJSON["last_comment_read_id"].intValue
                    let lastDeliveredId = participantJSON["last_comment_received_id"].intValue
                    
                    let savedUser = QUser.saveUser(withEmail: participantEmail, fullname: fullname, avatarURL: avatarURL)
                    
                    if room.type == .single {
                        if savedUser.email != QiscusMe.sharedInstance.email {
                            try! realm.write {
                                room.singleUser = participantEmail
                            }
                        }
                    }
                    let roomPariticipant = room.participants.filter("email == '\(participantEmail)'")
                    
                    if roomPariticipant.count == 0{
                        let newParticipant = QParticipant()
                        newParticipant.localId = "\(room.id)_\(participantEmail)"
                        newParticipant.roomId = room.id
                        newParticipant.email = participantEmail
                        newParticipant.lastReadCommentId = lastReadId
                        newParticipant.lastDeliveredCommentId = lastDeliveredId
                        if let storedParticipant = realm.object(ofType: QParticipant.self, forPrimaryKey: "\(room.id)_\(participantEmail)"){
                            try! realm.write {
                                realm.delete(storedParticipant)
                            }
                        }
                        do {
                            try realm.write {
                                room.participants.append(newParticipant)
                            }
                        }
                        catch let error as NSError {
                            Qiscus.printLog(text: "WARNING!! - \(error.localizedDescription)")
                        }
                        
                    }else{
                        let selectedParticipant = roomPariticipant.first!
                        try! realm.write {
                            selectedParticipant.email = participantEmail
                            selectedParticipant.lastReadCommentId = lastReadId
                            selectedParticipant.lastDeliveredCommentId = lastDeliveredId
                        }
                    }
                    participantString.append(participantEmail)
                }
                room.updateCommentStatus()
                var index = 0
                for participant in room.participants{
                    if !participantString.contains(participant.email){
                        room.participants.remove(objectAtIndex: index)
                    }
                    index += 1
                }
            }
        }
        
        if Qiscus.chatRooms[room.id] == nil {
            Qiscus.chatRooms[room.id] = room
        }
        if Qiscus.shared.chatViews[room.id] ==  nil{
            let chatView = QiscusChatVC()
            chatView.chatRoom = Qiscus.chatRooms[room.id]
            Qiscus.shared.chatViews[room.id] = chatView
        }
        Qiscus.sharedInstance.RealtimeConnect()
        DispatchQueue.main.async { autoreleasepool{
            if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                if !room.isInvalidated {
                    roomDelegate.didFinishLoadRoom(onRoom: room)
                }
            }
            }}
        return room
    }
    
    // MARK: Private Object Method
    private func resetRoomComment(){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let data =  realm.objects(QComment.self).filter("roomId == '\(self.id)'")
        
        try! realm.write {
            self.typingUser = ""
        }
        for comment in data {
            try! realm.write {
                comment.durationLabel = ""
                comment.currentTimeSlider = Float(0)
                comment.seekTimeLabel = "00:00"
                comment.audioIsPlaying = false
                // file variable
                comment.isDownloading = false
                comment.isUploading = false
                comment.progress = 0
            }
        }
    }
    internal func addComment(newComment:QComment, onTop:Bool = false){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let _ = newComment.textSize
        let roomId = self.id
        if let user = QUser.user(withEmail: newComment.senderEmail){
            user.updateLastSeen(lastSeen: newComment.createdAt)
        }
        if self.comments.count == 0 {
            let commentGroup = QCommentGroup()
            commentGroup.senderEmail = newComment.senderEmail
            commentGroup.senderName = newComment.senderName
            commentGroup.createdAt = newComment.createdAt
            commentGroup.id = "\(newComment.uniqueId)"
            commentGroup.append(comment: newComment)
            try! realm.write {
                self.comments.append(commentGroup)
            }
            QCommentGroup.cache["\(newComment.uniqueId)"] = commentGroup
            if !onTop {
                DispatchQueue.main.async { autoreleasepool{
                    Qiscus.chatRooms[roomId]?.delegate?.room?(gotNewGroupComment: 0)
                    }}
                self.updateLastComentInfo(comment: newComment)
                if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                    DispatchQueue.main.async { autoreleasepool{
                        if !newComment.isInvalidated {
                            roomDelegate.gotNewComment(newComment)
                        }
                    }}
                }
            }
        }
        else if onTop{
            let firstCommentGroup = self.comments.first!
            if firstCommentGroup.date == newComment.date && firstCommentGroup.senderEmail == newComment.senderEmail && newComment.type != .system {
                newComment.cellPosRaw = QCellPosition.first.rawValue
                try! realm.write {
                    firstCommentGroup.createdAt = newComment.createdAt
                    firstCommentGroup.senderName = newComment.senderName
                }
                firstCommentGroup.insert(comment: newComment, at: 0)
                var i = 0
                for comment in firstCommentGroup.comments {
                    var position = QCellPosition.first
                    if i == firstCommentGroup.commentsCount - 1 {
                        position = .last
                    }
                    else if i > 0 {
                        position = .middle
                    }
                    if comment.cellPos != position {
                        comment.updateCellPos(cellPos: position)
                    }
                    i += 1
                }
            }else{
                let commentGroup = QCommentGroup()
                commentGroup.senderEmail = newComment.senderEmail
                commentGroup.senderName = newComment.senderName
                commentGroup.createdAt = newComment.createdAt
                commentGroup.id = "\(newComment.uniqueId)"
                commentGroup.append(comment: newComment)
                try! realm.write {
                    self.comments.insert(commentGroup, at: 0)
                }
                commentGroup.cacheObject()
            }
        }
        else{
            let lastComment = self.comments[self.commentsGroupCount - 1]
            if lastComment.date == newComment.date && lastComment.senderEmail == newComment.senderEmail && newComment.type != .system{
                newComment.cellPosRaw = QCellPosition.last.rawValue
                lastComment.append(comment: newComment)
                let section = self.comments.count - 1
                let item = lastComment.commentsCount - 1
                DispatchQueue.main.async { autoreleasepool {
                    Qiscus.chatRooms[roomId]?.delegate?.room?(gotNewCommentOn: section, withCommentIndex: item)
                    }}
                self.updateUnreadCommentCount()
                
                var i = 0
                for comment in lastComment.comments{
                    var position = QCellPosition.first
                    if i == lastComment.commentsCount - 1 {
                        position = .last
                    }
                    else if i > 0 {
                        position = .middle
                    }
                    if comment.cellPos != position {
                        comment.updateCellPos(cellPos: position)
                    }
                    i += 1
                }
            }else{
                let commentGroup = QCommentGroup()
                commentGroup.senderEmail = newComment.senderEmail
                commentGroup.senderName = newComment.senderName
                commentGroup.createdAt = newComment.createdAt
                commentGroup.id = "\(newComment.uniqueId)"
                commentGroup.append(comment: newComment)
                try! realm.write {
                    self.comments.append(commentGroup)
                }
                commentGroup.cacheObject()
                let section = self.commentsGroupCount - 1
                DispatchQueue.main.async { autoreleasepool {
                    Qiscus.chatRooms[roomId]?.delegate?.room?(gotNewGroupComment: section)
                    }}
                self.updateUnreadCommentCount()
            }
            self.updateLastComentInfo(comment: newComment)
            if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                DispatchQueue.main.async { autoreleasepool{
                    if !newComment.isInvalidated {
                        roomDelegate.gotNewComment(newComment)
                    }
                }}
            }
        }
        newComment.cacheObject()
    }
    
    internal func updateLastComentInfo(comment:QComment){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        if !self.isInvalidated {
            if comment.createdAt > self.lastCommentCreatedAt {
                try! realm.write {
                    self.lastCommentId = comment.id
                    self.lastCommentText = comment.text
                    self.lastCommentUniqueId = comment.uniqueId
                    self.lastCommentBeforeId = comment.beforeId
                    self.lastCommentCreatedAt = comment.createdAt
                    self.lastCommentSenderEmail = comment.senderEmail
                    self.lastCommentSenderName = comment.senderName
                    self.lastCommentStatusRaw = comment.statusRaw
                    self.lastCommentTypeRaw = comment.typeRaw
                    self.lastCommentData = comment.data
                    self.lastCommentRawExtras = comment.rawExtra
                }
                
                let roomId = self.id
                let count = self.unreadCount + 1
                self.updateUnreadCommentCount(count: count)
                if Thread.isMainThread {
                    if let c = self.lastComment {
                        if let delegate = self.delegate {
                            delegate.room?(gotNewComment: c)
                        }
                        Qiscus.chatDelegate?.qiscusChat?(gotNewComment: c)
                        QiscusNotification.publish(gotNewComment: c, room: self)
                    }
                }else{
                    DispatchQueue.main.sync {
                        if let room = QRoom.room(withId: roomId){
                            if let c = room.lastComment {
                                if let delegate = room.delegate {
                                    delegate.room?(gotNewComment: c)
                                }
                                Qiscus.chatDelegate?.qiscusChat?(gotNewComment: c)
                                QiscusNotification.publish(gotNewComment: c, room: room)
                            }
                        }
                    }
                }
                
            }
        }
    }
    // MARK: - Public Object method
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
        if let unread = json["unread_count"].int {
            if unread != self.unreadCount {
                try! realm.write {
                    self.unreadCount = unread
                }
                let id = self.id
                DispatchQueue.main.async { autoreleasepool {
                    if let room = QRoom.room(withId: id){
                        QiscusNotification.publish(roomChange: room)
                    }
                }}
            }
        }
        if let roomName = json["room_name"].string {
            if roomName != self.storedName {
                try! realm.write {
                    self.storedName = roomName
                }
                let id = self.id
                DispatchQueue.main.async { autoreleasepool {
                    if let cache = QRoom.room(withId: id) {
                        if cache.definedname != "" {
                            QiscusNotification.publish(roomChange: cache)
                            cache.delegate?.room(didChangeName: cache)
                        }
                    }
                }}
            }
        }
        if let roomAvatar = json["avatar_url"].string {
            if roomAvatar != self.avatarURL {
                try! realm.write {
                    self.avatarURL = roomAvatar
                    self.avatarLocalPath = ""
                }
                let id = self.id
                DispatchQueue.main.async { autoreleasepool {
                    if let cache = QRoom.room(withId: id) {
                        QiscusNotification.publish(roomChange: cache)
                        cache.delegate?.room(didChangeAvatar: cache)
                    }
                }}
            }
        }
        if json["last_comment"] != JSON.null {
            let commentData = json["last_comment"]
            let comment = QComment.tempComment(fromJSON: commentData)
            if comment.id > self.lastCommentId {
                try! realm.write {
                    self.lastCommentId = comment.id
                    self.lastCommentText = comment.text
                    self.lastCommentUniqueId = comment.uniqueId
                    self.lastCommentBeforeId = comment.beforeId
                    self.lastCommentCreatedAt = comment.createdAt
                    self.lastCommentSenderEmail = comment.senderEmail
                    self.lastCommentSenderName = comment.senderName
                    self.lastCommentStatusRaw = comment.statusRaw
                    self.lastCommentTypeRaw = comment.typeRaw
                    self.lastCommentData = comment.data
                }
                let id = self.id
                DispatchQueue.main.async { autoreleasepool {
                    if let room = QRoom.room(withId: id){
                        QiscusNotification.publish(roomChange: room)
                    }
                    }}
            }
        }else{
            var change = false
            if let lastMessage = json["last_comment_message"].string{
                if lastMessage != self.lastCommentText {
                    change = true
                    try! realm.write {
                        self.lastCommentText = lastMessage
                    }
                }
            }
            if let lastMessageTime = json["last_comment_timestamp_unix"].double{
                if lastMessageTime != self.lastCommentCreatedAt {
                    change = true
                    try! realm.write {
                        self.lastCommentCreatedAt = lastMessageTime
                    }
                }
            }
            if let lastCommentId = json["last_comment_id"].int{
                change = true
                if lastCommentId > self.lastCommentId {
                    try! realm.write {
                        self.lastCommentId = lastCommentId
                    }
                }
            }
            if change {
                let id = self.id
                DispatchQueue.main.async { autoreleasepool {
                    if let room = QRoom.room(withId: id){
                        QiscusNotification.publish(roomChange: room)
                    }
                    }}
            }
        }
        
        if let participants = json["participants"].array {
            var participantString = [String]()
            var participantChanged = false
            for participantJSON in participants {
                let participantEmail = participantJSON["email"].stringValue
                let fullname = participantJSON["username"].stringValue
                let avatarURL = participantJSON["avatar_url"].stringValue
                let savedUser = QUser.saveUser(withEmail: participantEmail, fullname: fullname, avatarURL: avatarURL)
                let lastReadId = participantJSON["last_comment_read_id"].intValue
                let lastDeliveredId = participantJSON["last_comment_received_id"].intValue
                let savedParticipant = self.participants.filter("email == '\(participantEmail)'")
                if savedParticipant.count > 0{
                    let storedParticipant = savedParticipant.first!
                    storedParticipant.updateLastReadId(commentId: lastReadId)
                    storedParticipant.updateLastDeliveredId(commentId: lastDeliveredId)
                }else {
                    let newParticipant = QParticipant()
                    newParticipant.localId = "\(self.id)_\(participantEmail)"
                    newParticipant.roomId = self.id
                    newParticipant.email = participantEmail
                    newParticipant.lastReadCommentId = lastReadId
                    newParticipant.lastDeliveredCommentId = lastDeliveredId
                    
                    if let storedParticipant = realm.object(ofType: QParticipant.self, forPrimaryKey: "\(self.id)_\(participantEmail)"){
                        try! realm.write {
                            realm.delete(storedParticipant)
                        }
                    }
                    
                    do {
                        try realm.write {
                            self.participants.append(newParticipant)
                        }
                    }
                    catch let error as NSError {
                        Qiscus.printLog(text: "WARNING!! - \(error.localizedDescription)")
                    }
                    
                    participantChanged = true
                }
                participantString.append(participantEmail)
            }
            self.updateCommentStatus()
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
                let id = self.id
                DispatchQueue.main.async { autoreleasepool {
                    if let cache = QRoom.room(withId: id) {
                        cache.delegate?.room(didChangeParticipant: cache)
                        QiscusNotification.publish(roomChange: cache)
                    }
                    }}
            }
        }
        
    }
    public func saveNewComment(fromJSON json:JSON){
        let roomTS = ThreadSafeReference(to: self)
        QiscusDBThread.sync { autoreleasepool{
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            
            guard let room = realm.resolve(roomTS) else { return }
            
            let commentId = json["id"].intValue
            let commentUniqueId = json["unique_temp_id"].stringValue
            var commentText = json["message"].stringValue
            let commentSenderName = json["username"].stringValue
            let commentCreatedAt = json["unix_timestamp"].doubleValue
            let commentBeforeId = json["comment_before_id"].intValue
            let senderEmail = json["email"].stringValue
            let commentType = json["type"].stringValue
            let commentExtras = "\(json["extras"])"
            if commentType == "reply" || commentType == "buttons" {
                commentText = json["payload"]["text"].stringValue
            }
            
            let avatarURL = json["user_avatar_url"].stringValue
            let _ = QUser.saveUser(withEmail: senderEmail, fullname: commentSenderName, avatarURL: avatarURL, lastSeen: commentCreatedAt)
            
            let savedParticipant = self.participants.filter("email == '\(senderEmail)'")
            if savedParticipant.count > 0 {
                let storedParticipant = savedParticipant.first!
                if storedParticipant.lastReadCommentId < commentId {
                    try! realm.write {
                        storedParticipant.lastReadCommentId = commentId
                        storedParticipant.lastDeliveredCommentId = commentId
                    }
                }else if storedParticipant.lastDeliveredCommentId < commentId{
                    try! realm.write {
                        storedParticipant.lastDeliveredCommentId = commentId
                    }
                }
            }
            
            if let oldComment = QComment.comment(withUniqueId: commentUniqueId) {
                try! realm.write {
                    oldComment.id = commentId
                    oldComment.text = commentText
                    oldComment.senderName = commentSenderName
                    oldComment.createdAt = commentCreatedAt
                    oldComment.beforeId = commentBeforeId
                    oldComment.roomName = self.name
                }
                var status = QCommentStatus.sent
                if oldComment.id < room.lastParticipantsReadId {
                    status = .read
                }else if oldComment.id < room.lastParticipantsDeliveredId{
                    status = .delivered
                }
                oldComment.updateStatus(status: status)
            }
            else{
                let newComment = QComment()
                newComment.uniqueId = commentUniqueId
                newComment.id = commentId
                newComment.roomId = room.id
                newComment.text = commentText
                newComment.senderName = commentSenderName
                newComment.createdAt = commentCreatedAt
                newComment.beforeId = commentBeforeId
                newComment.senderEmail = senderEmail
                newComment.cellPosRaw = QCellPosition.single.rawValue
                newComment.roomAvatar = self.avatarURL
                newComment.roomName = self.name
                newComment.roomTypeRaw = self.typeRaw
                newComment.rawExtra = commentExtras
                
                var status = QCommentStatus.sent
                if newComment.id < room.lastParticipantsReadId {
                    status = .read
                }else if newComment.id < room.lastParticipantsDeliveredId{
                    status = .delivered
                }
                newComment.statusRaw = status.rawValue
                
                switch commentType {
                case "buttons":
                    newComment.data = "\(json["payload"]["buttons"])"
                    newComment.typeRaw = QCommentType.postback.name()
                    break
                case "account_linking":
                    newComment.data = "\(json["payload"])"
                    newComment.typeRaw = QCommentType.account.name()
                    break
                case "reply":
                    newComment.data = "\(json["payload"])"
                    newComment.typeRaw = QCommentType.reply.name()
                    break
                case "system_event":
                    newComment.data = "\(json["payload"])"
                    newComment.typeRaw = QCommentType.system.name()
                    break
                case "card":
                    newComment.data = "\(json["payload"])"
                    newComment.typeRaw = QCommentType.card.name()
                    break
                case "contact_person":
                    newComment.data = "\(json["payload"])"
                    newComment.typeRaw = QCommentType.contact.name()
                    break
                case "button_postback_response" :
                    newComment.data = "\(json["payload"])"
                    newComment.typeRaw = QCommentType.text.name()
                    break
                case "location":
                    newComment.data = "\(json["payload"])"
                    newComment.typeRaw = QCommentType.location.name()
                    break
                case "custom":
                    newComment.data = "\(json["payload"])"
                    newComment.typeRaw = json["payload"]["type"].stringValue
                    break
                case "file_attachment":
                    newComment.data = "\(json["payload"])"
                    var type = QiscusFileType.file
                    let fileURL = json["payload"]["url"].stringValue
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
                            newComment.file!.url = fileURL
                        }
                        type = newComment.file!.type
                    }
                    switch type {
                    case .image:
                        newComment.typeRaw = QCommentType.image.name()
                        break
                    case .video:
                        newComment.typeRaw = QCommentType.video.name()
                        break
                    case .audio:
                        newComment.typeRaw = QCommentType.audio.name()
                        break
                    default:
                        newComment.typeRaw = QCommentType.file.name()
                        break
                    }
                    break
                case "text":
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
                            newComment.typeRaw = QCommentType.image.name()
                            break
                        case .video:
                            newComment.typeRaw = QCommentType.video.name()
                            break
                        case .audio:
                            newComment.typeRaw = QCommentType.audio.name()
                            break
                        default:
                            newComment.typeRaw = QCommentType.file.name()
                            break
                        }
                    }else{
                        newComment.typeRaw = QCommentType.text.name()
                    }
                    break
                default:
                    newComment.data = "\(json["payload"])"
                    newComment.typeRaw = json["payload"]["type"].stringValue
                    break
                }
                room.addComment(newComment: newComment)
            }
            }}
    }
    public func saveOldComment(fromJSON json:JSON){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let commentId = json["id"].intValue
        let commentUniqueId = json["unique_temp_id"].stringValue
        var commentText = json["message"].stringValue
        let commentSenderName = json["username"].stringValue
        let commentCreatedAt = json["unix_timestamp"].doubleValue
        let commentBeforeId = json["comment_before_id"].intValue
        let senderEmail = json["email"].stringValue
        let commentType = json["type"].stringValue
        let commentExtras = "\(json["extras"])"
        if commentType == "reply" || commentType == "buttons" {
            commentText = json["payload"]["text"].stringValue
        }
        let avatarURL = json["user_avatar_url"].stringValue
        let user = QUser.saveUser(withEmail: senderEmail, fullname: commentSenderName, avatarURL: avatarURL, lastSeen: commentCreatedAt)

        let savedParticipant = self.participants.filter("email == '\(senderEmail)'")
        if savedParticipant.count > 0 {
            let participant = savedParticipant.first!
            if !participant.isInvalidated {
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
        
        if let oldComment = QComment.comment(withUniqueId: commentUniqueId) {
            if oldComment.isInvalidated {
                let newComment = QComment()
                newComment.uniqueId = commentUniqueId
                newComment.id = commentId
                newComment.roomId = self.id
                newComment.text = commentText
                newComment.senderName = commentSenderName
                newComment.createdAt = commentCreatedAt
                newComment.beforeId = commentBeforeId
                newComment.senderEmail = senderEmail
                newComment.cellPosRaw = QCellPosition.single.rawValue
                newComment.roomAvatar = self.avatarURL
                newComment.roomName = self.name
                newComment.roomTypeRaw = self.typeRaw
                newComment.rawExtra = commentExtras
                if let group = QCommentGroup.commentGroup(withId: newComment.uniqueId) {
                    try! realm.write {
                        realm.delete(group)
                    }
                }
                self.addComment(newComment: newComment, onTop: true)
            }else{
                try! realm.write {
                    oldComment.id = commentId
                    oldComment.text = commentText
                    oldComment.senderName = user.storedName
                    oldComment.senderEmail = user.email
                    oldComment.createdAt = commentCreatedAt
                    oldComment.beforeId = commentBeforeId
                    oldComment.roomName = self.name
                    oldComment.roomId = self.id
                    oldComment.rawExtra = commentExtras
                }
                if oldComment.statusRaw < QCommentStatus.sent.rawValue {
                    var status = QCommentStatus.sent
                    if oldComment.id < self.lastParticipantsReadId {
                        status = .read
                    }else if oldComment.id < self.lastParticipantsDeliveredId{
                        status = .delivered
                    }
                    
                    oldComment.updateStatus(status: status)
                }
                var found = false
                for group in self.comments {
                    for comment in group.comments {
                        if comment.id == oldComment.id {
                            found = true
                            break
                        }
                    }
                    if found {
                        break
                    }
                }
                if !found {
                    let newComment = QComment()
                    newComment.uniqueId = oldComment.uniqueId
                    newComment.id = oldComment.id
                    newComment.roomId = self.id
                    newComment.text = oldComment.text
                    newComment.senderName = oldComment.senderName
                    newComment.createdAt = oldComment.createdAt
                    newComment.beforeId = oldComment.beforeId
                    newComment.senderEmail = oldComment.senderEmail
                    newComment.cellPosRaw = QCellPosition.single.rawValue
                    newComment.roomAvatar = self.avatarURL
                    newComment.roomName = self.name
                    newComment.roomTypeRaw = self.typeRaw
                    newComment.rawExtra = commentExtras
                    try! realm.write {
                        realm.delete(oldComment)
                    }
                    if let group = QCommentGroup.commentGroup(withId: newComment.uniqueId) {
                        try! realm.write {
                            realm.delete(group)
                        }
                    }
                    self.addComment(newComment: newComment, onTop: true)
                }
            }
        }
        else{
            let newComment = QComment()
            newComment.uniqueId = commentUniqueId
            newComment.id = commentId
            newComment.roomId = self.id
            newComment.text = commentText
            newComment.senderName = commentSenderName
            newComment.createdAt = commentCreatedAt
            newComment.beforeId = commentBeforeId
            newComment.senderEmail = senderEmail
            newComment.cellPosRaw = QCellPosition.single.rawValue
            newComment.roomAvatar = self.avatarURL
            newComment.roomName = self.name
            newComment.roomTypeRaw = self.typeRaw
            newComment.rawExtra = commentExtras
            
            var status = QCommentStatus.sent
            if newComment.id < self.lastParticipantsReadId {
                status = .read
            }else if newComment.id < self.lastParticipantsDeliveredId{
                status = .delivered
            }
            newComment.statusRaw = status.rawValue
            
            switch commentType {
            case "buttons":
                newComment.data = "\(json["payload"]["buttons"])"
                newComment.typeRaw = QCommentType.postback.name()
                break
            case "account_linking":
                newComment.data = "\(json["payload"])"
                newComment.typeRaw = QCommentType.account.name()
                break
            case "reply":
                newComment.data = "\(json["payload"])"
                newComment.typeRaw = QCommentType.reply.name()
                break
            case "system_event":
                newComment.data = "\(json["payload"])"
                newComment.typeRaw = QCommentType.system.name()
                break
            case "card":
                newComment.data = "\(json["payload"])"
                newComment.typeRaw = QCommentType.card.name()
                break
            case "contact_person":
                newComment.data = "\(json["payload"])"
                newComment.typeRaw = QCommentType.contact.name()
                break
            case "location":
                newComment.data = "\(json["payload"])"
                newComment.typeRaw = QCommentType.location.name()
                break
            case "button_postback_response" :
                newComment.data = "\(json["payload"])"
                newComment.typeRaw = QCommentType.text.name()
                break
            case "custom":
                newComment.data = "\(json["payload"])"
                newComment.typeRaw = json["payload"]["type"].stringValue
                break
            case "file_attachment":
                newComment.data = "\(json["payload"])"
                var type = QiscusFileType.file
                let fileURL = json["payload"]["url"].stringValue
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
                        newComment.file!.url = fileURL
                    }
                    type = newComment.file!.type
                }
                switch type {
                case .image:
                    newComment.typeRaw = QCommentType.image.name()
                    break
                case .video:
                    newComment.typeRaw = QCommentType.video.name()
                    break
                case .audio:
                    newComment.typeRaw = QCommentType.audio.name()
                    break
                default:
                    newComment.typeRaw = QCommentType.file.name()
                    break
                }
                break
            case "text":
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
                        newComment.typeRaw = QCommentType.image.name()
                        break
                    case .video:
                        newComment.typeRaw = QCommentType.video.name()
                        break
                    case .audio:
                        newComment.typeRaw = QCommentType.audio.name()
                        break
                    default:
                        newComment.typeRaw = QCommentType.file.name()
                        break
                    }
                }else{
                    newComment.typeRaw = QCommentType.text.name()
                }
                break
            default:
                newComment.data = "\(json["payload"])"
                newComment.typeRaw = json["payload"]["type"].stringValue
                break
            }
            self.addComment(newComment: newComment, onTop: true)
        }
    }
    
    public func sync(){
        let service = QRoomService()
        service.sync(onRoom: self)
    }
    public func loadMore(){
        let service = QRoomService()
        service.loadMore(onRoom: self)
    }
    
    // MARK: - Updater method
    public func updateCommentStatus(inComment comment:QComment, status:QCommentStatus){
        comment.updateStatus(status: status)
    }
    
    public func publishCommentStatus(withStatus status:QCommentStatus){
        let service = QRoomService()
        service.publisComentStatus(onRoom: self, status: status)
    }
    public func newContactComment(name:String, value:String)->QComment{
        let comment = QComment()
        let payload = "{ \"name\": \"\(name)\", \"value\": \"\(value)\"}"
        let time = Double(Date().timeIntervalSince1970)
        let timeToken = UInt64(time * 10000)
        let uniqueID = "ios-\(timeToken)"
        
        comment.uniqueId = uniqueID
        comment.id = 0
        comment.roomId = self.id
        comment.text = "\(name) - \(value)"
        comment.createdAt = Double(Date().timeIntervalSince1970)
        comment.senderEmail = QiscusMe.sharedInstance.email
        comment.senderName = QiscusMe.sharedInstance.userName
        comment.statusRaw = QCommentStatus.sending.rawValue
        comment.typeRaw = "contact_person"
        comment.data = payload
        comment.roomAvatar = self.avatarURL
        comment.roomName = self.name
        comment.roomTypeRaw = self.typeRaw
        
        self.addComment(newComment: comment)
        return comment
    }
    public func newLocationComment(latitude:Double, longitude:Double, title:String?=nil, address:String?=nil)->QComment{
        let comment = QComment()
        var locTitle = title
        var locAddress = ""
        if address != nil {
            locAddress = address!
        }
        if title == nil {
            var newLat = latitude
            var newLong = longitude
            var latString = "N"
            var longString = "E"
            if latitude < 0 {
                latString = "S"
                newLat = 0 - latitude
            }
            if longitude < 0 {
                longString = "W"
                newLong = 0 - longitude
            }
            let intLat = Int(newLat)
            let intLong = Int(newLong)
            let subLat = Int((newLat - Double(intLat)) * 100)
            let subLong = Int((newLong - Double(intLong)) * 100)
            let subSubLat = Int((newLat - Double(intLat) - Double(Double(subLat)/100)) * 10000)
            let subSubLong = Int((newLong - Double(intLong) - Double(Double(subLong)/100)) * 10000)
            let pLat = Int((newLat - Double(intLat) - Double(Double(subLat)/100) - Double(Double(subSubLat)/10000)) * 100000)
            let pLong = Int((newLong - Double(intLong) - Double(Double(subLong)/100) - Double(Double(subSubLong)/10000)) * 100000)
            
            locTitle = "\(intLat)º\(subLat)\'\(subSubLat).\(pLat)\"\(latString) \(intLong)º\(subLong)\'\(subSubLong).\(pLong)\"\(longString)"
        }
        let url = "http://maps.google.com/maps?daddr=\(latitude),\(longitude)"
        
        let payload = "{ \"name\": \"\(locTitle!)\", \"address\": \"\(locAddress)\", \"latitude\": \(latitude), \"longitude\": \(longitude), \"map_url\": \"\(url)\"}"
        
        let time = Double(Date().timeIntervalSince1970)
        let timeToken = UInt64(time * 10000)
        let uniqueID = "ios-\(timeToken)"
        
        comment.uniqueId = uniqueID
        comment.id = 0
        comment.roomId = self.id
        comment.text = ""
        comment.createdAt = Double(Date().timeIntervalSince1970)
        comment.senderEmail = QiscusMe.sharedInstance.email
        comment.senderName = QiscusMe.sharedInstance.userName
        comment.statusRaw = QCommentStatus.sending.rawValue
        comment.typeRaw = "location"
        comment.data = payload
        comment.roomAvatar = self.avatarURL
        comment.roomName = self.name
        comment.roomTypeRaw = self.typeRaw
        
        self.addComment(newComment: comment)
        return comment
    }
    public func newCustomComment(type:String, payload:String, text:String? = nil )->QComment{
        let comment = QComment()
        let payloadData = JSON(parseJSON: payload)
        var contentString = "\"\""
        if payloadData == JSON.null{
            contentString = "\"\(payload)\""
        }else{
            contentString = "\(payloadData)"
        }
        let payload = "{ \"type\": \"\(type)\", \"content\": \(contentString)}"
        let time = Double(Date().timeIntervalSince1970)
        let timeToken = UInt64(time * 10000)
        let uniqueID = "ios-\(timeToken)"
        if text == nil {
            comment.text = "message type \(type)"
        }else{
            comment.text = text!
        }
        
        comment.uniqueId = uniqueID
        comment.id = 0
        comment.roomId = self.id
        
        comment.createdAt = Double(Date().timeIntervalSince1970)
        comment.senderEmail = QiscusMe.sharedInstance.email
        comment.senderName = QiscusMe.sharedInstance.userName
        comment.statusRaw = QCommentStatus.sending.rawValue
        comment.typeRaw = type
        comment.data = payload
        comment.roomAvatar = self.avatarURL
        comment.roomName = self.name
        comment.roomTypeRaw = self.typeRaw
        
        self.addComment(newComment: comment)
        return comment
    }
    public func newFileComment(type:QiscusFileType, filename:String = "", caption:String = "", data:Data? = nil, thumbImage:UIImage? = nil)->QComment{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let comment = QComment()
        let time = Double(Date().timeIntervalSince1970)
        let timeToken = UInt64(time * 10000)
        let uniqueID = "ios-\(timeToken)"
        let fileNameArr = filename.characters.split(separator: ".")
        let fileExt = String(fileNameArr.last!).lowercased()
        
        var fileName = filename.lowercased()
        if fileName == "asset.jpg" || fileName == "asset.png" {
            fileName = "\(uniqueID).\(fileExt)"
        }
        
        let payload = "{\"url\":\"\(fileName)\", \"caption\": \"\(caption)\"}"
        
        comment.uniqueId = uniqueID
        comment.id = 0
        comment.roomId = self.id
        
        comment.text = "[file]\(fileName) [/file]"
        comment.createdAt = Double(Date().timeIntervalSince1970)
        comment.senderEmail = QiscusMe.sharedInstance.email
        comment.senderName = QiscusMe.sharedInstance.userName
        comment.statusRaw = QCommentStatus.sending.rawValue
        comment.isUploading = true
        comment.progress = 0
        comment.data = payload
        comment.roomAvatar = self.avatarURL
        comment.roomName = self.name
        comment.roomTypeRaw = self.typeRaw
        
        let file = QFile()
        file.id = uniqueID
        file.roomId = self.id
        file.url = fileName
        file.senderEmail = QiscusMe.sharedInstance.email
        
        
        if let mime = QiscusFileHelper.mimeTypes["\(fileExt)"] {
            file.mimeType = mime
        }
        
        switch type {
        case .audio:
            comment.typeRaw = QCommentType.audio.name()
            file.localPath = QFile.saveFile(data!, fileName: fileName)
            break
        case .image:
            let image = UIImage(data: data!)
            let gif = (fileExt == "gif" || fileExt == "gif_")
            let jpeg = (fileExt == "jpg" || fileExt == "jpg_")
            let png = (fileExt == "png" || fileExt == "png_")
            
            var thumb = UIImage()
            var thumbData:Data?
            if !gif {
                thumb = QFile.createThumbImage(image!)
                if jpeg {
                    thumbData = UIImageJPEGRepresentation(thumb, 1)
                    file.localThumbPath = QFile.saveFile(thumbData!, fileName: "thumb-\(fileName)")
                }else if png {
                    thumbData = UIImagePNGRepresentation(thumb)
                    file.localThumbPath = QFile.saveFile(thumbData!, fileName: "thumb-\(fileName)")
                }
            }else{
                file.localThumbPath = QFile.saveFile(data!, fileName: "thumb-\(fileName)")
            }
            
            comment.typeRaw = QCommentType.image.name()
            file.localPath = QFile.saveFile(data!, fileName: fileName)
            break
        case .video:
            var fileNameOnly = String(fileNameArr.first!).lowercased()
            var i = 0
            for namePart in fileNameArr{
                if i > 0 && i < (fileNameArr.count - 1){
                    fileNameOnly += ".\(String(namePart).lowercased())"
                }
                i += 1
            }
            let thumbData = UIImagePNGRepresentation(thumbImage!)
            file.localThumbPath = QFile.saveFile(thumbData!, fileName: "thumb-\(fileNameOnly).png")
            comment.typeRaw = QCommentType.video.name()
            file.localPath = QFile.saveFile(data!, fileName: fileName)
            break
        default:
            file.localPath = QFile.saveFile(data!, fileName: fileName)
            comment.typeRaw = QCommentType.file.name()
            break
        }
        
        try! realm.write {
            realm.add(file, update: true)
        }
        self.addComment(newComment: comment)
        return comment
    }
    
    public func newComment(text:String, payload:JSON? = nil,type:QCommentType = .text, data:Data? = nil, image:UIImage? = nil, filename:String = "", filePath:URL? = nil )->QComment{
        let comment = QComment()
        let time = Double(Date().timeIntervalSince1970)
        let timeToken = UInt64(time * 10000)
        let uniqueID = "ios-\(timeToken)"
        
        comment.uniqueId = uniqueID
        comment.id = 0
        comment.roomId = self.id
        comment.text = text
        comment.createdAt = Double(Date().timeIntervalSince1970)
        comment.senderEmail = QiscusMe.sharedInstance.email
        comment.senderName = QiscusMe.sharedInstance.userName
        comment.statusRaw = QCommentStatus.sending.rawValue
        comment.typeRaw = type.name()
        comment.roomName = self.name
        comment.roomTypeRaw = self.typeRaw
        comment.roomAvatar = self.avatarURL
        
        if let data = payload {
            comment.data = "\(data)"
        }
        
        self.addComment(newComment: comment)
        return comment
    }
    public func postTextMessage(text:String){
        let comment = QComment()
        let time = Double(Date().timeIntervalSince1970)
        let timeToken = UInt64(time * 10000)
        let uniqueID = "ios-\(timeToken)"
        
        comment.uniqueId = uniqueID
        comment.id = 0
        comment.roomId = self.id
        comment.text = text
        comment.createdAt = Double(Date().timeIntervalSince1970)
        comment.senderEmail = QiscusMe.sharedInstance.email
        comment.senderName = QiscusMe.sharedInstance.userName
        comment.statusRaw = QCommentStatus.sending.rawValue
        comment.typeRaw = QCommentType.text.name()
        
        self.addComment(newComment: comment)
        self.post(comment: comment)
    }
    public func post(comment:QComment, type:String? = nil, payload:JSON? = nil){
        let service = QRoomService()
        service.postComment(onRoom: self.id, comment: comment, type: type, payload:payload)
    }
    
    public func upload(comment:QComment, onSuccess:  @escaping (QRoom, QComment)->Void, onError:  @escaping (QRoom,QComment,String)->Void, onProgress:((Double)->Void)? = nil){
        self.updateCommentStatus(inComment: comment, status: .sending)
        let service = QRoomService()
        service.uploadCommentFile(inRoom: self, comment: comment, onSuccess: onSuccess, onError: onError, onProgress: onProgress)
    }
    
    public func downloadMedia(onComment comment:QComment, thumbImageRef: UIImage? = nil, isAudioFile: Bool = false, onSuccess: ((QComment)->Void)? = nil, onError:((String)->Void)? = nil, onProgress:((Double)->Void)? = nil){
        let service = QRoomService()
        service.downloadMedia(inRoom: self, comment: comment, thumbImageRef: thumbImageRef, isAudioFile: isAudioFile, onSuccess: onSuccess, onError: onError, onProgress: onProgress)
    }
    public func getIndexPath(ofComment comment:QComment)->IndexPath?{
        var section = self.comments.count - 1
        var indexPath:IndexPath? = nil
        var found = false
        for commentGroup in self.comments.reversed() {
            if commentGroup.date == comment.date && commentGroup.senderEmail == comment.senderEmail{
                var row = 0
                for commentTarget in commentGroup.comments {
                    if commentTarget.uniqueId == comment.uniqueId{
                        indexPath = IndexPath(item: row, section: section)
                        found = true
                        break
                    }
                    row += 1
                }
            }
            if found {
                break
            }else{
                section -= 1
            }
        }
        return indexPath
    }
    public func updateUserTyping(userEmail: String){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        if userEmail != self.typingUser {
            try! realm.write {
                self.typingUser = userEmail
            }
            let id = self.id
            DispatchQueue.main.async {
                Qiscus.chatRooms[id]?.delegate?.room(userDidTyping: userEmail)
                //QiscusNotification.publish(userTyping: <#T##QUser#>)
            }
            if userEmail != "" {
                if self.typingTimer != nil {
                    self.typingTimer!.invalidate()
                }
                self.typingTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(self.clearUserTyping), userInfo: nil, repeats: false)
            }
        }
    }
    public func clearUserTyping(){
        self.updateUserTyping(userEmail: "")
    }
    public func deleteComment(comment:QComment){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let id = self.id
        if let commentIndex = self.getIndexPath(ofComment: comment) {
            let commentGroup = self.comments[commentIndex.section]
            let commentUniqueId = comment.uniqueId
            let commentGroupId = commentGroup.id
            if Thread.isMainThread {
                QComment.cache[commentUniqueId] = nil
            }else{
                DispatchQueue.main.sync { autoreleasepool {
                    QComment.cache[commentUniqueId] = nil
                    }}
            }
            if self.comments[commentIndex.section].commentsCount > 1{
                try! realm.write { realm.delete(comment) }
                if Thread.isMainThread {
                    Qiscus.chatRooms[id]?.delegate?.room(didDeleteComment: commentIndex.section, row: commentIndex.item)
                }else{
                    DispatchQueue.main.sync { autoreleasepool {
                        Qiscus.chatRooms[id]?.delegate?.room(didDeleteComment: commentIndex.section, row: commentIndex.item)
                        }}
                }
            }else{
                if Thread.isMainThread {
                    QComment.cache[commentUniqueId] = nil
                    QCommentGroup.cache[commentGroupId] = nil
                }else{
                    DispatchQueue.main.sync { autoreleasepool {
                        QComment.cache[commentUniqueId] = nil
                        QCommentGroup.cache[commentGroupId] = nil
                        }}
                }
                try! realm.write {
                    realm.delete(comment)
                    realm.delete(commentGroup)
                }
                if Thread.isMainThread {
                    Qiscus.chatRooms[id]?.delegate?.room(didDeleteGroupComment: commentIndex.section)
                }else{
                    DispatchQueue.main.sync { autoreleasepool {
                        Qiscus.chatRooms[id]?.delegate?.room(didDeleteGroupComment: commentIndex.section)
                        }}
                }
            }
        }
    }
    public func participant(withEmail email:String)->QParticipant?{
        let savedParticipant = self.participants.filter("email == '\(email)'")
        if savedParticipant.count > 0{
            return savedParticipant.first!
        }else{
            return nil
        }
    }
    public func updateLastReadId(commentId:Int){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        if self.lastReadCommentId < commentId {
            try! realm.write {
                self.lastReadCommentId = commentId
            }
            self.updateUnreadCommentCount()
        }
    }
    internal func updateUnreadCommentCount(count:Int){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        try! realm.write {
            self.unreadCount = count
        }
    }
    public func updateUnreadCommentCount(){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let unread = QComment.countComments(afterId: self.lastReadCommentId, roomId: self.id)
        if self.unreadCommentCount != unread {
            try! realm.write {
                self.unreadCommentCount = unread
            }
            let id = self.id
            let lastReadId = self.lastReadCommentId
            DispatchQueue.main.async { autoreleasepool {
                Qiscus.chatRooms[id]?.delegate?.room(didChangeUnread: lastReadId, unreadCount: unread)
                }}
        }
    }
    public func updateUnreadCommentCount(onSuccess:@escaping ()->Void){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let unread = QComment.countComments(afterId: self.lastReadCommentId, roomId: self.id)
        if self.unreadCommentCount != unread {
            try! realm.write {
                self.unreadCommentCount = unread
            }
        }
        onSuccess()
    }
    internal func updateCommentStatus(){
        if self.participants.count > 0 {
            var minDeliveredId = 0
            var minReadId = 0
            var first = true
            for participant in self.participants {
                if first && participant.email != QiscusMe.sharedInstance.email{
                    minDeliveredId = participant.lastDeliveredCommentId
                    minReadId = participant.lastReadCommentId
                    first = false
                }else if participant.email != QiscusMe.sharedInstance.email{
                    if participant.lastDeliveredCommentId < minDeliveredId {
                        minDeliveredId = participant.lastDeliveredCommentId
                    }
                    if participant.lastReadCommentId < minReadId {
                        minReadId = participant.lastReadCommentId
                    }
                }
            }
            if self.lastParticipantsReadId < minReadId {
                updateLastParticipantsReadId(readId: minReadId)
            }
            if self.lastParticipantsDeliveredId < minDeliveredId {
                updateLastParticipantsDeliveredId(deliveredId: minDeliveredId)
            }
        }
    }
    private func updateLastParticipantsReadId(readId:Int){
        if readId > self.lastParticipantsReadId {
            var section = 0
            for commentGroup in self.comments {
                var item = 0
                for comment in commentGroup.comments{
                    if (comment.statusRaw < QCommentStatus.read.rawValue && comment.status != .failed && comment.status != .sending && comment.status != .pending && comment.id < readId) || comment.id == readId{
                        comment.updateStatus(status: .read)
                    }
                    item += 1
                }
                section += 1
            }
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            try! realm.write {
                self.lastParticipantsReadId = readId
                self.lastParticipantsDeliveredId = readId
            }
        }
    }
    private func updateLastParticipantsDeliveredId(deliveredId:Int){
        if deliveredId > self.lastParticipantsDeliveredId {
            var section = 0
            for commentGroup in self.comments {
                var item = 0
                for comment in commentGroup.comments{
                    if (comment.statusRaw < QCommentStatus.delivered.rawValue && comment.status != .failed && comment.status != .sending && comment.id < deliveredId) || (comment.id == deliveredId && comment.status != .read){
                        if let cache = QComment.cache[comment.uniqueId] {
                            if !cache.isInvalidated {
                                cache.updateStatus(status: .read)
                            }else{
                                comment.updateStatus(status: .read)
                            }
                        }else{
                            comment.updateStatus(status: .read)
                        }
                    }
                    item += 1
                }
                section += 1
            }
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            try! realm.write {
                self.lastParticipantsDeliveredId = deliveredId
            }
        }
    }
    public class func publishStatus(roomId:String, commentId:Int, status:QCommentStatus){
        let service = QRoomService()
        service.publishStatus(inRoom: roomId, commentId: commentId, commentStatus: status)
    }
    public func commentGroup(index:Int)->QCommentGroup?{
        if self.comments.count > index {
            let commentGroup = self.comments[index]
            if let cachedData = QCommentGroup.commentGroup(withId: commentGroup.id){
                return cachedData
            }else{
                QCommentGroup.cache[commentGroup.id] = commentGroup
                return commentGroup
            }
        }else{
            return nil
        }
    }
    public func update(roomName:String? = nil, roomAvatarURL:String? = nil, roomOptions:String? = nil, onSuccess:@escaping ((_ room: QRoom)->Void),onError:@escaping ((_ error: String)->Void)){
        let service = QRoomService()
        service.updateRoom(onRoom: self, roomName: roomName, roomAvatarURL: roomAvatarURL, roomOptions: roomOptions, onSuccess: onSuccess, onError: onError)
    }
    public func publishStopTyping(){
        let roomId = self.id
        QiscusBackgroundThread.async { autoreleasepool{
            let message: String = "0";
            let channel = "r/\(roomId)/\(roomId)/\(QiscusMe.sharedInstance.email)/t"
            DispatchQueue.main.async {
                Qiscus.shared.mqtt?.publish(channel, withString: message, qos: .qos1, retained: false)
            }
            }}
        if self.selfTypingTimer != nil {
            if self.typingTimer!.isValid {
                self.typingTimer!.invalidate()
            }
            self.typingTimer = nil
        }
    }
    public func publishStartTyping(){
        let roomId = self.id
        QiscusBackgroundThread.async { autoreleasepool{
            let message: String = "1";
            let channel = "r/\(roomId)/\(roomId)/\(QiscusMe.sharedInstance.email)/t"
            DispatchQueue.main.async {
                Qiscus.shared.mqtt?.publish(channel, withString: message, qos: .qos1, retained: false)
            }
            }}
        if self.typingTimer != nil {
            if self.typingTimer!.isValid {
                self.typingTimer!.invalidate()
            }
        }
        
        DispatchQueue.main.async {
            self.typingTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(self.publishStopTyping), userInfo: nil, repeats: false)
        }
        
    }
    public func saveAvatar(image:UIImage){
        var filename = "room_\(self.id)"
        var ext = "png"
        var avatarData:Data? = nil
        if let data = UIImagePNGRepresentation(image) {
            avatarData = data
        }else if let data = UIImageJPEGRepresentation(image, 1.0) {
            avatarData = data
            ext = "jpg"
        }
        filename = "\(filename).\(ext)"
        if avatarData != nil {
            let localPath = QFileManager.saveFile(withData: avatarData!, fileName: filename, type: .room)
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            try! realm.write {
                self.avatarLocalPath = localPath
            }
        }
    }
    public func subscribeRealtimeStatus(){
        var channels = [String]()
        
        channels.append("r/\(self.id)/\(self.id)/+/d")
        channels.append("r/\(self.id)/\(self.id)/+/r")
        channels.append("r/\(self.id)/\(self.id)/+/t")
        
        for participant in self.participants{
            if participant.email != QiscusMe.sharedInstance.email {
                channels.append("u/\(participant.email)/s")
            }
        }
        
        //QiscusBackgroundThread.async {
        DispatchQueue.main.async {
            for channel in channels{
                Qiscus.shared.mqtt?.subscribe(channel)
                if !Qiscus.realtimeChannel.contains(channel){
                    Qiscus.realtimeChannel.append(channel)
                }
            }
        }
        
        //}
    }
    public func unsubscribeRealtimeStatus(){
        var channels = [String]()
        
        channels.append("r/\(self.id)/\(self.id)/+/d")
        channels.append("r/\(self.id)/\(self.id)/+/r")
        channels.append("r/\(self.id)/\(self.id)/+/t")
        
        for participant in self.participants{
            if participant.email != QiscusMe.sharedInstance.email {
                channels.append(participant.email)
            }
        }
        
        DispatchQueue.global().async {autoreleasepool{
            for channel in channels{
                Qiscus.shared.mqtt?.unsubscribe(channel)
            }
            }}
    }
    internal func update(name:String){
        let id = self.id
        if self.storedName != name {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            try! realm.write {
                self.storedName = name
            }
            DispatchQueue.main.async { autoreleasepool {
                if let room = QRoom.room(withId: id){
                    if room.definedname != "" {
                        QiscusNotification.publish(roomChange: room)
                        room.delegate?.room(didChangeName: room)
                    }
                }
            }}
        }
    }
    internal func update(avatarURL:String){
        let id = self.id
        let roomTS = ThreadSafeReference(to: self)
        QiscusDBThread.async { autoreleasepool {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            guard let r = realm.resolve(roomTS) else { return }
            try! realm.write {
                r.avatarURL = avatarURL
                r.avatarLocalPath = ""
            }
            DispatchQueue.main.sync { autoreleasepool {
                if let room = QRoom.room(withId: id){
                    QiscusNotification.publish(roomChange: room)
                    room.delegate?.room(didChangeAvatar: room)
                }
                }}
            }}
    }
    internal func update(data:String){
        let roomTS = ThreadSafeReference(to: self)
        QiscusDBThread.sync { autoreleasepool {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            guard let r = realm.resolve(roomTS) else { return }
            if r.data != data {
                try! realm.write {
                    r.data = data
                }
            }
            }}
    }
    public func setName(name:String){
        if name != self.definedname {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            try! realm.write {
                self.definedname = name
            }
            if self.type == .single {
                for participant in participants {
                    if participant.email != QiscusMe.sharedInstance.email {
                        if let user = participant.user {
                            user.setName(name: name)
                        }
                    }
                }
            }
            let id = self.id
            DispatchQueue.main.async { autoreleasepool {
                if let cache = QRoom.room(withId: id) {
                    QiscusNotification.publish(roomChange: cache)
                    cache.delegate?.room(didChangeName: cache)
                }
            }}
        }
    }
    public class func deleteRoom(room:QRoom){
        let roomTS = ThreadSafeReference(to: room)
        QiscusDBThread.sync {autoreleasepool{
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            guard let r = realm.resolve(roomTS) else { return }
            
            for group in r.comments {
                for comment in group.comments{
                    QComment.cache[comment.uniqueId] = nil
                    try! realm.write {
                        realm.delete(comment)
                    }
                }
                QCommentGroup.cache[group.id] = nil
                try! realm.write {
                    realm.delete(group)
                }
            }
            for participant in r.participants {
                if !participant.isInvalidated {
                    QParticipant.cache[participant.localId] = nil
                    try! realm.write {
                        realm.delete(participant)
                    }
                }
            }
            try! realm.write {
                realm.delete(r)
            }
        }}
    }
    public func comment(onIndexPath indexPath:IndexPath)->QComment?{
        if self.comments.count > indexPath.section && self.comments[indexPath.section].commentsCount > indexPath.row{
            let comment = self.comments[indexPath.section].comments[indexPath.row]
            return QComment.comment(withUniqueId: comment.uniqueId)
        }else{
            return nil
        }
    }
    internal func cache(){
        let roomTS = ThreadSafeReference(to:self)
        if Thread.isMainThread {
            if Qiscus.chatRooms[self.id] == nil {
                Qiscus.chatRooms[self.id] = self
            }
            if Qiscus.shared.chatViews[self.id] ==  nil{
                let chatView = QiscusChatVC()
                chatView.chatRoom = Qiscus.chatRooms[self.id]
                Qiscus.shared.chatViews[self.id] = chatView
            }
        }else{
            DispatchQueue.main.sync {
                let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                guard let room = realm.resolve(roomTS) else { return }
                if Qiscus.chatRooms[room.id] == nil {
                    Qiscus.chatRooms[room.id] = room
                }
                if Qiscus.shared.chatViews[room.id] ==  nil{
                    let chatView = QiscusChatVC()
                    chatView.chatRoom = Qiscus.chatRooms[room.id]
                    Qiscus.shared.chatViews[room.id] = chatView
                }
            }
        }
    }
    
    public func loadComments(limit:Int, offset:String, onSuccess:@escaping ([QComment])->Void, onError:@escaping (String)->Void){
        if let commentId = Int(offset) {
            if commentId == 0 {
                onError("invalid offset")
                return
            }
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            let data =  realm.objects(QComment.self).filter("roomId == '\(self.id)' AND id > \(commentId)").sorted(byKeyPath: "createdAt", ascending: true)
            if data.count >= limit {
                var comments = [QComment]()
                var i = 0
                for comment in data {
                    if i < limit {
                        comments.append(comment)
                    }else{
                        break
                    }
                    i += 1
                }
                onSuccess(comments)
            }else{
                QRoomService.loadComments(inRoom: self, limit: limit, offset: offset, onSuccess: onSuccess, onError: onError)
            }
        }else{
            onError("invalid offset")
        }
    }
    public func loadComments(onSuccess:@escaping ([QComment])->Void, onError:@escaping (String)->Void){
        QRoomService.loadComments(inRoom: self, onSuccess: onSuccess, onError: onError)
    }
    public func loadMore(limit:Int, offset:String, onSuccess:@escaping ([QComment],Bool)->Void, onError:@escaping (String)->Void){
        if let commentId = Int(offset) {
            if commentId == 0 {
                onError("invalid offset")
                return
            }
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            let data =  realm.objects(QComment.self).filter("roomId == '\(self.id)' AND id < \(commentId)").sorted(byKeyPath: "createdAt", ascending: true)
            if data.count >= limit {
                var comments = [QComment]()
                var i = 0
                for comment in data {
                    if i < limit {
                        comments.append(comment)
                    }else{
                        break
                    }
                    i += 1
                }
                let first = comments.first!
                let hasMoreMessages = first.id == 0 ? false : true
                onSuccess(comments, hasMoreMessages)
            }else{
                // CALL API Here
                QRoomService.loadMore(inRoom: self, limit: limit, offset: offset, onSuccess: onSuccess, onError: onError)
            }
        }else{
            onError("invalid offset")
        }
    }
}

