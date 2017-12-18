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
        let id = self.id
        QiscusDBThread.async {
            if let r = QRoom.threadSaveRoom(withId: id) {
                let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                realm.refresh()
                try! realm.write {
                    r.pinned = Double(Date().timeIntervalSince1970)
                }
            }
        }
    }
    internal func unpinRoom(){
        let id = self.id
        QiscusDBThread.async {
            if let r = QRoom.threadSaveRoom(withId: id) {
                if r.pinned != 0 {
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    realm.refresh()
                    try! realm.write {
                        r.pinned = 0
                    }
                }
            }
        }
    }
    internal func getCommentGroup(index:Int)->QCommentGroup?{
        if self.comments.count > index {
            return self.comments[index]
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
            let channel = "r/\(roomId)/\(roomId)/\(QiscusMe.shared.email)/t"
            
            Qiscus.shared.mqtt?.publish(channel, withString: message, qos: .qos1, retained: false)
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
            let channel = "r/\(roomId)/\(roomId)/\(QiscusMe.shared.email)/t"
            Qiscus.shared.mqtt?.publish(channel, withString: message, qos: .qos1, retained: false)
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
    internal func checkCommentStatus(){
        let id = self.id
        QiscusDBThread.async {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            realm.refresh()
            if let room = QRoom.threadSaveRoom(withId: id){
                var lastReadId = 0
                var lastDeliveredId = 0
                for participant in room.participants {
                    if lastReadId == 0 || lastReadId > participant.lastReadCommentId{
                        lastReadId = participant.lastReadCommentId
                    }
                    if lastDeliveredId == 0 || lastDeliveredId > participant.lastDeliveredCommentId{
                        lastDeliveredId = participant.lastDeliveredCommentId
                    }
                }
                if lastReadId > 0 && lastDeliveredId > 0 {
                    if lastReadId != room.lastReadCommentId {
                        try! realm.write {
                            room.lastReadCommentId = lastReadId
                        }
                    }
                    if lastDeliveredId != room.lastDeliveredCommentId {
                        try! realm.write {
                            room.lastDeliveredCommentId = lastDeliveredId
                        }
                    }
                    let filteredGroup = room.comments.filter("senderEmail == '\(QiscusMe.shared.email)'")
                    for group in filteredGroup {
                        let deliveredData = group.comments.filter("id != 0 AND id <= \(room.lastDeliveredCommentId) AND statusRaw < \(QCommentStatus.delivered.rawValue) ")
                        let readData = group.comments.filter("id != 0 AND id <= \(room.lastReadCommentId) AND statusRaw < \(QCommentStatus.read.rawValue) ")
                        for c in deliveredData {
                            c.updateStatus(status: .delivered)
                            if c.id == room.lastCommentId {
                                if room.lastCommentStatusRaw != QCommentStatus.delivered.rawValue{
                                    try! realm.write {
                                        room.lastCommentStatusRaw = QCommentStatus.delivered.rawValue
                                    }
                                    let rId = room.id
                                    let rts = ThreadSafeReference(to: room)
                                    DispatchQueue.main.async {
                                        let mainRealm = try! Realm(configuration: Qiscus.dbConfiguration)
                                        mainRealm.refresh()
                                        if Qiscus.chatRooms[rId] == nil {
                                            if let r = mainRealm.resolve(rts) {
                                                Qiscus.chatRooms[rId] = r
                                            }
                                        }
                                        if let r = QRoom.room(withId: rId){
                                            QiscusNotification.publish(roomChange: r, onProperty: .lastComment)
                                        }
                                    }
                                }
                            }
                        }
                        for c in readData {
                            c.updateStatus(status: .read)
                            if c.id == room.lastCommentId {
                                if room.lastCommentStatusRaw != QCommentStatus.read.rawValue{
                                    try! realm.write {
                                        room.lastCommentStatusRaw = QCommentStatus.read.rawValue
                                    }
                                    let rId = room.id
                                    let rts = ThreadSafeReference(to:room)
                                    DispatchQueue.main.async {
                                        let mainRealm = try! Realm(configuration: Qiscus.dbConfiguration)
                                        mainRealm.refresh()
                                        if Qiscus.chatRooms[rId] == nil {
                                            if let r = mainRealm.resolve(rts) {
                                                Qiscus.chatRooms[rId] = r
                                            }
                                        }
                                        if let r = QRoom.getRoom(withId: rId){
                                            QiscusNotification.publish(roomChange: r, onProperty: .lastComment)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
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
                    if participant.email != QiscusMe.shared.email {
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
        let id = self.id
        QiscusDBThread.async {
            if let room = QRoom.threadSaveRoom(withId: id){
                let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                realm.refresh()
                let data =  realm.objects(QComment.self).filter("roomId == '\(id)'")
                
                try! realm.write {
                    room.typingUser = ""
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
        }
    }
    
    internal func addComment(newComment:QComment, onTop:Bool = false){
        let id = self.id
        let cUniqueId = newComment.uniqueId
        
        QiscusDBThread.sync {
            if let room = QRoom.threadSaveRoom(withId: id) {
                let predicate = NSPredicate(format: "id CONTAINS %@", cUniqueId)
                if room.comments.filter(predicate).count > 0 {
                    Qiscus.printLog(text: "fail to add newComment, comment with same uniqueId already exist")
                    return
                }
                
                let senderEmail = newComment.senderEmail
                let senderName = newComment.senderName
                let avatarURL = newComment.senderAvatarURL
                
                let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                realm.refresh()
                
                if QUser.getUser(email: senderEmail) == nil {
                    let _ = QUser.saveUser(withEmail: senderEmail, fullname: senderName, avatarURL: avatarURL)
                }
                
                if room.comments.count == 0 {
                    newComment.cellPosRaw = QCellPosition.single.rawValue
                    let commentGroup = QCommentGroup()
                    commentGroup.senderEmail = newComment.senderEmail
                    commentGroup.senderName = newComment.senderName
                    commentGroup.createdAt = newComment.createdAt
                    commentGroup.id = "\(newComment.uniqueId)"
                    
                    try! realm.write {
                        room.comments.append(commentGroup)
                        realm.add(newComment, update: true)
                        commentGroup.comments.append(newComment)
                    }
                }
                else if onTop{
                    let firstCommentGroup = room.comments.first!
                    if firstCommentGroup.date == newComment.date && firstCommentGroup.senderEmail == newComment.senderEmail && newComment.type != .system {
                        newComment.cellPosRaw = QCellPosition.first.rawValue
                        let predicate = NSPredicate(format: "uniqueId = %@", newComment.uniqueId)
                        realm.refresh()
                        if firstCommentGroup.comments.filter(predicate).count == 0 {
                            try! realm.write {
                                firstCommentGroup.createdAt = newComment.createdAt
                                firstCommentGroup.senderName = newComment.senderName
                                realm.add(newComment, update: true)
                                firstCommentGroup.comments.insert(newComment, at: 0)
                            }
                            let changedComment = firstCommentGroup.comments[1]
                            if changedComment.cellPos == .single {
                                changedComment.updateCellPos(cellPos: .last)
                            }else if changedComment.cellPos == .first {
                                changedComment.updateCellPos(cellPos: .middle)
                            }
                            if !firstCommentGroup.id.contains(cUniqueId){
                                let newId = "\(firstCommentGroup.id)   \(cUniqueId)"
                                try! realm.write {
                                    firstCommentGroup.id = newId
                                }
                            }
                        }
                    }else{
                        let commentGroup = QCommentGroup()
                        commentGroup.senderEmail = newComment.senderEmail
                        commentGroup.senderName = newComment.senderName
                        commentGroup.createdAt = newComment.createdAt
                        commentGroup.id = "\(cUniqueId)"
                        newComment.cellPosRaw = QCellPosition.single.rawValue
                        try! realm.write {
                            self.comments.insert(commentGroup, at: 0)
                            realm.add(newComment, update: true)
                            commentGroup.comments.append(newComment)
                        }
                    }
                    if room.lastComment == nil {
                        room.updateLastComentInfo(comment: newComment)
                    }
                }
                else{
                    let lastGroup = room.comments[room.comments.count - 1]
                    let lastComment = lastGroup.comments[lastGroup.comments.count - 1]
                    if lastGroup.date == newComment.date && lastGroup.senderEmail == newComment.senderEmail && newComment.type != .system && lastComment.type != .system{
                        newComment.cellPosRaw = QCellPosition.last.rawValue
                        let predicate = NSPredicate(format: "uniqueId = %@", newComment.uniqueId)
                        realm.refresh()
                        
                        if lastGroup.comments.filter(predicate).count == 0 {
                            try! realm.write {
                                realm.add(newComment, update: true)
                                lastGroup.comments.append(newComment)
                            }
                            if !lastGroup.id.contains(cUniqueId){
                                let newId = "\(lastGroup.id)   \(cUniqueId)"
                                try! realm.write {
                                    lastGroup.id = newId
                                }
                            }
                            lastGroup.calculateCommentPosition()
                        }
                    }else{
                        let commentGroup = QCommentGroup()
                        commentGroup.senderEmail = newComment.senderEmail
                        commentGroup.senderName = newComment.senderName
                        commentGroup.createdAt = newComment.createdAt
                        commentGroup.id = "\(newComment.uniqueId)"
                        newComment.cellPosRaw = QCellPosition.single.rawValue
                        try! realm.write {
                            room.comments.append(commentGroup)
                            realm.add(newComment, update: true)
                            commentGroup.comments.append(newComment)
                        }
                    }
                }
                if !onTop {
                    let rId = self.id
                    if Thread.isMainThread {
                        if let r = QRoom.getRoom(withId: rId){
                            let groupPredicate = NSPredicate(format: "id CONTAINS %@", cUniqueId)
                            if let group = r.comments.filter(groupPredicate).last{
                                let cPredicate = NSPredicate(format: "uniqueId = %@", cUniqueId)
                                if let c = group.comments.filter(cPredicate).first {
                                    QiscusNotification.publish(gotNewComment: c, room: r)
                                }
                            }
                        }
                    }else{
                        DispatchQueue.main.sync {
                            if let r = QRoom.getRoom(withId: rId){
                                let groupPredicate = NSPredicate(format: "id CONTAINS %@", cUniqueId)
                                if let group = r.comments.filter(groupPredicate).last{
                                    let cPredicate = NSPredicate(format: "uniqueId = %@", cUniqueId)
                                    if let c = group.comments.filter(cPredicate).first {
                                        QiscusNotification.publish(gotNewComment: c, room: r)
                                    }
                                }
                            }
                        }
                    }
                }
            }else{
                Qiscus.printLog(text: "fail to add newComment, room not exist")
                return
            }
        }
    }
    
    internal func updateLastComentInfo(comment:QComment, triggerNotification:Bool = true){
        let id = self.id
        let cId = comment.id
        let cText = comment.text
        let cUniqueId = comment.uniqueId
        let cBeforeId = comment.beforeId
        let cCreatedAt = comment.createdAt
        let cSenderEmail = comment.senderEmail
        let cSenderName = comment.senderName
        let cStatusRaw = comment.statusRaw
        let cTypeRaw = comment.typeRaw
        let cData = comment.data
        let cRawExtras = comment.rawExtra
        QiscusDBThread.async {
            if let room = QRoom.threadSaveRoom(withId: id){
                if !room.isInvalidated {
                    if cCreatedAt > room.lastCommentCreatedAt || cId > room.lastCommentId || cId == 0 {
                        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                        realm.refresh()
                        try! realm.write {
                            room.lastCommentId = cId
                            room.lastCommentText = cText
                            room.lastCommentUniqueId = cUniqueId
                            room.lastCommentBeforeId = cBeforeId
                            room.lastCommentCreatedAt = cCreatedAt
                            room.lastCommentSenderEmail = cSenderEmail
                            room.lastCommentSenderName = cSenderName
                            room.lastCommentStatusRaw = cStatusRaw
                            room.lastCommentTypeRaw = cTypeRaw
                            room.lastCommentData = cData
                            room.lastCommentRawExtras = cRawExtras
                        }
                        let rts = ThreadSafeReference(to:room)
                        DispatchQueue.main.async {
                            let mainRealm = try! Realm(configuration: Qiscus.dbConfiguration)
                            mainRealm.refresh()
                            if Qiscus.chatRooms[id] == nil {
                                if let r = mainRealm.resolve(rts) {
                                    Qiscus.chatRooms[id] = r
                                }
                            }
                            if let cache = QRoom.room(withId: id){
                                if let c = cache.lastComment {
                                    if cache.comments.count == 0 {
                                        QiscusNotification.publish(gotNewComment: c, room: cache)
                                    }
                                    QiscusNotification.publish(roomChange: cache, onProperty: .lastComment)
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
        let id = self.id
        QiscusDBThread.async {
            if let room = QRoom.threadSaveRoom(withId: id) {
                let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                realm.refresh()
                if let option = json["options"].string {
                    if option != "" && option != "<null>" && option != room.data{
                        try! realm.write {
                            room.data = option
                        }
                        let rts = ThreadSafeReference(to:room)
                        DispatchQueue.main.async {
                            let mainRealm = try! Realm(configuration: Qiscus.dbConfiguration)
                            mainRealm.refresh()
                            if Qiscus.chatRooms[id] == nil {
                                if let r = mainRealm.resolve(rts) {
                                    Qiscus.chatRooms[id] = r
                                }
                            }
                            if let cache = QRoom.room(withId: id) {
                                QiscusNotification.publish(roomChange: cache, onProperty: .data)
                            }
                        }
                    }
                }
                if let unread = json["unread_count"].int {
                    if unread != room.unreadCount {
                        try! realm.write {
                            room.unreadCount = unread
                        }
                        let rts = ThreadSafeReference(to: room)
                        DispatchQueue.main.async {
                            let mainRealm = try! Realm(configuration: Qiscus.dbConfiguration)
                            mainRealm.refresh()
                            if Qiscus.chatRooms[id] == nil {
                                if let r = mainRealm.resolve(rts) {
                                    Qiscus.chatRooms[id] = r
                                }
                            }
                            if let cache = QRoom.getRoom(withId: id) {
                                QiscusNotification.publish(roomChange: cache, onProperty: .unreadCount)
                                cache.delegate?.room?(didChangeUnread: cache)
                            }
                        }
                    }
                }
                if let roomName = json["room_name"].string {
                    if roomName != room.storedName {
                        try! realm.write {
                            room.storedName = roomName
                        }
                        if room.definedname == "" {
                            let rts = ThreadSafeReference(to: room)
                            DispatchQueue.main.async {
                                let mainRealm = try! Realm(configuration: Qiscus.dbConfiguration)
                                mainRealm.refresh()
                                if Qiscus.chatRooms[id] == nil {
                                    if let r = mainRealm.resolve(rts) {
                                        Qiscus.chatRooms[id] = r
                                    }
                                }
                                if let cache = QRoom.room(withId: id) {
                                    QiscusNotification.publish(roomChange: cache, onProperty: .name)
                                }
                            }
                        }
                    }
                }
                if let roomAvatar = json["avatar_url"].string {
                    room.update(avatarURL: roomAvatar)
                }
                if json["last_comment"] != JSON.null {
                    let commentData = json["last_comment"]
                    let comment = QComment.tempComment(fromJSON: commentData)
                    if comment.id > room.lastCommentId {
                        try! realm.write {
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
                        }
                        let rts = ThreadSafeReference(to: room)
                        DispatchQueue.main.async {
                            let mainRealm = try! Realm(configuration: Qiscus.dbConfiguration)
                            mainRealm.refresh()
                            if Qiscus.chatRooms[id] == nil {
                                if let r = mainRealm.resolve(rts) {
                                    Qiscus.chatRooms[id] = r
                                }
                            }
                            if let cache = QRoom.room(withId: id) {
                                QiscusNotification.publish(roomChange: cache, onProperty: .lastComment)
                            }
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
                        
                        let _ = QUser.saveUser(withEmail: participantEmail, fullname: fullname, avatarURL: avatarURL)
                        
                        let lastReadId = participantJSON["last_comment_read_id"].intValue
                        let lastDeliveredId = participantJSON["last_comment_received_id"].intValue
                        let savedParticipant = room.participants.filter("email == '\(participantEmail)'")
                        if savedParticipant.count > 0{
                            let storedParticipant = savedParticipant.first!
                            storedParticipant.updateLastReadId(commentId: lastReadId)
                            storedParticipant.updateLastDeliveredId(commentId: lastDeliveredId)
                        }else {
                            let newParticipant = QParticipant()
                            newParticipant.localId = "\(room.id)_\(participantEmail)"
                            newParticipant.roomId = room.id
                            newParticipant.email = participantEmail
                            newParticipant.lastReadCommentId = lastReadId
                            newParticipant.lastDeliveredCommentId = lastDeliveredId
                            
                            do {
                                try realm.write {
                                    room.participants.append(newParticipant)
                                }
                            }
                            catch let error as NSError {
                                Qiscus.printLog(text: "WARNING!! - \(error.localizedDescription)")
                            }
                            
                            participantChanged = true
                        }
                        participantString.append(participantEmail)
                    }
                    
                    var index = 0
                    var participantRemoved = false
                    for participant in room.participants{
                        if !participantString.contains(participant.email){
                            try! realm.write {
                                room.participants.remove(objectAtIndex: index)
                                participantRemoved = true
                            }
                            participantChanged = true
                        }
                        index += 1
                    }
                    if participantChanged {
                        let rts = ThreadSafeReference(to: room)
                        DispatchQueue.main.async {
                            let mainRealm = try! Realm(configuration: Qiscus.dbConfiguration)
                            mainRealm.refresh()
                            if Qiscus.chatRooms[id] == nil {
                                if let r = mainRealm.resolve(rts) {
                                    Qiscus.chatRooms[id] = r
                                }
                            }
                            if let cache = QRoom.room(withId: id) {
                                cache.delegate?.room?(didChangeParticipant: cache)
                                QiscusNotification.publish(roomChange: cache, onProperty: .participant)
                            }
                        }
                    }
                    if participantRemoved {
                        room.checkCommentStatus()
                    }
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
        
        let _ = QUser.saveUser(withEmail: senderEmail, fullname: commentSenderName, avatarURL: avatarURL)
        
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
            let fileURL = json["payload"]["url"].stringValue
            var filename = newComment.fileName(text: fileURL)
            
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
            var type = QiscusFileType.file
            if newComment.file == nil {
                let file = QFile()
                file.id = newComment.uniqueId
                file.url = fileURL
                file.senderEmail = newComment.senderEmail
                file.filename = filename
                try! realm.write {
                    realm.add(file, update:true)
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
            case .document:
                newComment.typeRaw = QCommentType.document.name()
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
                var filename = newComment.fileName(text: fileURL)
                
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
                if newComment.file == nil {
                    let file = QFile()
                    file.id = newComment.uniqueId
                    file.url = fileURL
                    file.filename = filename
                    file.senderEmail = newComment.senderEmail
                    try! realm.write {
                        realm.add(file, update:true)
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
                case .document:
                    newComment.typeRaw = QCommentType.document.name()
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
                realm.refresh()
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
                realm.refresh()
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
    internal func getParticipant(withEmail email:String)->QParticipant?{
        let data = self.participants.filter("email == '\(email)'")
        return data.first
    }
    internal func getGrouppedComments()->[[QComment]]{
        var retVal = [[QComment]]()
        for commentGroup in self.comments {
            var group = [QComment]()
            var uidCollection = [String]()
            var i = 0
            for comment in commentGroup.comments {
                if !uidCollection.contains(comment.uniqueId){
                    uidCollection.append(comment.uniqueId)
                    group.append(comment)
                }else{
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        commentGroup.comments.remove(objectAtIndex: i)
                    }
                }
                i += 1
            }
            retVal.append(group)
        }
        return retVal
    }
    internal func getGrouppedCommentsUID()->[[String]]{
        var retVal = [[String]]()
        
        for commentGroup in self.comments {
            var group = [String]()
            var i = 0
            for comment in commentGroup.comments {
                if !group.contains(comment.uniqueId) {
                    group.append(comment.uniqueId)
                }else{
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        commentGroup.comments.remove(objectAtIndex: i)
                    }
                }
                i += 1
            }
            retVal.append(group)
        }
        return retVal
    }
}

