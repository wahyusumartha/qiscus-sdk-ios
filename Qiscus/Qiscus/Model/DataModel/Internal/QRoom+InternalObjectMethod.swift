//
//  QRoom+InternalObjectMethod.swift
//  Qiscus
//
//  Created by Ahmad Athaullah on 21/11/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftyJSON

internal extension QRoom {
    internal func pinRoom(){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        try! realm.write {
            self.pinned = Double(Date().timeIntervalSince1970)
        }
    }
    internal func unpinRoom(){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        try! realm.write {
            self.pinned = 0
        }
    }
    internal func getCommentGroup(index:Int)->QCommentGroup?{
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
    internal func updateRoom(roomName:String? = nil, roomAvatarURL:String? = nil, roomOptions:String? = nil, onSuccess:@escaping ((_ room: QRoom)->Void),onError:@escaping ((_ error: String)->Void)){
        let service = QRoomService()
        service.updateRoom(onRoom: self, roomName: roomName, roomAvatarURL: roomAvatarURL, roomOptions: roomOptions, onSuccess: onSuccess, onError: onError)
    }
    internal func publishStopTypingRoom(){
        let roomId = self.id
        QiscusBackgroundThread.async { autoreleasepool{
            let message: String = "0";
            let channel = "r/\(roomId)/\(roomId)/\(QiscusMe.sharedInstance.email)/t"
//            func execute(){
                Qiscus.shared.mqtt?.publish(channel, withString: message, qos: .qos1, retained: false)
//            }
            
//            DispatchQueue.main.async {
//                autoreleasepool {
//                    execute()
//                }
//            }
            }}
        if self.selfTypingTimer != nil {
            if self.typingTimer!.isValid {
                self.typingTimer!.invalidate()
            }
            self.typingTimer = nil
        }
    }
    internal func publishStartTypingRoom(){
        let roomId = self.id
        QiscusBackgroundThread.async { autoreleasepool{
            let message: String = "1";
            let channel = "r/\(roomId)/\(roomId)/\(QiscusMe.sharedInstance.email)/t"
            //func execute(){
                Qiscus.shared.mqtt?.publish(channel, withString: message, qos: .qos1, retained: false)
            //}
            
//            DispatchQueue.main.async {
//                autoreleasepool{
//                    execute()
//                }
//            }
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
    
    internal func subscribeRoomChannel(){
        let id = self.id
        QiscusBackgroundThread.async {
            if let room = QRoom.threadSaveRoom(withId: id) {
                var channels = [String]()
                
                channels.append("r/\(room.id)/\(room.id)/+/d")
                channels.append("r/\(room.id)/\(room.id)/+/r")
                channels.append("r/\(room.id)/\(room.id)/+/t")
                
                for participant in room.participants{
                    if participant.email != QiscusMe.sharedInstance.email {
                        channels.append("u/\(participant.email)/s")
                    }
                }
                
                DispatchQueue.main.async {
                    for channel in channels{
                        if Qiscus.realtimeConnected {
                            Qiscus.shared.mqtt?.subscribe(channel)
                        }else{
                            if !Qiscus.realtimeChannel.contains(channel) {
                                Qiscus.realtimeChannel.append(channel)
                            }
                        }
                    }
                }
            }
        }
    }
    internal func unsubscribeRoomChannel(){
        let id = self.id
        QiscusBackgroundThread.async {
            if let room = QRoom.threadSaveRoom(withId: id) {
                var channels = [String]()
                
                channels.append("r/\(room.id)/\(room.id)/+/d")
                channels.append("r/\(room.id)/\(room.id)/+/r")
                channels.append("r/\(room.id)/\(room.id)/+/t")
                                
                DispatchQueue.global().async {autoreleasepool{
                    for channel in channels{
                        Qiscus.shared.mqtt?.unsubscribe(channel)
                    }
                }}
            }
        }
        
    }
    internal func resetRoomComment(){
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
        let senderEmail = newComment.senderEmail
        let senderName = newComment.senderName
        let avatarURL = newComment.senderAvatarURL
        let user = QUser.getUser(email: senderEmail)
        if user == nil {
            DispatchQueue.main.async {
                let _ = QUser.saveUser(withEmail: senderEmail, fullname: senderName, avatarURL: avatarURL)
            }
        }
        if self.comments.count == 0 {
            let commentGroup = QCommentGroup()
            commentGroup.senderEmail = newComment.senderEmail
            commentGroup.senderName = newComment.senderName
            commentGroup.createdAt = newComment.createdAt
            commentGroup.id = "\(newComment.uniqueId)"
            commentGroup.comments.append(newComment)
            try! realm.write {
                
                self.comments.append(commentGroup)
            }
//            QCommentGroup.cache["\(newComment.uniqueId)"] = commentGroup
            if !onTop {
                if Thread.isMainThread {
                    Qiscus.chatRooms[roomId]?.delegate?.room?(gotNewGroupComment: 0)
                }else{
                    DispatchQueue.main.sync {
                        Qiscus.chatRooms[roomId]?.delegate?.room?(gotNewGroupComment: 0)
                    }
                }
                // TODO: !!
                self.updateLastComentInfo(comment: newComment)
                if Thread.isMainThread {
                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                        if !newComment.isInvalidated {
                            roomDelegate.gotNewComment(newComment)
                        }
                    }
                }
            }else{
                if self.lastCommentId < newComment.id || self.lastCommentCreatedAt < newComment.createdAt {
                    self.updateLastComentInfo(comment: newComment, triggerNotification: false)
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
                    firstCommentGroup.comments.insert(newComment, at: 0)
                }
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
                commentGroup.comments.append(newComment)
                try! realm.write {
                    self.comments.insert(commentGroup, at: 0)
                }
                commentGroup.cacheObject()
            }
            if self.lastCommentId < newComment.id || self.lastCommentCreatedAt < newComment.createdAt {
                self.updateLastComentInfo(comment: newComment, triggerNotification: false)
            }
        }
        else{
            let lastComment = self.comments[self.commentsGroupCount - 1]
            if lastComment.date == newComment.date && lastComment.senderEmail == newComment.senderEmail && newComment.type != .system{
                newComment.cellPosRaw = QCellPosition.last.rawValue
                try! realm.write {
                    lastComment.comments.append(newComment)
                }
                let section = self.comments.count - 1
                let item = lastComment.commentsCount - 1
                
                    DispatchQueue.main.async {
                        Qiscus.chatRooms[roomId]?.delegate?.room?(gotNewCommentOn: section, withCommentIndex: item)
                    }
                
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
                commentGroup.comments.append(newComment)
                try! realm.write {
                    self.comments.append(commentGroup)
                }
                commentGroup.cacheObject()
                let section = self.comments.count - 1
                DispatchQueue.main.async { autoreleasepool {
                    Qiscus.chatRooms[roomId]?.delegate?.room?(gotNewGroupComment: section)
                }}
                self.updateUnreadCommentCount()
            }
            self.updateLastComentInfo(comment: newComment)
            if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                let commentUniqueId = newComment.uniqueId
                DispatchQueue.main.async { autoreleasepool{
                    if let comment = QComment.threadSaveComment(withUniqueId: commentUniqueId){
                        roomDelegate.gotNewComment(comment)
                    }
                }}
            }
        }
        newComment.cacheObject()
    }
    
    internal func updateLastComentInfo(comment:QComment, triggerNotification:Bool = true){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        if !self.isInvalidated {
            if comment.createdAt > self.lastCommentCreatedAt || comment.id > self.lastCommentId || comment.id == 0{
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
                
                if triggerNotification {
                    let roomId = self.id
                    let count = self.unreadCount + 1
                    self.updateUnreadCommentCount(count: count)
                    
                    DispatchQueue.main.async {
                        if let room = QRoom.room(withId: roomId){
                            if let c = QComment.comment(withUniqueId: room.lastCommentUniqueId){
                                if let delegate = room.delegate {
                                    delegate.room?(gotNewComment: c)
                                }
                                Qiscus.chatDelegate?.qiscusChat?(gotNewComment: c)
                                QiscusNotification.publish(gotNewComment: c, room: room)
                            }else{
                                if self.lastCommentId > 0 {
                                    let c = QComment()
                                    c.id = self.lastCommentId
                                    c.uniqueId = self.lastCommentUniqueId
                                    c.roomId = self.id
                                    c.text = self.lastCommentText
                                    c.senderName = self.lastCommentSenderName
                                    c.createdAt = self.lastCommentCreatedAt
                                    c.beforeId = self.lastCommentBeforeId
                                    c.senderEmail = self.lastCommentSenderName
                                    c.roomName = self.name
                                    c.cellPosRaw = QCellPosition.single.rawValue
                                    c.typeRaw = self.lastCommentTypeRaw
                                    c.data = self.lastCommentData
                                    c.rawExtra = self.lastCommentRawExtras
                                    
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
    }
    // MARK: - Public Object method
    internal func syncRoomData(withJSON json:JSON){
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
                if Thread.isMainThread {
                    if let room = QRoom.room(withId: id){
                        QiscusNotification.publish(roomChange: room)
                    }
                }else{
                    DispatchQueue.main.sync {
                        if let room = QRoom.room(withId: id){
                            QiscusNotification.publish(roomChange: room)
                        }
                    }
                }
            }
        }
        if let roomName = json["room_name"].string {
            if roomName != self.storedName {
                try! realm.write {
                    self.storedName = roomName
                }
                let id = self.id
                func execute(){
                    if let cache = QRoom.room(withId: id) {
                        if cache.definedname != "" {
                            QiscusNotification.publish(roomChange: cache)
                            cache.delegate?.room(didChangeName: cache)
                        }
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
        if let roomAvatar = json["avatar_url"].string {
            self.update(avatarURL: roomAvatar)
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
                func execute(){
                    if let room = QRoom.room(withId: id){
                        QiscusNotification.publish(roomChange: room)
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
                func execute(){
                    if let room = QRoom.room(withId: id){
                        QiscusNotification.publish(roomChange: room)
                    }
                }
                if Thread.isMainThread {
                    execute()
                }else{
                    DispatchQueue.main.sync { autoreleasepool {
                        execute()
                        }}
                }
            }
        }
        
        if let participants = json["participants"].array {
            var participantString = [String]()
            var participantChanged = false
            for participantJSON in participants {
                let participantEmail = participantJSON["email"].stringValue
                let fullname = participantJSON["username"].stringValue
                let avatarURL = participantJSON["avatar_url"].stringValue
                DispatchQueue.main.async {
                    let _ = QUser.saveUser(withEmail: participantEmail, fullname: fullname, avatarURL: avatarURL)
                }
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
                func execute(){
                    if let cache = QRoom.room(withId: id) {
                        cache.delegate?.room(didChangeParticipant: cache)
                        QiscusNotification.publish(roomChange: cache)
                    }
                }
                if Thread.isMainThread {
                    execute()
                }else{
                    DispatchQueue.main.sync { autoreleasepool {
                        execute()
                        }}
                }
                
            }
        }
        
    }
    internal func createComment(withJSON json:JSON)->QComment{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let commentId = json["id"].intValue
        let commentUniqueId = json["unique_temp_id"].stringValue
        var commentText = json["message"].stringValue
        let commentSenderName = json["username"].stringValue
        let commentSenderAvatarURL = json["user_avatar_url"].stringValue
        let commentCreatedAt = json["unix_timestamp"].doubleValue
        let commentBeforeId = json["comment_before_id"].intValue
        let senderEmail = json["email"].stringValue
        let commentType = json["type"].stringValue
        let commentExtras = "\(json["extras"])"
        if commentType == "reply" || commentType == "buttons" {
            commentText = json["payload"]["text"].stringValue
        }
        let avatarURL = json["user_avatar_url"].stringValue
        DispatchQueue.main.async {
            let _ = QUser.saveUser(withEmail: senderEmail, fullname: commentSenderName, avatarURL: avatarURL)
        }
        
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
        newComment.senderAvatarURL = commentSenderAvatarURL
        
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
        return newComment
    }
    internal func saveNewComment(fromJSON json:JSON){
        let roomId = self.id
        
        QiscusDBThread.sync {
            if let room = QRoom.threadSaveRoom(withId:  roomId){
                let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                let newComment = room.createComment(withJSON: json)
                let commentUniqueId = newComment.uniqueId
                
                if let oldComment = QComment.threadSaveComment(withUniqueId: commentUniqueId) {
                    try! realm.write {
                        oldComment.id = newComment.id
                        oldComment.text = newComment.text
                        oldComment.senderName = newComment.senderName
                        oldComment.createdAt = newComment.createdAt
                        oldComment.beforeId = newComment.beforeId
                        oldComment.roomName = room.name
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
                    room.addComment(newComment: newComment)
                }
            }
        }
    }
    
    internal func saveOldComment(fromJSON json:JSON){
        let roomId = self.id
        
        QiscusDBThread.sync {
            autoreleasepool {
                let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                guard let room = QRoom.threadSaveRoom(withId: roomId) else { return }
                let commentUniqueId = json["unique_temp_id"].stringValue
                let newComment = room.createComment(withJSON: json)
                
                if let oldComment = QComment.threadSaveComment(withUniqueId: commentUniqueId) {
                    try! realm.write {
                        oldComment.id = newComment.id
                        oldComment.text = newComment.text
                        oldComment.senderName = newComment.senderName
                        oldComment.senderEmail = newComment.senderEmail
                        oldComment.createdAt = newComment.createdAt
                        oldComment.beforeId = newComment.beforeId
                        oldComment.roomName = room.name
                        oldComment.roomId = room.id
                        oldComment.rawExtra = newComment.rawExtra
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
                }
                else{
                    self.addComment(newComment: newComment, onTop: true)
                }
            }
        }
    }
    internal func syncRoom(){
        let service = QRoomService()
        service.sync(onRoom: self)
    }
    internal func loadMoreComment(){
        let service = QRoomService()
        service.loadMore(onRoom: self)
    }
    
    internal func updateStatus(inComment comment:QComment, status:QCommentStatus){
        comment.updateStatus(status: status)
    }
    
    internal func publishStatus(withStatus status:QCommentStatus){
        let service = QRoomService()
        service.publisComentStatus(onRoom: self, status: status)
    }
}
