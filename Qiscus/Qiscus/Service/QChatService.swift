//
//  QService.swift
//  Example
//
//  Created by Ahmad Athaullah on 7/6/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

@objc public protocol QChatServiceDelegate {
    func chatService(didFinishLoadRoom inRoom:QRoom, withMessage message:String?)
    func chatService(didFailLoadRoom error:String)
}
public class QChatService:NSObject {
    static var defaultService = QChatService()
    public var delegate:QChatServiceDelegate?
    static var syncTimer:Timer? = nil
    
    // MARK: - reconnect
    private func reconnect(onSuccess:@escaping (()->Void)){
        let email = QiscusMe.sharedInstance.userData.value(forKey: "qiscus_param_email") as? String
        let userKey = QiscusMe.sharedInstance.userData.value(forKey: "qiscus_param_pass") as? String
        let userName = QiscusMe.sharedInstance.userData.value(forKey: "qiscus_param_username") as? String
        let avatarURL = QiscusMe.sharedInstance.userData.value(forKey: "qiscus_param_avatar") as? String
        if email != nil && userKey != nil && userName != nil {
            QiscusCommentClient.sharedInstance.loginOrRegister(email!, password: userKey!, username: userName!, avatarURL: avatarURL, reconnect: true, onSuccess: onSuccess)
        }
    }
    
