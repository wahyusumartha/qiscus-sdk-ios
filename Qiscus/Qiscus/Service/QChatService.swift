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
    public var delegate:QChatServiceDelegate?
    static var syncTimer:Timer? = nil
    
    // MARK: - reconnect
    private func reconnect(onSuccess:@escaping (()->Void)){
        let email = QiscusMe.sharedInstance.userData.value(forKey: "qiscus_param_email") as? String
        let userKey = QiscusMe.sharedInstance.userData.value(forKey: "qiscus_param_pass") as? String
        let userName = QiscusMe.sharedInstance.userData.value(forKey: "qiscus_param_username") as? String
        let avatarURL = QiscusMe.sharedInstance.userData.value(forKey: "qiscus_param_avatar") as? String
        if email != nil && userKey != nil && userName != nil {
            QiscusCommentClient.sharedInstance.loginOrRegister(email!, password: userKey!, username: userName!, avatarURL: avatarURL, onSuccess: onSuccess)
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
                                }
                            }else if error != JSON.null{
                                self.delegate?.chatService(didFailLoadRoom: "\(error)")
                                DispatchQueue.main.async {
                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                        roomDelegate.didFailLoadRoom(withError: "\(error)")
                                    }
                                }
                            }else{
                                let error = "Failed to load room data"
                                self.delegate?.chatService(didFailLoadRoom: "\(error)")
                                DispatchQueue.main.async {
                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                        roomDelegate.didFailLoadRoom(withError: "\(error)")
                                    }
                                }
                                Qiscus.printLog(text: error)
                            }
                        }else{
                            let error = "Failed to load room data"
                            self.delegate?.chatService(didFailLoadRoom: "\(error)")
                            DispatchQueue.main.async {
                                if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                    roomDelegate.didFailLoadRoom(withError: "\(error)")
                                }
                            }
                            Qiscus.printLog(text: error)
                        }
                    })
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
                                    let room = QRoom.addRoom(fromJSON: roomData)
                                    
                                    for json in commentPayload {
                                        let commentId = json["id"].intValue
                                        if commentId <= QiscusMe.sharedInstance.lastCommentId {
                                            room.saveOldComment(fromJSON: json)
                                        }
                                    }
                                    onSuccess(room)
                                }
                            }else if error != JSON.null{
                                onError("\(error)")
                                DispatchQueue.main.async {
                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                        roomDelegate.didFailLoadRoom(withError: "\(error)")
                                    }
                                }
                            }else{
                                let error = "Failed to load room data"
                                onError("\(error)")
                                DispatchQueue.main.async {
                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                        roomDelegate.didFailLoadRoom(withError: "\(error)")
                                    }
                                }
                                Qiscus.printLog(text: error)
                            }
                        }else{
                            let error = "Failed to load room data"
                            onError("\(error)")
                            DispatchQueue.main.async {
                                if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                    roomDelegate.didFailLoadRoom(withError: "\(error)")
                                }
                            }
                            Qiscus.printLog(text: error)
                        }
                    })
                }
            }
        }else{
            reconnect {
                self.room(withUser: user, distincId: distincId, optionalData: optionalData, withMessage: withMessage)
            }
        }
    }
    //
    public func room(withUniqueId uniqueId:String, title:String, avatarURL:String, onSuccess:@escaping ((_ room: QRoom)->Void),onError:@escaping ((_ error: String)->Void)){ //
        if Qiscus.isLoggedIn{
            if let room = QRoom.room(withUniqueId: uniqueId){
                onSuccess(room)
            }else{
                QiscusRequestThread.async {
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
                                
                                DispatchQueue.main.async {
                                    let room = QRoom.addRoom(fromJSON: roomData)
                                    for json in commentPayload {
                                        let commentId = json["id"].intValue
                                        if commentId <= QiscusMe.sharedInstance.lastCommentId {
                                            room.saveOldComment(fromJSON: json)
                                        }
                                    }
                                    onSuccess(room)
                                    
                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                        roomDelegate.didFinishLoadRoom(onRoom: room)
                                    }
                                }
                            }else if error != JSON.null{
                                onError("\(error)")
                                Qiscus.printLog(text: "\(error)")
                                DispatchQueue.main.async {
                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                        roomDelegate.didFailLoadRoom(withError: "\(error)")
                                    }
                                }
                            }else{
                                let error = "Failed to load room data"
                                onError(error)
                                Qiscus.printLog(text: error)
                                DispatchQueue.main.async {
                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                        roomDelegate.didFailLoadRoom(withError: "\(error)")
                                    }
                                }
                            }
                            
                        }else{
                            let error = "Failed to load room data"
                            onError(error)
                            Qiscus.printLog(text: error)
                            DispatchQueue.main.async {
                                if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                    roomDelegate.didFailLoadRoom(withError: "\(error)")
                                }
                            }
                        }
                    })
                }
            }
        }else{
            reconnect {
                self.room(withUniqueId: uniqueId, title: title, avatarURL: avatarURL, onSuccess: onSuccess, onError: onError)
            }
        }
    }
    public func room(withUniqueId uniqueId:String, title:String, avatarURL:String, withMessage:String? = nil){ //
        
        if Qiscus.isLoggedIn{
            if let room = QRoom.room(withUniqueId: uniqueId){
                self.delegate?.chatService(didFinishLoadRoom: room, withMessage: withMessage)
                if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                    roomDelegate.didFinishLoadRoom(onRoom: room)
                }
            }else{
                QiscusRequestThread.async {
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
                                
                                DispatchQueue.main.async {
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
                                }
                            }else if error != JSON.null{
                                self.delegate?.chatService(didFailLoadRoom: "\(error)")
                                Qiscus.printLog(text: "\(error)")
                                DispatchQueue.main.async {
                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                        roomDelegate.didFailLoadRoom(withError: "\(error)")
                                    }
                                }
                            }else{
                                let error = "Failed to load room data"
                                self.delegate?.chatService(didFailLoadRoom: "\(error)")
                                Qiscus.printLog(text: error)
                                DispatchQueue.main.async {
                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                        roomDelegate.didFailLoadRoom(withError: "\(error)")
                                    }
                                }
                            }
                            
                        }else{
                            let error = "Failed to load room data"
                            self.delegate?.chatService(didFailLoadRoom: "\(error)")
                            Qiscus.printLog(text: error)
                            DispatchQueue.main.async {
                                if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                    roomDelegate.didFailLoadRoom(withError: "\(error)")
                                }
                            }
                        }
                    })
                }
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
                DispatchQueue.main.async {
                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                        roomDelegate.didFinishLoadRoom(onRoom: room)
                    }
                }
            }
            else{
                QiscusRequestThread.async {
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
                                
                                DispatchQueue.main.async {
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
                                }
                            }else if error != JSON.null{
                                self.delegate?.chatService(didFailLoadRoom: "\(error)")
                                Qiscus.printLog(text: "\(error)")
                                DispatchQueue.main.async {
                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                        roomDelegate.didFailLoadRoom(withError: "\(error)")
                                    }
                                }
                            }else{
                                let error = "Failed to load room data"
                                self.delegate?.chatService(didFailLoadRoom: "\(error)")
                                Qiscus.printLog(text: "\(error)")
                                DispatchQueue.main.async {
                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                        roomDelegate.didFailLoadRoom(withError: "\(error)")
                                    }
                                }
                            }
                        }else{
                            let error = "Failed to load room data"
                            self.delegate?.chatService(didFailLoadRoom: "\(error)")
                            Qiscus.printLog(text: error)
                            DispatchQueue.main.async {
                                if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                    roomDelegate.didFailLoadRoom(withError: "\(error)")
                                }
                            }
                        }
                    })
                }
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
                QiscusRequestThread.async {
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
                                
                                DispatchQueue.main.async {
                                    let room = QRoom.addRoom(fromJSON: roomData)
                                    for json in commentPayload {
                                        let commentId = json["id"].intValue
                                        
                                        if commentId <= QiscusMe.sharedInstance.lastCommentId {
                                            room.saveOldComment(fromJSON: json)
                                        }
                                    }
                                    onSuccess(room)
                                }
                            }else if error != JSON.null{
                                DispatchQueue.main.async {
                                    onError("\(error)")
                                }
                                Qiscus.printLog(text: "\(error)")
                            }else{
                                let error = "Failed to load room data"
                                DispatchQueue.main.async {
                                    onError(error)
                                }
                                Qiscus.printLog(text: "\(error)")
                            }
                        }else{
                            let error = "Failed to load room data"
                            DispatchQueue.main.async {
                                onError(error)
                            }
                        }
                    })
                }
            }
        }else{
            self.reconnect {
                self.room(withId: roomId, onSuccess: onSuccess, onError: onError)
            }
        }
    }
    
    @objc private func syncProcess(){
        QiscusRequestThread.async {
            let loadURL = QiscusConfig.SYNC_URL
            let parameters:[String: AnyObject] =  [
                "last_received_comment_id"  : QiscusMe.sharedInstance.lastCommentId as AnyObject,
                "token" : qiscus.config.USER_TOKEN as AnyObject,
                ]
            print("sync url: \(loadURL)")
            print("parameters sync url: \(parameters)")
            Alamofire.request(loadURL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
                print("response data sync: \(responseData)")
                if let response = responseData.result.value {
                    let json = JSON(response)
                    let results = json["results"]
                    let error = json["error"]
                    print("response json sync: \(json)")
                    if results != JSON.null{
                        let comments = json["results"]["comments"].arrayValue
                        if comments.count > 0 {
                            for newComment in comments.reversed() {
                                print("sync result: \(newComment)")
                                let roomId = newComment["room_id"].intValue
                                let id = newComment["id"].intValue
                                let type = newComment["type"].string
                                if id > QiscusMe.sharedInstance.lastCommentId {
                                    DispatchQueue.main.async(execute: { 
                                        if let room = QRoom.room(withId: roomId){
                                            room.saveNewComment(fromJSON: newComment)
                                            if id > QiscusMe.sharedInstance.lastCommentId{
                                                if type == "system_event" {
                                                    room.sync()
                                                }
                                            }
                                        }else{
                                            if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                                                let comment = QComment.tempComment(fromJSON: newComment)
                                                roomDelegate.gotNewComment(comment)
                                            }
                                        }
                                    })
                                    QiscusMe.updateLastCommentId(commentId: id)
                                }
                            }
                        }
                    }else if error != JSON.null{
                        Qiscus.printLog(text: "error sync message: \(error)")
                    }
                }
                else{
                    Qiscus.printLog(text: "error sync message")
                    
                }
            })
        }
    }
    // MARK syncMethod
    public func sync(){
        if QChatService.syncTimer != nil {
            QChatService.syncTimer?.invalidate()
        }
        QChatService.syncTimer = Timer.scheduledTimer(timeInterval:1.0, target: self, selector: #selector(self.syncProcess), userInfo: nil, repeats: false)
    }
    public func createRoom(withUsers users:[String], roomName:String, optionalData:String? = nil, withMessage:String? = nil){ //
        
        if Qiscus.isLoggedIn{
            QiscusRequestThread.async {
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
                            
                            DispatchQueue.main.async {
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
                            }
                        }else if error != JSON.null{
                            self.delegate?.chatService(didFailLoadRoom: "\(error)")
                            Qiscus.printLog(text: "\(error)")
                            DispatchQueue.main.async {
                                if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                    roomDelegate.didFailLoadRoom(withError: "\(error)")
                                }
                            }
                        }else{
                            let error = "Failed to load room data"
                            self.delegate?.chatService(didFailLoadRoom: "\(error)")
                            Qiscus.printLog(text: "\(error)")
                            DispatchQueue.main.async {
                                if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                    roomDelegate.didFailLoadRoom(withError: "\(error)")
                                }
                            }
                        }
                    }else{
                        let error = "Failed to load room data"
                        self.delegate?.chatService(didFailLoadRoom: "\(error)")
                        Qiscus.printLog(text: "\(error)")
                        DispatchQueue.main.async {
                            if let roomDelegate = QiscusCommentClient.shared.roomDelegate{
                                roomDelegate.didFailLoadRoom(withError: "\(error)")
                            }
                        }
                    }
                })
            }
        }
        else{
            reconnect {
                self.createRoom(withUsers: users, roomName: roomName, optionalData: optionalData, withMessage: withMessage)
            }
        }
    }
}
