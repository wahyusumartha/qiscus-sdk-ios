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
    func qiscusService(didFinishLoadRoom inRoom:QiscusRoom)
    func qiscusService(gotNewMessage data:QiscusCommentPresenter)
    func qiscusService(didChangeContent data:QiscusCommentPresenter)
    func qiscusService(didFinishLoadMore inRoom:QiscusRoom, dataCount:Int, from commentId:Int64)
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
        if linkRequest != nil && synchronous{
            linkRequest?.cancel()
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
                        DispatchQueue.main.async {
                            withCompletion(linkData)
                        }
                    }else{
                        DispatchQueue.main.async {
                            withFailCompletion()
                        }
                    }
                }else{
                    DispatchQueue.main.async {
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
                        DispatchQueue.main.async {
                            withCompletion(linkData)
                        }
                    }else{
                        DispatchQueue.main.async {
                            withFailCompletion()
                        }
                    }
                }else{
                    DispatchQueue.main.async {
                        withFailCompletion()
                    }
                }
            })
        }
    }
    // MARK: - Login or register
    open func loginOrRegister(_ email:String = "", password:String = "", username:String? = nil, avatarURL:String? = nil){
        let manager = Alamofire.SessionManager.default
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
        
        Qiscus.apiThread.async(execute: {
            Qiscus.printLog(text: "login url: \(QiscusConfig.LOGIN_REGISTER)")
            Qiscus.printLog(text: "post parameters: \(parameters)")
            Qiscus.printLog(text: "post headers: \(QiscusConfig.sharedInstance.requestHeader)")
            let request = manager.request(QiscusConfig.LOGIN_REGISTER, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: { response in
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
            request.resume()
        })
    }
    // MARK: - Register deviceToken
    func registerDevice(withToken deviceToken: String){
        let manager = Alamofire.SessionManager.default
        
        let parameters:[String: AnyObject] = [
            "token"  : qiscus.config.USER_TOKEN as AnyObject,
            "device_token" : deviceToken as AnyObject,
            "device_platform" : "ios" as AnyObject
        ]
        
        DispatchQueue.global().async(execute: {
            Qiscus.printLog(text: "registerDevice url: \(QiscusConfig.SET_DEVICE_TOKEN_URL)")
            Qiscus.printLog(text: "post parameters: \(parameters)")
            
            let request = manager.request(QiscusConfig.SET_DEVICE_TOKEN_URL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: { response in
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
            request.resume()
        })
    }
    // MARK: - Comment Methode
    open func postMessage(message: String, topicId: Int, roomId:Int? = nil, linkData:QiscusLinkData? = nil, indexPath:IndexPath? = nil){ //
        Qiscus.logicThread.async {
            var showLink = false
            if linkData != nil{
                showLink = true
                QiscusLinkData.copyLink(link: linkData!).saveLink()
            }
            
            let comment = QiscusComment.newComment(withMessage: message, inTopicId: topicId, showLink: showLink)
        
            let commentPresenter = QiscusCommentPresenter.getPresenter(forComment: comment)
            commentPresenter.commentIndexPath = indexPath
        
            Qiscus.apiThread.async {
                self.postComment(commentPresenter, roomId: roomId, linkData:linkData)
            }
            Qiscus.uiThread.async {
                self.delegate?.qiscusService(gotNewMessage: commentPresenter)
                self.commentDelegate?.gotNewComment([comment])
            }
            if QiscusCommentClient.sharedInstance.roomDelegate != nil{
                Qiscus.uiThread.async {
                    QiscusCommentClient.sharedInstance.roomDelegate?.gotNewComment(comment)
                }
            }
        }
    }
    open func postComment(_ data:QiscusCommentPresenter, file:QiscusFile? = nil, roomId:Int? = nil, linkData:QiscusLinkData? = nil){ //
        
        let manager = Alamofire.SessionManager.default
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
        
        if roomId != nil {
            parameters["room_id"] = roomId as AnyObject?
        }
        Qiscus.apiThread.async {
            Qiscus.printLog(text: "post url: \(QiscusConfig.postCommentURL)")
            Qiscus.printLog(text: "post parameters: \(parameters)")
            Qiscus.printLog(text: "post headers: \(QiscusConfig.sharedInstance.requestHeader)")
            let request = manager.request(QiscusConfig.postCommentURL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {response in
                Qiscus.printLog(text: "post message result: \(response)")
                if let comment = data.comment {
                    switch response.result {
                    case .success:
                        if let result = response.result.value {
                            let json = JSON(result)
                            let success = (json["status"].intValue == 200)
                            
                            if success == true {
                                let commentJSON = json["results"]["comment"]
                                data.commentId = commentJSON["id"].int64Value
                                comment.commentId = commentJSON["id"].int64Value
                                
                                if comment.commentStatus == .failed || comment.commentStatusRaw < QiscusCommentStatus.sent.rawValue{
                                    comment.commentStatusRaw = QiscusCommentStatus.sent.rawValue
                                    data.commentStatus = .sent
                                }
                                let commentBeforeid = QiscusComment.getCommentBeforeIdFromJSON(commentJSON)
                                comment.commentBeforeId = commentBeforeid
                                
                                if file != nil {
                                    let thisComment = QiscusComment.getComment(withLocalId: comment.localId)
                                    if(file != nil){
                                        file?.updateCommentId(thisComment!.commentId)
                                    }
                                    self.commentDelegate?.didSuccessPostFile(comment)
                                }
                                
                                Qiscus.uiThread.async {
                                    self.delegate?.qiscusService(didChangeContent: data)
                                }
                            }else{
                                comment.commentStatusRaw = QiscusCommentStatus.failed.rawValue
                                data.commentStatus = .failed
                                if file != nil{
                                    file?.updateCommentId(comment.commentId)
                                    self.commentDelegate?.didFailedPostFile(comment)
                                }
                                Qiscus.uiThread.async {
                                    self.delegate?.qiscusService(didChangeContent: data)
                                }
                            }
                        }else{
                            comment.commentStatusRaw = QiscusCommentStatus.failed.rawValue
                            data.commentStatus = .failed
                            
                            if file != nil{
                                file?.updateCommentId(comment.commentId)
                                self.commentDelegate?.didFailedPostFile(comment)
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
                            file?.updateCommentId(comment.commentId)
                            self.commentDelegate?.didFailedPostFile(comment)
                        }
                        Qiscus.uiThread.async {
                            self.delegate?.qiscusService(didChangeContent: data)
                        }
                        Qiscus.printLog(text: "fail to post comment with error: \(error)")
                        break
                    }
                }
            })
            request.resume()
        }
    }
    
    open func downloadMedia(data:QiscusCommentPresenter, thumbImageRef:UIImage? = nil, isAudioFile:Bool = false){
        Qiscus.apiThread.async {
            let comment = data.comment!
            
            let file = QiscusFile.getCommentFileWithComment(data.comment!)!
            let manager = Alamofire.SessionManager.default
            
            file.updateIsDownloading(true)
            
            data.isDownloading = true
            Qiscus.uiThread.async {
                self.delegate?.qiscusService(didChangeContent: data)
            }
            let fileURL = file.fileURL.replacingOccurrences(of: " ", with: "%20")
            manager.request(fileURL, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil)
                .responseData(completionHandler: { response in
                    Qiscus.printLog(text: "download result: \(response)")
                    if let imageData = response.data {
                        if !isAudioFile{
                            if let image = UIImage(data: imageData) {
                                var thumbImage = UIImage()
                                if !(file.fileExtension == "gif" || file.fileExtension == "gif_"){
                                    thumbImage = QiscusFile.createThumbImage(image, fillImageSize: thumbImageRef)
                                }
                                
                                
                                DispatchQueue.main.async(execute: {
                                    file.updateDownloadProgress(1.0)
                                    file.updateIsDownloading(false)
                                })
                                
                                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
                                let directoryPath = "\(documentsPath)/Qiscus"
                                if !FileManager.default.fileExists(atPath: directoryPath){
                                    do {
                                        try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: false, attributes: nil)
                                    } catch let error as NSError {
                                        Qiscus.printLog(text: error.localizedDescription);
                                    }
                                }
                                
                                let fileName = "\(comment.commentId)-Q-\(file.fileName.replacingOccurrences(of: " ", with: "%20") as String)"
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
                                file.updateLocalPath(path)
                                file.updateThumbPath(thumbPath)
                                
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
                                
                                file.updateDownloadProgress(1.0)
                                file.updateIsDownloading(false)
                                file.updateLocalPath(path)
                                file.updateThumbPath(thumbPath)
                                
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
                            //print
                            try! imageData.write(to: URL(fileURLWithPath: path), options: [.atomic])
                            
                            file.updateDownloadProgress(1.0)
                            file.updateIsDownloading(false)
                            file.updateLocalPath(path)
                            
                            data.isDownloading = false
                            data.downloadProgress = 1
                            data.localURL = path
                            data.localFileExist = true
                            data.audioFileExist = true
                            
                            self.delegate?.qiscusService(didChangeContent: data)
                        }
                    }
                }).downloadProgress(closure: { progressData in
                    let progress = CGFloat(progressData.fractionCompleted)
                    let progressDiv = progress - data.downloadProgress
                    data.downloadProgress = progress
                    file.updateDownloadProgress(progress)
                    
                    if progressDiv > 0.1 {
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
        Qiscus.apiThread.async {
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
                                    if let file = QiscusFile.getCommentFile(comment.commentFileId) {
                                        file.updateURL(url)
                                        file.updateIsUploading(false)
                                        file.updateUploadProgress(1.0)
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
                                            if let file = QiscusFile.getCommentFile(comment.commentFileId) {
                                                file.updateURL(url)
                                                file.updateIsUploading(false)
                                                file.updateUploadProgress(1.0)
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
                                if let file = QiscusFile.getCommentFile(comment.commentFileId) {
                                    file.updateIsUploading(false)
                                    file.updateUploadProgress(0)
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
                            if let file = QiscusFile.getCommentFile(comment.commentFileId) {
                                file.updateIsUploading(true)
                                file.updateUploadProgress(progress)
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
                        if let file = QiscusFile.getCommentFile(comment.commentFileId) {
                            file.updateIsUploading(false)
                            file.updateUploadProgress(0)
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
        Qiscus.logicThread.async {
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
            let commentFile = QiscusFile()
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
            commentFile.saveCommentFile()
            commentFile.updateIsUploading(true)
            commentFile.updateUploadProgress(0.0)
            
            comment.commentFileId = commentFile.fileId
            
            let presenter = QiscusCommentPresenter.getPresenter(forComment: comment)
            presenter.isUploading = true
            presenter.uploadProgress = CGFloat(0)
            presenter.fileName = fileName
            presenter.toUpload = true
            presenter.uploadData = imageData
            Qiscus.uiThread.async {
                self.delegate?.qiscusService(gotNewMessage: presenter)
            }
            self.commentDelegate?.gotNewComment([comment])
            
            let headers = QiscusConfig.sharedInstance.requestHeader
            
            var urlUpload = URLRequest(url: URL(string: QiscusConfig.UPLOAD_URL)!)
            if headers.count > 0 {
                for (key,value) in headers {
                    urlUpload.setValue(value, forHTTPHeaderField: key)
                }
            }
            urlUpload.httpMethod = "POST"
            Qiscus.apiThread.async {
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
                                    
                                    commentFile.updateURL(url)
                                    commentFile.updateIsUploading(false)
                                    commentFile.updateUploadProgress(1.0)
                                    
                                    let presenter = QiscusCommentPresenter.getPresenter(forComment: comment)
                                    presenter.isUploaded = true
                                    presenter.isUploading = false
                                    presenter.uploadProgress = CGFloat(1)
                                    presenter.remoteURL = url
                                    
                                    Qiscus.uiThread.async {
                                        self.delegate?.qiscusService(didChangeContent: presenter)
                                    }
                                    self.postComment(presenter)
                                    self.commentDelegate?.didUploadFile(comment)
                                }
                                else if json["results"].count > 0 {
                                    let data = json["results"]
                                    if data["file"].count > 0 {
                                        let file = data["file"]
                                        if let url = file["url"].string {
                                            comment.updateCommentStatus(QiscusCommentStatus.sending)
                                            comment.updateCommentText("[file]\(url) [/file]")
                                            Qiscus.printLog(text: "upload success")
                                            
                                            commentFile.updateURL(url)
                                            commentFile.updateIsUploading(false)
                                            commentFile.updateUploadProgress(1.0)
                                            
                                            let presenter = QiscusCommentPresenter.getPresenter(forComment: comment)
                                            presenter.isUploaded = true
                                            presenter.isUploading = false
                                            presenter.uploadProgress = CGFloat(1)
                                            presenter.remoteURL = url
                                            
                                            Qiscus.uiThread.async {
                                                self.delegate?.qiscusService(didChangeContent: presenter)
                                            }
                                            self.postComment(presenter)
                                            self.commentDelegate?.didUploadFile(comment)
                                        }
                                    }
                                }
                            }else{
                                Qiscus.printLog(text: "fail to upload file")
                                DispatchQueue.main.async(execute: {
                                    comment.commentStatusRaw = QiscusCommentStatus.failed.rawValue
                                    commentFile.updateIsUploading(false)
                                    commentFile.updateUploadProgress(0)
                                    
                                    let presenter = QiscusCommentPresenter.getPresenter(forComment: comment)
                                    presenter.isUploaded = false
                                    presenter.isUploading = false
                                    presenter.uploadProgress = CGFloat(0)
                                    
                                    Qiscus.uiThread.async {
                                        self.delegate?.qiscusService(didChangeContent: presenter)
                                    }
                                    //  self.commentDelegate?.didFailedUploadFile(comment)
                                })
                            }
                        })
                        upload.uploadProgress(closure: {uploadProgress in
                            let progress = CGFloat(uploadProgress.fractionCompleted)
                            Qiscus.printLog(text: "upload progress: \(progress)")
                            commentFile.updateIsUploading(true)
                            commentFile.updateUploadProgress(progress)
                            if let currentComment = QiscusComment.getComment(withUniqueId: comment.commentUniqueId){
                                let presenter = QiscusCommentPresenter.getPresenter(forComment: currentComment)
                                presenter.isUploading = true
                                presenter.uploadProgress = progress
                                
                                Qiscus.uiThread.async {
                                    self.delegate?.qiscusService(didChangeContent: presenter)
                                }
                            }
                        })
                        break
                    case .failure(let error):
                        Qiscus.printLog(text: "fail to upload with error: \(error)")
                        Qiscus.logicThread.async {
                            comment.updateCommentStatus(QiscusCommentStatus.failed)
                            commentFile.updateIsUploading(false)
                            commentFile.updateUploadProgress(0)
                            
                            let presenter = QiscusCommentPresenter.getPresenter(forComment: comment)
                            presenter.isUploaded = false
                            presenter.isUploading = false
                            presenter.uploadProgress = CGFloat(0)
                            
                            Qiscus.uiThread.async {
                                self.delegate?.qiscusService(didChangeContent: presenter)
                            }
                        }
                        break
                    }
                })
            }
        }
    }
    
    // MARK: - Communicate with Server
    open func syncMessage(inRoom room: QiscusRoom, fromComment commentId: Int64, silent:Bool = false, triggerDelegate:Bool = false) {
        Qiscus.logicThread.async {
            let topicId = room.roomLastCommentTopicId
            let manager = Alamofire.SessionManager.default
            let loadURL = QiscusConfig.LOAD_URL
            let parameters:[String: AnyObject] =  [
                "last_comment_id"  : commentId as AnyObject,
                "topic_id" : topicId as AnyObject,
                "token" : qiscus.config.USER_TOKEN as AnyObject,
                "after" : "true" as AnyObject
            ]
            Qiscus.printLog(text: "sync comment parameters: \n\(parameters)")
            Qiscus.printLog(text: "sync comment url: \n\(loadURL)")
            Qiscus.apiThread.async {
                manager.request(loadURL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
                    Qiscus.printLog(text: "sync comment response: \n\(responseData)")
                    if let response = responseData.result.value {
                        let json = JSON(response)
                        let results = json["results"]
                        let error = json["error"]
                        if results != nil{
                            let comments = json["results"]["comments"].arrayValue
                            if comments.count > 0 {
                                let service = QiscusCommentClient.shared
                                for newComment in comments {
                                    var saved = false
                                    let id = newComment["id"].int64Value
                                    let uniqueId = newComment["unique_temp_id"].stringValue
                                    var comment = QiscusComment()
                                    if let old = QiscusComment.comment(withId:id, andUniqueId: uniqueId){
                                        comment = old
                                    }else{
                                        comment = QiscusComment.newComment(withId: id, andUniqueId: uniqueId)
                                        saved = true
                                    }
                                    let email = newComment["email"].stringValue
                                    comment.commentText = newComment["message"].stringValue
                                    comment.commentBeforeId = newComment["comment_before_id"].int64Value
                                    comment.showLink = !(newComment["disable_link_preview"].boolValue)
                                    comment.commentSenderEmail = email
                                    comment.commentTopicId = topicId
                                    comment.commentCreatedAt = Double(newComment["unix_timestamp"].doubleValue / 1000)
                                    
                                    if let user = QiscusUser.getUserWithEmail(email) {
                                        user.updateUserAvatarURL(newComment["user_avatar_url"].stringValue)
                                        user.updateUserFullName(newComment["username"].stringValue)
                                    }
                                    if QiscusChatVC.sharedInstance.isPresence && QiscusChatVC.sharedInstance.room == room && triggerDelegate && saved{
                                        if let delegate = service.delegate {
                                            let presenter = QiscusCommentPresenter.getPresenter(forComment: comment)
                                            delegate.qiscusService(gotNewMessage: presenter)
                                        }
                                        if let roomDelegate = service.roomDelegate {
                                            Qiscus.uiThread.async {
                                                roomDelegate.gotNewComment(comment)
                                            }
                                        }
                                    }
                                    
                                }
                            }
                            if !silent {
                                QiscusDataPresenter.shared.loadComments(inRoom: room.roomId, checkSync: false)
                            }
                        }else if error != nil{
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
    open func syncRoom(inRoom room: QiscusRoom, fromComment commentId: Int64, silent:Bool = false) {
        Qiscus.logicThread.async {
            let topicId = room.roomLastCommentTopicId
            let manager = Alamofire.SessionManager.default
            let loadURL = QiscusConfig.LOAD_URL
            let parameters:[String: AnyObject] =  [
                "last_comment_id"  : commentId as AnyObject,
                "topic_id" : topicId as AnyObject,
                "token" : qiscus.config.USER_TOKEN as AnyObject,
                "after":"true" as AnyObject
            ]
            Qiscus.printLog(text: "sync comment parameters: \n\(parameters)")
            Qiscus.printLog(text: "sync comment url: \n\(loadURL)")
            Qiscus.apiThread.async {
                manager.request(loadURL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
                    Qiscus.printLog(text: "sync comment response: \n\(responseData)")
                    if let response = responseData.result.value {
                        let json = JSON(response)
                        let results = json["results"]
                        let error = json["error"]
                        if results != nil{
                            let comments = json["results"]["comments"].arrayValue
                            if comments.count > 0 {
                                for newComment in comments.reversed() {
                                    let notifTopicId = newComment["topic_id"].intValue
                                    let id = newComment["id"].int64Value
                                    let roomId = newComment["room_id"].intValue
                                    let senderName = newComment["username"].stringValue
                                    let isSaved = QiscusComment.getCommentFromJSON(newComment, topicId: notifTopicId, saved: true)
                                    let qiscusService = QiscusCommentClient.sharedInstance
                                    
                                    if isSaved{
                                        QiscusCommentClient.sharedInstance.publishMessageStatus(onComment: commentId, roomId: roomId, status: .delivered, withCompletion: {
                                            if let thisComment = QiscusComment.getComment(withId: commentId) {
                                                thisComment.updateCommentStatus(.read, email: thisComment.commentSenderEmail)
                                            }
                                        })
                                        let newMessage = QiscusComment.getComment(withId: id)
                                        
                                        if qiscusService.commentDelegate != nil{
                                            let copyComment = QiscusComment.copyComment(comment: newMessage!)
                                            let presenter = QiscusCommentPresenter.getPresenter(forComment: copyComment)
                                            presenter.userFullName = senderName
                                            Qiscus.uiThread.async {
                                                qiscusService.delegate?.qiscusService(gotNewMessage: presenter)
                                            }
                                        }
                                        Qiscus.logicThread.async {
                                            if qiscusService.roomDelegate != nil{
                                                let copyComment = QiscusComment.copyComment(comment: newMessage!)
                                                Qiscus.uiThread.async {
                                                    qiscusService.roomDelegate?.gotNewComment(copyComment)
                                                    
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            if !silent {
                                QiscusDataPresenter.shared.loadComments(inRoom: room.roomId, checkSync: false)
                            }
                        }else if error != nil{
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
    // MARK: - Communicate with Server
    open func syncChatFirst(fromComment commentId:Int64, roomId:Int) {
        let manager = Alamofire.SessionManager.default
        let loadURL = QiscusConfig.SYNC_URL
        let parameters:[String: AnyObject] =  [
            "last_received_comment_id"  : commentId as AnyObject,
            "token" : qiscus.config.USER_TOKEN as AnyObject,
            ]
        Qiscus.printLog(text: "sync chat parameters: \n\(parameters)")
        Qiscus.printLog(text: "sync chat url: \n\(loadURL)")
        //Qiscus.apiThread.async {
        manager.request(loadURL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
            Qiscus.printLog(text: "sync chat response: \n\(responseData)")
            if let response = responseData.result.value {
                let json = JSON(response)
                let results = json["results"]
                let error = json["error"]
                let qiscusService = QiscusCommentClient.sharedInstance
                if results != nil{
                    let comments = json["results"]["comments"].arrayValue
                    if comments.count > 0 {
                        Qiscus.logicThread.async {
                            for newComment in comments.reversed() {
                                let notifTopicId = newComment["topic_id"].intValue
                                let id = newComment["id"].int64Value
                                let isSaved = QiscusComment.getCommentFromJSON(newComment, topicId: notifTopicId, saved: true)
                                
                                if isSaved{
                                    let newMessage = QiscusComment.getComment(withId: id)
                                    
                                    Qiscus.logicThread.async {
                                        if qiscusService.roomDelegate != nil{
                                            let copyComment = QiscusComment.copyComment(comment: newMessage!)
                                            Qiscus.uiThread.async {
                                                qiscusService.roomDelegate?.gotNewComment(copyComment)
                                                
                                            }
                                        }
                                    }
                                }
                            }
                            
                        }
                    }
                    if let serviceDelegate = QiscusCommentClient.shared.delegate {
                        if let room = QiscusRoom.getRoomById(roomId){
                            serviceDelegate.qiscusService(didFinishLoadRoom: room)
                        }
                    }
                }else if error != nil{
                    Qiscus.printLog(text: "error sync message: \(error)")
                }
            }else{
                Qiscus.printLog(text: "error sync message")
                
            }
        })
        //}
    }

    open func syncChat(fromComment commentId:Int64, backgroundFetch:Bool = false) {
            let manager = Alamofire.SessionManager.default
            let loadURL = QiscusConfig.SYNC_URL
            let parameters:[String: AnyObject] =  [
                "last_received_comment_id"  : commentId as AnyObject,
                "token" : qiscus.config.USER_TOKEN as AnyObject,
            ]
            Qiscus.printLog(text: "sync chat parameters: \n\(parameters)")
            Qiscus.printLog(text: "sync chat url: \n\(loadURL)")
            Qiscus.shared.syncing = true
            //Qiscus.apiThread.async {
            manager.request(loadURL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
                Qiscus.printLog(text: "sync chat response: \n\(responseData)")
                let state = UIApplication.shared.applicationState
                if let response = responseData.result.value {
                    let json = JSON(response)
                    let results = json["results"]
                    let error = json["error"]
                    if results != nil{
                        let comments = json["results"]["comments"].arrayValue
                        if comments.count > 0 {
                            if state == .active{
                                Qiscus.logicThread.async {
                                    
                                    for newComment in comments.reversed() {
                                        let topicId = newComment["topic_id"].intValue
                                        let roomId = newComment["room_id"].intValue
                                        let id = newComment["id"].int64Value
                                        let uId = newComment["unique_temp_id"].stringValue
                                        var saved = false
                                        var comment = QiscusComment()
                                        if let dbComment = QiscusComment.comment(withId: id, andUniqueId: uId){
                                            comment = dbComment
                                        }else{
                                            comment = QiscusComment.newComment(withId: id, andUniqueId: uId)
                                            saved = true
                                        }
                                        
                                        let email = newComment["email"].stringValue
                                        comment.commentText = newComment["message"].stringValue
                                        comment.commentBeforeId = newComment["comment_before_id"].int64Value
                                        comment.showLink = !(newComment["disable_link_preview"].boolValue)
                                        comment.commentSenderEmail = email
                                        comment.commentTopicId = topicId
                                        comment.commentCreatedAt = Double(newComment["unix_timestamp"].doubleValue / 1000)
                                        
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
                                                if let delegate = QiscusDataPresenter.shared.delegate {
                                                    delegate.dataPresenter(didChangeUser: QiscusUser.copyUser(user: user), onUserWithEmail: email)
                                                }
                                            }
                                        }
                                        
                                        if saved{
                                            let service = QiscusCommentClient.shared
                                            if QiscusChatVC.sharedInstance.isPresence && QiscusChatVC.sharedInstance.room?.roomId == roomId{
                                                
                                                if let delegate = service.delegate {
                                                    let presenter = QiscusCommentPresenter.getPresenter(forComment: comment)
                                                    delegate.qiscusService(gotNewMessage: presenter)
                                                }
                                            }
                                            if let roomDelegate = service.roomDelegate {
                                                Qiscus.uiThread.async {
                                                    roomDelegate.gotNewComment(comment)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }else if error != nil{
                        Qiscus.printLog(text: "error sync message: \(error)")
                    }
                    Qiscus.shared.syncing = false
                }
                else{
                    Qiscus.printLog(text: "error sync message")
                    
                }
            })
            //}
    }
    
    open func getListComment(topicId: Int, commentId: Int64, triggerDelegate:Bool = false, loadMore:Bool = false, message:String? = nil){ //
        let manager = Alamofire.SessionManager.default
        var parameters:[String: AnyObject]? = nil
        let loadURL = QiscusConfig.LOAD_URL
            parameters =  [
                "last_comment_id"  : commentId as AnyObject,
                "topic_id" : topicId as AnyObject,
                "token" : qiscus.config.USER_TOKEN as AnyObject
            ]

        Qiscus.printLog(text: "request getListComment parameters: \(parameters)")
        Qiscus.printLog(text: "request getListComment url \(loadURL)")
        manager.request(loadURL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
            Qiscus.printLog(text: "getListComment result: \(responseData)")
            if let response = responseData.result.value{
                let json = JSON(response)
                let results = json["results"]
                let error = json["error"]
                if results != nil{
                    var newMessageCount: Int = 0
                    let comments = json["results"]["comments"].arrayValue
                    if comments.count > 0 {
                        var newComments = [QiscusComment]()
                        for comment in comments {
                            let isSaved = QiscusComment.getCommentFromJSON(comment, topicId: topicId, saved: true)
                            if let thisComment = QiscusComment.getComment(withId: QiscusComment.getCommentIdFromJSON(comment)){
                                
                                if isSaved {
                                    newMessageCount += 1
                                    if loadMore {
                                        newComments.append(thisComment)
                                    }else{
                                        newComments.insert(thisComment, at: 0)
                                    }
                                }
                            }
                        }

                        if loadMore {
                            self.commentDelegate?.didFinishLoadMore()
                        }
                        if message != nil{
                            QiscusCommentClient.sharedInstance.postMessage(message: message!, topicId: topicId)
                        }
                    }
                    self.commentDelegate?.finishedLoadFromAPI(topicId)
                }else if error != nil{
                    Qiscus.printLog(text: "error getListComment: \(error)")
                    var errorMessage = "Failed to load room data"
                    if let errorData = json["detailed_messages"].array {
                        if let message = errorData[0].string {
                            errorMessage = message
                        }
                    }else if let errorData = json["message"].string {
                        errorMessage = errorData
                    }
                    self.commentDelegate?.didFailedLoadDataFromAPI(errorMessage)
                }
            }else{
                self.commentDelegate?.didFailedLoadDataFromAPI("failed to sync message, connection error")
            }
        })
    }
    open func loadMore(room: QiscusRoom, fromComment commentId: Int64 = 0){ //
        let topicId = room.roomLastCommentTopicId
        let manager = Alamofire.SessionManager.default
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
        manager.request(loadURL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
            Qiscus.printLog(text: "loadMore result: \(responseData)")
            if let response = responseData.result.value{
                let json = JSON(response)
                let results = json["results"]
                let error = json["error"]
                if results != nil{
                    var newMessageCount: Int = 0
                    let comments = json["results"]["comments"].arrayValue
                    if comments.count > 0 {
                        for comment in comments {
                            let isSaved = QiscusComment.getCommentFromJSON(comment, topicId: topicId, saved: true)
                            if isSaved {
                                newMessageCount += 1
                            }
                        }
                    }
                    self.delegate?.qiscusService(didFinishLoadMore: room, dataCount: newMessageCount, from: commentId)
                }else if error != nil{
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
        let manager = Alamofire.SessionManager.default
        let loadURL = QiscusConfig.ROOM_REQUEST_ID_URL
        
        let parameters:[String : AnyObject] =  [
            "id" : roomId as AnyObject,
            "token"  : qiscus.config.USER_TOKEN as AnyObject
        ]
        Qiscus.printLog(text: "get room with id url: \(loadURL)")
        Qiscus.printLog(text: "get room with id parameters: \(parameters)")
        manager.request(loadURL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
            Qiscus.printLog(text: "response data: \(responseData)")
            if let response = responseData.result.value {
                Qiscus.printLog(text: "get room api response:\n\(response)")
                let json = JSON(response)
                let results = json["results"]
                let error = json["error"]
                
                if results != nil{
                    Qiscus.printLog(text: "getListComment with id response: \(responseData)")
                    let roomData = results["room"]
                    let room = QiscusRoom.getRoom(roomData)
                    let commentData = results["comments"].arrayValue
                    let topicId = roomData["last_topic_id"].intValue
                    
                    for payload in commentData{
                        let id = payload["id"].int64Value
                        let uId = payload["unique_temp_id"].stringValue
                        let email = payload["email"].stringValue
                        
                        var comment = QiscusComment()
                        if let old = QiscusComment.comment(withId: id, andUniqueId: uId){
                            comment = old
                        }else{
                            comment = QiscusComment.newComment(withId: id, andUniqueId: uId)
                        }
                        comment.commentId = id
                        comment.commentBeforeId = payload["comment_before_id"].int64Value
                        comment.commentText = payload["message"].stringValue
                        comment.showLink = !(payload["disable_link_preview"].boolValue)
                        comment.commentSenderEmail = email
                        comment.commentTopicId = topicId
                        comment.commentCreatedAt = Double(payload["unix_timestamp"].doubleValue / 1000)
                    }
                    
                    if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                        roomDelegate.didFinishLoadRoom(onRoom: room)
                    }
                    
                    QiscusUIConfiguration.sharedInstance.topicId = topicId
                    QiscusChatVC.sharedInstance.topicId = topicId
                    
                    if let participants = roomData["participants"].array {
                        for participant in participants{
                            let userEmail = participant["email"].stringValue
                            let userFullName = participant["username"].stringValue
                            let userAvatarURL = participant["avatar_url"].stringValue
                            
                            if let member = QiscusUser.getUserWithEmail(userEmail){
                                if member.userFullName != userFullName {
                                    member.updateUserFullName(userFullName)
                                    let user = QiscusUser.copyUser(user: member)
                                    user.userFullName = userFullName
                                    QiscusDataPresenter.shared.delegate?.dataPresenter(didChangeUser: user, onUserWithEmail: userEmail)
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
                                QiscusParticipant.addParticipant(user.userEmail, roomId: room.roomId)
                            }
                        }
                    }
                    QiscusChatVC.sharedInstance.loadTitle()
                    self.commentDelegate?.finishedLoadFromAPI(topicId)
                    self.delegate?.qiscusService(didFinishLoadRoom: room)
                    if withMessage != nil {
                        self.postMessage(message: withMessage!, topicId: topicId)
                        QiscusChatVC.sharedInstance.message = nil
                    }
                }else if error != nil{
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
    open func checkRoom(withID roomId:Int){
        let manager = Alamofire.SessionManager.default
        let loadURL = QiscusConfig.ROOM_REQUEST_ID_URL
        
        let parameters:[String : AnyObject] =  [
            "id" : roomId as AnyObject,
            "token"  : qiscus.config.USER_TOKEN as AnyObject
        ]
        Qiscus.printLog(text: "check room with id url: \(loadURL)")
        Qiscus.printLog(text: "check room with id parameters: \(parameters)")
        manager.request(loadURL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
            Qiscus.printLog(text: "response data: \(responseData)")
            if let response = responseData.result.value {
                Qiscus.printLog(text: "get room api response:\n\(response)")
                let json = JSON(response)
                let results = json["results"]
                let error = json["error"]
                
                if results != nil{
                    Qiscus.printLog(text: "getRoom API response: \(responseData)")
                    let roomData = json["results"]["room"]
                    let room = QiscusRoom.getRoom(roomData)
                    let topicId = room.roomLastCommentTopicId
                    
                    if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                        roomDelegate.didFinishLoadRoom(onRoom: room)
                    }
                    
                    //QiscusChatVC.sharedInstance.roomAvatar.loadAsync(room.roomAvatarURL)
                    
                    QiscusUIConfiguration.sharedInstance.topicId = topicId
                    QiscusChatVC.sharedInstance.topicId = topicId
                    var newMessageCount: Int = 0
                    let comments = json["results"]["comments"].arrayValue
                    if comments.count > 0 {
                        var newComments = [QiscusComment]()
                        for comment in comments {
                            let isSaved = QiscusComment.getCommentFromJSON(comment, topicId: topicId, saved: true)
                            if let thisComment = QiscusComment.getComment(withId: QiscusComment.getCommentIdFromJSON(comment)){
                                thisComment.updateCommentStatus(.sent)
                                if isSaved {
                                    newMessageCount += 1
                                    newComments.insert(thisComment, at: 0)
                                }
                            }
                        }
                        if newComments.count > 0 {
                            self.commentDelegate?.gotNewComment(newComments)
                        }
                    }
                    
                    if let participants = roomData["participants"].array {
                        QiscusParticipant.removeAllParticipant(inRoom: room.roomId)
                        for participant in participants{
                            let user = QiscusUser()
                            user.userEmail = participant["email"].stringValue
                            user.userFullName = participant["username"].stringValue
                            user.userAvatarURL = participant["avatar_url"].stringValue
                            
                            let _ = user.saveUser()
                            QiscusParticipant.addParticipant(user.userEmail, roomId: room.roomId)
                            if user.userEmail != QiscusMe.sharedInstance.email {
                                room.updateUser(user.userEmail)
                            }
                        }
                    }
                    QiscusChatVC.sharedInstance.loadTitle()
                    self.delegate?.qiscusService(didFinishLoadRoom: room)

                }else if error != nil{
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
                }
                
            }else{
                self.delegate?.qiscusService(didFailLoadRoom: "Failed to load room data")
                if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                    roomDelegate.didFailLoadRoom(withError: "fail to get chat room")
                }
            }
        })
    }
    open func getListComment(withUsers users:[String], triggerDelegate:Bool = true, loadMore:Bool = false, distincId:String? = nil, optionalData:String? = nil, withMessage:String? = nil){ // 
        let manager = Alamofire.SessionManager.default
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
        manager.request(loadURL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
            if let response = responseData.result.value {
                Qiscus.printLog(text: "get or create room api response:\n\(response)")
                let json = JSON(response)
                let results = json["results"]
                let error = json["error"]
                
                if results != nil{
                    Qiscus.printLog(text: "getListComment with user response: \(responseData)")
                    let roomData = results["room"]
                    let room = QiscusRoom.getRoom(roomData)
                    let commentData = results["comments"].arrayValue
                    let topicId = roomData["last_topic_id"].intValue
                    let users = parameters["emails"] as! [String]
                    
                    
                    for payload in commentData{
                        let id = payload["id"].int64Value
                        let uId = payload["unique_temp_id"].stringValue
                        let email = payload["email"].stringValue
                        
                        var comment = QiscusComment()
                        if let old = QiscusComment.comment(withId: id, andUniqueId: uId){
                            comment = old
                        }else{
                            comment = QiscusComment.newComment(withId: id, andUniqueId: uId)
                        }
                        comment.commentId = id
                        comment.commentBeforeId = payload["comment_before_id"].int64Value
                        comment.commentText = payload["message"].stringValue
                        comment.showLink = !(payload["disable_link_preview"].boolValue)
                        comment.commentSenderEmail = email
                        comment.commentTopicId = topicId
                        comment.commentCreatedAt = Double(payload["unix_timestamp"].doubleValue / 1000)
                    }
                    
                    if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                        roomDelegate.didFinishLoadRoom(onRoom: room)
                    }
                    
                    if users.count == 1 {
                        room.updateUser(users.first!)
                    }
                    if distincId != nil {
                        room.updateDistinctId(distincId!)
                    }
                    QiscusUIConfiguration.sharedInstance.topicId = topicId
                    QiscusChatVC.sharedInstance.topicId = topicId
                    
                    if let participants = roomData["participants"].array {
                        for participant in participants{
                            let userEmail = participant["email"].stringValue
                            let userFullName = participant["username"].stringValue
                            let userAvatarURL = participant["avatar_url"].stringValue
                            
                            if let member = QiscusUser.getUserWithEmail(userEmail){
                                if member.userFullName != userFullName {
                                    member.updateUserFullName(userFullName)
                                    let user = QiscusUser.copyUser(user: member)
                                    user.userFullName = userFullName
                                    QiscusDataPresenter.shared.delegate?.dataPresenter(didChangeUser: user, onUserWithEmail: userEmail)
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
                                QiscusParticipant.addParticipant(user.userEmail, roomId: room.roomId)
                            }
                        }
                    }
                    QiscusChatVC.sharedInstance.loadTitle()
                    self.commentDelegate?.finishedLoadFromAPI(topicId)
                    self.delegate?.qiscusService(didFinishLoadRoom: room)
                    if withMessage != nil {
                        self.postMessage(message: withMessage!, topicId: topicId)
                        QiscusChatVC.sharedInstance.message = nil
                    }
                }else if error != nil{
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
    
    // MARK: - Create New Room
    open func createNewRoom(withUsers users:[String], optionalData:String? = nil, withMessage:String? = nil){ // 
        let manager = Alamofire.SessionManager.default
        let loadURL = QiscusConfig.CREATE_NEW_ROOM
        
        var parameters:[String : AnyObject] =  [
            "name" : QiscusUIConfiguration.sharedInstance.copyright.chatTitle as AnyObject,
            "participants" : users as AnyObject,
            "token"  : qiscus.config.USER_TOKEN as AnyObject
        ]

        if optionalData != nil{
            parameters["options"] = optionalData! as AnyObject
        }
        Qiscus.printLog(text: "create new room parameters: \(parameters)")
        manager.request(loadURL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
            if let response = responseData.result.value {
                Qiscus.printLog(text: "create New room api response:\n\(response)")
                let json = JSON(response)
                let results = json["results"]
                let error = json["error"]
                
                if results != nil{
                    Qiscus.printLog(text: "getListComment with user response: \(responseData)")
                    let roomData = json["results"]["room"]
                    let room = QiscusRoom.getRoom(roomData)
                    let topicId = room.roomLastCommentTopicId
                    
                    if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                        roomDelegate.didFinishLoadRoom(onRoom: room)
                    }
                    //QiscusChatVC.sharedInstance.roomAvatar.loadAsync(room.roomAvatarURL)
                    
                    QiscusUIConfiguration.sharedInstance.topicId = topicId
                    QiscusChatVC.sharedInstance.topicId = topicId
                    var newMessageCount: Int = 0
                    let comments = json["results"]["comments"].arrayValue
                    if comments.count > 0 {
                        var newComments = [QiscusComment]()
                        for comment in comments {
                            let isSaved = QiscusComment.getCommentFromJSON(comment, topicId: topicId, saved: true)
                            if let thisComment =  QiscusComment.getComment(withId: QiscusComment.getCommentIdFromJSON(comment)){
                                thisComment.updateCommentStatus(QiscusCommentStatus.sent)
                                if isSaved {
                                    newMessageCount += 1
                                    newComments.insert(thisComment, at: 0)
                                }
                            }
                        }
                    }
                    
                    if let participants = roomData["participants"].array {
                        QiscusParticipant.removeAllParticipant(inRoom: room.roomId)
                        for participant in participants{
                            let user = QiscusUser()
                            user.userEmail = participant["email"].stringValue
                            user.userFullName = participant["username"].stringValue
                            user.userAvatarURL = participant["avatar_url"].stringValue
                            
                            let _ = user.saveUser()
                            QiscusParticipant.addParticipant(user.userEmail, roomId: room.roomId)
                            if user.userEmail != QiscusMe.sharedInstance.email && participants.count == 2{
                                room.updateUser(user.userEmail)
                            }
                        }
                    }
                    QiscusChatVC.sharedInstance.loadTitle()
                    self.commentDelegate?.finishedLoadFromAPI(topicId)
                    self.delegate?.qiscusService(didFinishLoadRoom: QiscusRoom.copyRoom(room: room))
                    if withMessage != nil {
                        self.postMessage(message: withMessage!, topicId: topicId)
                        QiscusChatVC.sharedInstance.message = nil
                    }
                }else if error != nil{
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
                }
                
            }else{
                self.delegate?.qiscusService(didFailLoadRoom: "Failed to load room data")
                if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                    roomDelegate.didFailLoadRoom(withError: "fail to create chat room")
                }
            }
        })
    }
    
    // MARK: - Load More
    open func loadMoreComment(fromCommentId commentId:Int64, topicId:Int, limit:Int = 10){
        let comments = QiscusComment.loadMoreComment(fromCommentId: commentId, topicId: topicId, limit: limit)
        Qiscus.printLog(text: "got \(comments.count) new comments")
        
        if comments.count > 0 {
            var commentData = [QiscusComment]()
            for comment in comments{
                commentData.insert(comment, at: 0)
            }
            Qiscus.printLog(text: "got \(comments.count) new comments")
            self.commentDelegate?.gotNewComment(commentData)
            self.commentDelegate?.didFinishLoadMore()
        }else{
            self.getListComment(topicId: topicId, commentId: commentId, loadMore: true)
        }
    }
    // MARK: - Update Room
    open func updateRoom(withRoomId roomId:Int, roomName:String? = nil, roomAvatarURL:String? = nil, roomAvatar:UIImage? = nil, roomOptions:String? = nil){
        if roomName != nil || roomAvatarURL != nil || roomOptions != nil {
            let manager = Alamofire.SessionManager.default
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
            manager.request(requestURL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
                if let response = responseData.result.value {
                    Qiscus.printLog(text: "update room api response:\n\(response)")
                    let json = JSON(response)
                    let results = json["results"]
                    let error = json["error"]
                    
                    if results != nil{
                        Qiscus.printLog(text: "getListComment with user response: \(responseData)")
                        let changed = json["results"]["changed"].boolValue
                        if changed {
                            let roomData = json["results"]["room"]
                            var room = QiscusRoom()
                            var roomExist = false
                            if let chatRoom = QiscusRoom.getRoomById(roomData["id"].intValue){
                                roomExist = true
                                room = QiscusRoom.copyRoom(room: chatRoom)
                            }else{
                                room = QiscusRoom.getRoom(roomData)
                            }
                            
                            if roomExist {
                                if roomName != nil {
                                    room.updateRoomName(roomName!)
                                }
                                if roomOptions != nil {
                                    room.updateRoomOptions(roomOptions!)
                                }
                                if roomAvatarURL != nil {
                                    room.updateRoomAvatar(roomAvatarURL!, avatarImage: roomAvatar)
                                }
                            }
                            
                            let topicId = room.roomLastCommentTopicId
                            
                            if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                                roomDelegate.didFinishUpdateRoom(onRoom: room)
                            }
                            var newMessageCount: Int = 0
                            let comments = json["results"]["comments"].arrayValue
                            if comments.count > 0 {
                                var newComments = [QiscusComment]()
                                for comment in comments {
                                    let isSaved = QiscusComment.getCommentFromJSON(comment, topicId: topicId, saved: true)
                                    if let thisComment =  QiscusComment.getComment(withId: QiscusComment.getCommentIdFromJSON(comment)){
                                        if isSaved {
                                            newMessageCount += 1
                                            newComments.insert(thisComment, at: 0)
                                        }
                                    }
                                }
                            }
                            
                            if let participants = roomData["participants"].array {
                                QiscusParticipant.removeAllParticipant(inRoom: room.roomId)
                                for participant in participants{
                                    let user = QiscusUser()
                                    user.userEmail = participant["email"].stringValue
                                    user.userFullName = participant["username"].stringValue
                                    user.userAvatarURL = participant["avatar_url"].stringValue
                                    
                                    let _ = user.saveUser()
                                    QiscusParticipant.addParticipant(user.userEmail, roomId: room.roomId)
                                    if user.userEmail != QiscusMe.sharedInstance.email {
                                        room.updateUser(user.userEmail)
                                    }
                                }
                            }
                            QiscusChatVC.sharedInstance.loadTitle()
                        }
                    }else if error != nil{
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
    // MARK: - SYNC ALL
    open func sync(){
        if Qiscus.isLoggedIn {
            if let lastComment = QiscusComment.getLastComment() {
                let manager = Alamofire.SessionManager.default
                let requestURL = QiscusConfig.SYNC_URL
                
                let parameters:[String : AnyObject] = [
                    "token" : qiscus.config.USER_TOKEN as AnyObject,
                    "last_received_comment_id": lastComment.commentId as AnyObject
                ]
                manager.request(requestURL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
                    if let response = responseData.result.value {
                        Qiscus.printLog(text: "create New room api response:\n\(response)")
                        let json = JSON(response)
                        let results = json["results"]
                        let error = json["error"]
                        
                        if results != nil {
                        
                        }
                        else if error != nil{
                        }
                        
                    }else{
                        
                    }
                })
            }
        }
    }
    // MARK: - Message Status
    open func publishMessageStatus(onComment commentId:Int64, roomId:Int, status:QiscusCommentStatus, withCompletion: @escaping ()->Void){
        if status == QiscusCommentStatus.delivered || status == QiscusCommentStatus.read{
            DispatchQueue.global().async {
                let manager = Alamofire.SessionManager.default
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
                manager.request(loadURL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
                    if let response = responseData.result.value {
                        Qiscus.printLog(text: "publish message response:\n\(response)")
                        let json = JSON(response)
                        let results = json["results"]
                        let error = json["error"]
                        
                        if results != nil{
                            Qiscus.printLog(text: "success change comment status on \(commentId) to \(status.rawValue)")
                            withCompletion()
                        }else if error != nil{
                            Qiscus.printLog(text: "error update message status: \(error)")
                        }
                    }else{
                        Qiscus.printLog(text: "error update message status")
                    }
                })
            }
        }
    }
}