    // MARK : - room getter method
    public func room(withUser user:String, distincId:String? = nil, optionalData:String? = nil, withMessage:String? = nil){ //
        if Qiscus.isLoggedIn{
            if let room = QRoom.room(withUser: user){
                self.delegate?.chatService(didFinishLoadRoom: room, withMessage: withMessage)
                if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                    roomDelegate.didFinishLoadRoom(onRoom: room)
                }
            }
            else{
                QiscusRequestThread.async {
                    autoreleasepool{
                    let loadURL = QiscusConfig.ROOM_REQUEST_URL
                    
                    var parameters:[String : AnyObject] =  [
                        "emails" : [user] as AnyObject,
                        "token"  : qiscus.config.USER_TOKEN as AnyObject
                    ]
                    if distincId != nil{
                        if distincId != "" {
                            parameters["distinct_id"] = distincId! as AnyObject
                        }
                    }
                    if optionalData != nil{
                        parameters["options"] = optionalData! as AnyObject
                    }
                    Qiscus.printLog(text: "get or create room parameters: \(parameters)")
                    Alamofire.request(loadURL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
                        if let response = responseData.result.value {
                            Qiscus.printLog(text: "get or create room api response:\n\(response)")
                            let json = JSON(response)
                            let results = json["results"]
                            let error = json["error"]
                            
                            if results != JSON.null{
                                Qiscus.printLog(text: "getListComment with id response: \(responseData)")
                                let roomData = results["room"]
                                let commentPayload = results["comments"].arrayValue
                                DispatchQueue.main.async {
                                    autoreleasepool{
                                    let room = QRoom.addRoom(fromJSON: roomData)
                                    for json in commentPayload {
                                        let commentId = json["id"].intValue
                                        if commentId <= QiscusMe.sharedInstance.lastCommentId {
                                            room.saveOldComment(fromJSON: json)
                                        }else{
                                            QiscusBackgroundThread.async {
                                                autoreleasepool{
                                                    QChatService.sync()
                                                }
                                            }
                                        }
                                    }
                                    self.delegate?.chatService(didFinishLoadRoom: room, withMessage: withMessage)
                                    
                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                                        roomDelegate.didFinishLoadRoom(onRoom: room)
                                    }
                                    }
                                }
                            }else if error != JSON.null{
                                self.delegate?.chatService(didFailLoadRoom: "\(error)")
                                DispatchQueue.main.async {
                                    autoreleasepool{
                                        if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                            roomDelegate.didFailLoadRoom(withError: "\(error)")
                                        }
                                    }
                                }
                            }else{
                                let error = "Failed to load room data"
                                self.delegate?.chatService(didFailLoadRoom: "\(error)")
                                DispatchQueue.main.async {
                                    autoreleasepool{
                                        if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                            roomDelegate.didFailLoadRoom(withError: "\(error)")
                                        }
                                    }
                                }
                                Qiscus.printLog(text: error)
                            }
                        }else{
                            let error = "Failed to load room data"
                            self.delegate?.chatService(didFailLoadRoom: "\(error)")
                            DispatchQueue.main.async {
                                autoreleasepool{
                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                        roomDelegate.didFailLoadRoom(withError: "\(error)")
                                    }
                                }
                            }
                            Qiscus.printLog(text: error)
                        }
                    })
                    }
                }
            }
        }else{
            reconnect {
                self.room(withUser: user, distincId: distincId, optionalData: optionalData, withMessage: withMessage)
            }
        }
    }
    public func room(withUser user:String, distincId:String? = nil, optionalData:String? = nil, withMessage:String? = nil, onSuccess:@escaping ((_ room: QRoom)->Void),onError:@escaping ((_ error: String)->Void)){ //
        if Qiscus.isLoggedIn{
            if let room = QRoom.room(withUser: user){
                onSuccess(room)
            }
            else{
                QiscusRequestThread.async {
                    autoreleasepool{
                    let loadURL = QiscusConfig.ROOM_REQUEST_URL
                    
                    var parameters:[String : AnyObject] =  [
                        "emails" : [user] as AnyObject,
                        "token"  : qiscus.config.USER_TOKEN as AnyObject
                    ]
                    if distincId != nil{
                        if distincId != "" {
                            parameters["distinct_id"] = distincId! as AnyObject
                        }
                    }
                    if optionalData != nil{
                        parameters["options"] = optionalData! as AnyObject
                    }
                    Qiscus.printLog(text: "get or create room parameters: \(parameters)")
                    Alamofire.request(loadURL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
                        if let response = responseData.result.value {
                            Qiscus.printLog(text: "get or create room api response:\n\(response)")
                            let json = JSON(response)
                            let results = json["results"]
                            let error = json["error"]
                            
                            if results != JSON.null{
                                Qiscus.printLog(text: "getListComment with id response: \(responseData)")
                                let roomData = results["room"]
                                let commentPayload = results["comments"].arrayValue
                                
                                DispatchQueue.main.async {
                                    autoreleasepool{
                                    let room = QRoom.addRoom(fromJSON: roomData)
                                    
                                    for json in commentPayload {
                                        let commentId = json["id"].intValue
                                        if commentId <= QiscusMe.sharedInstance.lastCommentId {
                                            room.saveOldComment(fromJSON: json)
                                        }else{
                                            QiscusBackgroundThread.async { autoreleasepool{
                                                QChatService.sync()
                                            }}
                                        }
                                    }
                                    onSuccess(room)
                                    }
                                }
                            }else if error != JSON.null{
                                onError("\(error)")
                                DispatchQueue.main.async { autoreleasepool{
                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                        roomDelegate.didFailLoadRoom(withError: "\(error)")
                                    }
                                }}
                            }else{
                                let error = "Failed to load room data"
                                onError("\(error)")
                                DispatchQueue.main.async { autoreleasepool{
                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                        roomDelegate.didFailLoadRoom(withError: "\(error)")
                                    }
                                }}
                                Qiscus.printLog(text: error)
                            }
                        }else{
                            let error = "Failed to load room data"
                            onError("\(error)")
                            DispatchQueue.main.async { autoreleasepool{
                                if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                    roomDelegate.didFailLoadRoom(withError: "\(error)")
                                }
                            }}
                            Qiscus.printLog(text: error)
                        }
                    })
                    }
                }
            }
        }else{
            reconnect {
                self.room(withUser: user, distincId: distincId, optionalData: optionalData, withMessage: withMessage)
            }
        }
    }
    //
    public func room(withUniqueId uniqueId:String, title:String = "", avatarURL:String = "", onSuccess:@escaping ((_ room: QRoom)->Void),onError:@escaping ((_ error: String)->Void)){ //
        if Qiscus.isLoggedIn{
            if let room = QRoom.room(withUniqueId: uniqueId){
                onSuccess(room)
            }else{
                QiscusRequestThread.async { autoreleasepool{
                    let loadURL = QiscusConfig.ROOM_UNIQUEID_URL
                    
                    var parameters:[String : AnyObject] =  [
                        "token"  : qiscus.config.USER_TOKEN as AnyObject,
                        "unique_id" : uniqueId as AnyObject
                    ]
                    if title != ""{
                        parameters["name"] = title as AnyObject
                    }
                    if avatarURL != ""{
                        parameters["avatar_url"] = avatarURL as AnyObject
                    }
                    Qiscus.printLog(text: "get or create room with uniqueId parameters: \(parameters)")
                    Alamofire.request(loadURL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
                        if let response = responseData.result.value {
                            Qiscus.printLog(text: "get or create room with uniqueId response:\n\(response)")
                            let json = JSON(response)
                            let results = json["results"]
                            let error = json["error"]
                            
                            if results != JSON.null{
                                Qiscus.printLog(text: "getListComment with id response: \(responseData)")
                                let roomData = results["room"]
                                let commentPayload = results["comments"].arrayValue
                                
                                DispatchQueue.main.async { autoreleasepool{
                                    let room = QRoom.addRoom(fromJSON: roomData)
                                    for json in commentPayload {
                                        let commentId = json["id"].intValue
                                        if commentId <= QiscusMe.sharedInstance.lastCommentId {
                                            room.saveOldComment(fromJSON: json)
                                        }else{
                                            QiscusBackgroundThread.async { autoreleasepool{
                                                QChatService.sync()
                                            }}
                                        }
                                    }
                                    onSuccess(room)
                                    
                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                        roomDelegate.didFinishLoadRoom(onRoom: room)
                                    }
                                }}
                            }else if error != JSON.null{
                                onError("\(error)")
                                Qiscus.printLog(text: "\(error)")
                                DispatchQueue.main.async { autoreleasepool{
                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                        roomDelegate.didFailLoadRoom(withError: "\(error)")
                                    }
                                }}
                            }else{
                                let error = "Failed to load room data"
                                onError(error)
                                Qiscus.printLog(text: error)
                                DispatchQueue.main.async { autoreleasepool{
                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                        roomDelegate.didFailLoadRoom(withError: "\(error)")
                                    }
                                }}
                            }
                            
                        }else{
                            let error = "Failed to load room data"
                            onError(error)
                            Qiscus.printLog(text: error)
                            DispatchQueue.main.async { autoreleasepool{
                                if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                    roomDelegate.didFailLoadRoom(withError: "\(error)")
                                }
                            }}
                        }
                    })
                }}
            }
        }else{
            reconnect {
                self.room(withUniqueId: uniqueId, title: title, avatarURL: avatarURL, onSuccess: onSuccess, onError: onError)
            }
        }
    }
    public func room(withUniqueId uniqueId:String, title:String = "", avatarURL:String = "", withMessage:String? = nil){ //
        
        if Qiscus.isLoggedIn{
            if let room = QRoom.room(withUniqueId: uniqueId){
                self.delegate?.chatService(didFinishLoadRoom: room, withMessage: withMessage)
                if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                    roomDelegate.didFinishLoadRoom(onRoom: room)
                }
            }else{
                QiscusRequestThread.async { autoreleasepool{
                    let loadURL = QiscusConfig.ROOM_UNIQUEID_URL
                    
                    var parameters:[String : AnyObject] =  [
                        "token"  : qiscus.config.USER_TOKEN as AnyObject,
                        "unique_id" : uniqueId as AnyObject
                    ]
                    if title != ""{
                        parameters["name"] = title as AnyObject
                    }
                    if avatarURL != ""{
                        parameters["avatar_url"] = avatarURL as AnyObject
                    }
                    Qiscus.printLog(text: "get or create room with uniqueId parameters: \(parameters)")
                    Alamofire.request(loadURL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
                        if let response = responseData.result.value {
                            Qiscus.printLog(text: "get or create room with uniqueId response:\n\(response)")
                            let json = JSON(response)
                            let results = json["results"]
                            let error = json["error"]
                            
                            if results != JSON.null{
                                Qiscus.printLog(text: "getListComment with id response: \(responseData)")
                                let roomData = results["room"]
                                let commentPayload = results["comments"].arrayValue
                                
                                DispatchQueue.main.async { autoreleasepool{
                                    let room = QRoom.addRoom(fromJSON: roomData)
                                    for json in commentPayload {
                                        let commentId = json["id"].intValue
                                        if commentId <= QiscusMe.sharedInstance.lastCommentId {
                                            room.saveOldComment(fromJSON: json)
                                        }else{
                                            QiscusBackgroundThread.async { autoreleasepool{
                                                QChatService.sync()
                                            }}
                                        }
                                    }
                                    self.delegate?.chatService(didFinishLoadRoom: room, withMessage: withMessage)
                                    
                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                                        roomDelegate.didFinishLoadRoom(onRoom: room)
                                    }
                                }}
                            }else if error != JSON.null{
                                self.delegate?.chatService(didFailLoadRoom: "\(error)")
                                Qiscus.printLog(text: "\(error)")
                                DispatchQueue.main.async { autoreleasepool{
                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                        roomDelegate.didFailLoadRoom(withError: "\(error)")
                                    }
                                }}
                            }else{
                                let error = "Failed to load room data"
                                self.delegate?.chatService(didFailLoadRoom: "\(error)")
                                Qiscus.printLog(text: error)
                                DispatchQueue.main.async { autoreleasepool{
                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                        roomDelegate.didFailLoadRoom(withError: "\(error)")
                                    }
                                }}
                            }
                            
                        }else{
                            let error = "Failed to load room data"
                            self.delegate?.chatService(didFailLoadRoom: "\(error)")
                            Qiscus.printLog(text: error)
                            DispatchQueue.main.async { autoreleasepool{
                                if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                    roomDelegate.didFailLoadRoom(withError: "\(error)")
                                }
                            }}
                        }
                    })
                }}
            }
        }else{
            reconnect {
                self.room(withUniqueId: uniqueId, title: title, avatarURL: avatarURL, withMessage: withMessage)
            }
        }
    }
    public func room(withId roomId:Int, withMessage:String? = nil){
        if Qiscus.isLoggedIn {
            if let room = QRoom.room(withId: roomId){
                self.delegate?.chatService(didFinishLoadRoom: room, withMessage: withMessage)
                DispatchQueue.main.async { autoreleasepool{
                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                        roomDelegate.didFinishLoadRoom(onRoom: room)
                    }
                }}
            }
            else{
                QiscusRequestThread.async { autoreleasepool{
                    let loadURL = QiscusConfig.ROOM_REQUEST_ID_URL
                    let parameters:[String : AnyObject] =  [
                        "id" : roomId as AnyObject,
                        "token"  : qiscus.config.USER_TOKEN as AnyObject
                    ]
                    Alamofire.request(loadURL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
                        if let response = responseData.result.value {
                            let json = JSON(response)
                            let results = json["results"]
                            let error = json["error"]
                            
                            if results != JSON.null{
                                Qiscus.printLog(text: "getListComment with id response: \(responseData)")
                                let roomData = results["room"]
                                let commentPayload = results["comments"].arrayValue
                                
                                DispatchQueue.main.async { autoreleasepool{
                                    let room = QRoom.addRoom(fromJSON: roomData)
                                    for json in commentPayload {
                                        let commentId = json["id"].intValue
                                        
                                        if commentId <= QiscusMe.sharedInstance.lastCommentId {
                                            room.saveOldComment(fromJSON: json)
                                        }else{
                                            QiscusBackgroundThread.async { autoreleasepool{
                                                QChatService.sync()
                                            }}
                                        }
                                    }
                                    self.delegate?.chatService(didFinishLoadRoom: room, withMessage: withMessage)
                                    
                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                                        roomDelegate.didFinishLoadRoom(onRoom: room)
                                    }
                                }}
                            }else if error != JSON.null{
                                self.delegate?.chatService(didFailLoadRoom: "\(error)")
                                Qiscus.printLog(text: "\(error)")
                                DispatchQueue.main.async { autoreleasepool{
                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                        roomDelegate.didFailLoadRoom(withError: "\(error)")
                                    }
                                }}
                            }else{
                                let error = "Failed to load room data"
                                self.delegate?.chatService(didFailLoadRoom: "\(error)")
                                Qiscus.printLog(text: "\(error)")
                                DispatchQueue.main.async { autoreleasepool{
                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                        roomDelegate.didFailLoadRoom(withError: "\(error)")
                                    }
                                }}
                            }
                        }else{
                            let error = "Failed to load room data"
                            self.delegate?.chatService(didFailLoadRoom: "\(error)")
                            Qiscus.printLog(text: error)
                            DispatchQueue.main.async { autoreleasepool{
                                if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                    roomDelegate.didFailLoadRoom(withError: "\(error)")
                                }
                            }}
                        }
                    })
                }}
            }
        }else{
            self.reconnect {
                self.room(withId: roomId, withMessage: withMessage)
            }
        }
    }
    public func room(withId roomId:Int, onSuccess:@escaping ((_ room: QRoom)->Void),onError:@escaping ((_ error: String)->Void)){
        if Qiscus.isLoggedIn {
            if let room = QRoom.room(withId: roomId){
                onSuccess(room)
            }
            else{
                QiscusRequestThread.async { autoreleasepool{
                    let loadURL = QiscusConfig.ROOM_REQUEST_ID_URL
                    let parameters:[String : AnyObject] =  [
                        "id" : roomId as AnyObject,
                        "token"  : qiscus.config.USER_TOKEN as AnyObject
                    ]
                    Alamofire.request(loadURL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
                        if let response = responseData.result.value {
                            let json = JSON(response)
                            let results = json["results"]
                            let error = json["error"]
                            
                            if results != JSON.null{
                                Qiscus.printLog(text: "getListComment with id response: \(responseData)")
                                let roomData = results["room"]
                                let commentPayload = results["comments"].arrayValue
                                
                                DispatchQueue.main.async { autoreleasepool{
                                    let room = QRoom.addRoom(fromJSON: roomData)
                                    for json in commentPayload {
                                        let commentId = json["id"].intValue
                                        
                                        if commentId <= QiscusMe.sharedInstance.lastCommentId {
                                            room.saveOldComment(fromJSON: json)
                                        }else{
                                            QiscusBackgroundThread.async { autoreleasepool{
                                                QChatService.sync()
                                            }}
                                        }
                                    }
                                    onSuccess(room)
                                }}
                            }else if error != JSON.null{
                                DispatchQueue.main.async { autoreleasepool{
                                    onError("\(error)")
                                }}
                                Qiscus.printLog(text: "\(error)")
                            }else{
                                let error = "Failed to load room data"
                                DispatchQueue.main.async { autoreleasepool{
                                    onError(error)
                                }}
                                Qiscus.printLog(text: "\(error)")
                            }
                        }else{
                            let error = "Failed to load room data"
                            DispatchQueue.main.async { autoreleasepool{
                                onError(error)
                            }}
                        }
                    })
                }}
            }
        }else{
            self.reconnect {
                self.room(withId: roomId, onSuccess: onSuccess, onError: onError)
            }
        }
    }
    
    @objc private func syncProcess(){
        QiscusRequestThread.async { autoreleasepool{
            let loadURL = QiscusConfig.SYNC_URL
            let parameters:[String: AnyObject] =  [
                "last_received_comment_id"  : QiscusMe.sharedInstance.lastCommentId as AnyObject,
                "token" : qiscus.config.USER_TOKEN as AnyObject,
                "order" : "asc" as AnyObject
                ]
            Alamofire.request(loadURL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
                if let response = responseData.result.value {
                    let json = JSON(response)
                    let results = json["results"]
                    let error = json["error"]
                    if results != JSON.null{
                        let comments = json["results"]["comments"].arrayValue
                        if comments.count > 0 {
                            for newComment in comments.reversed() {
                                let roomId = newComment["room_id"].intValue
                                let id = newComment["id"].intValue
                                let type = newComment["type"].string
                                if id > QiscusMe.sharedInstance.lastCommentId {
                                    DispatchQueue.main.async { autoreleasepool{
                                        if let room = QRoom.room(withId: roomId){
                                            if !room.isInvalidated {
                                                room.saveNewComment(fromJSON: newComment)
                                                if id > QiscusMe.sharedInstance.lastCommentId{
                                                    if type == "system_event" {
                                                        room.sync()
                                                    }
                                                }
                                            }
                                        }else{
                                            QiscusBackgroundThread.async { autoreleasepool{
                                                if id > QiscusMe.sharedInstance.lastKnownCommentId {
                                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                                                        DispatchQueue.main.async { autoreleasepool{
                                                            let comment = QComment.tempComment(fromJSON: newComment)
                                                            roomDelegate.gotNewComment(comment)
                                                        }}
                                                        
                                                        QiscusMe.updateLastKnownCommentId(commentId: id)
                                                    }
                                                }
                                            }}
                                        }
                                    }}
                                }
                            }
                        }
                        if comments.count == 20 {
                            self.syncProcess()
                        }
                    }else if error != JSON.null{
                        Qiscus.printLog(text: "error sync message: \(error)")
                    }
                }
                else{
                    Qiscus.printLog(text: "error sync message")
                    
                }
            })
        }}
    }
    // MARK syncMethod
    private func sync(){
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector( self.syncProcess), object: nil)
        self.perform(#selector(self.syncProcess), with: nil, afterDelay: 1.0)
    }
    internal class func sync(){
        DispatchQueue.main.async { autoreleasepool{
            QChatService.defaultService.sync()
        }}
    }
    public func createRoom(withUsers users:[String], roomName:String, optionalData:String? = nil, withMessage:String? = nil){ //
        if Qiscus.isLoggedIn{
            QiscusRequestThread.async {autoreleasepool{
                let loadURL = QiscusConfig.CREATE_NEW_ROOM
                
                var parameters:[String : AnyObject] =  [
                    "name" : roomName as AnyObject,
                    "participants" : users as AnyObject,
                    "token"  : qiscus.config.USER_TOKEN as AnyObject
                ]
                
                if optionalData != nil{
                    parameters["options"] = optionalData! as AnyObject
                }
                Qiscus.printLog(text: "create new room parameters: \(parameters)")
                Alamofire.request(loadURL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
                    if let response = responseData.result.value {
                        Qiscus.printLog(text: "create group room api response:\n\(response)")
                        let json = JSON(response)
                        let results = json["results"]
                        let error = json["error"]
                        
                        if results != JSON.null{
                            Qiscus.printLog(text: "getListComment with id response: \(responseData)")
                            let roomData = results["room"]
                            let commentPayload = results["comments"].arrayValue
                            
                            DispatchQueue.main.async { autoreleasepool{
                                let room = QRoom.addRoom(fromJSON: roomData)
                                for json in commentPayload {
                                    let commentId = json["id"].intValue
                                    
                                    if commentId <= QiscusMe.sharedInstance.lastCommentId {
                                        room.saveOldComment(fromJSON: json)
                                    }
                                }
                                self.delegate?.chatService(didFinishLoadRoom: room, withMessage: withMessage)
                                
                                if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                                    roomDelegate.didFinishLoadRoom(onRoom: room)
                                }
                            }}
                        }else if error != JSON.null{
                            self.delegate?.chatService(didFailLoadRoom: "\(error)")
                            Qiscus.printLog(text: "\(error)")
                            DispatchQueue.main.async { autoreleasepool{
                                if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                    roomDelegate.didFailLoadRoom(withError: "\(error)")
                                }
                            }}
                        }else{
                            let error = "Failed to load room data"
                            self.delegate?.chatService(didFailLoadRoom: "\(error)")
                            Qiscus.printLog(text: "\(error)")
                            DispatchQueue.main.async { autoreleasepool{
                                if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                    roomDelegate.didFailLoadRoom(withError: "\(error)")
                                }
                            }}
                        }
                    }else{
                        let error = "Failed to load room data"
                        self.delegate?.chatService(didFailLoadRoom: "\(error)")
                        Qiscus.printLog(text: "\(error)")
                        DispatchQueue.main.async { autoreleasepool{
                            if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                roomDelegate.didFailLoadRoom(withError: "\(error)")
                            }
                        }}
                    }
                })
            }}
        }
        else{
            reconnect {
                self.createRoom(withUsers: users, roomName: roomName, optionalData: optionalData, withMessage: withMessage)
            }
        }
    }
    
    internal class func registerDevice(withToken deviceToken: String){
        func register(){
            let parameters:[String: AnyObject] = [
                "token"  : qiscus.config.USER_TOKEN as AnyObject,
                "device_token" : deviceToken as AnyObject,
                "device_platform" : "ios" as AnyObject
            ]
            
            Qiscus.printLog(text: "registerDevice url: \(QiscusConfig.SET_DEVICE_TOKEN_URL)")
            Qiscus.printLog(text: "post parameters: \(parameters)")
            
            Alamofire.request(QiscusConfig.SET_DEVICE_TOKEN_URL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: { response in
                Qiscus.printLog(text: "registerDevice result: \(response)")
                Qiscus.printLog(text: "registerDevice url: \(QiscusConfig.LOGIN_REGISTER)")
                Qiscus.printLog(text: "registerDevice parameters: \(parameters)")
                Qiscus.printLog(text: "registerDevice headers: \(QiscusConfig.sharedInstance.requestHeader)")
                switch response.result {
                case .success:
                    DispatchQueue.main.async(execute: {
                        if let result = response.result.value{
                            let json = JSON(result)
                            let success:Bool = (json["status"].intValue == 200)
                            
                            if success {
                                let pnData = json["results"]
                                let configured = pnData["pn_ios_configured"].boolValue
                                if configured {
                                    if let delegate = Qiscus.shared.delegate {
                                        delegate.qiscus?(didRegisterPushNotification: true, deviceToken: deviceToken, error: nil)
                                    }
                                }else{
                                    if let delegate = Qiscus.shared.delegate  {
                                        delegate.qiscus?(didRegisterPushNotification: false, deviceToken: deviceToken, error: "failed to register deviceToken : pushNotification not configured")
                                    }
                                }
                            }else{
                                if let delegate = Qiscus.shared.delegate {
                                    delegate.qiscus?(didRegisterPushNotification: false, deviceToken: deviceToken, error: "unsuccessful register deviceToken")
                                }
                            }
                        }else{
                            if let delegate = Qiscus.shared.delegate {
                                delegate.qiscus?(didRegisterPushNotification: false, deviceToken: deviceToken, error: "unsuccessful register deviceToken")
                            }
                        }
                    })
                    break
                case .failure(let error):
                    if let delegate = Qiscus.shared.delegate {
                        delegate.qiscus?(didRegisterPushNotification: false, deviceToken: deviceToken, error: "unsuccessful register deviceToken: \(error)")
                    }
                    break
                }
            })
        }
        if Qiscus.isLoggedIn {
            register()
        }else{
            QChatService.defaultService.reconnect {
                register()
            }
        }
        
    }
}
