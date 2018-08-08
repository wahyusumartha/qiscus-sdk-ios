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
    
    public func loadAvatar(onSuccess:  @escaping (UIImage)->Void, onError:  @escaping (String)->Void){
        
    }
    
    /// Need get data from localdatabase
    ///
    /// - Returns: [QRoom]
    public class func all() -> [QRoom]?{
        
        return nil
    }
    
    public class func getRoom(withId: String, completion: @escaping (QRoom?, QError?) -> Void) {
        QiscusCore.shared.getRoom(withID: withId) { (qRoom,error) in
            completion(qRoom as! QRoom,nil)
        }
    }
    
    
    public class func getAllRoom(completion: @escaping ([QRoom]?, QError?) -> Void){
        QiscusCore.shared.getAllRoom() { (qRoom,error) in
            completion(qRoom as! [QRoom],nil)
        }
    }
    
}


