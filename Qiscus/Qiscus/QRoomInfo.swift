//
//  QRoomInfo.swift
//  Example
//
//  Created by Ahmad Athaullah on 7/27/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import Foundation
import SwiftyJSON

public class QRoomInfo:NSObject {
    public var lastCommentId:Int = 0
    public var lastCommentMessage:String = ""
    public var roomId:Int = 0
    public var lastCommentTimestamp:String = ""
    public var roomName:String = ""
    public var roomType:QRoomType = .single
    public var unreadCount = 0
    public var participants = [QParticipantInfo]()
    
    public class func roomInfo(fromJSON data:JSON)->QRoomInfo{
        let roomInfo = QRoomInfo()
        roomInfo.lastCommentId = data["last_comment_id"].intValue
        roomInfo.lastCommentMessage = data["last_comment_message"].stringValue
        roomInfo.roomId = data["room_id"].intValue
        roomInfo.lastCommentTimestamp = data["lastCommentTimestamp"].stringValue
        roomInfo.roomName = data["room_name"].stringValue
        
        if data["room_type"].stringValue == "single" {
            roomInfo.roomType = .single
        }else{
            roomInfo.roomType = .group
        }
        roomInfo.unreadCount = data["unread_count"].intValue
        
        if let participans = data["participants"].array {
            for participantData in participants {
                let participant = QParticipantInfo.participantInfo(fromJSON: participantData)
                roomInfo.participants.append(participant)
            }
        }
        
        return roomInfo
    }
}
