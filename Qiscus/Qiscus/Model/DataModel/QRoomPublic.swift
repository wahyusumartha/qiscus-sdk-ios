//
//  QRoomPublic.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 06/07/18.
//

import Foundation
import RealmSwift
import SwiftyJSON

extension QRoom {
    public func comments(withFilter query:NSPredicate?)->[QComment]{
        var comments = [QComment]()
        var results = self.rawComments.sorted(byKeyPath: "createdAt", ascending: true)
        
        if query != nil {
            results = results.filter(query!)
        }
        
        if results.count > 0 {
            comments = Array(results)
        }
        return comments
    }
    
    public func newContactComment(name:String, value:String)->QComment{
        let comment = QComment()
        let payload = "{ \"name\": \"\(name)\", \"value\": \"\(value)\"}"
        let time = Double(Date().timeIntervalSince1970)
        let timeToken = UInt64(time * 10000)
        let uniqueID = "ios-\(timeToken)"
        
        comment.uniqueId = uniqueID
        comment.id = 0
        comment.roomId = self.id
        comment.text = "\(name) - \(value)"
        comment.createdAt = Double(Date().timeIntervalSince1970)
        comment.senderEmail = Qiscus.client.email
        comment.senderName = Qiscus.client.userName
        comment.statusRaw = QCommentStatus.sending.rawValue
        comment.typeRaw = "contact_person"
        comment.data = payload
        comment.roomAvatar = self.avatarURL
        comment.roomName = self.name
        comment.roomTypeRaw = self.typeRaw
        comment.isRead = true
        
        self.addComment(newComment: comment)
        return comment
    }
    public func newLocationComment(latitude:Double, longitude:Double, title:String?=nil, address:String?=nil)->QComment{
        let comment = QComment()
        var locTitle = title
        var locAddress = ""
        if address != nil {
            locAddress = address!
        }
        if title == nil {
            var newLat = latitude
            var newLong = longitude
            var latString = "N"
            var longString = "E"
            if latitude < 0 {
                latString = "S"
                newLat = 0 - latitude
            }
            if longitude < 0 {
                longString = "W"
                newLong = 0 - longitude
            }
            let intLat = Int(newLat)
            let intLong = Int(newLong)
            let subLat = Int((newLat - Double(intLat)) * 100)
            let subLong = Int((newLong - Double(intLong)) * 100)
            let subSubLat = Int((newLat - Double(intLat) - Double(Double(subLat)/100)) * 10000)
            let subSubLong = Int((newLong - Double(intLong) - Double(Double(subLong)/100)) * 10000)
            let pLat = Int((newLat - Double(intLat) - Double(Double(subLat)/100) - Double(Double(subSubLat)/10000)) * 100000)
            let pLong = Int((newLong - Double(intLong) - Double(Double(subLong)/100) - Double(Double(subSubLong)/10000)) * 100000)
            
            locTitle = "\(intLat)º\(subLat)\'\(subSubLat).\(pLat)\"\(latString) \(intLong)º\(subLong)\'\(subSubLong).\(pLong)\"\(longString)"
        }
        let url = "http://maps.google.com/maps?daddr=\(latitude),\(longitude)"
        
        let payload = "{ \"name\": \"\(locTitle!)\", \"address\": \"\(locAddress)\", \"latitude\": \(latitude), \"longitude\": \(longitude), \"map_url\": \"\(url)\"}"
        
        let time = Double(Date().timeIntervalSince1970)
        let timeToken = UInt64(time * 10000)
        let uniqueID = "ios-\(timeToken)"
        
        comment.uniqueId = uniqueID
        comment.id = 0
        comment.roomId = self.id
        comment.text = ""
        comment.createdAt = Double(Date().timeIntervalSince1970)
        comment.senderEmail = Qiscus.client.email
        comment.senderName = Qiscus.client.userName
        comment.statusRaw = QCommentStatus.sending.rawValue
        comment.typeRaw = "location"
        comment.data = payload
        comment.roomAvatar = self.avatarURL
        comment.roomName = self.name
        comment.roomTypeRaw = self.typeRaw
        comment.isRead = true
        self.addComment(newComment: comment)
        return comment
    }
    public func newCustomComment(type:String, payload:String, text:String? = nil )->QComment{
        let comment = QComment()
        let payloadData = JSON(parseJSON: payload)
        var contentString = "\"\""
        if payloadData == JSON.null{
            contentString = "\"\(payload)\""
        }else{
            contentString = "\(payloadData)"
        }
        let payload = "{ \"type\": \"\(type)\", \"content\": \(contentString)}"
        let time = Double(Date().timeIntervalSince1970)
        let timeToken = UInt64(time * 10000)
        let uniqueID = "ios-\(timeToken)"
        if text == nil {
            comment.text = "message type \(type)"
        }else{
            comment.text = text!
        }
        
        comment.uniqueId = uniqueID
        comment.id = 0
        comment.roomId = self.id
        
        comment.createdAt = Double(Date().timeIntervalSince1970)
        comment.senderEmail = Qiscus.client.email
        comment.senderName = Qiscus.client.userName
        comment.statusRaw = QCommentStatus.sending.rawValue
        comment.typeRaw = type
        comment.data = payload
        comment.roomAvatar = self.avatarURL
        comment.roomName = self.name
        comment.roomTypeRaw = self.typeRaw
        comment.isRead = true
        self.addComment(newComment: comment)
        return comment
    }
    
