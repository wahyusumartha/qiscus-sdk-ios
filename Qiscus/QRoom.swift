//
//  QRoom.swift
//  Qiscus
//
//  Created by Qiscus on 07/08/18.
//

import Foundation
import QiscusCore
import UIKit

@objc public enum QRoomType:Int{
    case single
    case group
}

public class QRoom: RoomModel {
    public var lastCommentMessage: QComment{
        get{
            return lastComment as! QComment
        }
    }
    
    public var roomName : String{
        get{
            return name
        }
    }
    
    public var roomType : QRoomType{
        get{
            if chatType != "single" {
                return QRoomType.group
            }else{
                return QRoomType.single
            }
            
        }
    }
    
    public var avatarURL : String {
        get{
            return avatarUrl
        }
    }
    
    //Todo Need to be implement from qiscus core
    public func loadAvatar(onSuccess:  @escaping (UIImage)->Void, onError:  @escaping (String)->Void){
        
    }
    
    /// Need get data from localdatabase
    ///
    /// - Returns: [QRoom]
    public class func all() -> [QRoom]?{
        
        return nil
    }
    
    public class func getRoom(withId: String, completion: @escaping (QRoom?, String?) -> Void) {
        QiscusCore.shared.getRoom(withID: withId) { (qRoom,error) in
            if let qRoomData = qRoom {
                 completion(qRoom as! QRoom,nil)
            }else{
                completion(nil,error?.message)
            }
        }
    }
    
    
    public class func getAllRoom(completion: @escaping ([QRoom]?, String) -> Void){
        QiscusCore.shared.getAllRoom() { (qRoom,error) in
            if let qRoomData = qRoom {
                 completion(qRoomData as! [QRoom],"suceess")
            }else{
                completion(nil,(error?.message)!)
            }
           
        }
    }
    
    public class func getUnreadCount(completion: @escaping (Int) -> Void){
        QiscusCore.shared.getAllRoom() { (qRoom,error) in
            var countUnread = 0
            if let qRoomData = qRoom {
                for room in qRoomData.enumerated() {
                    countUnread = countUnread + room.element.unreadCount
                }
            }
            
            completion(countUnread)
        }
    }
    
    public func update(withID: String, roomName:String? = nil, roomAvatarURL:String? = nil, roomOptions:String? = nil, onSuccess:@escaping ((_ room: QRoom)->Void),onError:@escaping ((_ error: String)->Void)){
        QiscusCore.shared.updateRoom(withID: withID, name: roomName, avatarURL: URL(string: roomAvatarURL!), options: roomOptions) { (qRoom, error) in
            if let qRoomData = qRoom {
                onSuccess(qRoom as! QRoom)
            }else{
                onError((error?.message)!)
            }
           
        }
    }
}


