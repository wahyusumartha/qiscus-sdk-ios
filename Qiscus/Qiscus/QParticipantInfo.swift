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
        participant.id = data["id"].intValue
        participant.lastCommentReadId = data["lastCommentReadId"].intValue
        participant.lastCommentReceivedId = data["lastCommentReceivedId"].intValue
        participant.username = data[""].stringValue
        
        return participant
    }
}