    public func prepareImageComment(filename: String = "", caption: String = "", data: Data? = nil, thumbImage: UIImage? = nil) -> QComment {
        
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        let comment = QComment()
        let time = Double(Date().timeIntervalSince1970)
        let timeToken = UInt64(time * 10000)
        let uniqueID = "ios-\(timeToken)"
        let fileNameArr = filename.split(separator: ".")
        let fileExt = String(fileNameArr.last!).lowercased()
        
        var fileName = filename.lowercased()
        if fileName == "asset.jpg" || fileName == "asset.png" {
            fileName = "\(uniqueID).\(fileExt)"
        }
        fileName = fileName.replacingOccurrences(of: "%", with: "")
        
        var payloadData:[AnyHashable : Any] = [
            "url" : fileName,
            "caption" : caption
        ]
        
        comment.uniqueId = uniqueID
        comment.id = 0
        comment.roomId = self.id
        
        comment.text = "[file]\(fileName) [/file]"
        comment.createdAt = Double(Date().timeIntervalSince1970)
        comment.senderEmail = Qiscus.client.email
        comment.senderName = Qiscus.client.userName
        comment.statusRaw = QCommentStatus.sending.rawValue
        comment.isUploading = true
        comment.progress = 0
        comment.roomAvatar = self.avatarURL
        comment.roomName = self.name
        comment.roomTypeRaw = self.typeRaw
        comment.isRead = true
        
        let file = QFile()
        file.id = uniqueID
        file.roomId = self.id
        file.url = fileName
        file.senderEmail = Qiscus.client.email
        file.filename = fileName
        
        if let fileData = data {
            let size = fileData.count
            file.size = Double(size)
            file.localPath = QFile.saveFile(data!, fileName: fileName)
            
            payloadData = [
                "url" : fileName,
                "caption" : caption,
                "size" : file.size,
                "pages" : 0,
                "file_name": fileName
            ]
        }
        
        if let mime = QiscusFileHelper.mimeTypes["\(fileExt)"] {
            file.mimeType = mime
        }
        
        let image = UIImage(data: data!)
        let gif = (fileExt == "gif" || fileExt == "gif_")
        let jpeg = (fileExt == "jpg" || fileExt == "jpg_" || fileExt == "heic")
        let png = (fileExt == "png" || fileExt == "png_")
        
        var thumb = UIImage()
        var thumbData:Data?
        if !gif {
            thumb = QFile.createThumbImage(image!)
            if jpeg {
                thumbData = UIImageJPEGRepresentation(thumb, 1)
                file.localThumbPath = QFile.saveFile(thumbData!, fileName: "thumb-\(fileName)")
            }else if png {
                thumbData = UIImagePNGRepresentation(thumb)
                file.localThumbPath = QFile.saveFile(thumbData!, fileName: "thumb-\(fileName)")
            }
        }else{
            file.localThumbPath = QFile.saveFile(data!, fileName: "thumb-\(fileName)")
        }
        
        comment.typeRaw = QCommentType.image.name()
        let payloadJSON = JSON(payloadData)
        comment.data = "\(payloadJSON)"
        try! realm.write {
            realm.add(file, update:true)
        }
        
        return comment
    }
    
