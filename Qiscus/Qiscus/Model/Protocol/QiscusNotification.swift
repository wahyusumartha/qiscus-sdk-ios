//
//  QiscusNotification.swift
//  Example
//
//  Created by Ahmad Athaullah on 9/12/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

public class QiscusNotification: NSObject {
    
    static let shared = QiscusNotification()
    let nc = NotificationCenter.default
    var roomOrderTimer:Timer?
    
    private static var typingTimer = [String:Timer]()
    
    public static let GOT_NEW_ROOM = NSNotification.Name("qiscus_gotNewRoom")
    public static let GOT_NEW_COMMENT = NSNotification.Name("qiscus_gotNewComment")
    public static let COMMENT_DELETE = NSNotification.Name("qiscus_commentDelete")
    public static let USER_PRESENCE = NSNotification.Name("quscys_userPresence")
    public static let USER_TYPING = NSNotification.Name("qiscus_userTyping")
    public static let USER_AVATAR_CHANGE = NSNotification.Name("qiscus_userAvatarChange")
    public static let MESSAGE_STATUS = NSNotification.Name("qiscus_messageStatus")
    public static let ROOM_CHANGE = NSNotification.Name("qiscus_roomChange")
    public static let ROOM_DELETED = NSNotification.Name("qiscus_roomDeleted")
    public static let ROOM_ORDER_MAY_CHANGE = NSNotification.Name("qiscus_romOrderChange")
    public static let FINISHED_CLEAR_MESSAGES = NSNotification.Name("qiscus_finishedClearMessages")
    public static let FINISHED_SYNC_ROOMLIST = NSNotification.Name("qiscus_finishedSyncRoomList")
    public static let START_CLOUD_SYNC = NSNotification.Name("qiscus_startCloudSync")
    public static let FINISHED_CLOUD_SYNC = NSNotification.Name("qiscus_finishedCloudSync")
    public static let ERROR_CLOUD_SYNC = NSNotification.Name("qiscus_finishedCloudSync")
    
    override private init(){
        super.init()
    }
    internal class func publish(userAvatarChange user:QUser){
        let notification = QiscusNotification.shared
        notification.publish(userAvatarChange: user)
    }
    internal class func publish(userPresence user:QUser){
        let notification = QiscusNotification.shared
        notification.publish(userPresence: user)
    }
    public class func publish(finishedClearMessage cleared:Bool = true){
        let notification = QiscusNotification.shared
        notification.finishedClearMessage()
    }
    public class func publish(startCloudSync sync:Bool = true){
        let notification = QiscusNotification.shared
        notification.startCloudSync()
    }
    public class func publish(finishedCloudSync sync:Bool = true){
        let notification = QiscusNotification.shared
        notification.finishedCloudSync()
    }
    public class func publish(errorCloudSync error:String){
        let notification = QiscusNotification.shared
        notification.errorCloudSync(error: error)
    }
    public class func publish(finishedSyncRoomList synced:Bool = true){
        let notification = QiscusNotification.shared
        notification.finishedSyncRoomList()
    }
    public class func publish(roomOrder change:Bool = true){
        let notification = QiscusNotification.shared
        notification.roomOrderChange()
    }
    public class func publish(roomChange room:QRoom){
        let notification = QiscusNotification.shared
        notification.publish(roomChange: room)
    }
    public class func publish(roomDeleted roomId:String){
        let notification = QiscusNotification.shared
        notification.publish(roomDeleted: roomId)
    }
    public class func publish(messageStatus comment:QComment, status:QCommentStatus){
        let notification = QiscusNotification.shared
        notification.publish(messageStatus: comment, status: status)
    }
    public class func publish(gotNewRoom room:QRoom){
        if !room.isInvalidated {
            let notification = QiscusNotification.shared
            notification.publish(gotNewRoom: room)
        }
    }
    public class func publish(gotNewComment comment:QComment, room:QRoom){
        if !comment.isInvalidated {
            let notification = QiscusNotification.shared
            notification.publish(gotNewComment: comment, room: room)
            notification.roomOrderChange()
        }
    }
    public class func publish(commentDeleteOnRoom room:QRoom){
        let notification = QiscusNotification.shared
        notification.publish(commentDeleteOnRoom: room)
    }
    public class func publish(userTyping user:QUser, room:QRoom ,typing:Bool = true){
        let notification = QiscusNotification.shared
        notification.publish(userTyping: user, room: room, typing: typing)
    }
    
