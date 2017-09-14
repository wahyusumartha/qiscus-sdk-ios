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
    
    internal class func updateProfil(userName: String? = nil, userAvatarURL: String? = nil, onSuccess: @escaping (()->Void),onError:@escaping ((String)->Void)){
        if Qiscus.isLoggedIn {
            var parameters:[String: AnyObject] = [String: AnyObject]()
            let email = QiscusMe.sharedInstance.userData.value(forKey: "qiscus_param_email") as? String
            let userKey = QiscusMe.sharedInstance.userData.value(forKey: "qiscus_param_pass") as? String
            let currentName = QiscusMe.sharedInstance.userData.value(forKey: "qiscus_param_username") as? String
            let currentAvatarURL = QiscusMe.sharedInstance.userData.value(forKey: "qiscus_param_avatar") as? String
            
            parameters = [
                "email"  : email as AnyObject,
                "password" : userKey as AnyObject,
            ]
            var noChange = true
            if let name = userName{
                if name != currentName {
                    parameters["username"] = name as AnyObject?
                    noChange = false
                }
            }
            if let avatar =  userAvatarURL{
                if avatar != currentAvatarURL {
                    parameters["avatar_url"] = avatar as AnyObject?
                    noChange = false
                }
            }
            
            if noChange {
                onError("no change")
            }else{
                DispatchQueue.global().async(execute: {
                    Alamofire.request(QiscusConfig.LOGIN_REGISTER, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: { response in
                        switch response.result {
                        case .success:
                            if let result = response.result.value{
                                let json = JSON(result)
                                let success:Bool = (json["status"].intValue == 200)
                                
                                if success {
                                    let userData = json["results"]["user"]
                                    let _ = QiscusMe.saveData(fromJson: userData, reconnect: true)
                                    Qiscus.setupReachability()
                                    if let delegate = Qiscus.shared.delegate {
                                        Qiscus.uiThread.async { autoreleasepool{
                                            delegate.qiscus?(didConnect: true, error: nil)
                                            delegate.qiscusConnected?()
                                            }}
                                    }
                                    Qiscus.registerNotification()
                                    Qiscus.uiThread.async { autoreleasepool{
                                        onSuccess()
                                    }}
                                }else{
                                    Qiscus.uiThread.async { autoreleasepool{
                                        onError(json["message"].stringValue)
                                    }}
                                }
                            }else{
                                if let delegate = Qiscus.shared.delegate {
                                    Qiscus.uiThread.async { autoreleasepool{
                                        let error = "Cant get data from qiscus server"
                                        onError(error)
                                    }}
                                }
                            }
                            break
                        case .failure(let error):
                            if let delegate = Qiscus.shared.delegate {
                                Qiscus.uiThread.async {autoreleasepool{
                                    onError("\(error)")
                                }}
                            }
                            break
                        }
                    })
                })
            }
        }else{
            onError("Not logged in to Qiscus")
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
            var needToLoad = true
            if let room = QRoom.room(withId: roomId){
                if room.comments.count > 0 {
                    needToLoad = false
                }
            }
            if !needToLoad {
                let room = QRoom.room(withId: roomId)!
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
            var needToLoad = true
            if let room = QRoom.room(withId: roomId){
                if room.comments.count > 0 {
                    needToLoad = false
                }
            }
            if !needToLoad {
                onSuccess(QRoom.room(withId: roomId)!)
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
    
    @objc private func syncProcess(first:Bool = true){
        QiscusRequestThread.async {
            let loadURL = QiscusConfig.SYNC_URL
            let parameters:[String: AnyObject] =  [
                "last_received_comment_id"  : QiscusMe.sharedInstance.lastCommentId as AnyObject,
                "token" : qiscus.config.USER_TOKEN as AnyObject,
                "order" : "asc" as AnyObject
                ]
            print("paremeters sync: \(parameters)")
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
                                    QiscusMe.updateLastCommentId(commentId: id)
                                    DispatchQueue.main.async { autoreleasepool{
                                        if let room = QRoom.room(withId: roomId){
                                            if !room.isInvalidated {
                                                if room.commentsGroupCount > 0 {
                                                    room.saveNewComment(fromJSON: newComment)
                                                    if id > QiscusMe.sharedInstance.lastCommentId{
                                                        if type == "system_event" {
                                                            room.sync()
                                                        }
                                                    }
                                                }else{
                                                    let commentTemp = QComment.tempComment(fromJSON: newComment)
                                                    room.updateLastComentInfo(comment: commentTemp)
                                                    if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                                                        DispatchQueue.main.async { autoreleasepool{
                                                            let comment = QComment.tempComment(fromJSON: newComment)
                                                            roomDelegate.gotNewComment(comment)
                                                        }}
                                                    }
                                                }
                                            }
                                        }else{
                                            QiscusBackgroundThread.async { autoreleasepool{
                                                if let roomDelegate = QiscusCommentClient.shared.roomDelegate {
                                                    DispatchQueue.main.async { autoreleasepool{
                                                        let comment = QComment.tempComment(fromJSON: newComment)
                                                        roomDelegate.gotNewComment(comment)
                                                    }}
                                                }
                                            }}
                                            let comment = QComment.tempComment(fromJSON: newComment)
                                            QChatService.roomInfo(withId: comment.roomId, onSuccess: { (room) in
                                                Qiscus.chatDelegate?.qiscusChat?(gotNewRoom: room)
                                            }, onFailed: { (error) in
                                                print("error getting room info")
                                            })
                                        }
                                    }}
                                }
                            }
                        }
                        if comments.count == 20 {
                            self.sync(first: false)
                        }else{
                            Qiscus.printLog(text: "finish syncing process.")
                            if !Qiscus.realtimeConnected {
                                Qiscus.mqttConnect()
                            }else{
                                if Qiscus.shared.syncTimer != nil {
                                    Qiscus.shared.syncTimer?.invalidate()
                                    Qiscus.shared.syncTimer = nil
                                }
                            }
                            Qiscus.shared.delegate?.qiscus?(finishSync: true, error: nil)
                        }
                    }else if error != JSON.null{
                        Qiscus.printLog(text: "error sync message: \(error)")
                        Qiscus.shared.delegate?.qiscus?(finishSync: false, error: "\(error)")
                    }
                }
                else{
                    Qiscus.shared.delegate?.qiscus?(finishSync: false, error: "error sync message")
                    Qiscus.printLog(text: "error sync message")
                }
            })
        }
    }
    // MARK syncMethod
    private func sync(first:Bool = true){
        if first {
            Qiscus.printLog(text: "start syncing process...")
            Qiscus.shared.delegate?.qiscusStartSyncing?()
        }
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector( self.syncProcess), object: nil)
        self.perform(#selector(self.syncProcess), with: nil, afterDelay: 1.0)
    }
    internal class func sync(){
        DispatchQueue.main.async {
            QChatService.defaultService.sync()
        }
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
    internal class func getNonce(withAppId appId:String, onSuccess:@escaping ((String)->Void), onFailed:@escaping ((String)->Void), secureURL:Bool = true){
        QiscusRequestThread.async { autoreleasepool{
            var requestProtocol = "https"
            if !secureURL {
                requestProtocol = "http"
            }
            let baseUrl = "\(requestProtocol)://\(appId).qiscus.com/api/v2/mobile"
            let authURL = "\(baseUrl)/auth/nonce"
            QiscusMe.sharedInstance.baseUrl = baseUrl
            QiscusMe.sharedInstance.userData.set(baseUrl, forKey: "qiscus_base_url")
            
            Alamofire.request(authURL, method: .post, parameters: nil, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: { response in
                
                switch response.result {
                case .success:
                    if let result = response.result.value{
                        let json = JSON(result)
                        let success:Bool = (json["status"].intValue == 200)
                        
                        if success {
                            let resultData = json["results"]
                            let nonce = resultData["nonce"].stringValue
                            DispatchQueue.main.async {
                                onSuccess(nonce)
                            }
                        }else{
                            DispatchQueue.main.async {
                                onSuccess("Cant get nonce from server")
                            }
                        }
                    }else{
                        DispatchQueue.main.async {
                            onSuccess("Cant get nonce from server")
                        }
                    }
                    break
                case .failure(let error):
                    DispatchQueue.main.async {
                        onSuccess("\(error)")
                    }
                    break
                }
            })
        }}
    }
    internal class func setup(withuserIdentityToken uidToken:String){
        QiscusRequestThread.async { autoreleasepool{
            
            let authURL = "\(QiscusConfig.sharedInstance.BASE_URL)/auth/verify_identity_token"
            let parameters:[String: AnyObject] = [
                "identity_token"  : uidToken as AnyObject
            ]
            
            Alamofire.request(authURL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: { response in
                
                switch response.result {
                case .success:
                    if let result = response.result.value{
                        let json = JSON(result)
                        let success:Bool = (json["status"].intValue == 200)
                        
                        if success {
                            let userData = json["results"]["user"]
                            let _ = QiscusMe.saveData(fromJson: userData)
                            Qiscus.setupReachability()
                            if let delegate = Qiscus.shared.delegate {
                                Qiscus.uiThread.async { autoreleasepool{
                                    delegate.qiscus?(didConnect: true, error: nil)
                                    delegate.qiscusConnected?()
                                    }}
                            }
                            Qiscus.registerNotification()
                            
                        }else{
                            if let delegate = Qiscus.shared.delegate {
                                Qiscus.uiThread.async { autoreleasepool{
                                    delegate.qiscusFailToConnect?("\(json["message"].stringValue)")
                                    delegate.qiscus?(didConnect: false, error: "\(json["message"].stringValue)")
                                }}
                            }
                        }
                    }else{
                        if let delegate = Qiscus.shared.delegate {
                            Qiscus.uiThread.async { autoreleasepool{
                                let error = "Cant get data from qiscus server"
                                delegate.qiscusFailToConnect?(error)
                                delegate.qiscus?(didConnect: false, error: error)
                            }}
                        }
                    }
                    break
                case .failure(let error):
                    if let delegate = Qiscus.shared.delegate {
                        Qiscus.uiThread.async {autoreleasepool{
                            delegate.qiscusFailToConnect?("\(error)")
                            delegate.qiscus?(didConnect: false, error: "\(error)")
                        }}
                    }
                    break
                }
            })
        }}
    }
    
    public class func roomList(withLimit limit:Int = 100, page:Int? = nil, showParticipant:Bool = true, onSuccess:@escaping (([QRoom],Int,Int,Int)->Void), onFailed: @escaping ((String)->Void)){
        QiscusRequestThread.async {
            autoreleasepool{
                var parameters:[String: AnyObject] = [
                    "token"             : qiscus.config.USER_TOKEN as AnyObject,
                    "show_participants" : showParticipant as AnyObject,
                    "limit"             : limit as AnyObject
                    ]
                if page != nil {
                    parameters["page"] = page as AnyObject
                }
                Qiscus.printLog(text: "room list url: \(QiscusConfig.SEARCH_URL)")
                Qiscus.printLog(text: "room list parameters: \(parameters)")
                Alamofire.request(QiscusConfig.ROOMLIST_URL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: { response in
                    Qiscus.printLog(text: "room list result: \(response)")
                    switch response.result {
                    case .success:
                        if let result = response.result.value{
                            let json = JSON(result)
                            let success:Bool = (json["status"].intValue == 200)
                            
                            if success {
                                let resultData = json["results"]
                                let currentPage = resultData["meta"]["current_page"].intValue
                                let totalRoom = resultData["meta"]["total_room"].intValue
                                let rooms = resultData["rooms_info"].arrayValue
                                
                                DispatchQueue.main.async { autoreleasepool {
                                    var roomResult = [QRoom]()
                                    for roomData in rooms {
                                        let roomId = roomData["id"].intValue
                                        let unread = roomData["unread_count"].intValue
                                        if let room = QRoom.room(withId: roomId){
                                            let lastCommentData = roomData["last_comment"]
                                            let lastComment = QComment.tempComment(fromJSON: lastCommentData)
                                            room.updateLastComentInfo(comment: lastComment)
                                            roomResult.append(room)
                                        }else{
                                            let room = QRoom.addRoom(fromJSON: roomData)
                                            room.updateUnreadCommentCount(count: unread)
                                            roomResult.append(room)
                                        }
                                    }
                                    onSuccess(roomResult,totalRoom,currentPage,limit)
                                }}
                            }else{
                                onFailed("can't load room list")
                            }
                        }else{
                            onFailed("can't load room list")
                        }
                        break
                    case .failure(let error):
                        onFailed("\(error.localizedDescription)")
                        break
                    }
                })
            }
        }
    }
    
    public class func roomInfo(withId id:Int, onSuccess:@escaping ((QRoom)->Void), onFailed: @escaping ((String)->Void)){
        QiscusRequestThread.async {
            let parameters:[String: AnyObject] = [
                "token"  : qiscus.config.USER_TOKEN as AnyObject,
                "room_id" : [id] as AnyObject,
                "show_participants": true as AnyObject
            ]
            Qiscus.printLog(text: "room info url: \(QiscusConfig.SEARCH_URL)")
            Qiscus.printLog(text: "room info parameters: \(parameters)")
            Alamofire.request(QiscusConfig.ROOMINFO_URL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: { response in
                Qiscus.printLog(text: "room info result: \(response)")
                switch response.result {
                case .success:
                    if let result = response.result.value{
                        let json = JSON(result)
                        let success:Bool = (json["status"].intValue == 200)
                        
                        if success {
                            let resultData = json["results"]
                            let roomsData = resultData["rooms_info"].arrayValue
                            
                            if roomsData.count > 0 {
                                let roomData = roomsData[0]
                                DispatchQueue.main.async { autoreleasepool {
                                    let roomId = roomData["id"].intValue
                                    let unread = roomData["unread_count"].intValue
                                    if let room = QRoom.room(withId: roomId){
                                        let lastCommentData = roomData["last_comment"]
                                        let lastComment = QComment.tempComment(fromJSON: lastCommentData)
                                        room.updateLastComentInfo(comment: lastComment)
                                        onSuccess(room)
                                    }else{
                                        let room = QRoom.addRoom(fromJSON: roomData)
                                        room.updateUnreadCommentCount(count: unread)
                                        onSuccess(room)
                                    }
                                }}
                            }else{
                                onFailed("room notfound")
                            }
                        }else{
                            onFailed("can't get search result")
                        }
                    }else{
                        onFailed("can't get search result")
                    }
                    break
                case .failure(let error):
                    onFailed("\(error.localizedDescription)")
                    break
                }
            })
        }
    }
    public class func searchComment(withQuery text:String, room:QRoom? = nil, fromComment:QComment? = nil, onSuccess:@escaping (([QComment])->Void), onFailed: @escaping ((String)->Void)){
        let roomId:Int? = room?.id
        let commentId:Int? = fromComment?.id
        if text.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            onFailed("cant search empty string")
            return
        }
        QiscusRequestThread.async {
            var parameters:[String: AnyObject] = [
                "token"  : qiscus.config.USER_TOKEN as AnyObject,
                "query" : text as AnyObject,
            ]
            if roomId != nil {
                parameters["room_id"] = roomId as AnyObject
            }
            if commentId != nil {
                parameters["last_comment_id"] = commentId as AnyObject
            }
            Qiscus.printLog(text: "search url: \(QiscusConfig.SEARCH_URL)")
            Qiscus.printLog(text: "search parameters: \(parameters)")
            Alamofire.request(QiscusConfig.SEARCH_URL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: { response in
                Qiscus.printLog(text: "search result: \(response)")
                switch response.result {
                case .success:
                    if let result = response.result.value{
                        let json = JSON(result)
                        let success:Bool = (json["status"].intValue == 200)
                        
                        if success {
                            let resultData = json["results"]
                            let comments = resultData["comments"].arrayValue
                            
                            DispatchQueue.main.async { autoreleasepool {
                                var commentResult = [QComment]()
                                for commentData in comments {
                                    let uniqueId = commentData["unique_temp_id"].stringValue
                                    if let comment = QComment.comment(withUniqueId: uniqueId){
                                        commentResult.append(comment)
                                    }else{
                                        let comment = QComment.tempComment(fromJSON: commentData)
                                        commentResult.append(comment)
                                    }
                                }
                                onSuccess(commentResult)
                            }}
                        }else{
                            onFailed("can't get search result")
                        }
                    }else{
                        onFailed("can't get search result")
                    }
                    break
                case .failure(let error):
                    onFailed("\(error.localizedDescription)")
                    break
                }
            })
        }
    }
}