    public func newFileComment(type:QiscusFileType, filename:String = "", caption:String = "", data:Data? = nil, thumbImage:UIImage? = nil)->QComment{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        let comment = QComment()
        let time = Double(Date().timeIntervalSince1970)
        let timeToken = UInt64(time * 10000)
        let uniqueID = "ios-\(timeToken)"
        let fileNameArr = filename.split(separator: ".")
        let fileExt = String(fileNameArr.last!).lowercased()
        
        var fileName = filename.lowercased()
        if fileName == "asset.jpg" || fileName == "asset.png" {
            fileName = "\(uniqueID).\(fileExt)"
        }
        fileName = fileName.replacingOccurrences(of: "%", with: "")
        
        var payloadData:[AnyHashable : Any] = [
            "url" : fileName,
            "caption" : caption
        ]
        
        comment.uniqueId = uniqueID
        comment.id = 0
        comment.roomId = self.id
        
        comment.text = "[file]\(fileName) [/file]"
        comment.createdAt = Double(Date().timeIntervalSince1970)
        comment.senderEmail = Qiscus.client.email
        comment.senderName = Qiscus.client.userName
        comment.statusRaw = QCommentStatus.sending.rawValue
        comment.isUploading = true
        comment.progress = 0
        comment.roomAvatar = self.avatarURL
        comment.roomName = self.name
        comment.roomTypeRaw = self.typeRaw
        comment.isRead = true
        
        let file = QFile()
        file.id = uniqueID
        file.roomId = self.id
        file.url = fileName
        file.senderEmail = Qiscus.client.email
        file.filename = fileName
        
        if let fileData = data {
            let size = fileData.count
            file.size = Double(size)
            file.localPath = QFile.saveFile(data!, fileName: fileName)
            
            payloadData = [
                "url" : fileName,
                "caption" : caption,
                "size" : file.size,
                "pages" : 0,
                "file_name": fileName
            ]
        }
        
        if let mime = QiscusFileHelper.mimeTypes["\(fileExt)"] {
            file.mimeType = mime
        }
        
        switch type {
        case .audio:
            comment.typeRaw = QCommentType.audio.name()
            break
        case .image:
            let image = UIImage(data: data!)
            let gif = (fileExt == "gif" || fileExt == "gif_")
            let jpeg = (fileExt == "jpg" || fileExt == "jpg_")
            let png = (fileExt == "png" || fileExt == "png_")
            
            var thumb = UIImage()
            var thumbData:Data?
            if !gif {
                thumb = QFile.createThumbImage(image!)
                if jpeg {
                    thumbData = UIImageJPEGRepresentation(thumb, 1)
                    file.localThumbPath = QFile.saveFile(thumbData!, fileName: "thumb-\(fileName)")
                }else if png {
                    thumbData = UIImagePNGRepresentation(thumb)
                    file.localThumbPath = QFile.saveFile(thumbData!, fileName: "thumb-\(fileName)")
                }
            }else{
                file.localThumbPath = QFile.saveFile(data!, fileName: "thumb-\(fileName)")
            }
            
            comment.typeRaw = QCommentType.image.name()
            break
        case .document:
            if let provider = CGDataProvider(data: data! as NSData) {
                if let pdfDoc = CGPDFDocument(provider) {
                    file.pages = pdfDoc.numberOfPages
                    
                    if let pdfImage = thumbImage {
                        let imageSize = pdfImage.size
                        var bigPart = CGFloat(0)
                        if(imageSize.width > imageSize.height){
                            bigPart = imageSize.width
                        }else{
                            bigPart = imageSize.height
                        }
                        
                        var compressVal = CGFloat(1)
                        if(bigPart > 2000){
                            compressVal = 2000 / bigPart
                        }
                        
                        if let thumbData = UIImageJPEGRepresentation(pdfImage, compressVal) {
                            file.localThumbPath = QFile.saveFile(thumbData, fileName: "thumb-\(fileName).jpg")
                        }
                    }
                }
            }
            comment.typeRaw = QCommentType.document.name()
            break
        case .video:
            var fileNameOnly = String(fileNameArr.first!).lowercased()
            var i = 0
            for namePart in fileNameArr{
                if i > 0 && i < (fileNameArr.count - 1){
                    fileNameOnly += ".\(String(namePart).lowercased())"
                }
                i += 1
            }
            let thumbData = UIImagePNGRepresentation(thumbImage!)
            file.localThumbPath = QFile.saveFile(thumbData!, fileName: "thumb-\(fileNameOnly).png")
            comment.typeRaw = QCommentType.video.name()
            break
        default:
            comment.typeRaw = QCommentType.file.name()
            break
        }
        let payloadJSON = JSON(payloadData)
        comment.data = "\(payloadJSON)"
        try! realm.write {
            realm.add(file, update:true)
        }
        self.addComment(newComment: comment)
        realm.refresh()
        return comment
    }
    
