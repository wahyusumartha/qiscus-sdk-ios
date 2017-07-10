//
//  QiscusCommentClient.swift
//  QiscusSDK
//
//  Created by ahmad athaullah on 7/17/16.
//  Copyright © 2016 qiscus. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import AlamofireImage
import SwiftyJSON
import AVFoundation
import Photos
import UserNotifications
import CocoaMQTT

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}
@objc public protocol QiscusServiceDelegate {
    func qiscusService(didFinishLoadRoom inRoom:QiscusRoom, withMessage message:String?)
    func qiscusService(didChangeContent data:QiscusCommentPresenter)
    func qiscusService(didFinishLoadMore inRoom:QiscusRoom, dataCount:Int, from commentId:Int)
    func qiscusService(didFailLoadMore inRoom:QiscusRoom)
    func qiscusService(didFailLoadRoom withError: String)
    func qiscusService(didChangeUser user:QiscusUser, onUserWithEmail email:String)
    func qiscusService(didChangeRoom room:QiscusRoom, onRoomWithId roomId:Int)
}

let qiscus = Qiscus.sharedInstance

open class QiscusCommentClient: NSObject {
    open static let sharedInstance = QiscusCommentClient()
    
    class var shared:QiscusCommentClient{
        get{
            return QiscusCommentClient.sharedInstance
        }
    }
    
    open var commentDelegate: QCommentDelegate?
    open var roomDelegate: QiscusRoomDelegate?
    open var configDelegate: QiscusConfigDelegate?
    
    open var delegate:QiscusServiceDelegate?
    
