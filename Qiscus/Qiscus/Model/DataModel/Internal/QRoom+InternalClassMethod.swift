//
//  QRoom+InternalClassMethod.swift
//  Qiscus
//
//  Created by Ahmad Athaullah on 21/11/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import RealmSwift
import SwiftyJSON

internal extension QRoom {
    internal class func allRoom()->[QRoom]{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let data = realm.objects(QRoom.self).sorted(byKeyPath: "pinned", ascending: false).sorted(byKeyPath: "lastCommentCreatedAt", ascending: false)
        
        if data.count > 0 {
            return Array(data)
        }else{
            return [QRoom]()
        }
    }
    internal class func unpinAllRoom(){
        let data = QRoom.allRoom()
        for room in data {
            room.unpin()
        }
    }
    internal class func getRoom(withId id:String) -> QRoom?{
        if Thread.isMainThread {
            if let cache = Qiscus.chatRooms[id] {
                if !cache.isInvalidated {
                    cache.subscribeRoomChannel()
                    return cache
                }else{
                    Qiscus.chatRooms[id] = nil
                }
            }
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            let rooms = realm.objects(QRoom.self).filter("id == '\(id)'")
            if rooms.count > 0 {
                let room = rooms.first!
                room.resetRoomComment()
                Qiscus.chatRooms[room.id] = room
                if Qiscus.shared.chatViews[room.id] ==  nil{
                    let chatView = QiscusChatVC()
                    chatView.chatRoom = Qiscus.chatRooms[room.id]
                    Qiscus.shared.chatViews[room.id] = chatView
                }
                room.subscribeRoomChannel()
                return room
            }
        }
        return nil
    }
    internal class func getRoom(withUniqueId uniqueId:String) -> QRoom? {
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
    internal class func getSingleRoom(withUser user:String) -> QRoom? {
        if Thread.isMainThread {
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
        }
        return nil
    }
    internal class func addNewRoom(json:JSON)->QRoom{
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
                room.storedAvatarURL = roomAvatar
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
                realm.add(room)
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
        func execute(){
            if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                if !room.isInvalidated {
                    roomDelegate.didFinishLoadRoom(onRoom: room)
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
        return room
    }
    internal class func removeRoom(room:QRoom){
        let roomId = room.id
        QiscusDBThread.sync {autoreleasepool{
            if let r = QRoom.threadSaveRoom(withId: roomId){
                let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                r.unsubscribeRoomChannel()
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
            }
        }}
    }
    
    internal class func cacheAll(){
        let rooms = QRoom.all()
        for room in rooms{
            room.cache()
        }
    }
    internal class func threadSaveRoom(withId id:String) -> QRoom? {
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let rooms = realm.objects(QRoom.self).filter("id == '\(id)'")
        if rooms.count > 0 {
            return rooms.first!
        }
        return nil
    }
}
