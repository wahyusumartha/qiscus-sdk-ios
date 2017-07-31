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
public protocol QRoomDelegate {
    func room(didChangeName room:QRoom)
    func room(didChangeAvatar room:QRoom)
    func room(didChangeParticipant room:QRoom)
    func room(didChangeGroupComment section:Int)
    func room(didChangeComment section:Int, row:Int, action:String)
    func room(didDeleteComment section:Int, row:Int)
    func room(didDeleteGroupComment section:Int)
    
    func room(didChangeUser room:QRoom, user:QUser)
    func room(didFinishSync room:QRoom)
    func room(gotNewGroupComment onIndex:Int)
    func room(gotNewCommentOn groupIndex:Int, withCommentIndex index:Int)
    func room(didFailUpdate error:String)
    
    func room(userDidTyping userEmail:String)
    func room(didFinishLoadMore inRoom:QRoom, success:Bool, gotNewComment:Bool)
    func room(didChangeUnread lastReadCommentId:Int, unreadCount:Int)
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
    public dynamic var typingUser:String = ""
    public dynamic var lastReadCommentId: Int = 0
    public dynamic var unreadCommentCount:Int = 0
    
    // MARK: private method
    private dynamic var lastParticipantsReadId:Int = 0
    private dynamic var lastParticipantsDeliveredId:Int = 0
    
    private let comments = List<QCommentGroup>()
    public let participants = List<QParticipant>()
    
    public var delegate:QRoomDelegate?
    private var typingTimer:Timer?
    private var selfTypingTimer:Timer?
    
    
    // MARK: - Unstored properties
    override public static func ignoredProperties() -> [String] {
        return ["typingTimer"]
    }
    
