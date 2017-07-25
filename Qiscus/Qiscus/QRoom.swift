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
    public var listComment:[QComment]{
        get{
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            var comments = [QComment]()
            let data =  realm.objects(QComment.self).filter("roomId == \(self.id)").sorted(byKeyPath: "createdAt", ascending: true)
            for comment in data {
                comments.append(comment)
            }
            return comments
        }
    }
    public var lastComment:QComment?{
        get{
            if self.comments.count > 0 {
                return self.comments.last!.comments.last!
            }else{
                return nil
            }
        }
    }
    //public var service:QRoomService?
    
    // MARK: - Class method
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
    public class func room(withId id:Int) -> QRoom? {
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
    private func addComment(newComment:QComment, onTop:Bool = false){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        if self.comments.count == 0 {
            let commentGroup = QCommentGroup()
            commentGroup.senderEmail = newComment.senderEmail
            commentGroup.senderName = newComment.senderName
            commentGroup.createdAt = newComment.createdAt
            commentGroup.id = "\(self.id):::\(newComment.senderEmail):::\(newComment.uniqueId)"
            commentGroup.comments.append(newComment)
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
            }
        }else if onTop{
            let firstCommentGroup = self.comments.first!
            if firstCommentGroup.date == newComment.date && firstCommentGroup.senderEmail == newComment.senderEmail{
                newComment.cellPosRaw = QCellPosition.first.rawValue
                try! realm.write {
                    firstCommentGroup.createdAt = newComment.createdAt
                    firstCommentGroup.senderName = newComment.senderName
                    firstCommentGroup.comments.insert(newComment, at: 0)
                }
                var i = 0
                for comment in firstCommentGroup.comments {
                    var position = QCellPosition.first
                    if i == firstCommentGroup.comments.count - 1 {
                        position = .last
                    }
                    else if i > 0 {
                        position = .middle
                    }
                    if comment.cellPos != position {
                        try! realm.write {
                            comment.cellPosRaw = position.rawValue
                        }
                    }
                    i += 1
                }
            }else{
                let commentGroup = QCommentGroup()
                commentGroup.senderEmail = newComment.senderEmail
                commentGroup.senderName = newComment.senderName
                commentGroup.createdAt = newComment.createdAt
                commentGroup.id = "\(self.id):::\(newComment.senderEmail):::\(newComment.uniqueId)"
                commentGroup.comments.append(newComment)
                try! realm.write {
                    self.comments.insert(commentGroup, at: 0)
                }
            }
        }else{
            let lastComment = self.comments.last!
            if lastComment.date == newComment.date && lastComment.senderEmail == newComment.senderEmail{
                newComment.cellPosRaw = QCellPosition.last.rawValue
                try! realm.write {
                    lastComment.comments.append(newComment)
                }
                self.delegate?.room(gotNewCommentOn: self.comments.count - 1, withCommentIndex: lastComment.comments.count - 1)
                DispatchQueue.main.async {
                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                        roomDelegate.gotNewComment(newComment)
                    }
                }
                var i = 0
                let section = self.comments.count - 1
                for comment in lastComment.comments {
                    var position = QCellPosition.first
                    if i == lastComment.comments.count - 1 {
                        position = .last
                    }
                    else if i > 0 {
                        position = .middle
                    }
                    if comment.cellPos != position {
                        try! realm.write {
                            comment.cellPosRaw = position.rawValue
                        }
                        self.delegate?.room(didChangeComment: section, row: i, action: "position")
                    }
                    i += 1
                }
            }else{
                let commentGroup = QCommentGroup()
                commentGroup.senderEmail = newComment.senderEmail
                commentGroup.senderName = newComment.senderName
                commentGroup.createdAt = newComment.createdAt
                commentGroup.id = "\(self.id):::\(newComment.senderEmail):::\(newComment.uniqueId)"
                commentGroup.comments.append(newComment)
                try! realm.write {
                    self.comments.append(commentGroup)
                }
                self.delegate?.room(gotNewGroupComment: self.comments.count - 1)
                DispatchQueue.main.async {
                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                        roomDelegate.gotNewComment(newComment)
                    }
                }
            }
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
        //Check sender
        //Check sender
        if let user = QUser.user(withEmail: senderEmail){
            if user.lastSeen < commentCreatedAt {
                try! realm.write {
                    user.lastSeen = commentCreatedAt
                }
                self.delegate?.room(didChangeUser: self, user: user)
            }
        }else{
            let user = QUser()
            user.email = senderEmail
            user.avatarURL = json["user_avatar_url"].stringValue
            user.fullname = commentSenderName
            user.lastSeen = commentCreatedAt
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
                            self.delegate?.room(didChangeComment: section, row: row, action: "status")
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
            newComment.roomId = self.id
            newComment.text = commentText
            newComment.senderName = commentSenderName
            newComment.createdAt = commentCreatedAt
            newComment.beforeId = commentBeforeId
            newComment.senderEmail = senderEmail
            newComment.cellPosRaw = QCellPosition.single.rawValue
            newComment.statusRaw = QCommentStatus.sent.rawValue
            
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
        //Check sender
        if let user = QUser.user(withEmail: senderEmail){
            if user.lastSeen < commentCreatedAt {
                try! realm.write {
                    user.lastSeen = commentCreatedAt
                }
                self.delegate?.room(didChangeUser: self, user: user)
            }
        }else{
            let user = QUser()
            user.email = senderEmail
            user.avatarURL = json["user_avatar_url"].stringValue
            user.fullname = commentSenderName
            user.lastSeen = commentCreatedAt
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
                            self.delegate?.room(didChangeComment: section, row: row, action: "status")
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
            newComment.roomId = self.id
            newComment.text = commentText
            newComment.senderName = commentSenderName
            newComment.createdAt = commentCreatedAt
            newComment.beforeId = commentBeforeId
            newComment.senderEmail = senderEmail
            newComment.cellPosRaw = QCellPosition.single.rawValue
            newComment.statusRaw = QCommentStatus.sent.rawValue
            
            
            
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
                var row = 0
                var found = false
                for commentTarget in commentGroup.comments{
                    if commentTarget.uniqueId == comment.uniqueId {
                        found = true
                        if commentTarget.statusRaw != status.rawValue{
                            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                            try! realm.write {
                                commentTarget.statusRaw = status.rawValue
                            }
                            self.delegate?.room(didChangeComment: section, row: row, action: "status")
                        }
                        break
                    }
                    row += 1
                }
                if found {
                    break
                }
                section += 1
            }
        }
    }
    public func update(name:String? = nil, avatarURL:String? = nil, data:String? = nil){
        let service = QRoomService()
        service.updateRoom(onRoom: self, roomName: name, roomAvatarURL: avatarURL, roomOptions: data)
    }
    public func publishCommentStatus(withStatus status:QCommentStatus){
        let service = QRoomService()
        service.publisComentStatus(onRoom: self, status: status)
    }
    
    //postFile(image: UIImage? = nil, filename:String, filePath:URL? = nil, data:Data? = nil)
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
    public func post(comment:QComment, type:String? = nil, payload:JSON? = nil){
        let service = QRoomService()
        service.postComment(onRoom: self, comment: comment)
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
    public func getIndexPath(ofComment comment:QComment)->IndexPath{
        var section = self.comments.count - 1
        var indexPath = IndexPath(item: self.comments[section].comments.count - 1, section: section)
        for commentGroup in self.comments.reversed() {
            if commentGroup.date == comment.date && commentGroup.senderEmail == comment.senderEmail{
                var row = commentGroup.comments.count - 1
                for commentTarget in commentGroup.comments.reversed(){
                    if commentTarget.uniqueId == comment.uniqueId{
                        indexPath.section = section
                        indexPath.item = row
                        break
                    }
                    row -= 1
                }
            }
            section -= 1
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
        }
        
    }
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
    public func deleteComment(comment:QComment){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let commentIndex = self.getIndexPath(ofComment: comment)
        if self.comments[commentIndex.section].comments.count > 1{
            try! realm.write {
                realm.delete(self.comments[commentIndex.section].comments[commentIndex.item])
            }
            self.delegate?.room(didDeleteComment: commentIndex.section, row: commentIndex.item)
        }else{
            try! realm.write {
                realm.delete(self.comments[commentIndex.section].comments[commentIndex.item])
                realm.delete(self.comments[commentIndex.section])
            }
            self.delegate?.room(didDeleteGroupComment: commentIndex.section)
        }
    }
}
