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
    
    private static var typingTimer = [Int:Timer]()
    
    public static let GOT_NEW_COMMENT = NSNotification.Name("qiscus_gotNewComment")
    public static let USER_TYPING = NSNotification.Name("qiscus_userTyping")
    public static let MESSAGE_STATUS = NSNotification.Name("qiscus_messageStatus")
    public static let ROOM_CHANGE = NSNotification.Name("qiscus_roomChange")
    
    override private init(){
        super.init()
    }
    
    public class func publish(roomChange room:QRoom){
        let notification = QiscusNotification.shared
        notification.publish(roomChange: room)
    }
    public class func publish(messageStatus comment:QComment, status:QCommentStatus){
        let notification = QiscusNotification.shared
        notification.publish(messageStatus: comment, status: status)
    }
    public class func publish(gotNewComment comment:QComment){
        let notification = QiscusNotification.shared
        notification.publish(gotNewComment: comment)
    }
    public class func publish(userTyping user:QUser, room:QRoom ,typing:Bool = true){
        let notification = QiscusNotification.shared
        notification.publish(userTyping: user, room: room, typing: typing)
    }
    
    // MARK: - private method
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
    private func publish(gotNewComment comment:QComment){
        let userInfo = ["comment" : comment]
        self.nc.post(name: QiscusNotification.GOT_NEW_COMMENT, object: nil, userInfo: userInfo)
    }
    private func publish(userTyping user:QUser, room:QRoom ,typing:Bool = true){
        
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
