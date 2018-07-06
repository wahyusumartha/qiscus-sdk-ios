//
//  QRoomFunction.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 06/07/18.
//

import Foundation
import RealmSwift

extension QRoom {
    internal func resendPendingMessage(){
        let id = self.id
        let pendingMessages = self.rawComments.filter("statusRaw == %d", QCommentStatus.pending.rawValue)
        if pendingMessages.count > 0 {
            if let pendingMessage = pendingMessages.first {
                service.postComment(onRoom: id, comment: pendingMessage) {
                    self.resendPendingMessage()
                }
            }
        }
    }
    
    internal func redeletePendingDeletedMessage() {
        let pendingDeletedMessages = self.rawComments.filter("statusRaw == %d", QCommentStatus.deletePending.rawValue)
        if pendingDeletedMessages.count > 0 {
            for pendingDeletedMessage in pendingDeletedMessages {
                pendingDeletedMessage.delete(forMeOnly: false, hardDelete: true, onSuccess: {
                    if !pendingDeletedMessage.isInvalidated {
                        self.deleteComment(comment: pendingDeletedMessage)
                    }
                }, onError: { (code) in
                    
                })
            }
        }
    }
    
    
    internal func updateUnreadCommentCount(count:Int){
        let id = self.id
        QiscusDBThread.async {
            if let room = QRoom.threadSaveRoom(withId: id){
                if room.unreadCount != count {
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    realm.refresh()
                    try! realm.write {
                        room.unreadCount = count
                    }
                    DispatchQueue.main.async {
                        if let cache = QRoom.room(withId: id){
                            QiscusNotification.publish(roomChange: cache, onProperty: .unreadCount)
                            cache.delegate?.room?(didChangeUnread: cache)
                        }
                    }
                }
            }
        }
    }
    