    public func newComment(text:String, payload:JSON? = nil,type:QCommentType = .text, data:Data? = nil, image:UIImage? = nil, filename:String = "", filePath:URL? = nil )->QComment{
        let comment = QComment()
        let time = Double(Date().timeIntervalSince1970)
        let timeToken = UInt64(time * 10000)
        let uniqueID = "ios-\(timeToken)"
        
        comment.uniqueId = uniqueID
        comment.id = 0
        comment.roomId = self.id
        comment.text = text
        comment.createdAt = Double(Date().timeIntervalSince1970)
        comment.senderEmail = Qiscus.client.email
        comment.senderName = Qiscus.client.userName
        comment.statusRaw = QCommentStatus.sending.rawValue
        comment.typeRaw = type.name()
        comment.roomName = self.name
        comment.roomTypeRaw = self.typeRaw
        comment.roomAvatar = self.avatarURL
        comment.isRead = true
        
        if let data = payload {
            comment.data = "\(data)"
        }
        
        self.addComment(newComment: comment)
        return comment
    }
    public func postTextMessage(text:String){
        let comment = QComment()
        let time = Double(Date().timeIntervalSince1970)
        let timeToken = UInt64(time * 10000)
        let uniqueID = "ios-\(timeToken)"
        
        comment.uniqueId = uniqueID
        comment.id = 0
        comment.roomId = self.id
        comment.text = text
        comment.createdAt = Double(Date().timeIntervalSince1970)
        comment.senderEmail = Qiscus.client.email
        comment.senderName = Qiscus.client.userName
        comment.statusRaw = QCommentStatus.sending.rawValue
        comment.typeRaw = QCommentType.text.name()
        
        self.addComment(newComment: comment)
        self.post(comment: comment)
    }
    
    public func post(comment:QComment, type:String? = nil, payload:JSON? = nil, onSuccess: @escaping ()->Void = {}){
        let service = QRoomService()
        let id = self.id
        //        self.resendPendingMessage()
        self.redeletePendingDeletedMessage()
        service.postComment(onRoom: id, comment: comment, type: type, payload:payload, onSuccess: onSuccess)
    }
    
    public func upload(comment:QComment, onSuccess:  @escaping (QRoom, QComment)->Void, onError:  @escaping (QRoom,QComment,String)->Void, onProgress:((Double)->Void)? = nil){
        self.updateCommentStatus(inComment: comment, status: .sending)
        let service = QRoomService()
        service.uploadCommentFile(inRoom: self, comment: comment, onSuccess: onSuccess, onError: onError, onProgress: onProgress)
    }
    
