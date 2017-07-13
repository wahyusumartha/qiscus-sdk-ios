//
//  QRoomService.swift
//  Example
//
//  Created by Ahmad Athaullah on 7/8/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import AlamofireImage
import RealmSwift

public class QRoomService:NSObject{    
    public func sync(onRoom room:QRoom){
        let loadURL = QiscusConfig.ROOM_REQUEST_ID_URL
        let parameters:[String : AnyObject] =  [
            "id" : room.id as AnyObject,
            "token"  : Qiscus.shared.config.USER_TOKEN as AnyObject
        ]
        Alamofire.request(loadURL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
            if let response = responseData.result.value {
                let json = JSON(response)
                let results = json["results"]
                let error = json["error"]
                
                if results != JSON.null{
                    let roomData = results["room"]
                    room.syncRoomData(withJSON: roomData)
                }else if error != JSON.null{
                    Qiscus.printLog(text: "error getRoom")
                    
                }else{
                    Qiscus.printLog(text: "error getRoom: ")
                }
            }else{
                Qiscus.printLog(text: "error getRoom")
            }
        })
    }
    public func loadMore(onRoom room:QRoom){
        let loadURL = QiscusConfig.LOAD_URL
        var parameters =  [
            "topic_id" : room.id as AnyObject,
            "token" : Qiscus.shared.config.USER_TOKEN as AnyObject
        ]
        if room.comments.count > 0 {
            parameters["last_comment_id"] = room.comments.first!.comments.first!.id as AnyObject
        }
        Qiscus.printLog(text: "request loadMore parameters: \(parameters)")
        Qiscus.printLog(text: "request loadMore url \(loadURL)")
        
        Alamofire.request(loadURL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
            Qiscus.printLog(text: "loadMore result: \(responseData)")
            if let response = responseData.result.value{
                let json = JSON(response)
                let results = json["results"]
                let error = json["error"]
                if results != JSON.null{
                    let comments = json["results"]["comments"].arrayValue
                    if comments.count > 0 {
                        for newComment in comments {
                            room.saveOldComment(fromJSON: newComment)
                        }
                    }
                }else if error != JSON.null{
                    Qiscus.printLog(text: "error loadMore: \(error)")
                }
            }else{
                Qiscus.printLog(text: "fail to LoadMore Data")
            }
        })
    }
    public func updateRoom(onRoom room:QRoom, roomName:String? = nil, roomAvatarURL:String? = nil, roomOptions:String? = nil){
        if Qiscus.isLoggedIn{
            if roomName != nil || roomAvatarURL != nil || roomOptions != nil {
                let requestURL = QiscusConfig.UPDATE_ROOM_URL
                
                var parameters:[String : AnyObject] = [
                    "id" : room.id as AnyObject,
                    "token" : Qiscus.shared.config.USER_TOKEN  as AnyObject
                ]
                if roomName != nil {
                    parameters["room_name"] = roomName as AnyObject
                }
                if roomAvatarURL != nil {
                    parameters["avatar_url"] = roomAvatarURL as AnyObject
                }
                if roomOptions != nil {
                    parameters["options"] = roomOptions as AnyObject
                }
                Qiscus.printLog(text: "update room parameters: \(parameters)")
                Alamofire.request(requestURL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
                    if let response = responseData.result.value {
                        Qiscus.printLog(text: "update room api response:\n\(response)")
                        let json = JSON(response)
                        let results = json["results"]
                        let error = json["error"]
                        
                        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                        if results != JSON.null{
                            Qiscus.printLog(text: "getListComment with user response: \(responseData)")
                            let changed = json["results"]["changed"].boolValue
                            if changed {
                                if roomName != nil && roomName != room.name {
                                    try! realm.write {
                                        room.name = roomName!
                                    }
                                    room.delegate?.room(didChangeName: room)
                                }
                                if roomAvatarURL != nil && room.avatarURL != roomAvatarURL {
                                    try! realm.write {
                                        room.avatarURL = roomAvatarURL!
                                        room.avatarLocalPath = ""
                                    }
                                    room.delegate?.room(didChangeAvatar: room)
                                }
                                if roomOptions != nil && room.data != roomOptions {
                                    try! realm.write {
                                        room.data = roomOptions!
                                    }
                                }
                            }else{
                                room.delegate?.room(didFailUpdate: "No change on room data")
                            }
                        }else if error != JSON.null{
                            Qiscus.printLog(text: "error update chat room: \(error)")
                            room.delegate?.room(didFailUpdate: "\(error)")
                        }
                    }else{
                        Qiscus.printLog(text: "fail to update chat room")
                        room.delegate?.room(didFailUpdate: "fail to update chat room")
                    }
                })
            }else{
                room.delegate?.room(didFailUpdate: "fail to update chat room")
            }
        }
        room.delegate?.room(didFailUpdate: "User not logged in")
    }
    public func publisComentStatus(onRoom room:QRoom, status:QCommentStatus){
        if (status == QCommentStatus.delivered || status == QCommentStatus.read) && (room.comments.count > 0){
            let loadURL = QiscusConfig.UPDATE_COMMENT_STATUS_URL
            let lastCommentId = room.comments.last!.comments.last!.id
            var parameters:[String : AnyObject] =  [
                "token" : Qiscus.shared.config.USER_TOKEN as AnyObject,
                "room_id" : room.id as AnyObject,
                ]
            
            if status == QCommentStatus.delivered{
                parameters["last_comment_received_id"] = lastCommentId as AnyObject
            }else{
                parameters["last_comment_read_id"] = lastCommentId as AnyObject
            }
            Alamofire.request(loadURL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
                if let response = responseData.result.value {
                    Qiscus.printLog(text: "publish message status result: \(response)")
                    if let participant = QParticipant.participant(inRoomWithId: room.id, andEmail: QiscusMe.sharedInstance.email) {
                        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                        if status == .delivered {
                            try! realm.write {
                                participant.lastDeliveredCommentId = lastCommentId
                            }
                        }else{
                            try! realm.write {
                                participant.lastReadCommentId = lastCommentId
                                participant.lastDeliveredCommentId = lastCommentId
                            }
                        }
                    }
                }else{
                    Qiscus.printLog(text: "error update message status")
                }
            })
        }
    }
    public func postComment(onRoom room:QRoom, comment:QComment){
        var parameters:[String: AnyObject] = [String: AnyObject]()
        
        parameters = [
            "comment"  : comment.text as AnyObject,
            "room_id"   : room.id as AnyObject,
            "topic_id" : room.id as AnyObject,
            "unique_temp_id" : comment.uniqueId as AnyObject,
            "disable_link_preview" : true as AnyObject,
            "token" : Qiscus.shared.config.USER_TOKEN as AnyObject
        ]
        
        if comment.type == .reply && comment.data != ""{
            parameters["type"] = "reply" as AnyObject
            parameters["payload"] = "\(comment.data)" as AnyObject
        }

        Alamofire.request(QiscusConfig.postCommentURL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {response in
            switch response.result {
            case .success:
                if let result = response.result.value {
                    let json = JSON(result)
                    let success = (json["status"].intValue == 200)
                    
                    if success == true {
                        let commentJSON = json["results"]["comment"]
                        let commentId = commentJSON["id"].intValue
                        let commentBeforeId = commentJSON["comment_before_id"].intValue
                        
                        // TODO: - later we use it to move sent comment to last position in the room
                        // let commentCreatedAt = commentJSON["unix_timestamp"].doubleValue
                        
                        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                        try! realm.write {
                            comment.id = commentId
                            comment.beforeId = commentBeforeId
                        }
                        if comment.statusRaw == QCommentStatus.sending.rawValue {
                            room.updateCommentStatus(inComment: comment, status: .sent)
                        }
                    }else{
                        room.updateCommentStatus(inComment: comment, status: .failed)
                    }
                }else{
                    room.updateCommentStatus(inComment: comment, status: .failed)
                }
                break
            case .failure(let error):
                room.updateCommentStatus(inComment: comment, status: .failed)
                Qiscus.printLog(text: "fail to post comment with error: \(error)")
                break
            }
        })
    }
}
