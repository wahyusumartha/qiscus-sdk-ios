//
//  QParticipantInfo.swift
//  Example
//
//  Created by Ahmad Athaullah on 7/27/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import Foundation
import SwiftyJSON

public class QParticipantInfo:NSObject {
    /*
    "avatar_url": "https://res.cloudinary.com/qiscus/image/fetch/http://res.cloudinary.com/qiscus/image/upload/v1486010155/kiwari-prod_user_id_73/zpvh5zf6dqzthtjgjggs.jpg",
    "email": "userid_73_6285743021232@kiwari.com",
    "id": 102,
    "last_comment_read_id": 123512,
    "last_comment_received_id": 123484,
    "username": "Anisa"
    */
    public var avatarUrl:String = ""
    public var email:String = ""
    public var id:Int = 0
    public var lastCommentReadId:Int = 0
    public var lastCommentReceivedId:Int = 0
    public var username:String = ""
    
    public class func participantInfo(fromJSON data:JSON)->QParticipantInfo{
        let participant = QParticipantInfo()
        participant.avatarUrl = data["avatarUrl"].stringValue
        participant.email = data["email"].stringValue
        participant.id = data["id"].int
        participant.lastCommentReadId = data["lastCommentReadId"].intValue
        participant.lastCommentReceivedId = data["lastCommentReceivedId"].intValue
        participant.username = data[""].stringValue
        
        return participant
    }
}