    public func downloadMedia(onComment comment:QComment, thumbImageRef: UIImage? = nil, isAudioFile: Bool = false, onSuccess: ((QComment)->Void)? = nil, onError:((String)->Void)? = nil, onProgress:((Double)->Void)? = nil){
        let service = QRoomService()
        service.downloadMedia(inRoom: self, comment: comment, thumbImageRef: thumbImageRef, isAudioFile: isAudioFile, onSuccess: onSuccess, onError: onError, onProgress: onProgress)
    }
    //    public func getIndexPath(ofComment comment:QComment)->IndexPath?{
    //        var section = self.comments.count - 1
    //        var indexPath:IndexPath? = nil
    //        var found = false
    //        for commentGroup in self.comments.reversed() {
    //            if commentGroup.date == comment.date && commentGroup.senderEmail == comment.senderEmail{
    //                var row = 0
    //                for commentTarget in commentGroup.comments {
    //                    if commentTarget.uniqueId == comment.uniqueId{
    //                        indexPath = IndexPath(item: row, section: section)
    //                        found = true
    //                        break
    //                    }
    //                    row += 1
    //                }
    //            }
    //            if found {
    //                break
    //            }else{
    //                section -= 1
    //            }
    //        }
    //        return indexPath
    //    }
    public func updateUserTyping(userEmail: String){
        if !self.isInvalidated {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            realm.refresh()
            if userEmail != self.typingUser {
                try! realm.write {
                    self.typingUser = userEmail
                }
                if userEmail != "" {
                    if self.typingTimer != nil {
                        self.typingTimer!.invalidate()
                    }
                    self.typingTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(self.clearUserTyping), userInfo: nil, repeats: false)
                }
            }
        }
    }
    @objc public func clearUserTyping(){
        if !self.isInvalidated {
            self.updateUserTyping(userEmail: "")
        }
    }
    public func deleteComment(comment:QComment){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        let id = self.id
        let cUid = comment.uniqueId
        func publishNotification(roomId:String){
            if let mainRoom = QRoom.room(withId: id){
                if let roomDelegate = mainRoom.delegate {
                    roomDelegate.room?(didDeleteComment: mainRoom)
                }
                QiscusNotification.publish(commentDeleteOnRoom: mainRoom)
            }
        }
        QiscusDBThread.sync {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            realm.refresh()
            if let r = QRoom.threadSaveRoom(withId: id){
                var i = r.rawComments.count - 1
                for c in r.rawComments.reversed() {
                    if c.uniqueId == cUid {
                        try! realm.write {
                            r.rawComments.remove(at: i)
                            realm.delete(c)
                        }
                        if cUid == r.lastCommentUniqueId {
                            r.recalculateLastComment()
                        }
                        if Thread.isMainThread {
                            publishNotification(roomId: id)
                        }else{
                            DispatchQueue.main.sync { autoreleasepool {
                                publishNotification(roomId: id)
                                }}
                        }
                        break
                    }
                    i -= 1
                }
            }
        }
    }
    public func participant(withEmail email:String)->QParticipant?{
        let savedParticipant = self.participants.filter("email == '\(email)'")
        if savedParticipant.count > 0{
            return savedParticipant.first!
        }else{
            return nil
        }
    }
    public func updateLastReadId(commentId:Int){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        if self.lastReadCommentId < commentId {
            try! realm.write {
                self.lastReadCommentId = commentId
            }
            if self.lastDeliveredCommentId < commentId {
                try! realm.write {
                    self.lastDeliveredCommentId = commentId
                }
            }
            //            self.updateUnreadCommentCount()
        }
    }
    
    public func readAll(){
        let id = self.id
        QiscusDBThread.async {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            realm.refresh()
            let unreadData =  realm.objects(QComment.self).filter("roomId == '\(id)' AND isRead ==  false").sorted(byKeyPath: "createdAt", ascending: true)
            
            if let last = unreadData.last {
                last.read()
            }
        }
    }
    public func updateUnreadCommentCount(){
        let id = self.id
        QiscusDBThread.async {
            if let room = QRoom.threadSaveRoom(withId: id){
                if room.rawComments.count > 0 {
                    let unreadComment = room.rawComments.filter("isRead == false")
                    let unread = unreadComment.count
                    
                    if room.unreadCount != unread {
                        room.updateUnreadCommentCount(count: unread)
                    }
                }
            }
        }
    }
    
    public class func publishStatus(roomId:String, commentId:Int, status:QCommentStatus){
        if let room = QRoom.room(withId: roomId) {
            if !room.isPublicChannel {
                QiscusBackgroundThread.async {
                    let service = QRoomService()
                    service.publishStatus(inRoom: roomId, commentId: commentId, commentStatus: status)
                }
            }
        } else {
            QiscusBackgroundThread.async {
                let service = QRoomService()
                service.publishStatus(inRoom: roomId, commentId: commentId, commentStatus: status)
            }
        }
    }
    
    public func setAvatar(url:String){
        if self.definedAvatarURL != url {
            let id = self.id
            QiscusDBThread.async {
                if let room = QRoom.threadSaveRoom(withId: id){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    realm.refresh()
                    try! realm.write {
                        room.definedAvatarURL = url
                        room.avatarData = nil
                    }
                    DispatchQueue.main.async {
                        if let cache = QRoom.room(withId: id) {
                            QiscusNotification.publish(roomChange: cache, onProperty: .avatar)
                            cache.delegate?.room?(didChangeName: cache)
                        }
                    }
                }
            }
        }
    }
    public func setName(name:String){
        if name != self.definedname {
            let id = self.id
            QiscusDBThread.async {
                if let room = QRoom.threadSaveRoom(withId: id) {
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    realm.refresh()
                    try! realm.write {
                        room.definedname = name
                    }
                    if room.type == .single {
                        for participant in room.participants {
                            if participant.email != Qiscus.client.email {
                                if let user = QUser.getUser(email: participant.email) {
                                    user.setName(name: name)
                                }
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        if let cache = QRoom.room(withId: id) {
                            QiscusNotification.publish(roomChange: cache, onProperty: .name)
                            cache.delegate?.room?(didChangeName: cache)
                        }
                    }
                }
            }
        }
    }
    
    public func loadComments(limit:Int, offset:String, onSuccess:@escaping ([QComment])->Void, onError:@escaping (String)->Void){
        if let commentId = Int(offset) {
            if commentId == 0 {
                onError("invalid offset")
                return
            }
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            realm.refresh()
            let data =  realm.objects(QComment.self).filter("roomId == '\(self.id)' AND id > \(commentId)").sorted(byKeyPath: "createdAt", ascending: true)
            if data.count >= limit {
                var comments = [QComment]()
                var i = 0
                for comment in data {
                    if i < limit {
                        comments.append(comment)
                    }else{
                        break
                    }
                    i += 1
                }
                onSuccess(comments)
            }else{
                QRoomService.loadComments(inRoom: self, limit: limit, offset: offset, onSuccess: onSuccess, onError: onError)
            }
        }else{
            onError("invalid offset")
        }
    }
    public func loadComments(onSuccess:@escaping ([QComment])->Void, onError:@escaping (String)->Void){
        QRoomService.loadComments(inRoom: self, onSuccess: onSuccess, onError: onError)
    }
    public func loadMore(limit:Int, offset:String, onSuccess:@escaping ([QComment],Bool)->Void, onError:@escaping (String)->Void){
        if let commentId = Int(offset) {
            if commentId == 0 {
                onError("invalid offset")
                return
            }
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            realm.refresh()
            let data =  realm.objects(QComment.self).filter("roomId == '\(self.id)' AND id < \(commentId)").sorted(byKeyPath: "createdAt", ascending: true)
            if data.count >= limit {
                var comments = [QComment]()
                var i = 0
                for comment in data {
                    if i < limit {
                        comments.append(comment)
                    }else{
                        break
                    }
                    i += 1
                }
                let first = comments.first!
                let hasMoreMessages = first.id == 0 ? false : true
                onSuccess(comments, hasMoreMessages)
            }else{
                // CALL API Here
                QRoomService.loadMore(inRoom: self, limit: limit, offset: offset, onSuccess: onSuccess, onError: onError)
            }
        }else{
            onError("invalid offset")
        }
    }
    
    public func clearMessages(onSuccess:@escaping ()->Void, onError:@escaping (Int)->Void){
        let uid = self.uniqueId
        QRoomService.clearMessages(inRoomsChannel: [uid], onSuccess: { (_, _) in
            onSuccess()
        }) { (statusCode) in
            onError(statusCode)
        }
    }
    
}
