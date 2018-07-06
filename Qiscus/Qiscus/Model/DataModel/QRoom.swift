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
@objc public enum QRoomProperty:Int{
    case name
    case avatar
    case participant
    case lastComment
    case unreadCount
    case data
}
@objc public protocol QRoomDelegate {
    @objc optional func room(didChangeName room:QRoom)
    @objc optional func room(didChangeAvatar room:QRoom)
    @objc optional func room(didChangeParticipant room:QRoom)
    @objc optional func room(didDeleteComment room:QRoom)
    
    @objc optional func room(didChangeUser room:QRoom, user:QUser)
    @objc optional func room(didFinishSync room:QRoom)
    @objc optional func room(gotNewGroupComment onIndex:Int)
    @objc optional func room(gotNewComment comment:QComment)
    
    @objc optional func room(didFinishLoadMore inRoom:QRoom, success:Bool, gotNewComment:Bool)
    @objc optional func room(didChangeUnread inRoom:QRoom)
    @objc optional func room(didClearMessages cleared:Bool)
}
public class QRoom:Object {
    @objc public dynamic var id:String = ""
    @objc public dynamic var uniqueId:String = ""
    @objc internal dynamic var storedName:String = ""
    @objc internal dynamic var definedname:String = ""
    @objc public dynamic var storedAvatarURL:String = ""
    @objc public dynamic var definedAvatarURL:String = ""
    @objc internal dynamic var avatarData:Data?
    @objc public dynamic var isPublicChannel: Bool = false
    @objc public dynamic var roomTotalParticipant: Int = 0
    @objc public dynamic var data:String = ""
    @objc public dynamic var distinctId:String = ""
    @objc public dynamic var typeRaw:Int = QRoomType.single.rawValue
    @objc public dynamic var singleUser:String = ""
    @objc public dynamic var typingUser:String = ""
    @objc public dynamic var lastReadCommentId: Int = 0
    @objc public dynamic var lastDeliveredCommentId: Int = 0
    @objc public dynamic var isLocked:Bool = false
    
    @objc internal dynamic var unreadCommentCount:Int = 0
    @objc public dynamic var unreadCount:Int = 0
    @objc internal dynamic var pinned:Double = 0
    
    // MARK: - lastComment variable
    @objc internal dynamic var lastCommentId:Int = 0
    @objc internal dynamic var lastCommentText:String = ""
    @objc internal dynamic var lastCommentUniqueId: String = ""
    @objc internal dynamic var lastCommentBeforeId:Int = 0
    @objc internal dynamic var lastCommentCreatedAt: Double = 0
    @objc internal dynamic var lastCommentSenderEmail:String = ""
    @objc internal dynamic var lastCommentSenderName:String = ""
    @objc internal dynamic var lastCommentStatusRaw:Int = QCommentStatus.sending.rawValue
    @objc internal dynamic var lastCommentTypeRaw:String = QCommentType.text.name()
    @objc internal dynamic var lastCommentData:String = ""
    @objc internal dynamic var lastCommentRawExtras:String = ""
        
    // MARK: private method
    @objc internal dynamic var lastParticipantsReadId:Int = 0
    @objc internal dynamic var lastParticipantsDeliveredId:Int = 0
    @objc internal dynamic var roomVersion017:Bool = true
    
    internal let rawComments = List<QComment>()
    internal let service = QRoomService()
    
    public var comments:[QComment]{
        get{
            var comments = [QComment]()
            if self.rawComments.count > 0 {
                comments = Array(self.rawComments.sorted(byKeyPath: "createdAt", ascending: true))
            }
            return comments
        }
    }
    
    
    public let participants = List<QParticipant>()
    
    public var delegate:QRoomDelegate? {
        didSet {
            if Thread.isMainThread && !self.isInvalidated {
                Qiscus.chatRooms[id] = self
            }
        }
    }
    internal var typingTimer:Timer?
    internal var selfTypingTimer:Timer?
    
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    // MARK: - Unstored properties
    override public static func ignoredProperties() -> [String] {
        return ["typingTimer","delegate","selfTypingTimer"]
    }
    
}

