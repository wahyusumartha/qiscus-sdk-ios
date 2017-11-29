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
    internal dynamic var storedName:String = ""
    internal dynamic var definedname:String = ""
    public dynamic var storedAvatarURL:String = ""
    public dynamic var definedAvatarURL:String = ""
    public dynamic var avatarLocalPath:String = ""
    public dynamic var data:String = ""
    public dynamic var distinctId:String = ""
    public dynamic var typeRaw:Int = QRoomType.single.rawValue
    public dynamic var singleUser:String = ""
    public dynamic var typingUser:String = ""
    public dynamic var lastReadCommentId: Int = 0
    public dynamic var lastDeliveredCommentId: Int = 0
    public dynamic var isLocked:Bool = false
    
    internal dynamic var unreadCommentCount:Int = 0
    public dynamic var unreadCount:Int = 0
    internal dynamic var pinned:Double = 0
    
    // MARK: - lastComment variable
    internal dynamic var lastCommentId:Int = 0
    internal dynamic var lastCommentText:String = ""
    internal dynamic var lastCommentUniqueId: String = ""
    internal dynamic var lastCommentBeforeId:Int = 0
    internal dynamic var lastCommentCreatedAt: Double = 0
    internal dynamic var lastCommentSenderEmail:String = ""
    internal dynamic var lastCommentSenderName:String = ""
    internal dynamic var lastCommentStatusRaw:Int = QCommentStatus.sending.rawValue
    internal dynamic var lastCommentTypeRaw:String = QCommentType.text.name()
    internal dynamic var lastCommentData:String = ""
    internal dynamic var lastCommentRawExtras:String = ""
    
    
    // MARK: private method
    internal dynamic var lastParticipantsReadId:Int = 0
    internal dynamic var lastParticipantsDeliveredId:Int = 0
    internal dynamic var roomVersion006:Bool = true
    
    public let comments = List<QCommentGroup>()
    public let participants = List<QParticipant>()
    
    public var delegate:QRoomDelegate?
    internal var typingTimer:Timer?
    internal var selfTypingTimer:Timer?
    
    
    
    // MARK: - Unstored properties
    override public static func ignoredProperties() -> [String] {
        return ["typingTimer","delegate","selfTypingTimer"]
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
        let fileNameArr = filename.split(separator: ".")
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
            realm.add(file)
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
        if !self.isInvalidated {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            if userEmail != self.typingUser {
                try! realm.write {
                    self.typingUser = userEmail
                }
                let id = self.id
                DispatchQueue.main.async {
                    Qiscus.chatRooms[id]?.delegate?.room(userDidTyping: userEmail)
                }
                if userEmail != "" {
                    if self.typingTimer != nil {
                        self.typingTimer!.invalidate()
                    }
                    self.typingTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(self.clearUserTyping), userInfo: nil, repeats: false)
                }
            }
        }
    }
    public func clearUserTyping(){
        if !self.isInvalidated {
            self.updateUserTyping(userEmail: "")
        }
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
                let roomId = self.id
                if Thread.isMainThread {
                    Qiscus.chatRooms[id]?.delegate?.room(didDeleteComment: commentIndex.section, row: commentIndex.item)
                    QiscusNotification.publish(commentDeleteOnRoom: self)
                }else{
                    DispatchQueue.main.sync { autoreleasepool {
                        Qiscus.chatRooms[id]?.delegate?.room(didDeleteComment: commentIndex.section, row: commentIndex.item)
                        if let room = QRoom.room(withId: roomId) {
                            QiscusNotification.publish(commentDeleteOnRoom:room)
                        }
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
                    QiscusNotification.publish(commentDeleteOnRoom:self)
                }else{
                    let roomId = self.id
                    DispatchQueue.main.sync { autoreleasepool {
                        if let room = QRoom.room(withId: roomId){
                            QiscusNotification.publish(commentDeleteOnRoom:room)
                        }
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
    internal func updateLastParticipantsReadId(readId:Int){
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
    internal func updateLastParticipantsDeliveredId(deliveredId:Int){
        if deliveredId > self.lastParticipantsDeliveredId {
            var section = 0
            for commentGroup in self.comments {
                var item = 0
                for comment in commentGroup.comments{
                    if (comment.statusRaw < QCommentStatus.delivered.rawValue && comment.status != .failed && comment.status != .sending && comment.id < deliveredId) || (comment.id == deliveredId && comment.status != .read){
                        if let cache = QComment.cache[comment.uniqueId] {
                            if !cache.isInvalidated {
                                cache.updateStatus(status: .delivered)
                            }else{
                                comment.updateStatus(status: .delivered)
                            }
                        }else{
                            comment.updateStatus(status: .delivered)
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
        QiscusBackgroundThread.async {
            let service = QRoomService()
            service.publishStatus(inRoom: roomId, commentId: commentId, commentStatus: status)
        }
    }
    
    internal func update(name:String){
        let id = self.id
        if self.storedName != name {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            try! realm.write {
                self.storedName = name
            }
            func execute(){
                if let room = QRoom.room(withId: id){
                    if room.definedname != "" {
                        QiscusNotification.publish(roomChange: room)
                        room.delegate?.room(didChangeName: room)
                    }
                }
            }
            if Thread.isMainThread {
                execute()
            }else{
                DispatchQueue.main.sync {
                    autoreleasepool{
                        execute()
                    }
                }
            }
        }
    }
    internal func update(avatarURL:String){
        let id = self.id
        let roomTS = ThreadSafeReference(to: self)
        QiscusDBThread.async { autoreleasepool {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            guard let r = realm.resolve(roomTS) else { return }
            try! realm.write {
                r.storedAvatarURL = avatarURL
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
    public func setAvatar(url:String){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let oldAvatarURL = self.avatarURL
        try! realm.write {
            self.definedAvatarURL = url
            self.avatarLocalPath = ""
        }
        let id = self.id
        if oldAvatarURL != url {
            func execute(){
                if let cache = QRoom.room(withId: id) {
                    QiscusNotification.publish(roomChange: cache)
                    cache.delegate?.room(didChangeName: cache)
                }
            }
            if Thread.isMainThread {
                execute()
            }else{
                DispatchQueue.main.sync {
                    autoreleasepool{
                        execute()
                    }
                }
            }
        }
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
            func execute(){
                if let cache = QRoom.room(withId: id) {
                    QiscusNotification.publish(roomChange: cache)
                    cache.delegate?.room(didChangeName: cache)
                }
            }
            if Thread.isMainThread {
                execute()
            }else{
                DispatchQueue.main.sync {
                    execute()
                }
            }
        }
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