    open var linkRequest: Alamofire.Request?
    
    
    open func getLinkMetadata(url:String, synchronous:Bool = true, withCompletion: @escaping (QiscusLinkData)->Void, withFailCompletion: @escaping ()->Void){
        DispatchQueue.global().async {
            if self.linkRequest != nil && synchronous{
                self.linkRequest?.cancel()
            }
            let parameters:[String: AnyObject] =  [
                "url" : url as AnyObject
            ]
            Qiscus.printLog(text: "getLinkMetadata for url: \(url)")
            if synchronous{
                self.linkRequest = Alamofire.request(QiscusConfig.LINK_METADATA_URL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
                    Qiscus.printLog(text: "getLinkMetadata response: \n\(responseData)")
                    if let response = responseData.result.value {
                        let json = JSON(response)
                        var title = ""
                        var description = ""
                        var imageURL = ""
                        var linkURL = ""
                        
                        if json["results"]["metadata"].exists(){
                            let metadata = json["results"]["metadata"]
                            if let desc = metadata["description"].string{
                                description = desc
                            }
                            if let metaTitle = metadata["title"].string{
                                title = metaTitle
                            }
                            if let image = metadata["image"].string{
                                imageURL = image
                            }
                            if let url = json["results"]["url"].string{
                                linkURL = url
                            }
                        }
                        if title != ""{
                            let linkData = QiscusLinkData()
                            linkData.linkURL = linkURL
                            if description != "" {
                                linkData.linkDescription = description
                            }else{
                                linkData.linkDescription = "No description available for this site"
                            }
                            linkData.linkTitle = title
                            linkData.linkImageURL = imageURL
                            Qiscus.uiThread.async {
                                withCompletion(linkData)
                            }
                        }else{
                            Qiscus.uiThread.async {
                                withFailCompletion()
                            }
                        }
                    }else{
                        Qiscus.uiThread.async {
                            withFailCompletion()
                        }
                    }
                    self.linkRequest = nil
                })
            }else{
                Alamofire.request(QiscusConfig.LINK_METADATA_URL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
                    Qiscus.printLog(text: "getLinkMetadata response: \n\(responseData)")
                    if let response = responseData.result.value {
                        let json = JSON(response)
                        var title = ""
                        var description = ""
                        var imageURL = ""
                        var linkURL = ""
                        
                        if json["results"]["metadata"].exists(){
                            let metadata = json["results"]["metadata"]
                            if let desc = metadata["description"].string{
                                description = desc
                            }
                            if let metaTitle = metadata["title"].string{
                                title = metaTitle
                            }
                            if let image = metadata["image"].string{
                                imageURL = image
                            }
                            if let url = json["results"]["url"].string{
                                linkURL = url
                            }
                        }
                        if title != ""{
                            let linkData = QiscusLinkData()
                            linkData.linkURL = linkURL
                            if description != "" {
                                linkData.linkDescription = description
                            }else{
                                linkData.linkDescription = "No description available for this site"
                            }
                            linkData.linkTitle = title
                            linkData.linkImageURL = imageURL
                            Qiscus.uiThread.async {
                                withCompletion(linkData)
                            }
                        }else{
                            Qiscus.uiThread.async {
                                withFailCompletion()
                            }
                        }
                    }else{
                        Qiscus.uiThread.async {
                            withFailCompletion()
                        }
                    }
                })
            }
        }
    }
    // MARK: - Login or register
    open func loginOrRegister(_ email:String = "", password:String = "", username:String? = nil, avatarURL:String? = nil, onSuccess:(()->Void)? = nil){
        
        var parameters:[String: AnyObject] = [String: AnyObject]()
        
        parameters = [
            "email"  : email as AnyObject,
            "password" : password as AnyObject,
        ]
        
        if let name = username{
            parameters["username"] = name as AnyObject?
        }
        if let avatar =  avatarURL{
            parameters["avatar_url"] = avatar as AnyObject?
        }
        
        DispatchQueue.global().async(execute: {
            Qiscus.printLog(text: "login url: \(QiscusConfig.LOGIN_REGISTER)")
            Qiscus.printLog(text: "post parameters: \(parameters)")
            Qiscus.printLog(text: "post headers: \(QiscusConfig.sharedInstance.requestHeader)")
            Alamofire.request(QiscusConfig.LOGIN_REGISTER, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: { response in
                Qiscus.printLog(text: "login register result: \(response)")
                Qiscus.printLog(text: "login url: \(QiscusConfig.LOGIN_REGISTER)")
                Qiscus.printLog(text: "post parameters: \(parameters)")
                Qiscus.printLog(text: "post headers: \(QiscusConfig.sharedInstance.requestHeader)")
                switch response.result {
                    case .success:
                        DispatchQueue.main.async(execute: {
                            if let result = response.result.value{
                                let json = JSON(result)
                                let success:Bool = (json["status"].intValue == 200)
                                
                                if success {
                                    let userData = json["results"]["user"]
                                    let _ = QiscusMe.saveData(fromJson: userData)
                                    if self.configDelegate != nil {
                                        Qiscus.setupReachability()
                                        Qiscus.uiThread.async {
                                            self.configDelegate!.qiscusConnected()
                                        }
                                        Qiscus.registerNotification()
                                        if let successAction = onSuccess {
                                            successAction()
                                        }
                                    }
                                }else{
                                    if let delegate = self.configDelegate{
                                        Qiscus.uiThread.async {
                                            delegate.qiscusFailToConnect("\(json["message"].stringValue)")
                                        }
                                    }
                                }
                            }else{
                                if self.configDelegate != nil {
                                    Qiscus.uiThread.async {
                                        self.configDelegate!.qiscusFailToConnect("Cant get data from qiscus server")
                                    }
                                }
                            }
                        })
                    break
                    case .failure(let error):
                        DispatchQueue.main.async(execute: {
                            if self.configDelegate != nil {
                                Qiscus.uiThread.async {
                                    self.configDelegate!.qiscusFailToConnect("\(error)")
                                }
                            }
                        })
                    break
                }
            })
        })
    }
    // MARK: - Register deviceToken
    func registerDevice(withToken deviceToken: String){
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
                                    if let delegate = self.configDelegate {
                                        delegate.didRegisterQiscusPushNotification?(withDeviceToken: Qiscus.deviceToken)
                                    }
                                }else{
                                    if let delegate = self.configDelegate {
                                        delegate.failToRegisterQiscusPushNotification?(withError: "unsuccessful register deviceToken : pushNotification not configured", andDeviceToken: Qiscus.deviceToken)
                                    }
                                }
                            }else{
                                if let delegate = self.configDelegate {
                                    delegate.failToRegisterQiscusPushNotification?(withError: "unsuccessful register deviceToken", andDeviceToken: Qiscus.deviceToken)
                                }
                            }
                        }else{
                            if let delegate = self.configDelegate {
                                delegate.failToRegisterQiscusPushNotification?(withError: "unsuccessful register deviceToken", andDeviceToken: Qiscus.deviceToken)
                            }
                        }
                    })
                    break
                case .failure(let error):
                    DispatchQueue.main.async(execute: {
                        if let delegate = self.configDelegate {
                            delegate.failToRegisterQiscusPushNotification?(withError: "unsuccessful register deviceToken: \(error)", andDeviceToken: Qiscus.deviceToken)
                        }
                    })
                    break
                }
            })
        }
        if Qiscus.isLoggedIn {
            register()
        }else{
            reconnect {
                register()
            }
        }
        
    }
    private func reconnect(onSuccess:@escaping (()->Void)){
        let email = QiscusMe.sharedInstance.userData.value(forKey: "qiscus_param_email") as? String
        let userKey = QiscusMe.sharedInstance.userData.value(forKey: "qiscus_param_pass") as? String
        let userName = QiscusMe.sharedInstance.userData.value(forKey: "qiscus_param_username") as? String
        let avatarURL = QiscusMe.sharedInstance.userData.value(forKey: "qiscus_param_avatar") as? String
        if email != nil && userKey != nil && userName != nil {
            QiscusCommentClient.sharedInstance.loginOrRegister(email!, password: userKey!, username: userName!, avatarURL: avatarURL, onSuccess: onSuccess)
        }
        
    }
    // MARK: - Remove deviceToken
    open func unRegisterDevice(){
        if QiscusMe.sharedInstance.deviceToken != "" {
            let parameters:[String: AnyObject] = [
                "token"  : qiscus.config.USER_TOKEN as AnyObject,
                "device_token" : QiscusMe.sharedInstance.deviceToken as AnyObject,
                "device_platform" : "ios" as AnyObject
            ]
            
            Alamofire.request(QiscusConfig.REMOVE_DEVICE_TOKEN_URL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: { response in
                switch response.result {
                case .success:
                    DispatchQueue.main.async(execute: {
                        if let result = response.result.value{
                            let json = JSON(result)
                            let success:Bool = (json["status"].intValue == 200)
                            
                            if success {
                                let pnData = json["results"]
                                let success = pnData["success"].boolValue
                                if success {
                                    if let delegate = self.configDelegate {
                                        delegate.didUnregisterQiscusPushNotification?(success: true, error: nil, deviceToken: QiscusMe.sharedInstance.deviceToken)
                                        QiscusMe.sharedInstance.deviceToken = ""
                                    }
                                }else{
                                    if let delegate = self.configDelegate {
                                        delegate.didUnregisterQiscusPushNotification?(success: false, error: "cannot unregister device", deviceToken: QiscusMe.sharedInstance.deviceToken)
                                    }
                                    DispatchQueue.global().async {
                                        self.unRegisterDevice()
                                    }
                                }
                            }else{
                                if let delegate = self.configDelegate {
                                    delegate.didUnregisterQiscusPushNotification?(success: false, error: "cannot unregister device", deviceToken: QiscusMe.sharedInstance.deviceToken)
                                }
                                DispatchQueue.global().async {
                                    self.unRegisterDevice()
                                }
                            }
                        }else{
                            if let delegate = self.configDelegate {
                                delegate.didUnregisterQiscusPushNotification?(success: false, error: "cannot unregister device", deviceToken: QiscusMe.sharedInstance.deviceToken)
                            }
                            DispatchQueue.global().async {
                                self.unRegisterDevice()
                            }
                        }
                    })
                    break
                case .failure( _):
                    DispatchQueue.main.async(execute: {
                        if let delegate = self.configDelegate {
                            delegate.didUnregisterQiscusPushNotification?(success: false, error: "cannot unregister device", deviceToken: QiscusMe.sharedInstance.deviceToken)
                        }
                        DispatchQueue.global().async {
                            self.unRegisterDevice()
                        }
                    })
                    break
                }
            })
        }
    }
    // MARK: - Comment Methode
    open func postMessage(message: String, topicId: Int, roomId:Int? = nil, linkData:QiscusLinkData? = nil, indexPath:IndexPath? = nil, payload:JSON? = nil, type:String? = nil){ //
        DispatchQueue.global().async {
            var showLink = false
            if linkData != nil{
                showLink = true
                QiscusLinkData.copyLink(link: linkData!).saveLink()
            }
            var payloadRequest:JSON? = payload
            let comment = QiscusComment.newComment(withMessage: message, inTopicId: topicId, showLink: showLink)
            if type == "reply" {
                comment.commentButton = "\(payload!)"
                comment.commentType = .reply
                payloadRequest = JSON(dictionaryLiteral: [
                    ("text", message),
                    ("replied_comment_id", payload!["replied_comment_id"].intValue)
                    ])
            }
            let commentPresenter = QiscusCommentPresenter.getPresenter(forComment: comment)
            commentPresenter.commentIndexPath = indexPath
            
            DispatchQueue.global().async {
                self.postComment(commentPresenter, roomId: roomId, linkData: linkData, payload: payloadRequest, type: type)
            }
            if let room = QiscusRoom.room(withLastTopicId: topicId) {
                if let chatView = Qiscus.shared.chatViews[room.roomId] {
                    chatView.dataPresenter(gotNewData: commentPresenter, inRoom: room, realtime: true)
                }
            }
            
            if QiscusCommentClient.sharedInstance.roomDelegate != nil{
                Qiscus.uiThread.async {
                    QiscusCommentClient.sharedInstance.roomDelegate?.gotNewComment(comment)
                }
            }
        }
    }
    open func postComment(_ data:QiscusCommentPresenter, file:QiscusFile? = nil, roomId:Int? = nil, linkData:QiscusLinkData? = nil, payload:JSON? = nil, type:String? = nil){ //
        
        var parameters:[String: AnyObject] = [String: AnyObject]()
        
        parameters = [
            "comment"  : data.commentText as AnyObject,
            "topic_id" : data.topicId as AnyObject,
            "unique_temp_id" : data.commentUniqueid as AnyObject
        ]
        
        parameters["token"] = qiscus.config.USER_TOKEN as AnyObject?
        
        if linkData == nil{
            parameters["disable_link_preview"] = true as AnyObject
        }
        if payload != nil && type != nil {
            parameters["type"] = type! as AnyObject
            parameters["payload"] = "\(payload!)" as AnyObject
        }
        
        if roomId != nil {
            parameters["room_id"] = roomId as AnyObject?
        }
        
        DispatchQueue.global().async {
            Alamofire.request(QiscusConfig.postCommentURL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {response in
                if let comment = data.comment {
                    switch response.result {
                    case .success:
                        if let result = response.result.value {
                            let json = JSON(result)
                            let success = (json["status"].intValue == 200)
                            
                            if success == true {
                                let commentJSON = json["results"]["comment"]
                                let roomId = commentJSON["room_id"].intValue
                                data.commentId = commentJSON["id"].intValue
                                data.createdAt = commentJSON["unix_timestamp"].doubleValue
                                comment.commentId = commentJSON["id"].intValue
                                comment.commentBeforeId = commentJSON["comment_before_id"].intValue
                                comment.commentCreatedAt = commentJSON["unix_timestamp"].doubleValue
                                
                                if comment.commentStatus == .failed || comment.commentStatusRaw < QiscusCommentStatus.sent.rawValue{
                                    comment.commentStatusRaw = QiscusCommentStatus.sent.rawValue
                                    data.commentStatus = .sent
                                }
                                if file != nil {
                                    file!.fileCommentId = comment.commentId
                                }
                                if let chatView = Qiscus.shared.chatViews[roomId] {
                                    if let room = chatView.room {
                                        chatView.dataPresenter(didChangeContent: data, inRoom: room)
                                    }
                                }
                            }else{
                                comment.commentStatusRaw = QiscusCommentStatus.failed.rawValue
                                data.commentStatus = .failed
                                if file != nil{
                                    file!.fileCommentId = comment.commentId
                                }
                                Qiscus.uiThread.async {
                                    self.delegate?.qiscusService(didChangeContent: data)
                                }
                            }
                        }else{
                            comment.commentStatusRaw = QiscusCommentStatus.failed.rawValue
                            data.commentStatus = .failed
                            
                            if file != nil{
                                file!.fileCommentId = comment.commentId
                            }
                            Qiscus.uiThread.async {
                                self.delegate?.qiscusService(didChangeContent: data)
                            }
                        }
                        break
                    case .failure(let error):
                        comment.commentStatusRaw = QiscusCommentStatus.failed.rawValue
                        data.commentStatus = .failed
                        if file != nil{
                            file!.fileCommentId = comment.commentId
                        }
                        Qiscus.uiThread.async {
                            self.delegate?.qiscusService(didChangeContent: data)
                        }
                        Qiscus.printLog(text: "fail to post comment with error: \(error)")
                        break
                    }
                }
            })
        }
    }
    
    open func downloadMedia(data:QiscusCommentPresenter, thumbImageRef:UIImage? = nil, isAudioFile:Bool = false){
        DispatchQueue.global().async {
            let comment = data.comment!
            
            let file = QiscusFile.file(forComment: comment)!
            
            file.isDownloading = true
            data.isDownloading = true
            
            Qiscus.uiThread.async {
                self.delegate?.qiscusService(didChangeContent: data)
            }
            
            let fileURL = file.fileURL.replacingOccurrences(of: " ", with: "%20")
            Alamofire.request(fileURL, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil).responseData(completionHandler: { response in
                    Qiscus.printLog(text: "download result: \(response)")
                    if let imageData = response.data {
                        if !isAudioFile{
                            if let image = UIImage(data: imageData) {
                                var thumbImage = UIImage()
                                if !(file.fileExtension == "gif" || file.fileExtension == "gif_"){
                                    thumbImage = QiscusFile.createThumbImage(image, fillImageSize: thumbImageRef)
                                }
                                
                                file.downloadProgress = 1
                                file.isDownloading = false
                                
                                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
                                let directoryPath = "\(documentsPath)/Qiscus"
                                if !FileManager.default.fileExists(atPath: directoryPath){
                                    do {
                                        try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: false, attributes: nil)
                                    } catch let error as NSError {
                                        Qiscus.printLog(text: error.localizedDescription);
                                    }
                                }
                                
                                let fileName = "\(file.fileName.replacingOccurrences(of: " ", with: "%20").replacingOccurrences(of: "%20", with: "_"))"
                                let path = "\(documentsPath)/Qiscus/\(fileName)"
                                let thumbPath = "\(documentsPath)/Qiscus/thumb_\(fileName)"
                                
                                if (file.fileExtension == "png" || file.fileExtension == "png_") {
                                    try? UIImagePNGRepresentation(image)!.write(to: URL(fileURLWithPath: path), options: [.atomic])
                                    try? UIImagePNGRepresentation(thumbImage)!.write(to: URL(fileURLWithPath: thumbPath), options: [.atomic])
                                } else if(file.fileExtension == "jpg" || file.fileExtension == "jpg_"){
                                    try? UIImageJPEGRepresentation(image, 1.0)!.write(to: URL(fileURLWithPath: path), options: [.atomic])
                                    try? UIImageJPEGRepresentation(thumbImage, 1.0)!.write(to: URL(fileURLWithPath: thumbPath), options: [.atomic])
                                } else if(file.fileExtension == "gif" || file.fileExtension == "gif_"){
                                    try? imageData.write(to: URL(fileURLWithPath: path), options: [.atomic])
                                    try? imageData.write(to: URL(fileURLWithPath: thumbPath), options: [.atomic])
                                    thumbImage = image
                                }
                                file.fileLocalPath = path
                                file.fileThumbPath = thumbPath
                                
                                data.isDownloading = false
                                data.downloadProgress = 1
                                data.displayImage = thumbImage
                                data.localURL = path
                                data.localThumbURL = thumbPath
                                data.localFileExist = true
                                Qiscus.uiThread.async {
                                    self.delegate?.qiscusService(didChangeContent: data)
                                }
                                
                            }else{
                                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
                                let directoryPath = "\(documentsPath)/Qiscus"
                                if !FileManager.default.fileExists(atPath: directoryPath){
                                    do {
                                        try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: false, attributes: nil)
                                    } catch let error as NSError {
                                        Qiscus.printLog(text: error.localizedDescription);
                                    }
                                }
                                let path = "\(documentsPath)/Qiscus/\(file.fileName as String)"
                                let thumbPath = "\(documentsPath)/Qiscus/thumb_\(file.fileCommentId).png"
                                
                                try? imageData.write(to: URL(fileURLWithPath: path), options: [.atomic])
                                
                                let assetMedia = AVURLAsset(url: URL(fileURLWithPath: "\(path)"))
                                let thumbGenerator = AVAssetImageGenerator(asset: assetMedia)
                                thumbGenerator.appliesPreferredTrackTransform = true
                                
                                let thumbTime = CMTimeMakeWithSeconds(0, 30)
                                let maxSize = CGSize(width: file.screenWidth, height: file.screenWidth)
                                thumbGenerator.maximumSize = maxSize
                                var thumbImage:UIImage?
                                do{
                                    let thumbRef = try thumbGenerator.copyCGImage(at: thumbTime, actualTime: nil)
                                    thumbImage = UIImage(cgImage: thumbRef)
                                    
                                    let thumbData = UIImagePNGRepresentation(thumbImage!)
                                    try? thumbData!.write(to: URL(fileURLWithPath: thumbPath), options: [.atomic])
                                }catch{
                                    Qiscus.printLog(text: "error creating thumb image")
                                }
                                
                                file.downloadProgress = 1
                                file.isDownloading = false
                                file.fileLocalPath = path
                                file.fileThumbPath = thumbPath
                                
                                data.isDownloading = false
                                data.downloadProgress = 1
                                data.displayImage = thumbImage
                                data.localURL = path
                                data.localThumbURL = thumbPath
                                data.localFileExist = true
                                Qiscus.uiThread.async {
                                    self.delegate?.qiscusService(didChangeContent: data)
                                }
                            }
                        }
                        else{
                            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
                            let directoryPath = "\(documentsPath)/Qiscus"
                            if !FileManager.default.fileExists(atPath: directoryPath){
                                do {
                                    try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: false, attributes: nil)
                                } catch let error as NSError {
                                    Qiscus.printLog(text: error.localizedDescription);
                                }
                            }
                            let path = "\(documentsPath)/Qiscus/\(file.fileName as String)"
                            try! imageData.write(to: URL(fileURLWithPath: path), options: [.atomic])
                            
                            file.downloadProgress = 1
                            file.isDownloading = false
                            file.fileLocalPath = path
                            
                            data.isDownloading = false
                            data.downloadProgress = 1
                            data.localURL = path
                            data.localFileExist = true
                            data.audioFileExist = true
                            
                            self.delegate?.qiscusService(didChangeContent: data)
                        }
                    }
                }
            ).downloadProgress(closure: { progressData in
                DispatchQueue.global().async {
                    let progress = CGFloat(progressData.fractionCompleted)
                    data.downloadProgress = progress
                    data.isDownloading = true
                    file.downloadProgress = progress
                    
                    self.delegate?.qiscusService(didChangeContent: data)
                    Qiscus.printLog(text: "Download progress: \(progress)")
                }
            })
        }
    }
    
    public func uploadMediaData(withData presenterData:QiscusCommentPresenter){
        let headers = QiscusConfig.sharedInstance.requestHeader
        
        var urlUpload = URLRequest(url: URL(string: QiscusConfig.UPLOAD_URL)!)
        if headers.count > 0 {
            for (key,value) in headers {
                urlUpload.setValue(value, forHTTPHeaderField: key)
            }
        }
        urlUpload.httpMethod = "POST"
        DispatchQueue.global().async {
            Alamofire.upload(multipartFormData: {formData in
                formData.append(presenterData.uploadData!, withName: "file", fileName: presenterData.fileName, mimeType: presenterData.uploadMimeType!)
            }, with: urlUpload, encodingCompletion: {
                encodingResult in
                switch encodingResult{
                case .success(let upload, _, _):
                    upload.responseJSON(completionHandler: {response in
                        Qiscus.printLog(text: "success upload: \(response)")
                        if let jsonData = response.result.value {
                            let json = JSON(jsonData)
                            if let url = json["url"].string {
                                if let comment = presenterData.comment{
                                    comment.commentStatusRaw = QiscusCommentStatus.sending.rawValue
                                    comment.commentText = "[file]\(url) [/file]"
                                    if let file = QiscusFile.file(forComment: comment) {
                                        file.fileURL = url
                                        file.isUploading = false
                                        file.uploaded = true
                                        file.uploadProgress = 1
                                    }
                                }
                                presenterData.commentStatus = .sending
                                presenterData.commentText = "[file]\(url) [/file]"
                                presenterData.remoteURL = url
                                presenterData.isUploaded = true
                                presenterData.isUploading = false
                                presenterData.uploadProgress = CGFloat(1)
                                presenterData.remoteURL = url
                                
                                Qiscus.uiThread.async {
                                    self.delegate?.qiscusService(didChangeContent: presenterData)
                                }
                                self.postComment(presenterData)
                            }
                            else if json["results"].count > 0 {
                                let data = json["results"]
                                if data["file"].count > 0 {
                                    let file = data["file"]
                                    if let url = file["url"].string {
                                        if let comment = presenterData.comment{
                                            comment.commentStatusRaw = QiscusCommentStatus.sending.rawValue
                                            comment.commentText = "[file]\(url) [/file]"
                                            if let file = QiscusFile.file(forComment: comment) {
                                                file.fileURL = url
                                                file.isUploading = false
                                                file.uploaded = true
                                                file.uploadProgress = 1
                                            }
                                        }

                                        presenterData.commentStatus = .sending
                                        presenterData.commentText = "[file]\(url) [/file]"
                                        presenterData.remoteURL = url
                                        presenterData.isUploaded = true
                                        presenterData.isUploading = false
                                        presenterData.uploadProgress = CGFloat(1)
                                        presenterData.remoteURL = url
                                        
                                        Qiscus.uiThread.async {
                                            self.delegate?.qiscusService(didChangeContent: presenterData)
                                        }
                                        self.postComment(presenterData)
                                    }
                                }
                            }
                        }else{
                            Qiscus.printLog(text: "fail to upload file")
                            if let comment = presenterData.comment{
                                comment.commentStatusRaw = QiscusCommentStatus.failed.rawValue
                                if let file = QiscusFile.file(forComment: comment) {
                                    file.isUploading = false
                                    file.uploaded = false
                                    file.uploadProgress = 0
                                }
                            }
                            presenterData.commentStatus = .failed
                            presenterData.isUploaded = false
                            presenterData.isUploading = false
                            presenterData.uploadProgress = CGFloat(0)
                            
                            Qiscus.uiThread.async {
                                self.delegate?.qiscusService(didChangeContent: presenterData)
                            }
                        }
                    })
                    upload.uploadProgress(closure: {uploadProgress in
                        let progress = CGFloat(uploadProgress.fractionCompleted)
                        Qiscus.printLog(text: "upload progress: \(progress)")
                        if let comment = presenterData.comment{
                            if let file = QiscusFile.file(forComment: comment) {
                                file.isUploading = true
                                file.uploaded = false
                                file.uploadProgress = progress
                            }
                        }
                        presenterData.isUploading = true
                        presenterData.uploadProgress = progress
                        Qiscus.uiThread.async {
                            self.delegate?.qiscusService(didChangeContent: presenterData)
                        }
                    })
                    break
                case .failure(let error):
                    Qiscus.printLog(text: "fail to upload with error: \(error)")
                    if let comment = presenterData.comment{
                        comment.commentStatusRaw = QiscusCommentStatus.failed.rawValue
                        if let file = QiscusFile.file(forComment: comment) {
                            file.isUploading = false
                            file.uploaded = false
                            file.uploadProgress = 0
                        }
                    }
                    presenterData.commentStatus = .failed
                    presenterData.isUploaded = false
                    presenterData.isUploading = false
                    presenterData.uploadProgress = CGFloat(0)
                    
                    Qiscus.uiThread.async {
                        self.delegate?.qiscusService(didChangeContent: presenterData)
                    }
                    break
                }
            })
        }
    }
    open func uploadImage(_ topicId: Int,image:UIImage?,imageName:String,imagePath:URL? = nil, imageNSData:Data? = nil, roomId:Int? = nil, thumbImageRef:UIImage? = nil, videoFile:Bool = true, audioFile:Bool = false){
        DispatchQueue.global().async {
            var imageData:Data = Data()
            if imageNSData != nil {
                imageData = imageNSData!
            }
            var thumbData:Data = Data()
            var imageMimeType:String = ""
            let imageNameArr = imageName.characters.split(separator: ".")
            let imageExt:String = String(imageNameArr.last!).lowercased()
            let comment = QiscusComment.newComment(withMessage: "", inTopicId: topicId)
            
            if image != nil {
                if !videoFile{
                    var thumbImage = UIImage()
                    
                    let isGifImage:Bool = (imageExt == "gif" || imageExt == "gif_")
                    let isJPEGImage:Bool = (imageExt == "jpg" || imageExt == "jpg_")
                    let isPNGImage:Bool = (imageExt == "png" || imageExt == "png_")
                    
                    if !isGifImage{
                        thumbImage = QiscusFile.createThumbImage(image!, fillImageSize: thumbImageRef)
                    }
                    
                    if isJPEGImage == true{
                        let imageSize = image?.size
                        var bigPart = CGFloat(0)
                        if(imageSize?.width > imageSize?.height){
                            bigPart = (imageSize?.width)!
                        }else{
                            bigPart = (imageSize?.height)!
                        }
                        
                        var compressVal = CGFloat(1)
                        if(bigPart > 2000){
                            compressVal = 2000 / bigPart
                        }
                        
                        imageData = UIImageJPEGRepresentation(image!, compressVal)!
                        thumbData = UIImageJPEGRepresentation(thumbImage, 1)!
                        imageMimeType = "image/jpg"
                    }else if isPNGImage == true{
                        imageData = UIImagePNGRepresentation(image!)!
                        thumbData = UIImagePNGRepresentation(thumbImage)!
                        imageMimeType = "image/png"
                    }else if isGifImage == true{
                        if imageNSData == nil{
                            let asset = PHAsset.fetchAssets(withALAssetURLs: [imagePath!], options: nil)
                            if let phAsset = asset.firstObject {
                                
                                let option = PHImageRequestOptions()
                                option.isSynchronous = true
                                option.isNetworkAccessAllowed = true
                                PHImageManager.default().requestImageData(for: phAsset, options: option) {
                                    (data, dataURI, orientation, info) -> Void in
                                    imageData = data!
                                    thumbData = data!
                                    imageMimeType = "image/gif"
                                }
                            }
                        }else{
                            imageData = imageNSData!
                            thumbData = imageNSData!
                            imageMimeType = "image/gif"
                        }
                    }
                }else{
                    if let mime:String = QiscusFileHelper.mimeTypes["\(imageExt)"] {
                        imageMimeType = mime
                        Qiscus.printLog(text: "mime: \(mime)")
                    }
                    thumbData = UIImagePNGRepresentation(image!)!
                }
            }else{
                if let mime:String = QiscusFileHelper.mimeTypes["\(imageExt)"] {
                    imageMimeType = mime
                    Qiscus.printLog(text: "mime: \(mime)")
                }
            }
            var imageThumbName = "thumb_\(comment.commentUniqueId).\(imageExt)"
            let fileName = "\(comment.commentUniqueId).\(imageExt)"
            if videoFile{
                imageThumbName = "thumb_\(comment.commentUniqueId).png"
            }
            
            let commentFile = QiscusFile.newFile()
            if image != nil {
                commentFile.fileLocalPath = QiscusFile.saveFile(imageData, fileName: fileName)
                commentFile.fileThumbPath = QiscusFile.saveFile(thumbData, fileName: imageThumbName)
            }else{
                commentFile.fileLocalPath = QiscusFile.saveFile(imageData, fileName: fileName)
            }
            comment.commentText = "[file]\(fileName) [/file]"
            
            
            commentFile.fileTopicId = topicId
            commentFile.isUploading = true
            commentFile.uploaded = false
            commentFile.isUploading = true
            commentFile.uploadProgress = 0
            
            comment.commentFileId = commentFile.fileId
            
            DispatchQueue.global(qos: .background).async {
                let presenter = QiscusCommentPresenter.getPresenter(forComment: comment)
                presenter.isUploading = true
                presenter.uploadProgress = CGFloat(0)
                presenter.fileName = fileName
                presenter.toUpload = true
                presenter.uploadData = imageData
                
                if let room = QiscusRoom.room(withLastTopicId: topicId) {
                    if let chatView = Qiscus.shared.chatViews[room.roomId] {
                        chatView.dataPresenter(gotNewData: presenter, inRoom: room, realtime: true)
                    }
                }
            }
            
            
            let headers = QiscusConfig.sharedInstance.requestHeader
            
            var urlUpload = URLRequest(url: URL(string: QiscusConfig.UPLOAD_URL)!)
            if headers.count > 0 {
                for (key,value) in headers {
                    urlUpload.setValue(value, forHTTPHeaderField: key)
                }
            }
            urlUpload.httpMethod = "POST"
            DispatchQueue.global().async {
                Alamofire.upload(multipartFormData: {formData in
                    formData.append(imageData, withName: "file", fileName: fileName, mimeType: imageMimeType)
                }, with: urlUpload, encodingCompletion: {
                    encodingResult in
                    switch encodingResult{
                    case .success(let upload, _, _):
                        upload.responseJSON(completionHandler: {response in
                            Qiscus.printLog(text: "success upload: \(response)")
                            if let jsonData = response.result.value {
                                let json = JSON(jsonData)
                                if let url = json["url"].string {
                                    comment.commentStatusRaw = QiscusCommentStatus.sent.rawValue
                                    comment.commentText = "[file]\(url) [/file]"
                                    
                                    commentFile.fileURL = url
                                    commentFile.isUploading = false
                                    commentFile.uploaded = true
                                    commentFile.uploadProgress = 1
                                    
                                    DispatchQueue.global(qos: .background).async {
                                        let presenter = QiscusCommentPresenter.getPresenter(forComment: comment)
                                        presenter.isUploaded = true
                                        presenter.isUploading = false
                                        presenter.uploadProgress = CGFloat(1)
                                        presenter.remoteURL = url
                                        
                                        Qiscus.uiThread.async {
                                            self.delegate?.qiscusService(didChangeContent: presenter)
                                        }
                                        self.postComment(presenter)
                                    }
                                }
                                else if json["results"].count > 0 {
                                    let data = json["results"]
                                    if data["file"].count > 0 {
                                        let file = data["file"]
                                        if let url = file["url"].string {
                                            comment.updateCommentStatus(.sending)
                                            comment.commentText = "[file]\(url) [/file]"
                                            Qiscus.printLog(text: "upload success")
                                            
                                            commentFile.fileURL = url
                                            commentFile.isUploading = false
                                            commentFile.uploaded = true
                                            commentFile.uploadProgress = 1
                                            
                                            DispatchQueue.global(qos: .background).async {
                                                let presenter = QiscusCommentPresenter.getPresenter(forComment: comment)
                                                presenter.isUploaded = true
                                                presenter.isUploading = false
                                                presenter.uploadProgress = CGFloat(1)
                                                presenter.remoteURL = url
                                                
                                                Qiscus.uiThread.async {
                                                    self.delegate?.qiscusService(didChangeContent: presenter)
                                                }
                                                self.postComment(presenter)
                                            }
                                            
                                        }
                                    }
                                }
                            }else{
                                Qiscus.printLog(text: "fail to upload file")
                                comment.commentStatusRaw = QiscusCommentStatus.failed.rawValue
                                commentFile.isUploading = false
                                commentFile.uploaded = false
                                commentFile.uploadProgress = 0
                                
                                let presenter = QiscusCommentPresenter.getPresenter(forComment: comment)
                                presenter.isUploaded = false
                                presenter.isUploading = false
                                presenter.uploadProgress = CGFloat(0)
                                
                                Qiscus.uiThread.async {
                                    self.delegate?.qiscusService(didChangeContent: presenter)
                                }
                            }
                        })
                        upload.uploadProgress(closure: {uploadProgress in
                            let progress = CGFloat(uploadProgress.fractionCompleted)
                            Qiscus.printLog(text: "upload progress: \(progress)")
                            commentFile.isUploading = true
                            commentFile.uploadProgress = progress
                            
                            let presenter = QiscusCommentPresenter.getPresenter(forComment: comment)
                            presenter.isUploading = true
                            presenter.uploadProgress = progress
                            
                            Qiscus.uiThread.async {
                                self.delegate?.qiscusService(didChangeContent: presenter)
                            }
                        })
                        break
                    case .failure(let error):
                        Qiscus.printLog(text: "fail to upload with error: \(error)")
                        comment.updateCommentStatus(QiscusCommentStatus.failed)
                        
                        commentFile.isUploading = false
                        commentFile.uploadProgress = 0
                        commentFile.uploaded = false
                        
                        let presenter = QiscusCommentPresenter.getPresenter(forComment: comment)
                        presenter.isUploaded = false
                        presenter.isUploading = false
                        presenter.uploadProgress = CGFloat(0)
                        
                        Qiscus.uiThread.async {
                            self.delegate?.qiscusService(didChangeContent: presenter)
                        }
                        break
                    }
                })
            }
        }
    }
    
    // MARK: - Communicate with Server
    open func syncMessage(inRoom room: QiscusRoom, fromComment commentId: Int, silent:Bool = false, triggerDelegate:Bool = false) {
        DispatchQueue.global().async {
            let topicId = room.roomLastCommentTopicId
            let loadURL = QiscusConfig.LOAD_URL
            let parameters:[String: AnyObject] =  [
                "last_comment_id"  : commentId as AnyObject,
                "topic_id" : topicId as AnyObject,
                "token" : qiscus.config.USER_TOKEN as AnyObject,
                "after" : "true" as AnyObject
            ]
            Qiscus.printLog(text: "sync comment parameters: \n\(parameters)")
            Qiscus.printLog(text: "sync comment url: \n\(loadURL)")
            DispatchQueue.global().async {
                Alamofire.request(loadURL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
                    Qiscus.printLog(text: "sync comment response: \n\(responseData)")
                    if let response = responseData.result.value {
                        let json = JSON(response)
                        let results = json["results"]
                        let error = json["error"]
                        if results != JSON.null{
                            let comments = json["results"]["comments"].arrayValue
                            if comments.count > 0 {
                                for newComment in comments {
                                    var saved = false
                                    let id = newComment["id"].intValue
                                    let uniqueId = newComment["unique_temp_id"].stringValue
                                    var comment = QiscusComment()
                                    if let old = QiscusComment.comment(withUniqueId: uniqueId){
                                        comment = old
                                    }else{
                                        comment = QiscusComment.newComment(withId: id, andUniqueId: uniqueId)
                                        comment.commentText = newComment["message"].stringValue
                                        comment.showLink = !(newComment["disable_link_preview"].boolValue)
                                        saved = true
                                    }
                                    let email = newComment["email"].stringValue
                                    
                                    comment.commentBeforeId = newComment["comment_before_id"].intValue
                                    comment.commentSenderEmail = email
                                    comment.commentTopicId = topicId
                                    comment.commentCreatedAt = Double(newComment["unix_timestamp"].doubleValue)
                                    
                                    if newComment["type"].string == "buttons" {
                                        comment.commentText = newComment["payload"]["text"].stringValue
                                        comment.commentButton = "\(newComment["payload"]["buttons"])"
                                        comment.commentType = .postback
                                    }else if newComment["type"].string == "account_linking" {
                                        comment.commentButton = "\(newComment["payload"])"
                                        comment.commentType = .account
                                    }else if newComment["type"].string == "reply" {
                                        if comment.commentButton == "" {
                                            comment.commentButton = "\(newComment["payload"])"
                                        }
                                        comment.commentType = .reply
                                    }else if newComment["type"].string == "system_event"{
                                        comment.commentType = .system
                                    }else if comment.commentIsFile {
                                        comment.commentType = .attachment
                                    }else{
                                        comment.commentType = .text
                                    }
                                    
                                    comment.updateCommentStatus(.sent)
                                    
                                    if let participant = QiscusParticipant.getParticipant(withEmail: email, roomId: room.roomId){
                                        participant.updateLastReadCommentId(commentId: comment.commentId)
                                    }
                                    
                                    if let user = QiscusUser.getUserWithEmail(email) {
                                        user.updateUserAvatarURL(newComment["user_avatar_url"].stringValue)
                                        user.updateUserFullName(newComment["username"].stringValue)
                                    }
                                    DispatchQueue.global().async {
                                        if triggerDelegate && saved {
                                            if let chatView = Qiscus.shared.chatViews[room.roomId] {
                                                let presenter = QiscusCommentPresenter.getPresenter(forComment: comment)
                                                chatView.dataPresenter(gotNewData: presenter, inRoom: room, realtime: true)
                                            }
                                            
                                        }
                                    }
                                }
                            }
                        }else if error != JSON.null{
                            Qiscus.printLog(text: "error sync message: \(error)")
                            if !silent {
                                QiscusDataPresenter.shared.loadComments(inRoom: room.roomId, checkSync: false)
                            }
                        }
                    }else{
                        Qiscus.printLog(text: "error sync message")
                        if !silent {
                            QiscusDataPresenter.shared.loadComments(inRoom: room.roomId, checkSync: false)
                        }
                    }
                })
            }
        }
    }

    open func syncChat(backgroundFetch:Bool = false, trigger:Bool = false) {
        DispatchQueue.global().async {
            let loadURL = QiscusConfig.SYNC_URL
            let parameters:[String: AnyObject] =  [
                "last_received_comment_id"  : QiscusMe.sharedInstance.lastCommentId as AnyObject,
                "token" : qiscus.config.USER_TOKEN as AnyObject,
            ]
            Qiscus.printLog(text: "sync chat parameters: \n\(parameters)")
            Qiscus.printLog(text: "sync chat url: \n\(loadURL)")
            Qiscus.shared.syncing = true
        
            Alamofire.request(loadURL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
                Qiscus.printLog(text: "sync chat response: \n\(responseData)")
                if let response = responseData.result.value {
                    let json = JSON(response)
                    let results = json["results"]
                    let error = json["error"]
                    if results != JSON.null{
                        let comments = json["results"]["comments"].arrayValue
                        if comments.count > 0 {
                            DispatchQueue.global().async {
                                for newComment in comments.reversed() {
                                    let topicId = newComment["topic_id"].intValue
                                    let roomId = newComment["room_id"].intValue
                                    let id = newComment["id"].intValue
                                    let uId = newComment["unique_temp_id"].stringValue
                                    var saved = false
                                    var comment = QiscusComment()
                                    
                                    if let dbComment = QiscusComment.comment(withUniqueId: uId) {
                                        comment = dbComment
                                    }else{
                                        comment = QiscusComment.newComment(withId: id, andUniqueId: uId)
                                        comment.commentText = newComment["message"].stringValue
                                        comment.showLink = !(newComment["disable_link_preview"].boolValue)
                                        saved = true
                                    }
                                    
                                    let email = newComment["email"].stringValue
                                    QiscusMe.updateLastCommentId(commentId: id)
                                    comment.commentBeforeId = newComment["comment_before_id"].intValue
                                    comment.commentSenderEmail = email
                                    comment.commentTopicId = topicId
                                    comment.commentCreatedAt = Double(newComment["unix_timestamp"].doubleValue)
                                    
                                    if newComment["type"].string == "buttons" {
                                        comment.commentText = newComment["payload"]["text"].stringValue
                                        comment.commentButton = "\(newComment["payload"]["buttons"])"
                                        comment.commentType = .postback
                                    }else if newComment["type"].string == "account_linking" {
                                        comment.commentButton = "\(newComment["payload"])"
                                        comment.commentType = .account
                                    }else if newComment["type"].string == "reply" {
                                        if comment.commentButton == "" {
                                            comment.commentButton = "\(newComment["payload"])"
                                        }
                                        comment.commentType = .reply
                                    }else if newComment["type"].string == "system_event"{
                                        comment.commentType = .system
                                    }else if comment.commentIsFile {
                                        comment.commentType = .attachment
                                    }else{
                                        comment.commentType = .text
                                    }

                                    comment.updateCommentStatus(.sent)
                                    
                                    if saved{
                                        if let chatView = Qiscus.shared.chatViews[roomId] {
                                            let presenter = QiscusCommentPresenter.getPresenter(forComment: comment)
                                            if let room = QiscusRoom.room(withId: roomId){
                                                chatView.dataPresenter(gotNewData: presenter, inRoom: room, realtime: true)
                                            }
                                        }
//                                        let service = QiscusCommentClient.shared
//                                        if let roomDelegate = service.roomDelegate {
//                                            Qiscus.uiThread.async {
//                                                roomDelegate.gotNewComment(comment)
//                                            }
//                                        }
                                    }
                                    if let participant = QiscusParticipant.getParticipant(withEmail: email, roomId: roomId){
                                        participant.updateLastReadCommentId(commentId: comment.commentId)
                                    }
                                    
                                    if let user = QiscusUser.getUserWithEmail(email) {
                                        var userChanged = false
                                        if user.userAvatarURL != newComment["user_avatar_url"].stringValue{
                                            user.updateUserAvatarURL(newComment["user_avatar_url"].stringValue)
                                        }
                                        if user.userFullName != newComment["username"].stringValue{
                                            userChanged = true
                                            user.updateUserFullName(newComment["username"].stringValue)
                                        }
                                        if userChanged {
                                            if let chatView = Qiscus.shared.chatViews[roomId] {
                                                chatView.dataPresenter(didChangeUser: QiscusUser.copyUser(user: user), onUserWithEmail: email)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }else if error != JSON.null{
                        Qiscus.printLog(text: "error sync message: \(error)")
                    }
                    Qiscus.shared.syncing = false
                }
                else{
                    Qiscus.printLog(text: "error sync message")
                    
                }
            })
        }
    }
    
    open func loadMore(room: QiscusRoom, fromComment commentId: Int = 0){ //
        let topicId = room.roomLastCommentTopicId
        let loadURL = QiscusConfig.LOAD_URL
        var parameters =  [
            "topic_id" : topicId as AnyObject,
            "token" : qiscus.config.USER_TOKEN as AnyObject
        ]
        if commentId > 0 {
            parameters["last_comment_id"] = commentId as AnyObject
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
                    var newMessageCount = 0
                    if comments.count > 0 {
                        for newComment in comments {
                            let id = newComment["id"].intValue
                            let uId = newComment["unique_temp_id"].stringValue
                            var comment = QiscusComment()
                            if let dbComment = QiscusComment.comment(withUniqueId: uId) {
                                comment = dbComment
                            }else{
                                comment = QiscusComment.newComment(withId: id, andUniqueId: uId)
                                comment.commentText = newComment["message"].stringValue
                                comment.showLink = !(newComment["disable_link_preview"].boolValue)
                                newMessageCount += 1
                            }
                            
                            let email = newComment["email"].stringValue
                            comment.commentBeforeId = newComment["comment_before_id"].intValue
                            comment.commentSenderEmail = email
                            comment.commentTopicId = topicId
                            comment.commentCreatedAt = Double(newComment["unix_timestamp"].doubleValue)
                            if newComment["type"].string == "buttons" {
                                comment.commentText = newComment["payload"]["text"].stringValue
                                comment.commentButton = "\(newComment["payload"]["buttons"])"
                                comment.commentType = .postback
                            }else if newComment["type"].string == "account_linking" {
                                comment.commentButton = "\(newComment["payload"])"
                                comment.commentType = .account
                            }else if newComment["type"].string == "reply" {
                                if comment.commentButton == "" {
                                    comment.commentButton = "\(newComment["payload"])"
                                }
                                comment.commentType = .reply
                            }else if newComment["type"].string == "system_event"{
                                comment.commentType = .system
                            }else if comment.commentIsFile {
                                comment.commentType = .attachment
                            }else{
                                comment.commentType = .text
                            }

                            comment.updateCommentStatus(.sent)

                            if let user = QiscusUser.getUserWithEmail(email) {
                                var userChanged = false
                                if user.userAvatarURL != newComment["user_avatar_url"].stringValue{
                                    user.updateUserAvatarURL(newComment["user_avatar_url"].stringValue)
                                }
                                if user.userFullName != newComment["username"].stringValue{
                                    userChanged = true
                                    user.updateUserFullName(newComment["username"].stringValue)
                                }
                                if userChanged {
                                    if let room = QiscusRoom.room(withLastTopicId: topicId){
                                        if let chatView = Qiscus.shared.chatViews[room.roomId] {
                                            chatView.dataPresenter(didChangeUser: QiscusUser.copyUser(user: user), onUserWithEmail: email)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    self.delegate?.qiscusService(didFinishLoadMore: room, dataCount: newMessageCount, from: commentId)
                }else if error != JSON.null{
                    Qiscus.printLog(text: "error loadMore: \(error)")
                    self.delegate?.qiscusService(didFailLoadMore: room)
                }
            }else{
                Qiscus.printLog(text: "fail to LoadMore Data")
                self.delegate?.qiscusService(didFailLoadMore: room)
            }
        })
    }
    open func getRoom(withID roomId:Int, triggerDelegate:Bool = false, withMessage:String? = nil){
        func room(){
            let loadURL = QiscusConfig.ROOM_REQUEST_ID_URL
            
            let parameters:[String : AnyObject] =  [
                "id" : roomId as AnyObject,
                "token"  : qiscus.config.USER_TOKEN as AnyObject
            ]
            Qiscus.printLog(text: "get room with id url: \(loadURL)")
            Qiscus.printLog(text: "get room with id parameters: \(parameters)")
            Alamofire.request(loadURL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
                Qiscus.printLog(text: "response data: \(responseData)")
                if let response = responseData.result.value {
                    Qiscus.printLog(text: "get room api response:\n\(response)")
                    let json = JSON(response)
                    let results = json["results"]
                    let error = json["error"]
                    
                    if results != JSON.null{
                        Qiscus.printLog(text: "getListComment with id response: \(responseData)")
                        let roomData = results["room"]
                        let room = QiscusRoom.room(fromJSON: roomData)
                        let commentData = results["comments"].arrayValue
                        let topicId = roomData["last_topic_id"].intValue
                        
                        if let chatView = Qiscus.shared.chatViews[roomId] {
                            for payload in commentData{
                                let id = payload["id"].intValue
                                let uId = payload["unique_temp_id"].stringValue
                                let email = payload["email"].stringValue
                                
                                var comment = QiscusComment()
                                if let old = QiscusComment.comment(withUniqueId: uId){
                                    comment = old
                                }else{
                                    comment = QiscusComment.newComment(withId: id, andUniqueId: uId)
                                    comment.commentText = payload["message"].stringValue
                                    comment.showLink = !(payload["disable_link_preview"].boolValue)
                                }
                                comment.commentId = id
                                comment.commentBeforeId = payload["comment_before_id"].intValue
                                comment.commentSenderEmail = email
                                comment.commentTopicId = topicId
                                comment.commentCreatedAt = Double(payload["unix_timestamp"].doubleValue)
                                
                                if payload["type"].string == "buttons" {
                                    comment.commentText = payload["payload"]["text"].stringValue
                                    comment.commentButton = "\(payload["payload"]["buttons"])"
                                    comment.commentType = .postback
                                }else if payload["type"].string == "account_linking" {
                                    comment.commentButton = "\(payload["payload"])"
                                    comment.commentType = .account
                                }else if payload["type"].string == "reply" {
                                    if comment.commentButton == "" {
                                        comment.commentButton = "\(payload["payload"])"
                                    }
                                    comment.commentType = .reply
                                }else if payload["type"].string == "system_event"{
                                    comment.commentType = .system
                                }else if comment.commentIsFile {
                                    comment.commentType = .attachment
                                }else{
                                    comment.commentType = .text
                                }

                                comment.updateCommentStatus(.sent)
                                if let participant = QiscusParticipant.getParticipant(withEmail: email, roomId: room.roomId){
                                    participant.updateLastReadCommentId(commentId: comment.commentId)
                                }
                            }
                            if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                                roomDelegate.didFinishLoadRoom(onRoom: room)
                            }
                            
                            QiscusUIConfiguration.sharedInstance.topicId = topicId
                            chatView.topicId = topicId
                            
                            if let participants = roomData["participants"].array {
                                var participantArray = [String]()
                                for participant in participants {
                                    let userEmail = participant["email"].stringValue
                                    let userFullName = participant["username"].stringValue
                                    let userAvatarURL = participant["avatar_url"].stringValue
                                    
                                    if let member = QiscusUser.getUserWithEmail(userEmail){
                                        if member.userFullName != userFullName {
                                            member.updateUserFullName(userFullName)
                                            let user = QiscusUser.copyUser(user: member)
                                            user.userFullName = userFullName
                                            chatView.dataPresenter(didChangeUser: user, onUserWithEmail: userEmail)
                                        }
                                        if member.userAvatarURL != userAvatarURL {
                                            member.updateUserAvatarURL(userAvatarURL)
                                        }
                                    }else{
                                        let user = QiscusUser()
                                        user.userEmail = userEmail
                                        user.userFullName = userFullName
                                        user.userAvatarURL = userAvatarURL
                                        let _ = user.saveUser()
                                    }
                                    if QiscusParticipant.getParticipant(withEmail: userEmail, roomId: room.roomId) == nil {
                                        QiscusParticipant.addParticipant(userEmail, roomId: room.roomId)
                                    }
                                    participantArray.append(userEmail)
                                }
                                
                                let roomMembers = QiscusParticipant.getParticipant(onRoomId: room.roomId)
                                for member in roomMembers {
                                    if !participantArray.contains(member.participantEmail) {
                                        member.remove()
                                    }
                                }
                                self.delegate?.qiscusService(didChangeRoom: room, onRoomWithId: room.roomId)
                            }
//                            chatView.loadTitle()
                            self.commentDelegate?.finishedLoadFromAPI(topicId)
                            self.delegate?.qiscusService(didFinishLoadRoom: room, withMessage: withMessage)
                        }
                    }else if error != JSON.null{
                        Qiscus.printLog(text: "error getRoom: \(error)")
                        var errorMessage = "Failed to load room data"
                        if let errorData = json["detailed_messages"].array {
                            if let message = errorData[0].string {
                                errorMessage = message
                            }
                        }else if let errorData = json["message"].string {
                            errorMessage = errorData
                            if errorData.contains("not found") {
                                errorMessage = "Fial to load room, user not found"
                            }
                        }
                        self.delegate?.qiscusService(didFailLoadRoom: errorMessage)
                        if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                            roomDelegate.didFailLoadRoom(withError: errorMessage)
                        }
                    }else{
                        let errorMessage = "Failed to load room data"
                        self.delegate?.qiscusService(didFailLoadRoom: errorMessage)
                        if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                            roomDelegate.didFailLoadRoom(withError: errorMessage)
                        }
                    }
                }else{
                    self.delegate?.qiscusService(didFailLoadRoom: "Failed to load room data")
                    if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                        roomDelegate.didFailLoadRoom(withError: "fail to get chat room")
                    }
                }
            })
        }
        if Qiscus.isLoggedIn {
            room()
        }else{
            reconnect {
                room()
            }
        }
        
    }
    open func getListComment(withUsers users:[String], triggerDelegate:Bool = true, loadMore:Bool = false, distincId:String? = nil, optionalData:String? = nil, withMessage:String? = nil){ //
        func listComment(){
            let loadURL = QiscusConfig.ROOM_REQUEST_URL
            
            var parameters:[String : AnyObject] =  [
                "emails" : users as AnyObject,
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
                        Qiscus.printLog(text: "getListComment with user response: \(responseData)")
                        let roomData = results["room"]
                        let room = QiscusRoom.room(fromJSON: roomData)
                        let commentData = results["comments"].arrayValue
                        let topicId = roomData["last_topic_id"].intValue
                        let users = parameters["emails"] as! [String]
                        
                        
                        for payload in commentData{
                            let id = payload["id"].intValue
                            let uId = payload["unique_temp_id"].stringValue
                            let email = payload["email"].stringValue
                            
                            var comment = QiscusComment()
                            if let old = QiscusComment.comment(withUniqueId: uId) {
                                comment = old
                            }else{
                                comment = QiscusComment.newComment(withId: id, andUniqueId: uId)
                                comment.commentText = payload["message"].stringValue
                                comment.showLink = !(payload["disable_link_preview"].boolValue)
                            }
                            comment.commentId = id
                            comment.commentBeforeId = payload["comment_before_id"].intValue
                            comment.commentSenderEmail = email
                            comment.commentTopicId = topicId
                            comment.commentCreatedAt = Double(payload["unix_timestamp"].doubleValue)
                            
                            if payload["type"].string == "buttons" {
                                comment.commentText = payload["payload"]["text"].stringValue
                                comment.commentButton = "\(payload["payload"]["buttons"])"
                                comment.commentType = .postback
                            }else if payload["type"].string == "account_linking" {
                                comment.commentButton = "\(payload["payload"])"
                                comment.commentType = .account
                            }else if payload["type"].string == "reply" {
                                if comment.commentButton == "" {
                                    comment.commentButton = "\(payload["payload"])"
                                }
                                comment.commentType = .reply
                            }else if payload["type"].string == "system_event"{
                                comment.commentType = .system
                            }else if comment.commentIsFile {
                                comment.commentType = .attachment
                            }else{
                                comment.commentType = .text
                            }

                            comment.updateCommentStatus(.sent)
                            if let participant = QiscusParticipant.getParticipant(withEmail: email, roomId: room.roomId){
                                participant.updateLastReadCommentId(commentId: comment.commentId)
                            }
                        }
                        
                        if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                            roomDelegate.didFinishLoadRoom(onRoom: room)
                        }
                        
                        if users.count == 1 {
                            room.user = users.first!
                        }
                        if distincId != nil {
                            room.distinctId = distincId!
                        }
                        QiscusUIConfiguration.sharedInstance.topicId = topicId
                        
                        
                        if let participants = roomData["participants"].array {
                            var participantArray = [String]()
                            for participant in participants {
                                let userEmail = participant["email"].stringValue
                                let userFullName = participant["username"].stringValue
                                let userAvatarURL = participant["avatar_url"].stringValue
                                
                                if let member = QiscusUser.getUserWithEmail(userEmail){
                                    if member.userFullName != userFullName {
                                        member.updateUserFullName(userFullName)
                                        let user = QiscusUser.copyUser(user: member)
                                        user.userFullName = userFullName
                                        if let chatView = Qiscus.shared.chatViews[room.roomId] {
                                            chatView.dataPresenter(didChangeUser: user, onUserWithEmail: userEmail)
                                        }
                                    }
                                    if member.userAvatarURL != userAvatarURL {
                                        member.updateUserAvatarURL(userAvatarURL)
                                    }
                                }else{
                                    let user = QiscusUser()
                                    user.userEmail = userEmail
                                    user.userFullName = userFullName
                                    user.userAvatarURL = userAvatarURL
                                    let _ = user.saveUser()
                                }
                                if QiscusParticipant.getParticipant(withEmail: userEmail, roomId: room.roomId) == nil {
                                    QiscusParticipant.addParticipant(userEmail, roomId: room.roomId)
                                }
                                participantArray.append(userEmail)
                            }
                            
                            let roomMembers = QiscusParticipant.getParticipant(onRoomId: room.roomId)
                            for member in roomMembers {
                                if !participantArray.contains(member.participantEmail) {
                                    member.remove()
                                }
                            }
                            self.delegate?.qiscusService(didChangeRoom: room, onRoomWithId: room.roomId)
                        }
                        
                        
                        self.commentDelegate?.finishedLoadFromAPI(topicId)
                        self.delegate?.qiscusService(didFinishLoadRoom: room, withMessage: withMessage)
                    }else if error != JSON.null{
                        Qiscus.printLog(text: "error getListComment: \(error)")
                        var errorMessage = "Failed to load room data"
                        if let errorData = json["detailed_messages"].array {
                            if let message = errorData[0].string {
                                errorMessage = message
                            }
                        }else if let errorData = json["message"].string {
                            errorMessage = errorData
                            if errorMessage.contains("not found"){
                                errorMessage = "Fail to load room, user not found"
                            }
                            
                        }
                        self.delegate?.qiscusService(didFailLoadRoom: errorMessage)
                        if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                            roomDelegate.didFailLoadRoom(withError: errorMessage)
                        }
                    }else{
                        let errorMessage = "Failed to load room data"
                        self.delegate?.qiscusService(didFailLoadRoom: errorMessage)
                        if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                            roomDelegate.didFailLoadRoom(withError: errorMessage)
                        }
                    }
                }else{
                    self.delegate?.qiscusService(didFailLoadRoom: "Failed to load room data")
                    if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                        roomDelegate.didFailLoadRoom(withError: "fail to create or get chat room")
                    }
                }
            })
        }
        if Qiscus.isLoggedIn {
            listComment()
        }else{
            reconnect {
                listComment()
            }
        }
    }
    open func getListComment(withRoomUniqueId uniqueId:String, title:String, avatarURL:String, withMessage:String? = nil){ //
        func listComment(){
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
                        Qiscus.printLog(text: "getListComment with user response: \(responseData)")
                        let roomData = results["room"]
                        let room = QiscusRoom.room(fromJSON: roomData)
                        let commentData = results["comments"].arrayValue
                        let topicId = roomData["last_topic_id"].intValue
                        
                        
                        for payload in commentData{
                            let id = payload["id"].intValue
                            let uId = payload["unique_temp_id"].stringValue
                            let email = payload["email"].stringValue
                            
                            var comment = QiscusComment()
                            if let old = QiscusComment.comment(withUniqueId: uId) {
                                comment = old
                            }else{
                                comment = QiscusComment.newComment(withId: id, andUniqueId: uId)
                                comment.commentText = payload["message"].stringValue
                                comment.showLink = !(payload["disable_link_preview"].boolValue)
                            }
                            comment.commentId = id
                            comment.commentBeforeId = payload["comment_before_id"].intValue
                            comment.commentSenderEmail = email
                            comment.commentTopicId = topicId
                            comment.commentCreatedAt = Double(payload["unix_timestamp"].doubleValue)
                            
                            if payload["type"].string == "buttons" {
                                comment.commentText = payload["payload"]["text"].stringValue
                                comment.commentButton = "\(payload["payload"]["buttons"])"
                                comment.commentType = .postback
                            }else if payload["type"].string == "account_linking" {
                                comment.commentButton = "\(payload["payload"])"
                                comment.commentType = .account
                            }else if payload["type"].string == "reply" {
                                if comment.commentButton == "" {
                                    comment.commentButton = "\(payload["payload"])"
                                }
                                comment.commentType = .reply
                            }else if payload["type"].string == "system_event"{
                                comment.commentType = .system
                            }else if comment.commentIsFile {
                                comment.commentType = .attachment
                            }else{
                                comment.commentType = .text
                            }
                            
                            comment.updateCommentStatus(.sent)
                            if let participant = QiscusParticipant.getParticipant(withEmail: email, roomId: room.roomId){
                                participant.updateLastReadCommentId(commentId: comment.commentId)
                            }
                        }
                        
                        if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                            roomDelegate.didFinishLoadRoom(onRoom: room)
                        }
                        
                        if let participants = roomData["participants"].array {
                            var participantArray = [String]()
                            for participant in participants {
                                let userEmail = participant["email"].stringValue
                                let userFullName = participant["username"].stringValue
                                let userAvatarURL = participant["avatar_url"].stringValue
                                
                                if let member = QiscusUser.getUserWithEmail(userEmail){
                                    if member.userFullName != userFullName {
                                        member.updateUserFullName(userFullName)
                                        let user = QiscusUser.copyUser(user: member)
                                        user.userFullName = userFullName
                                        if let chatView = Qiscus.shared.chatViews[room.roomId] {
                                            chatView.dataPresenter(didChangeUser: user, onUserWithEmail: userEmail)
                                        }
                                    }
                                    if member.userAvatarURL != userAvatarURL {
                                        member.updateUserAvatarURL(userAvatarURL)
                                    }
                                }else{
                                    let user = QiscusUser()
                                    user.userEmail = userEmail
                                    user.userFullName = userFullName
                                    user.userAvatarURL = userAvatarURL
                                    let _ = user.saveUser()
                                }
                                if QiscusParticipant.getParticipant(withEmail: userEmail, roomId: room.roomId) == nil {
                                    QiscusParticipant.addParticipant(userEmail, roomId: room.roomId)
                                }
                                participantArray.append(userEmail)
                            }
                            
                            let roomMembers = QiscusParticipant.getParticipant(onRoomId: room.roomId)
                            for member in roomMembers {
                                if !participantArray.contains(member.participantEmail) {
                                    member.remove()
                                }
                            }
                            self.delegate?.qiscusService(didChangeRoom: room, onRoomWithId: room.roomId)
                        }
                        
                        
                        self.commentDelegate?.finishedLoadFromAPI(topicId)
                        self.delegate?.qiscusService(didFinishLoadRoom: room, withMessage: withMessage)
                    }else if error != JSON.null{
                        Qiscus.printLog(text: "error getListComment: \(error)")
                        var errorMessage = "Failed to load room data"
                        if let errorData = json["detailed_messages"].array {
                            if let message = errorData[0].string {
                                errorMessage = message
                            }
                        }else if let errorData = json["message"].string {
                            errorMessage = errorData
                            if errorMessage.contains("not found"){
                                errorMessage = "Fail to load room, user not found"
                            }
                            
                        }
                        self.delegate?.qiscusService(didFailLoadRoom: errorMessage)
                        if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                            roomDelegate.didFailLoadRoom(withError: errorMessage)
                        }
                    }else{
                        let errorMessage = "Failed to load room data"
                        self.delegate?.qiscusService(didFailLoadRoom: errorMessage)
                        if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                            roomDelegate.didFailLoadRoom(withError: errorMessage)
                        }
                    }
                }else{
                    self.delegate?.qiscusService(didFailLoadRoom: "Failed to load room data")
                    if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                        roomDelegate.didFailLoadRoom(withError: "fail to create or get chat room")
                    }
                }
            })
        }
        if Qiscus.isLoggedIn {
            listComment()
        }else{
            reconnect {
                listComment()
            }
        }
    }
    // MARK: - Create New Room
    open func createNewRoom(withUsers users:[String], roomName:String, optionalData:String? = nil, withMessage:String? = nil){ //
        func newGroupRoom(){
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
                        Qiscus.printLog(text: "getListComment with user response: \(responseData)")
                        let roomData = results["room"]
                        let room = QiscusRoom.room(fromJSON: roomData)
                        let commentData = results["comments"].arrayValue
                        let topicId = roomData["last_topic_id"].intValue
                        
                        for payload in commentData{
                            let id = payload["id"].intValue
                            let uId = payload["unique_temp_id"].stringValue
                            let email = payload["email"].stringValue
                            
                            var comment = QiscusComment()
                            if let old = QiscusComment.comment(withUniqueId: uId){
                                comment = old
                            }else{
                                comment = QiscusComment.newComment(withId: id, andUniqueId: uId)
                                comment.commentText = payload["message"].stringValue
                                comment.showLink = !(payload["disable_link_preview"].boolValue)
                            }
                            comment.commentId = id
                            comment.commentBeforeId = payload["comment_before_id"].intValue
                            comment.commentSenderEmail = email
                            comment.commentTopicId = topicId
                            comment.commentCreatedAt = Double(payload["unix_timestamp"].doubleValue)
                            if payload["type"].string == "buttons" {
                                comment.commentText = payload["payload"]["text"].stringValue
                                comment.commentButton = "\(payload["payload"]["buttons"])"
                                comment.commentType = .postback
                            }else if payload["type"].string == "account_linking" {
                                comment.commentButton = "\(payload["payload"])"
                                comment.commentType = .account
                            }else if payload["type"].string == "reply" {
                                if comment.commentButton == "" {
                                    comment.commentButton = "\(payload["payload"])"
                                }
                                comment.commentType = .reply
                            }else if payload["type"].string == "system_event"{
                                comment.commentType = .system
                            }else if comment.commentIsFile {
                                comment.commentType = .attachment
                            }else{
                                comment.commentType = .text
                            }
                            comment.updateCommentStatus(.sent)
                            if let participant = QiscusParticipant.getParticipant(withEmail: email, roomId: room.roomId){
                                participant.updateLastReadCommentId(commentId: comment.commentId)
                            }
                            
                        }
                        
                        if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                            roomDelegate.didFinishLoadRoom(onRoom: room)
                        }
                        
                        if users.count == 1 {
                            room.user = users.first!
                        }
                        
                        QiscusUIConfiguration.sharedInstance.topicId = topicId
                        
                        
                        if let participants = roomData["participants"].array {
                            var participantArray = [String]()
                            for participant in participants {
                                let userEmail = participant["email"].stringValue
                                let userFullName = participant["username"].stringValue
                                let userAvatarURL = participant["avatar_url"].stringValue
                                
                                if let member = QiscusUser.getUserWithEmail(userEmail){
                                    if member.userFullName != userFullName {
                                        member.updateUserFullName(userFullName)
                                        let user = QiscusUser.copyUser(user: member)
                                        user.userFullName = userFullName
                                        if let chatView = Qiscus.shared.chatViews[room.roomId] {
                                            chatView.dataPresenter(didChangeUser: user, onUserWithEmail: userEmail)
                                        }
                                    }
                                    if member.userAvatarURL != userAvatarURL {
                                        member.updateUserAvatarURL(userAvatarURL)
                                    }
                                }else{
                                    let user = QiscusUser()
                                    user.userEmail = userEmail
                                    user.userFullName = userFullName
                                    user.userAvatarURL = userAvatarURL
                                    let _ = user.saveUser()
                                    //QiscusParticipant.addParticipant(user.userEmail, roomId: room.roomId)
                                }
                                if QiscusParticipant.getParticipant(withEmail: userEmail, roomId: room.roomId) == nil {
                                    QiscusParticipant.addParticipant(userEmail, roomId: room.roomId)
                                }
                                participantArray.append(userEmail)
                            }
                            
                            let roomMembers = QiscusParticipant.getParticipant(onRoomId: room.roomId)
                            for member in roomMembers {
                                if !participantArray.contains(member.participantEmail) {
                                    member.remove()
                                }
                            }
                            self.delegate?.qiscusService(didChangeRoom: room, onRoomWithId: room.roomId)
                        }
                        
                        self.commentDelegate?.finishedLoadFromAPI(topicId)
                        self.delegate?.qiscusService(didFinishLoadRoom: room, withMessage: withMessage)
                        if withMessage != nil {
                            self.postMessage(message: withMessage!, topicId: topicId)
                        }
                    }else if error != JSON.null{
                        Qiscus.printLog(text: "error getListComment: \(error)")
                        var errorMessage = "Failed to load room data"
                        if let errorData = json["detailed_messages"].array {
                            if let message = errorData[0].string {
                                errorMessage = message
                            }
                        }else if let errorData = json["message"].string {
                            errorMessage = errorData
                            if errorMessage.contains("not found"){
                                errorMessage = "Fail to load room, user not found"
                            }
                            
                        }
                        self.delegate?.qiscusService(didFailLoadRoom: errorMessage)
                        if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                            roomDelegate.didFailLoadRoom(withError: errorMessage)
                        }
                    }else{
                        let errorMessage = "Failed to load room data"
                        self.delegate?.qiscusService(didFailLoadRoom: errorMessage)
                        if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                            roomDelegate.didFailLoadRoom(withError: errorMessage)
                        }
                    }
                }else{
                    self.delegate?.qiscusService(didFailLoadRoom: "Failed to load room data")
                    if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                        roomDelegate.didFailLoadRoom(withError: "fail to create chat room")
                    }
                }
            })
        }
        if Qiscus.isLoggedIn {
            newGroupRoom()
        }else{
            reconnect {
                newGroupRoom()
            }
        }
    }
    
    // MARK: - Update Room
    open func updateRoom(withRoomId roomId:Int, roomName:String? = nil, roomAvatarURL:String? = nil, roomAvatar:UIImage? = nil, roomOptions:String? = nil){
        func update(){
            if roomName != nil || roomAvatarURL != nil || roomOptions != nil {
                let requestURL = QiscusConfig.UPDATE_ROOM_URL
                
                var parameters:[String : AnyObject] = [
                    "id" : roomId as AnyObject,
                    "token" : qiscus.config.USER_TOKEN as AnyObject
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
                        
                        if results != JSON.null{
                            Qiscus.printLog(text: "getListComment with user response: \(responseData)")
                            let changed = json["results"]["changed"].boolValue
                            if changed {
                                let roomData = json["results"]["room"]
                                var room = QiscusRoom()
                                var roomExist = false
                                if let chatRoom = QiscusRoom.room(withId: roomData["id"].intValue){
                                    roomExist = true
                                    room = chatRoom
                                }else{
                                    room = QiscusRoom.room(fromJSON: roomData)
                                }
                                
                                if roomExist {
                                    if roomName != nil {
                                        room.roomName = roomName!
                                    }
                                    if roomOptions != nil {
                                        room.optionalData = roomOptions!
                                    }
                                    if roomAvatarURL != nil {
                                        room.updateRoomAvatar(roomAvatarURL!, avatarImage: roomAvatar)
                                    }
                                }
                                
                                let topicId = room.roomLastCommentTopicId
                                
                                if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                                    roomDelegate.didFinishUpdateRoom(onRoom: room)
                                }
                                let comments = json["results"]["comments"].arrayValue
                                if comments.count > 0 {
                                    for payload in comments {
                                        var comment = QiscusComment()
                                        let id = payload["id"].intValue
                                        let uid = payload["unique_temp_id"].stringValue
                                        let email = payload["email"].stringValue
                                        if let old = QiscusComment.comment(withUniqueId: uid){
                                            comment = old
                                        }else{
                                            comment = QiscusComment.newComment(withId: id, andUniqueId: uid)
                                        }
                                        comment.commentId = id
                                        comment.commentBeforeId = payload["comment_before_id"].intValue
                                        comment.commentText = payload["message"].stringValue
                                        comment.showLink = !(payload["disable_link_preview"].boolValue)
                                        comment.commentSenderEmail = email
                                        comment.commentTopicId = topicId
                                        comment.commentCreatedAt = Double(payload["unix_timestamp"].doubleValue)
                                        if payload["type"].string == "buttons" {
                                            comment.commentText = payload["payload"]["text"].stringValue
                                            comment.commentButton = "\(payload["payload"]["buttons"])"
                                            comment.commentType = .postback
                                        }else if payload["type"].string == "account_linking" {
                                            comment.commentButton = "\(payload["payload"])"
                                            comment.commentType = .account
                                        }else if payload["type"].string == "reply" {
                                            if comment.commentButton == "" {
                                                comment.commentButton = "\(payload["payload"])"
                                            }
                                            comment.commentType = .reply
                                        }else if payload["type"].string == "system_event"{
                                            comment.commentType = .system
                                        }else if comment.commentIsFile {
                                            comment.commentType = .attachment
                                        }else{
                                            comment.commentType = .text
                                        }
                                    }
                                }
                                
                                if let participants = roomData["participants"].array {
                                    var participantArray = [String]()
                                    for participant in participants {
                                        let userEmail = participant["email"].stringValue
                                        let userFullName = participant["username"].stringValue
                                        let userAvatarURL = participant["avatar_url"].stringValue
                                        
                                        if let member = QiscusUser.getUserWithEmail(userEmail){
                                            if member.userFullName != userFullName {
                                                member.updateUserFullName(userFullName)
                                                let user = QiscusUser.copyUser(user: member)
                                                user.userFullName = userFullName
                                                if let chatView = Qiscus.shared.chatViews[room.roomId] {
                                                    chatView.dataPresenter(didChangeUser: user, onUserWithEmail: userEmail)
                                                }
                                            }
                                            if member.userAvatarURL != userAvatarURL {
                                                member.updateUserAvatarURL(userAvatarURL)
                                            }
                                        }else{
                                            let user = QiscusUser()
                                            user.userEmail = userEmail
                                            user.userFullName = userFullName
                                            user.userAvatarURL = userAvatarURL
                                            let _ = user.saveUser()
                                        }
                                        if QiscusParticipant.getParticipant(withEmail: userEmail, roomId: room.roomId) == nil {
                                            QiscusParticipant.addParticipant(userEmail, roomId: room.roomId)
                                        }
                                        participantArray.append(userEmail)
                                    }
                                    
                                    let roomMembers = QiscusParticipant.getParticipant(onRoomId: room.roomId)
                                    for member in roomMembers {
                                        if !participantArray.contains(member.participantEmail) {
                                            member.remove()
                                        }
                                    }
                                    self.delegate?.qiscusService(didChangeRoom: room, onRoomWithId: room.roomId)
                                }

                                if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                                    roomDelegate.didFinishUpdateRoom(onRoom: room)
                                }
                            }
                        }else if error != JSON.null{
                            Qiscus.printLog(text: "error update chat room: \(error)")
                            var errorMessage = "Failed to load room data"
                            if let errorData = json["detailed_messages"].array {
                                if let message = errorData[0].string {
                                    errorMessage = message
                                }
                            }else if let errorData = json["message"].string {
                                errorMessage = errorData
                            }
                            if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                                roomDelegate.didFailUpdateRoom(withError: errorMessage)
                            }
                        }
                    }else{
                        Qiscus.printLog(text: "fail to update chat room")
                        if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                            roomDelegate.didFailUpdateRoom(withError: "fail to update chat room")
                        }
                    }
                })
            }else{
                // fail update room with error no data
                if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                    roomDelegate.didFailUpdateRoom(withError: "fail to update chat with no data passed")
                }
            }
        }
        if Qiscus.isLoggedIn {
            update()
        }else{
            reconnect {
                update()
            }
        }
    }
    
    // MARK: - Message Status
    open func publishMessageStatus(onComment commentId:Int, roomId:Int, status:QiscusCommentStatus, withCompletion: @escaping ()->Void){
        DispatchQueue.global().async {
            if status == QiscusCommentStatus.delivered || status == QiscusCommentStatus.read{
                let loadURL = QiscusConfig.UPDATE_COMMENT_STATUS_URL
                
                var parameters:[String : AnyObject] =  [
                    "token" : qiscus.config.USER_TOKEN as AnyObject,
                    "room_id" : roomId as AnyObject,
                    ]
                
                if status == QiscusCommentStatus.delivered{
                    parameters["last_comment_received_id"] = commentId as AnyObject
                }else{
                    parameters["last_comment_read_id"] = commentId as AnyObject
                }
                Alamofire.request(loadURL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
                    if let response = responseData.result.value {
                        Qiscus.printLog(text: "publish message response:\n\(response)")
                        let json = JSON(response)
                        let results = json["results"]
                        let error = json["error"]
                        
                        if results != JSON.null{
                            Qiscus.printLog(text: "success change comment status on \(commentId) to \(status.rawValue)")
                            let roomJson = results["room"]
                            let room = QiscusRoom.room(fromJSON: roomJson)
                            let participantsJson = roomJson["participants"].arrayValue
                            var participantArray = [String]()
                            for participant in participantsJson {
                                let userEmail = participant["email"].stringValue
                                let userFullName = participant["username"].stringValue
                                let userAvatarURL = participant["avatar_url"].stringValue
                                
                                if let member = QiscusUser.getUserWithEmail(userEmail){
                                    if member.userFullName != userFullName {
                                        member.updateUserFullName(userFullName)
                                        let user = QiscusUser.copyUser(user: member)
                                        user.userFullName = userFullName
                                        if let chatView = Qiscus.shared.chatViews[roomId] {
                                            chatView.dataPresenter(didChangeUser: user, onUserWithEmail: userEmail)
                                        }
                                    }
                                    if member.userAvatarURL != userAvatarURL {
                                        member.updateUserAvatarURL(userAvatarURL)
                                    }
                                }else{
                                    let user = QiscusUser()
                                    user.userEmail = userEmail
                                    user.userFullName = userFullName
                                    user.userAvatarURL = userAvatarURL
                                    let _ = user.saveUser()
                                    //QiscusParticipant.addParticipant(user.userEmail, roomId: room.roomId)
                                }
                                if QiscusParticipant.getParticipant(withEmail: userEmail, roomId: room.roomId) == nil {
                                    QiscusParticipant.addParticipant(userEmail, roomId: room.roomId)
                                }
                                participantArray.append(userEmail)
                            }
                            
                            let roomMembers = QiscusParticipant.getParticipant(onRoomId: room.roomId)
                            for member in roomMembers {
                                if !participantArray.contains(member.participantEmail) {
                                    member.remove()
                                }
                            }
                            self.delegate?.qiscusService(didChangeRoom: room, onRoomWithId: room.roomId)
                            withCompletion()
                        }else if error != JSON.null{
                            Qiscus.printLog(text: "error update message status: \(error)")
                        }
                    }else{
                        Qiscus.printLog(text: "error update message status")
                    }
                })
            }
        }
    }
    public func syncRoom(withID roomId:Int){
        let loadURL = QiscusConfig.ROOM_REQUEST_ID_URL
        
        let parameters:[String : AnyObject] =  [
            "id" : roomId as AnyObject,
            "token"  : qiscus.config.USER_TOKEN as AnyObject
        ]
        Alamofire.request(loadURL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
            Qiscus.printLog(text: "response sync room data: \(responseData)")
            if let response = responseData.result.value {
                Qiscus.printLog(text: "sync room api response:\n\(response)")
                let json = JSON(response)
                let results = json["results"]
                
                if results != JSON.null{
                    Qiscus.printLog(text: "getListComment with id response: \(responseData)")
                    let roomData = results["room"]
                    let room = QiscusRoom.room(fromJSON: roomData)
//                    let commentData = results["comments"].arrayValue
//                    let topicId = roomData["last_topic_id"].intValue
                    
                    if let participants = roomData["participants"].array {
                        var participantArray = [String]()
                        for participant in participants {
                            let userEmail = participant["email"].stringValue
                            let userFullName = participant["username"].stringValue
                            let userAvatarURL = participant["avatar_url"].stringValue
                            
                            if let member = QiscusUser.getUserWithEmail(userEmail){
                                if member.userFullName != userFullName {
                                    member.updateUserFullName(userFullName)
                                    let user = QiscusUser.copyUser(user: member)
                                    user.userFullName = userFullName
                                    if let chatView = Qiscus.shared.chatViews[room.roomId] {
                                        chatView.dataPresenter(didChangeUser: user, onUserWithEmail: userEmail)
                                    }
                                }
                                if member.userAvatarURL != userAvatarURL {
                                    member.updateUserAvatarURL(userAvatarURL)
                                }
                            }else{
                                let user = QiscusUser()
                                user.userEmail = userEmail
                                user.userFullName = userFullName
                                user.userAvatarURL = userAvatarURL
                                let _ = user.saveUser()
                            }
                            if QiscusParticipant.getParticipant(withEmail: userEmail, roomId: room.roomId) == nil {
                                QiscusParticipant.addParticipant(userEmail, roomId: room.roomId)
                            }
                            participantArray.append(userEmail)
                        }
                        
                        let roomMembers = QiscusParticipant.getParticipant(onRoomId: room.roomId)
                        for member in roomMembers {
                            if !participantArray.contains(member.participantEmail) {
                                member.remove()
                            }
                        }
                        self.delegate?.qiscusService(didChangeRoom: room, onRoomWithId: room.roomId)
                    }
//                    for payload in commentData.reversed(){
//                        let id = payload["id"].intValue
//                        let uId = payload["unique_temp_id"].stringValue
//                        let email = payload["email"].stringValue
//                        
//                        var comment = QiscusComment()
//                        var isSaved = false
//                        if let old = QiscusComment.comment(withId: id, andUniqueId: uId){
//                            comment = old
//                        }else{
//                            comment = QiscusComment.newComment(withId: id, andUniqueId: uId)
//                            isSaved = true
//                            comment.commentText = payload["message"].stringValue
//                            comment.showLink = !(payload["disable_link_preview"].boolValue)
//                        }
//                        QiscusMe.updateLastCommentId(commentId: id)
//                        comment.commentId = id
//                        comment.commentBeforeId = payload["comment_before_id"].intValue
//                        comment.commentSenderEmail = email
//                        comment.commentTopicId = topicId
//                        comment.commentCreatedAt = Double(payload["unix_timestamp"].doubleValue)
//                        if payload["type"].string == "buttons" {
//                            comment.commentText = payload["payload"]["text"].stringValue
//                            comment.commentButton = "\(payload["payload"]["buttons"])"
//                            comment.commentType = .postback
//                        }else if payload["type"].string == "account_linking" {
//                            comment.commentButton = "\(payload["payload"])"
//                            comment.commentType = .account
//                        }else if payload["type"].string == "reply" {
//                            if comment.commentButton == "" {
//                                comment.commentButton = "\(payload["payload"])"
//                            }
//                            comment.commentType = .reply
//                        }else if comment.commentIsFile {
//                            comment.commentType = .attachment
//                        }else{
//                            comment.commentType = .text
//                        }
//                        comment.updateCommentStatus(.sent)
//                        
//                        if isSaved {
//                            DispatchQueue.global().sync{
//                                if let chatView = Qiscus.shared.chatViews[room.roomId] {
//                                    let presenter = QiscusCommentPresenter.getPresenter(forComment: comment)
//                                    chatView.dataPresenter(gotNewData: presenter, inRoom: room, realtime: true)
//                                }
//                            }
//                        }
//                        if let participant = QiscusParticipant.getParticipant(withEmail: email, roomId: room.roomId){
//                            participant.updateLastReadCommentId(commentId: comment.commentId)
//                        }
//                    }
                }
            }
        })
    }

}