    // MARK: - Getter variable
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
            if let comment = self.lastCommentGroup?.lastComment {
                return QComment.comment(withUniqueId: comment.uniqueId)
            }else{
                return nil
            }
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
            let data =  realm.objects(QComment.self).filter("roomId == \(self.id)").sorted(byKeyPath: "createdAt", ascending: true)
            for comment in data {
                if let cached = QComment.cache[comment.uniqueId] {
                    comments.append(cached)
                }else{
                    QComment.cache[comment.uniqueId] = comment
                    comments.append(comment)
                }
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
        var allRoom = [QRoom]()
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        
        let data = realm.objects(QRoom.self)
        
        if data.count > 0 {
            for room in data{
                allRoom.append(room)
            }
        }
        return allRoom
    }
    public class func room(withId id:Int) -> QRoom? {
        Qiscus.checkDatabaseMigration()
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        var room:QRoom? = nil
        room = realm.object(ofType: QRoom.self, forPrimaryKey: id)
        if room != nil {
            if let cachedRoom = Qiscus.chatRooms[room!.id] {
                room = cachedRoom
            }else{
                room!.resetRoomComment()
                Qiscus.chatRooms[room!.id] = room!
                Qiscus.sharedInstance.RealtimeConnect()
            }
            DispatchQueue.main.async {
                if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                    roomDelegate.didFinishLoadRoom(onRoom: room!)
                }
            }
        }
        return room
    }
    public class func room(withUniqueId uniqueId:String) -> QRoom? {
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        var room:QRoom? = nil
        let data =  realm.objects(QRoom.self).filter("uniqueId == '\(uniqueId)'")
        
        if data.count > 0{
            room = data.first!
            if let cachedRoom = Qiscus.chatRooms[room!.id] {
                room = cachedRoom
            }else{
                room!.resetRoomComment()
                Qiscus.chatRooms[room!.id] = room!
                Qiscus.sharedInstance.RealtimeConnect()
            }
            DispatchQueue.main.async {
                if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                    roomDelegate.didFinishLoadRoom(onRoom: room!)
                }
            }
        }
        return room
    }
    public class func room(withUser user:String) -> QRoom? {
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        var room:QRoom? = nil
        let data =  realm.objects(QRoom.self).filter("singleUser == '\(user)'")
        
        if data.count > 0{
            room = data.first!
            if let cachedRoom = Qiscus.chatRooms[room!.id] {
                room = cachedRoom
            }else{
                room!.resetRoomComment()
                Qiscus.chatRooms[room!.id] = room!
                Qiscus.sharedInstance.RealtimeConnect()
            }
            DispatchQueue.main.async {
                if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                    roomDelegate.didFinishLoadRoom(onRoom: room!)
                }
            }
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
                let fullname = participantJSON["username"].stringValue
                let avatarURL = participantJSON["avatar_url"].stringValue
                
                let savedUser = QUser.saveUser(withEmail: participantEmail, fullname: fullname, avatarURL: avatarURL)
                
                if room.type == .single {
                    if savedUser.email != QiscusMe.sharedInstance.email {
                        try! realm.write {
                            room.singleUser = participantEmail
                        }
                    }
                }
                //then save participants
                if QParticipant.participant(inRoomWithId: room.id, andEmail: participantEmail) == nil{
                    let newParticipant = QParticipant()
                    newParticipant.localId = "\(room.id)_\(participantEmail)"
                    newParticipant.roomId = room.id
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
        Qiscus.chatRooms[room.id] = room
        Qiscus.sharedInstance.RealtimeConnect()
        DispatchQueue.main.async {
            if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                roomDelegate.didFinishLoadRoom(onRoom: room)
            }
        }
        return room
    }
    
    // MARK: Private Object Method
    private func resetRoomComment(){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let data =  realm.objects(QComment.self).filter("roomId == \(self.id)")
        
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
        if self.comments.count == 0 {
            let commentGroup = QCommentGroup()
            commentGroup.senderEmail = newComment.senderEmail
            commentGroup.senderName = newComment.senderName
            commentGroup.createdAt = newComment.createdAt
            commentGroup.id = "\(self.id):::\(newComment.senderEmail):::\(newComment.uniqueId)"
            commentGroup.append(comment: newComment)
            try! realm.write {
                self.comments.append(commentGroup)
            }
            if !onTop {
                self.delegate?.room(gotNewGroupComment: 0)
                DispatchQueue.main.async {
                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                        roomDelegate.gotNewComment(newComment)
                    }
                }
                self.updateUnreadCommentCount()
            }
        }else if onTop{
            let firstCommentGroup = self.comments.first!
            if firstCommentGroup.date == newComment.date && firstCommentGroup.senderEmail == newComment.senderEmail{
                newComment.cellPosRaw = QCellPosition.first.rawValue
                try! realm.write {
                    firstCommentGroup.createdAt = newComment.createdAt
                    firstCommentGroup.senderName = newComment.senderName
                }
                firstCommentGroup.insert(comment: newComment, at: 0)
                for i in 0...(firstCommentGroup.commentsCount - 1){
                    let comment = firstCommentGroup.comment(index: i)!
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
                }
            }else{
                let commentGroup = QCommentGroup()
                commentGroup.senderEmail = newComment.senderEmail
                commentGroup.senderName = newComment.senderName
                commentGroup.createdAt = newComment.createdAt
                commentGroup.id = "\(self.id):::\(newComment.senderEmail):::\(newComment.uniqueId)"
                commentGroup.append(comment: newComment)
                try! realm.write {
                    self.comments.insert(commentGroup, at: 0)
                }
            }
        }else{
            let lastComment = self.comments.last!
            if lastComment.date == newComment.date && lastComment.senderEmail == newComment.senderEmail{
                newComment.cellPosRaw = QCellPosition.last.rawValue
                lastComment.append(comment: newComment)
                
                self.delegate?.room(gotNewCommentOn: self.comments.count - 1, withCommentIndex: lastComment.commentsCount - 1)
                DispatchQueue.main.async {
                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                        roomDelegate.gotNewComment(newComment)
                        self.updateUnreadCommentCount()
                    }
                }
                let section = self.comments.count - 1
                for i in 0...(lastComment.commentsCount - 1) {
                    let comment = lastComment.comment(index: i)!
                    var position = QCellPosition.first
                    if i == lastComment.commentsCount - 1 {
                        position = .last
                    }
                    else if i > 0 {
                        position = .middle
                    }
                    if comment.cellPos != position {
                        comment.updateCellPos(cellPos: position)
                        self.delegate?.room(didChangeComment: section, row: i, action: "position")
                    }
                }
            }else{
                let commentGroup = QCommentGroup()
                commentGroup.senderEmail = newComment.senderEmail
                commentGroup.senderName = newComment.senderName
                commentGroup.createdAt = newComment.createdAt
                commentGroup.id = "\(self.id):::\(newComment.senderEmail):::\(newComment.uniqueId)"
                commentGroup.append(comment: newComment)
                try! realm.write {
                    self.comments.append(commentGroup)
                }
                self.delegate?.room(gotNewGroupComment: self.comments.count - 1)
                DispatchQueue.main.async {
                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                        roomDelegate.gotNewComment(newComment)
                        self.updateUnreadCommentCount()
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
        
        var participantString = [String]()
        var participantChanged = false
        for participantJSON in json["participants"].arrayValue {
            let participantEmail = participantJSON["email"].stringValue
            let fullname = participantJSON["username"].stringValue
            let avatarURL = participantJSON["avatar_url"].stringValue
            let savedUser = QUser.saveUser(withEmail: participantEmail, fullname: fullname, avatarURL: avatarURL)
            
            if QParticipant.participant(inRoomWithId: self.id, andEmail: savedUser.email) == nil{
                let newParticipant = QParticipant()
                newParticipant.localId = "\(self.id)_\(participantEmail)"
                newParticipant.roomId = self.id
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
        var commentText = json["message"].stringValue
        let commentSenderName = json["username"].stringValue
        let commentCreatedAt = json["unix_timestamp"].doubleValue
        let commentBeforeId = json["comment_before_id"].intValue
        let senderEmail = json["email"].stringValue
        let commentType = json["type"].stringValue
        
        if commentType == "reply" || commentType == "buttons" {
            commentText = json["payload"]["text"].stringValue
        }
        
        let avatarURL = json["user_avatar_url"].stringValue
        let _ = QUser.saveUser(withEmail: senderEmail, fullname: commentSenderName, avatarURL: avatarURL, lastSeen: commentCreatedAt)
        
        if let oldComment = QComment.comment(withUniqueId: commentUniqueId) {
            try! realm.write {
                oldComment.id = commentId
                oldComment.text = commentText
                oldComment.senderName = commentSenderName
                oldComment.createdAt = commentCreatedAt
                oldComment.beforeId = commentBeforeId
            }
            if oldComment.statusRaw < QCommentStatus.sent.rawValue{
                var status = QCommentStatus.sent
                if oldComment.id < self.lastParticipantsReadId {
                    status = .read
                }else if oldComment.id < self.lastParticipantsDeliveredId{
                    status = .delivered
                }
                oldComment.updateStatus(status: status)
                
                var section = 0
                for commentGroup in self.comments{
                    for row in 0...(commentGroup.commentsCount - 1) {
                        let commentTarget = commentGroup.comment(index: row)!
                        if commentTarget.uniqueId == oldComment.uniqueId{
                            self.delegate?.room(didChangeComment: section, row: row, action: "status")
                            break
                        }
                    }
                    section += 1
                }
            }
        }else{
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
                newComment.typeRaw = QCommentType.postback.rawValue
                break
            case "account_linking":
                newComment.data = "\(json["payload"])"
                newComment.typeRaw = QCommentType.account.rawValue
                break
            case "reply":
                newComment.data = "\(json["payload"])"
                newComment.typeRaw = QCommentType.reply.rawValue
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
            self.addComment(newComment: newComment)
        }
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
        var commentText = json["message"].stringValue
        let commentSenderName = json["username"].stringValue
        let commentCreatedAt = json["unix_timestamp"].doubleValue
        let commentBeforeId = json["comment_before_id"].intValue
        let senderEmail = json["email"].stringValue
        let commentType = json["type"].stringValue
        
        if commentType == "reply" || commentType == "buttons" {
            commentText = json["payload"]["text"].stringValue
        }
        let avatarURL = json["user_avatar_url"].stringValue
        let user = QUser.saveUser(withEmail: senderEmail, fullname: commentSenderName, avatarURL: avatarURL, lastSeen: commentCreatedAt)
        
        if let oldComment = QComment.comment(withUniqueId: commentUniqueId) {
            try! realm.write {
                oldComment.id = commentId
                oldComment.text = commentText
                oldComment.senderName = user.fullname
                oldComment.senderEmail = user.email
                oldComment.createdAt = commentCreatedAt
                oldComment.beforeId = commentBeforeId
            }
            if oldComment.statusRaw < QCommentStatus.sent.rawValue{
                var status = QCommentStatus.sent
                if oldComment.id < self.lastParticipantsReadId {
                    status = .read
                }else if oldComment.id < self.lastParticipantsDeliveredId{
                    status = .delivered
                }
                
                oldComment.updateStatus(status: status)
                if let indexPath = self.getIndexPath(ofComment: oldComment) {
                    self.delegate?.room(didChangeComment: indexPath.section, row: indexPath.row, action: "status")
                }
            }
        }else{
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
                newComment.typeRaw = QCommentType.postback.rawValue
                break
            case "account_linking":
                newComment.data = "\(json["payload"])"
                newComment.typeRaw = QCommentType.account.rawValue
                break
            case "reply":
                newComment.data = "\(json["payload"])"
                newComment.typeRaw = QCommentType.reply.rawValue
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
            self.addComment(newComment: newComment, onTop: true)
        }
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
        let service = QRoomService()
        service.sync(onRoom: self)
    }
    public func loadMore(){
        let service = QRoomService()
        service.loadMore(onRoom: self)
    }
    
    // MARK: - Updater method
    public func updateCommentStatus(inComment comment:QComment, status:QCommentStatus){
        if self.comments.count > 0 {
            var section = 0
            for commentGroup in self.comments {
                var found = false
                for row in 0...(commentGroup.commentsCount - 1) {
                    let commentTarget = commentGroup.comment(index: row)!
                    if commentTarget.uniqueId == comment.uniqueId {
                        found = true
                        let rawStatus = commentTarget.statusRaw
                        var newStatus = QCommentStatus.sent
                        if commentTarget.id < self.lastParticipantsReadId {
                            newStatus = .read
                        }else if commentTarget.id < self.lastParticipantsDeliveredId{
                            newStatus = .delivered
                        }
                        commentTarget.updateStatus(status: newStatus)
                        if rawStatus != newStatus.rawValue{
                            self.delegate?.room(didChangeComment: section, row: row, action: "status")
                        }
                        break
                    }
                }
                
                if found {
                    break
                }
                section += 1
            }
        }
    }
    
    public func publishCommentStatus(withStatus status:QCommentStatus){
        let service = QRoomService()
        service.publisComentStatus(onRoom: self, status: status)
    }
    
    public func newFileComment(type:QiscusFileType, filename:String = "", data:Data? = nil, thumbImage:UIImage? = nil)->QComment{
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
            comment.typeRaw = QCommentType.audio.rawValue
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
            
            comment.typeRaw = QCommentType.image.rawValue
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
            comment.typeRaw = QCommentType.video.rawValue
            file.localPath = QFile.saveFile(data!, fileName: fileName)
            break
        default:
            file.localPath = QFile.saveFile(data!, fileName: fileName)
            comment.typeRaw = QCommentType.file.rawValue
            break
        }
        
        try! realm.write {
            realm.add(file, update: true)
        }
        self.addComment(newComment: comment)
        
        return comment
    }
    public func newComment(text:String, payload:JSON? = nil, type:QCommentType = .text, data:Data? = nil, image:UIImage? = nil, filename:String = "", filePath:URL? = nil )->QComment{
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
        comment.typeRaw = type.rawValue
        
        switch type {
        case .reply:
            if let data = payload {
                comment.data = "\(data)"
            }
            break
         default:
            break
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
        comment.typeRaw = QCommentType.text.rawValue
        
        self.addComment(newComment: comment)
        
        self.post(comment: comment)
    }
    public func post(comment:QComment, type:String? = nil, payload:JSON? = nil){
        let service = QRoomService()
        service.postComment(onRoom: self.id, comment: comment)
    }
    public func upload(comment:QComment, onSuccess:  @escaping (QRoom, QComment)->Void, onError:  @escaping (QRoom,QComment,String)->Void){
        self.updateCommentStatus(inComment: comment, status: .sending)
        let service = QRoomService()
        service.uploadCommentFile(inRoom: self, comment: comment, onSuccess: onSuccess, onError: onError)
    }
    public func downloadMedia(onComment comment:QComment, thumbImageRef: UIImage? = nil, isAudioFile: Bool = false){
        let service = QRoomService()
        service.downloadMedia(inRoom: self, comment: comment, thumbImageRef: thumbImageRef, isAudioFile: isAudioFile)
    }
    public func getIndexPath(ofComment comment:QComment)->IndexPath?{
        var section = self.comments.count - 1
        var indexPath:IndexPath? = nil
        var found = false
        for commentGroup in self.comments.reversed() {
            if commentGroup.date == comment.date && commentGroup.senderEmail == comment.senderEmail{
                for row in 0...(commentGroup.commentsCount - 1) {
                    let commentTarget = commentGroup.comment(index: row)!
                    if commentTarget.uniqueId == comment.uniqueId{
                        indexPath = IndexPath(item: row, section: section)
                        found = true
                        break
                    }
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
            self.delegate?.room(userDidTyping: userEmail)
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
        if let commentIndex = self.getIndexPath(ofComment: comment) {
            let commentGroup = self.comments[commentIndex.section]
            
            if QComment.cache[comment.uniqueId] != nil{
                QComment.cache[comment.uniqueId] = nil
            }
            if self.comments[commentIndex.section].commentsCount > 1{
                try! realm.write {
                    realm.delete(comment)
                }
                self.delegate?.room(didDeleteComment: commentIndex.section, row: commentIndex.item)
            }else{
                try! realm.write {
                    realm.delete(comment)
                    realm.delete(commentGroup)
                }
                self.delegate?.room(didDeleteGroupComment: commentIndex.section)
            }
        }
    }
    public func participant(withEmail email:String)->QParticipant?{
        if let participant = QParticipant.participant(inRoomWithId: self.id, andEmail: email){
            return participant
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
    public func updateUnreadCommentCount(){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let unread = QComment.countComments(afterId: self.lastReadCommentId, roomId: self.id)
        if self.unreadCommentCount != unread {
            try! realm.write {
                self.unreadCommentCount = unread
            }
            self.delegate?.room(didChangeUnread: self.lastReadCommentId, unreadCount: unread)
        }
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
        var section = 0
        for commentGroup in self.comments {
            for item in 0...(self.comments[section].commentsCount - 1){
                let comment = commentGroup.comment(index: item)!
                if comment.statusRaw < QCommentStatus.read.rawValue || comment.status == .failed{
                    comment.updateStatus(status: .read)
                    self.delegate?.room(didChangeComment: section, row: item, action: "status")
                }
            }
            section += 1
        }
    }
    private func updateLastParticipantsDeliveredId(deliveredId:Int){
        var section = 0
        for commentGroup in self.comments {
            for item in 0...(self.comments[section].commentsCount - 1){
                let comment = commentGroup.comment(index: item)!
                if comment.statusRaw < QCommentStatus.delivered.rawValue || comment.status == .failed{
                    comment.updateStatus(status: .delivered)
                    self.delegate?.room(didChangeComment: section, row: item, action: "status")
                }
            }
            section += 1
        }
    }
    public class func publishStatus(roomId:Int, commentId:Int, status:QCommentStatus){
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
        let message: String = "0";
        let channel = "r/\(self.id)/\(self.id)/\(QiscusMe.sharedInstance.email)/t"
        Qiscus.shared.mqtt?.publish(channel, withString: message, qos: .qos1, retained: false)
        if self.selfTypingTimer != nil {
            if self.typingTimer!.isValid {
                self.typingTimer!.invalidate()
            }
            self.typingTimer = nil
        }
    }
    public func publishStartTyping(){
        let message: String = "1";
        let channel = "r/\(self.id)/\(self.id)/\(QiscusMe.sharedInstance.email)/t"
        Qiscus.shared.mqtt?.publish(channel, withString: message, qos: .qos1, retained: false)
        if self.typingTimer != nil {
            if self.typingTimer!.isValid {
                self.typingTimer!.invalidate()
            }
        }
        self.typingTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(self.publishStopTyping), userInfo: nil, repeats: false)
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
}