    // MARK: - private method
    private func startCloudSync(){
        self.nc.post(name: QiscusNotification.START_CLOUD_SYNC, object: nil, userInfo: nil)
    }
    private func finishedCloudSync(){
        self.nc.post(name: QiscusNotification.FINISHED_CLOUD_SYNC, object: nil, userInfo: nil)
    }
    private func errorCloudSync(error:String){
        let userInfo: [AnyHashable: Any] = ["error" : error]
        self.nc.post(name: QiscusNotification.ERROR_CLOUD_SYNC, object: nil, userInfo: userInfo)
    }
    private func finishedSyncRoomList(){
        self.nc.post(name: QiscusNotification.FINISHED_SYNC_ROOMLIST, object: nil, userInfo: nil)
    }
    private func finishedClearMessage(){
        self.nc.post(name: QiscusNotification.FINISHED_CLEAR_MESSAGES, object: nil, userInfo: nil)
    }
    private func roomOrderChange(){
        if self.roomOrderTimer != nil {
            self.roomOrderTimer?.invalidate()
        }
        self.roomOrderTimer = Timer.scheduledTimer(timeInterval: 1.3, target: self, selector: #selector(self.publishRoomOrderChange), userInfo: nil, repeats: false)
    }
    private func publish(userAvatarChange user:QUser){
        let userInfo: [AnyHashable: Any] = ["user" : user]
        self.nc.post(name: QiscusNotification.USER_AVATAR_CHANGE, object: nil, userInfo: userInfo)
    }
    private func publish(userPresence user:QUser){
        let userInfo: [AnyHashable: Any] = ["user" : user]
        self.nc.post(name: QiscusNotification.USER_PRESENCE, object: nil, userInfo: userInfo)
    }
    @objc private func publishRoomOrderChange(){
        self.nc.post(name: QiscusNotification.ROOM_ORDER_MAY_CHANGE, object: nil, userInfo: nil)
        self.roomOrderTimer = nil
    }
    
    private func publish(roomDeleted roomId:String){
        let userInfo: [AnyHashable: Any] = ["room_id" : roomId]
        self.nc.post(name: QiscusNotification.ROOM_DELETED, object: nil, userInfo: userInfo)
    }
    private func publish(roomChange room:QRoom){
        if !room.isInvalidated {
            let userInfo: [AnyHashable: Any] = ["room" : room]
            self.nc.post(name: QiscusNotification.ROOM_CHANGE, object: nil, userInfo: userInfo)
        }
    }
    private func publish(messageStatus comment:QComment, status:QCommentStatus){
        if !comment.isInvalidated {
            let userInfo: [AnyHashable: Any] = ["comment" : comment, "status": status]
            self.nc.post(name: QiscusNotification.MESSAGE_STATUS, object: nil, userInfo: userInfo)
        }
    }
    private func publish(gotNewRoom room:QRoom){
        if !room.isInvalidated {
            let userInfo = ["room" : room]
            self.nc.post(name: QiscusNotification.GOT_NEW_ROOM, object: nil, userInfo: userInfo)
        }
    }
    private func publish(gotNewComment comment:QComment, room:QRoom){
        if !comment.isInvalidated {
            let userInfo = ["comment" : comment, "room" : room]
            self.nc.post(name: QiscusNotification.GOT_NEW_COMMENT, object: nil, userInfo: userInfo)
        }
    }
    private func publish(commentDeleteOnRoom room:QRoom) {
        let userInfo = ["room" : room]
        self.nc.post(name: QiscusNotification.COMMENT_DELETE, object: nil, userInfo: userInfo)
    }
    private func publish(userTyping user:QUser, room:QRoom ,typing:Bool = true){
        if room.isInvalidated || user.isInvalidated {
            return
        }
        let userInfo: [AnyHashable: Any] = ["room" : room,"user" : user, "typing": typing]
        
        self.nc.post(name: QiscusNotification.USER_TYPING, object: nil, userInfo: userInfo)
        
        if typing {
            if QiscusNotification.typingTimer[room.id] != nil {
                QiscusNotification.typingTimer[room.id]!.invalidate()
            }
            QiscusNotification.typingTimer[room.id] = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(QiscusNotification.clearUserTyping(timer:)), userInfo: userInfo, repeats: false)
        }else{
            if QiscusNotification.typingTimer[room.id] != nil {
                QiscusNotification.typingTimer[room.id]!.invalidate()
                QiscusNotification.typingTimer[room.id] = nil
            }
        }
    }
    @objc private func clearUserTyping(timer: Timer){
        let data = timer.userInfo as! [AnyHashable : Any]
        let user = data["user"] as! QUser
        let room = data["room"] as! QRoom
        
        self.publish(userTyping: user, room: room, typing: false)
    }
}

