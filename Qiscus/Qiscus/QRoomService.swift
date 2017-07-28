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
import AVFoundation

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
                    room.delegate?.room(didFinishSync: room)
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
        if room.commentsGroupCount > 0 {
            let firstGroup = room.commentGroup(index: 0)!
            let firstComment = firstGroup.comment(index: 0)!
            parameters["last_comment_id"] = firstComment.id as AnyObject
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
                        room.delegate?.room(didFinishLoadMore: room, success: true, gotNewComment: true)
                    }else{
                        room.delegate?.room(didFinishLoadMore: room, success: true, gotNewComment: false)
                    }
                }else if error != JSON.null{
                    room.delegate?.room(didFinishLoadMore: room, success: false, gotNewComment: false)
                    Qiscus.printLog(text: "error loadMore: \(error)")
                }
            }else{
                room.delegate?.room(didFinishLoadMore: room, success: false, gotNewComment: false)
                Qiscus.printLog(text: "fail to LoadMore Data")
            }
        })
    }
    public func updateRoom(onRoom room:QRoom, roomName:String? = nil, roomAvatarURL:String? = nil, roomOptions:String? = nil, onSuccess:@escaping ((_ room: QRoom)->Void),onError:@escaping ((_ error: String)->Void)){
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
                                onSuccess(room)
                            }else{
                                onError("No change on room data")
                            }
                        }else if error != JSON.null{
                            onError("\(error)")
                            Qiscus.printLog(text: "error update chat room: \(error)")
                        }
                    }else{
                        Qiscus.printLog(text: "fail to update chat room")
                        onError("fail to update chat room")
                    }
                })
            }else{
                onError("fail to update chat room")
            }
        }
        else{
            onError("User not logged in")
        }
    }
    public func publisComentStatus(onRoom room:QRoom, status:QCommentStatus){
        if (status == QCommentStatus.delivered || status == QCommentStatus.read) && (room.commentsGroupCount > 0){
            let loadURL = QiscusConfig.UPDATE_COMMENT_STATUS_URL
            let lastCommentId = room.lastComment!.id
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
    public func postComment(onRoom roomId:Int, comment:QComment, type:String? = nil, payload:JSON? = nil){
        var parameters:[String: AnyObject] = [String: AnyObject]()
        
        parameters = [
            "comment"  : comment.text as AnyObject,
            "room_id"   : roomId as AnyObject,
            "topic_id" : roomId as AnyObject,
            "unique_temp_id" : comment.uniqueId as AnyObject,
            "disable_link_preview" : true as AnyObject,
            "token" : Qiscus.shared.config.USER_TOKEN as AnyObject
        ]
        
        if comment.type == .reply && comment.data != ""{
            parameters["type"] = "reply" as AnyObject
            parameters["payload"] = "\(comment.data)" as AnyObject
        }
        
        if type != nil && payload != nil {
            parameters["type"] = type as AnyObject
            parameters["payload"] = "\(payload!)" as AnyObject
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
                        
                        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                        try! realm.write {
                            comment.id = commentId
                            comment.beforeId = commentBeforeId
                        }
                        if let room = QRoom.room(withId: roomId){
                            if comment.status == QCommentStatus.sending || comment.status == QCommentStatus.failed {
                                    room.updateCommentStatus(inComment: comment, status: .sent)
                            }
                            self.sync(onRoom: room)
                        }
                    }else{
                        if let room = QRoom.room(withId: roomId){
                            room.updateCommentStatus(inComment: comment, status: .failed)
                        }
                    }
                }else{
                    if let room = QRoom.room(withId: roomId){
                        room.updateCommentStatus(inComment: comment, status: .failed)
                    }
                }
                break
            case .failure(let error):
                if let room = QRoom.room(withId: roomId){
                    room.updateCommentStatus(inComment: comment, status: .failed)
                }
                Qiscus.printLog(text: "fail to post comment with error: \(error)")
                break
            }
        })
    }
    public func downloadMedia(inRoom room: QRoom, comment:QComment, thumbImageRef:UIImage? = nil, isAudioFile:Bool = false){
        let indexPath = room.getIndexPath(ofComment: comment)!
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        if let file = comment.file {
            
            comment.updateDownloading(downloading: true)
            comment.updateProgress(progress: 0)
            
            room.delegate?.room(didChangeComment: indexPath.section, row: indexPath.item, action: "downloadProgress")
            
            let fileURL = file.url.replacingOccurrences(of: " ", with: "%20")
            Alamofire.request(fileURL, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil).responseData(completionHandler: { response in
                Qiscus.printLog(text: "download result: \(response)")
                if let imageData = response.data {
                    if !isAudioFile{
                        if let image = UIImage(data: imageData) {
                            var thumbImage = UIImage()
                            if !(file.ext == "gif" || file.ext == "gif_"){
                                thumbImage = QiscusFile.createThumbImage(image, fillImageSize: thumbImageRef)
                            }
                            
                            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
                            let directoryPath = "\(documentsPath)/Qiscus"
                            if !FileManager.default.fileExists(atPath: directoryPath){
                                do {
                                    try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: false, attributes: nil)
                                } catch let error as NSError {
                                    Qiscus.printLog(text: error.localizedDescription);
                                }
                            }
                            
                            let fileName = "\(file.filename.replacingOccurrences(of: " ", with: "%20").replacingOccurrences(of: "%20", with: "_"))"
                            let path = "\(documentsPath)/Qiscus/\(fileName)"
                            let thumbPath = "\(documentsPath)/Qiscus/thumb_\(fileName)"
                            
                            if (file.ext == "png" || file.ext == "png_") {
                                try? UIImagePNGRepresentation(image)!.write(to: URL(fileURLWithPath: path), options: [.atomic])
                                try? UIImagePNGRepresentation(thumbImage)!.write(to: URL(fileURLWithPath: thumbPath), options: [.atomic])
                            } else if(file.ext == "jpg" || file.ext == "jpg_"){
                                try? UIImageJPEGRepresentation(image, 1.0)!.write(to: URL(fileURLWithPath: path), options: [.atomic])
                                try? UIImageJPEGRepresentation(thumbImage, 1.0)!.write(to: URL(fileURLWithPath: thumbPath), options: [.atomic])
                            } else if(file.ext == "gif" || file.ext == "gif_"){
                                try? imageData.write(to: URL(fileURLWithPath: path), options: [.atomic])
                                try? imageData.write(to: URL(fileURLWithPath: thumbPath), options: [.atomic])
                                thumbImage = image
                            }
                            try! realm.write {
                                file.localPath = path
                                file.localThumbPath = thumbPath
                            }
                            comment.updateDownloading(downloading: false)
                            comment.updateProgress(progress: 1)
                            
                            comment.displayImage = thumbImage
                            room.delegate?.room(didChangeComment: indexPath.section, row: indexPath.item, action: "downloadFinish")
                            
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
                            let path = "\(documentsPath)/Qiscus/\(file.filename)"
                            let thumbPath = "\(documentsPath)/Qiscus/thumb_\(file.id).png"
                            
                            try? imageData.write(to: URL(fileURLWithPath: path), options: [.atomic])
                            
                            let assetMedia = AVURLAsset(url: URL(fileURLWithPath: "\(path)"))
                            let thumbGenerator = AVAssetImageGenerator(asset: assetMedia)
                            thumbGenerator.appliesPreferredTrackTransform = true
                            
                            let thumbTime = CMTimeMakeWithSeconds(0, 30)
                            let maxSize = CGSize(width: QiscusHelper.screenWidth(), height: QiscusHelper.screenWidth())
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
                            
                            try! realm.write {
                                file.localPath = path
                                file.localThumbPath = thumbPath
                            }
                            comment.updateProgress(progress: 1)
                            comment.updateDownloading(downloading: false)
                            room.delegate?.room(didChangeComment: indexPath.section, row: indexPath.item, action: "downloadFinish")
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
                        let path = "\(documentsPath)/Qiscus/\(file.filename)"
                        try! imageData.write(to: URL(fileURLWithPath: path), options: [.atomic])
                        
                        
                        try! realm.write {
                            file.localPath = path
                        }
                        comment.updateDownloading(downloading: false)
                        comment.updateProgress(progress: 1)
                        
                        room.delegate?.room(didChangeComment: indexPath.section, row: indexPath.item, action: "downloadFinish")
                    }
                }
            }).downloadProgress(closure: { progressData in
                let progress = CGFloat(progressData.fractionCompleted)
                comment.updateProgress(progress: progress)
                comment.updateDownloading(downloading: true)
                
                room.delegate?.room(didChangeComment: indexPath.section, row: indexPath.item, action: "downloadProgress")
            })
        }
    }
    public func publishStatus(inRoom roomId: Int, commentId:Int, commentStatus:QCommentStatus){
        if commentStatus == QCommentStatus.delivered || commentStatus == QCommentStatus.read{
            let loadURL = QiscusConfig.UPDATE_COMMENT_STATUS_URL
            
            var parameters:[String : AnyObject] =  [
                "token" : qiscus.config.USER_TOKEN as AnyObject,
                "room_id" : roomId as AnyObject,
                ]
            
            if commentStatus == QCommentStatus.delivered{
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
                        Qiscus.printLog(text: "success change comment status on \(commentId) to \(commentStatus.rawValue)")
                    }else if error != JSON.null{
                        Qiscus.printLog(text: "error update message status: \(error)")
                    }
                }else{
                    Qiscus.printLog(text: "error update message status")
                }
            })
        }
    }
    public func uploadCommentFile(inRoom room:QRoom, comment:QComment, onSuccess:  @escaping (QRoom, QComment)->Void, onError:  @escaping (QRoom,QComment,String)->Void){
        if let file = comment.file {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            do {
                //print("file.localPath: \(file.localPath)")
                let data = try Data(contentsOf: URL(string: "file://\(file.localPath)")!)
                let headers = QiscusConfig.sharedInstance.requestHeader
                let indexPath = room.getIndexPath(ofComment: comment)!
                var urlUpload = URLRequest(url: URL(string: QiscusConfig.UPLOAD_URL)!)
                if headers.count > 0 {
                    for (key,value) in headers {
                        urlUpload.setValue(value, forHTTPHeaderField: key)
                    }
                }
                urlUpload.httpMethod = "POST"
                let filename = file.filename
                let mimeType = file.mimeType
                Alamofire.upload(multipartFormData: {formData in
                    formData.append(data, withName: "file", fileName: filename, mimeType: mimeType)
                }, with: urlUpload, encodingCompletion: {
                    encodingResult in
                    switch encodingResult{
                    case .success(let upload, _, _):
                        upload.responseJSON(completionHandler: {response in
                            Qiscus.printLog(text: "success upload: \(response)")
                            if let jsonData = response.result.value {
                                let json = JSON(jsonData)
                                if let url = json["url"].string {
                                    try! realm.write {
                                        comment.text = "[file]\(url) [/file]"
                                        file.url = url
                                        comment.updateUploading(uploading: false)
                                        comment.updateProgress(progress: 1)
                                    }
                                    room.delegate?.room(didChangeComment: indexPath.section, row: indexPath.item, action: "uploadFinish")
                                }
                                else if json["results"].count > 0 {
                                    let jsonData = json["results"]
                                    if jsonData["file"].count > 0 {
                                        let fileData = jsonData["file"]
                                        if let url = fileData["url"].string {
                                            try! realm.write {
                                                comment.text = "[file]\(url) [/file]"
                                                file.url = url
                                                comment.updateUploading(uploading: false)
                                                comment.updateProgress(progress: 1)
                                            }
                                            room.delegate?.room(didChangeComment: indexPath.section, row: indexPath.item, action: "uploadFinish")
                                        }
                                    }
                                }
                                onSuccess(room,comment)
                            }else{
                                try! realm.write {
                                    comment.updateUploading(uploading: false)
                                    comment.updateProgress(progress: 0)
                                    comment.updateStatus(status: .failed)
                                }
                                room.delegate?.room(didChangeComment: indexPath.section, row: indexPath.item, action: "status")
                                onError(room,comment,"Fail to upload file, no readable response")
                            }
                        })
                        upload.uploadProgress(closure: {uploadProgress in
                            let progress = CGFloat(uploadProgress.fractionCompleted)
                            try! realm.write {
                                comment.updateUploading(uploading: true)
                                comment.updateProgress(progress: progress)
                            }
                            room.delegate?.room(didChangeComment: indexPath.section, row: indexPath.item, action: "uploadProgress")
                        })
                        break
                    case .failure(let error):
                        try! realm.write {
                            comment.updateUploading(uploading: false)
                            comment.updateProgress(progress: 0)
                            comment.updateStatus(status: .failed)
                        }
                        room.delegate?.room(didChangeComment: indexPath.section, row: indexPath.item, action: "status")
                        onError(room,comment,"Fail to upload file, \(error)")
                        break
                    }
                })
            } catch {
                try! realm.write {
                    comment.updateUploading(uploading: false)
                    comment.updateProgress(progress: 0)
                    comment.updateStatus(status: .failed)
                }
                onError(room, comment, "Local file not found")
            }
        }
    }
}