    internal func updateTotalParticipant(count:Int){
        let id = self.id
        QiscusDBThread.async {
            if let room = QRoom.threadSaveRoom(withId: id){
                if room.roomTotalParticipant != count {
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    realm.refresh()
                    try! realm.write {
                        room.roomTotalParticipant = count
                    }
                }
            }
        }
    }
    
    
    internal func updateCommentStatus(){
        if self.participants.count > 0 {
            var minDeliveredId = 0
            var minReadId = 0
            var first = true
            for participant in self.participants {
                if first && participant.email != Qiscus.client.email{
                    minDeliveredId = participant.lastDeliveredCommentId
                    minReadId = participant.lastReadCommentId
                    first = false
                }else if participant.email != Qiscus.client.email{
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
        let roomId = self.id
        QiscusBackgroundThread.async {
            if let room = QRoom.threadSaveRoom(withId: roomId){
                if readId > room.lastParticipantsReadId {
                    for comment in room.rawComments{
                        if (comment.statusRaw < QCommentStatus.read.rawValue && comment.status != .failed && comment.status != .sending && comment.status != .pending && comment.id < readId) || comment.id == readId{
                            comment.updateStatus(status: .read)
                        }
                    }
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    realm.refresh()
                    try! realm.write {
                        room.lastParticipantsReadId = readId
                        room.lastParticipantsDeliveredId = readId
                    }
                }
            }
        }
    }
    internal func updateLastParticipantsDeliveredId(deliveredId:Int){
        let roomId = self.id
        QiscusDBThread.async {
            if let room = QRoom.threadSaveRoom(withId: roomId){
                if deliveredId > room.lastParticipantsDeliveredId {
                    for comment in room.rawComments{
                        if (comment.statusRaw < QCommentStatus.delivered.rawValue && comment.status != .failed && comment.status != .sending && comment.id < deliveredId) || (comment.id == deliveredId && comment.status != .read){
                            if !comment.isInvalidated {
                                comment.updateStatus(status: .delivered)
                            }
                        }
                    }
                    
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    realm.refresh()
                    try! realm.write {
                        room.lastParticipantsDeliveredId = deliveredId
                    }
                }
            }
        }
    }
    
    
    internal func update(name:String){
        let id = self.id
        if self.storedName != name {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            realm.refresh()
            try! realm.write {
                self.storedName = name
            }
            DispatchQueue.main.async {
                if let room = QRoom.room(withId: id){
                    if room.definedname == "" {
                        QiscusNotification.publish(roomChange: room, onProperty: .name)
                        room.delegate?.room?(didChangeName: room)
                    }
                }
            }
        }
    }
    internal func update(avatarURL:String){
        if self.storedAvatarURL != avatarURL {
            let id = self.id
            QiscusDBThread.async {
                if let room = QRoom.threadSaveRoom(withId: id){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    realm.refresh()
                    try! realm.write {
                        room.storedAvatarURL = avatarURL
                    }
                    if room.definedAvatarURL == "" {
                        try! realm.write {
                            room.avatarData = nil
                        }
                        DispatchQueue.main.async { autoreleasepool {
                            if let cache = QRoom.room(withId: id){
                                QiscusNotification.publish(roomChange: cache, onProperty: .avatar)
                                cache.delegate?.room?(didChangeAvatar: cache)
                            }
                            }}
                    }
                }
            }
        }
    }
    internal func update(data:String){
        let roomTS = ThreadSafeReference(to: self)
        QiscusDBThread.sync { autoreleasepool {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            realm.refresh()
            guard let r = realm.resolve(roomTS) else { return }
            if r.data != data {
                try! realm.write {
                    r.data = data
                }
            }
            }}
    }
    
    
    internal func cache(){
        let roomTS = ThreadSafeReference(to:self)
        if Thread.isMainThread {
            if Qiscus.chatRooms[self.id] == nil {
                Qiscus.chatRooms[self.id] = self
            }
        }else{
            DispatchQueue.main.sync {
                let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                realm.refresh()
                guard let room = realm.resolve(roomTS) else { return }
                if Qiscus.chatRooms[room.id] == nil {
                    Qiscus.chatRooms[room.id] = room
                }
            }
        }
    }
    
    internal func loadRoomData(limit:Int = 20, offset:String?, onSuccess:@escaping (QRoom)->Void, onError:@escaping (String)->Void){
        QRoomService.loadData(inRoom: self, limit: limit, offset: offset, onSuccess: onSuccess, onError: onError)
    }
    
    internal func downloadRoomAvatar(){
        let id = self.id
        let url = self.avatarURL.replacingOccurrences(of: "/upload/", with: "/upload/c_thumb,g_center,h_100,w_100/")
        if !QChatService.downloadTasks.contains(url){
            QChatService.downloadImage(url: url, onSuccess: { (data) in
                QiscusDBThread.async {
                    if let room = QRoom.threadSaveRoom(withId: id){
                        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                        realm.refresh()
                        try! realm.write {
                            room.avatarData = data
                        }
                        DispatchQueue.main.async { autoreleasepool {
                            if let cache = QRoom.room(withId: id){
                                QiscusNotification.publish(roomChange: cache, onProperty: .avatar)
                                cache.delegate?.room?(didChangeAvatar: cache)
                            }
                            }}
                    }
                }
            }, onFailed: { (error) in
                Qiscus.printLog(text: error)
            })
        }
    }
    internal func loadRoomAvatar(onSuccess:  @escaping (UIImage)->Void, onError:  @escaping (String)->Void){
        let id = self.id
        QiscusDBThread.async {
            if let room = QRoom.threadSaveRoom(withId: id){
                if let imageData = room.avatarData {
                    if let image = UIImage(data: imageData){
                        DispatchQueue.main.async {
                            onSuccess(image)
                        }
                    }else{
                        DispatchQueue.main.async {
                            onError("cant't render data to image")
                        }
                    }
                }else{
                    DispatchQueue.main.async {
                        onError("image not found")
                    }
                }
            }else{
                DispatchQueue.main.async {
                    onError("room not found")
                }
            }
        }
    }
    
    
    internal func clearRemain30() {
        if self.rawComments.count > 30 {
            let id = self.id
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            
            let tempRawComment = List<QComment>()
            let commentToDelete = List<QComment>()
            
            var iteration = 0
            
            for rawComment in self.rawComments.sorted(by: { (q1, q2) -> Bool in
                return q1.createdAt < q2.createdAt
            }).reversed() {
                if iteration < 30 {
                    tempRawComment.insert(rawComment, at: 0)
                } else {
                    QComment.cache.removeValue(forKey: rawComment.uniqueId)
                    commentToDelete.insert(rawComment, at: 0)
                }
                
                iteration += 1
            }
            
            try! realm.write {
                realm.delete(commentToDelete)
                self.rawComments.removeAll()
                tempRawComment.last?.beforeId = 0
                realm.add(tempRawComment, update: true)
                self.rawComments.append(objectsIn: tempRawComment)
            }
        }
    }
    
    internal func clearMessage(){
        let id = self.id
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        
        try! realm.write {
            self.rawComments.removeAll()
        }
        DispatchQueue.main.async {
            if let room = QRoom.room(withId: id){
                room.delegate?.room?(didClearMessages: true)
                QiscusNotification.publish(roomCleared: room)
            }
        }
    }
    internal class func removeAllMessage(){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        for room in QRoom.all() {
            room.clearMessage()
        }
        let comments = realm.objects(QComment.self)
        try! realm.write {
            realm.delete(comments)
        }
        QComment.cache = [String : QComment]()
    }
}
