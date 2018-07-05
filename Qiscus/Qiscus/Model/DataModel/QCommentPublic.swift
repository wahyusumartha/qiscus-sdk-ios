//
//  QCommentFunction.swift
//  Qiscus
//
//  Created by Qiscus on 05/07/18.
//

import UIKit
import RealmSwift

// MARK: Public function
extension QComment {
    
    public func updateCellPos(cellPos: QCellPosition){
        let uId = self.uniqueId
        if self.cellPos != cellPos {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            realm.refresh()
            if self.isInvalidated { return }
            try! realm.write {
                self.cellPosRaw = cellPos.rawValue
            }
            func execute(){
                if let cache = QComment.cache[uId] {
                    if cache.isInvalidated { return }
                    cache.delegate?.comment(didChangePosition: cache, position: cellPos)
                }
            }
            if Thread.isMainThread{
                execute()
            }else{
                DispatchQueue.main.sync {
                    execute()
                }
            }
        }
    }
    
    public func updateDurationLabel(label:String){
        let uId = self.uniqueId
        if self.durationLabel != label {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            realm.refresh()
            try! realm.write {
                self.durationLabel = label
            }
            func execute(){
                if let cache = QComment.cache[uId] {
                    cache.delegate?.comment?(didChangeDurationLabel: cache, label: label)
                }
            }
            if Thread.isMainThread{
                execute()
            }else{
                DispatchQueue.main.sync {
                    execute()
                }
            }
        }
    }
    
    public func updateTimeSlider(value:Float){
        let uId = self.uniqueId
        if self.currentTimeSlider != value {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            realm.refresh()
            try! realm.write {
                self.currentTimeSlider = value
            }
            func execute(){
                if let cache = QComment.cache[uId] {
                    cache.delegate?.comment?(didChangeCurrentTimeSlider: cache, value: value)
                }
            }
            if Thread.isMainThread{
                execute()
            }else{
                DispatchQueue.main.sync {
                    execute()
                }
            }
        }
    }
    
    public func updateSeekLabel(label:String){
        let uId = self.uniqueId
        if self.seekTimeLabel != label {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            realm.refresh()
            try! realm.write {
                self.seekTimeLabel = label
            }
            func execute(){
                if let cache = QComment.cache[uId] {
                    cache.delegate?.comment?(didChangeSeekTimeLabel: cache, label: label)
                }
            }
            if Thread.isMainThread{
                execute()
            }else{
                DispatchQueue.main.sync {
                    execute()
                }
            }
        }
    }
    
    public func updatePlaying(playing:Bool){
        let uId = self.uniqueId
        if self.audioIsPlaying != playing {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            realm.refresh()
            try! realm.write {
                self.audioIsPlaying = playing
            }
            func execute(){
                if let cache = QComment.cache[uId] {
                    cache.delegate?.comment?(didChangeAudioPlaying: cache, playing: playing)
                }
            }
            if Thread.isMainThread{
                execute()
            }else{
                DispatchQueue.main.sync {
                    execute()
                }
            }
        }
    }
    
    public func updateUploading(uploading:Bool){
        let uId = self.uniqueId
        DispatchQueue.main.async {
            if let comment = QComment.cache[uId] {
                if comment.isUploading != uploading {
                    comment.isUploading = uploading
                    comment.delegate?.comment?(didUpload: comment, uploading: uploading)
                }
            }
        }
    }
    
    public func updateDownloading(downloading:Bool){
        let uId = self.uniqueId
        DispatchQueue.main.async {
            if let comment = QComment.cache[uId] {
                if comment.isDownloading != downloading {
                    comment.isDownloading = downloading
                    if let delegate = comment.delegate {
                        delegate.comment?(didDownload: comment, downloading: downloading)
                    }
                }
            }
        }
    }
    
    public func updateProgress(progress:CGFloat){
        let uId = self.uniqueId
        DispatchQueue.main.async {
            if let comment = QComment.cache[uId] {
                if comment.progress != progress {
                    comment.progress = progress
                    comment.delegate?.comment?(didChangeProgress: comment, progress: progress)
                }
            }
        }
    }
    
    public class func decodeDictionary(data:[AnyHashable : Any]) -> QComment? {
        if let isQiscusdata = data["qiscus_commentdata"] as? Bool{
            if isQiscusdata {
                let temp = QComment()
                if let uniqueId = data["qiscus_uniqueId"] as? String{
                    temp.uniqueId = uniqueId
                }
                if let id = data["qiscus_id"] as? Int {
                    temp.id = id
                }
                if let roomId = data["qiscus_roomId"] as? String {
                    temp.roomId = roomId
                }
                if let beforeId = data["qiscus_beforeId"] as? Int {
                    temp.beforeId = beforeId
                }
                if let text = data["qiscus_text"] as? String {
                    temp.text = text
                }
                if let createdAt = data["qiscus_createdAt"] as? Double{
                    temp.createdAt = createdAt
                }
                if let email = data["qiscus_senderEmail"] as? String{
                    temp.senderEmail = email
                }
                if let name = data["qiscus_senderName"] as? String{
                    temp.senderName = name
                }
                if let statusRaw = data["qiscus_statusRaw"] as? Int {
                    temp.statusRaw = statusRaw
                }
                if let typeRaw = data["qiscus_typeRaw"] as? String {
                    temp.typeRaw = typeRaw
                }
                if let payload = data["qiscus_data"] as? String {
                    temp.data = payload
                }
                
                return temp
            }
        }
        return nil
    }
    
    public func read(check:Bool = true){
        if self.isInvalidated {return}
        let uniqueId = self.uniqueId
        if self.isRead {return}
        QiscusDBThread.async {
            if let comment = QComment.threadSaveComment(withUniqueId: uniqueId){
                if comment.isInvalidated {return}
                let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                realm.refresh()
                try! realm.write {
                    if !comment.isInvalidated {
                        comment.isRead = true
                    }
                }
                if check {
                    let data = realm.objects(QComment.self).filter("isRead == false AND createdAt < \(comment.createdAt) AND roomId == '\(comment.roomId)'")
                    for olderComment in data {
                        try! realm.write {
                            if !olderComment.isInvalidated {
                                olderComment.isRead = true
                            }
                        }
                    }
                }
                if let room = QRoom.threadSaveRoom(withId: comment.roomId) {
                    room.updateUnreadCommentCount()
                    if comment.id > 0 {
                        let roomId = room.id
                        let commentId = comment.id
                        QRoom.publishStatus(roomId: roomId, commentId: commentId, status: .read)
                    }
                }
            }
        }
    }
    
    public func receive(){
        let uniqueId = self.uniqueId
        QiscusDBThread.async {
            if let comment = QComment.threadSaveComment(withUniqueId: uniqueId){
                if let room = QRoom.threadSaveRoom(withId: comment.roomId) {
                    if room.lastDeliveredCommentId < comment.id {
                        QRoom.publishStatus(roomId: room.id, commentId: comment.id, status: .delivered)
                        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                        realm.refresh()
                        try! realm.write {
                            room.lastDeliveredCommentId = comment.id
                        }
                    }
                }
            }
        }
    }
    
    public func encodeDictionary()->[AnyHashable : Any]{
        var data = [AnyHashable : Any]()
        
        data["qiscus_commentdata"] = true
        data["qiscus_uniqueId"] = self.uniqueId
        data["qiscus_id"] = self.id
        data["qiscus_roomId"] = self.roomId
        data["qiscus_beforeId"] = self.beforeId
        data["qiscus_text"] = self.text
        data["qiscus_createdAt"] = self.createdAt
        data["qiscus_senderEmail"] = self.senderEmail
        data["qiscus_senderName"] = self.senderName
        data["qiscus_statusRaw"] = self.statusRaw
        data["qiscus_typeRaw"] = self.typeRaw
        data["qiscus_data"] = self.data
        
        return data
    }
    
    public func set(extras data:[String:Any], onSuccess: @escaping (QComment)->Void, onError: @escaping (QComment, String)->Void){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        if let jsonData = try? JSONSerialization.data(withJSONObject: data as Any, options: []){
            if let jsonString = String(data: jsonData,
                                       encoding: .ascii){
                try! realm.write {
                    self.rawExtra = jsonString
                }
                onSuccess(self)
            }else{
                Qiscus.printLog(text: "cant parse object")
                onError(self, "cant parse object")
            }
        }else{
            Qiscus.printLog(text: "invalid json object")
            onError(self,"invalid json object")
        }
    }
    
    public func set(extras data:[String:Any])->QComment?{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        if let jsonData = try? JSONSerialization.data(withJSONObject: data as Any, options: []){
            if let jsonString = String(data: jsonData,
                                       encoding: .ascii){
                try! realm.write {
                    self.rawExtra = jsonString
                }
                return self
            }else{
                Qiscus.printLog(text: "cant parse object")
                return nil
            }
        }else{
            Qiscus.printLog(text: "invalid json object")
            return nil
        }
    }
    
    public func delete(forMeOnly forMe:Bool = false, hardDelete:Bool = false, onSuccess: @escaping ()->Void, onError: @escaping (Int?)->Void){
        let uid = self.uniqueId
        let roomId = self.roomId
        QiscusBackgroundThread.async {
            if let c = QComment.threadSaveComment(withUniqueId: uid) {
                c.updateStatus(status: .deleting)
                QRoomService.delete(messagesWith: [uid], forMe: forMe, hardDelete: hardDelete, onSuccess: { (uids) in
                    if uids.contains(uid){
                        DispatchQueue.main.async {
                            onSuccess()
                        }
                        
                    }
                }, onError: { (uids, statusCode) in
                    if uids.contains(uid){
                        if let comment = QComment.threadSaveComment(withUniqueId: uid){
                            comment.updateStatus(status: .deletePending)
                        }
                    }
                    DispatchQueue.main.async {
                        onError(statusCode)
                    }
                })
            }
        }
    }
    
    public func getAttachmentURL(message: String) -> String {
        let component1 = message.components(separatedBy: "[file]")
        let component2 = component1.last!.components(separatedBy: "[/file]")
        let mediaUrlString = component2.first?.trimmingCharacters(in: CharacterSet.whitespaces).replacingOccurrences(of: " ", with: "%20")
        return mediaUrlString!
    }
    
    public func fileName(text:String) ->String{
        let url = getAttachmentURL(message: text)
        var fileName:String = ""
        
        let remoteURL = url.replacingOccurrences(of: " ", with: "%20").replacingOccurrences(of: "’", with: "%E2%80%99")
        
        if let mediaURL = URL(string: remoteURL) {
            fileName = mediaURL.lastPathComponent.replacingOccurrences(of: "%20", with: "_")
        }
        
        return fileName
    }
    
    // MARK : updater method
    public func updateStatus(status:QCommentStatus){
        let uId = self.uniqueId
        let rId = self.roomId
        
        func update (c:QComment){
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            realm.refresh()
            if c.isInvalidated {return}
            try! realm.write {
                if !c.isInvalidated {
                    c.statusRaw = status.rawValue
                }
            }
            if status == .deleted {
                //                if !c.isInvalidated {
                //                    try! realm.write {
                //                        c.text = "This message was deleted"
                //                        c.typeRaw = QCommentType.text.name()
                //                    }
                //                }
                if let r = QRoom.threadSaveRoom(withId: rId){
                    if r.lastCommentUniqueId == uId {
                        r.recalculateLastComment()
                    }
                }
            }
            DispatchQueue.main.async {
                if let cache = QComment.cache[uId]{
                    QiscusNotification.publish(messageStatus: cache, status: status)
                    cache.delegate?.comment(didChangeStatus: cache, status: status)
                }
            }
        }
        QiscusDBThread.async {
            if let c = QComment.threadSaveComment(withUniqueId: uId){
                if c.status == status { return }
                switch c.status {
                case .read:
                    if (status == .deleting || status == .deletePending || status == .deleted){
                        update(c: c)
                    }
                    break
                case .deleted: break
                case .deleting, .deletePending:
                    if  (status != c.status) && ( status == .deletePending || status == .deleted || status == .deleting){
                        update(c: c)
                    }
                    break
                case .sent:
                    if status == .delivered || status == .read || status == .deleting || status == .deletePending || status == .deleted{
                        update(c: c)
                    }
                    break
                case .delivered:
                    if status == .read || status == .deleting || status == .deletePending || status == .deleted{
                        update(c: c)
                    }
                    break
                default:
                    update(c: c)
                    break
                }
            }
        }
    }
    
    public func replyType(message:String)->QReplyType{
        if self.isAttachment(text: message){
            let url = getAttachmentURL(message: message)
            
            switch self.fileExtension(fromURL: url) {
            case "jpg","jpg_","png","png_","gif","gif_":
                return .image
            case "m4a","m4a_","aac","aac_","mp3","mp3_":
                return .audio
            case "mov","mov_","mp4","mp4_":
                return .video
            case "pdf","pdf_":
                return .document
            case "doc","docx","ppt","pptx","xls","xlsx","txt":
                return .file
            default:
                return .other
            }
        }else{
            return .text
        }
    }
    
    public func forward(toRoomWithId roomId: String){
        let comment = QComment()
        let time = Double(Date().timeIntervalSince1970)
        let timeToken = UInt64(time * 10000)
        let uniqueID = "ios-\(timeToken)"
        
        comment.uniqueId = uniqueID
        comment.roomId = roomId
        comment.text = self.text
        comment.createdAt = Double(Date().timeIntervalSince1970)
        comment.senderEmail = Qiscus.client.email
        comment.senderName = Qiscus.client.userName
        comment.statusRaw = QCommentStatus.sending.rawValue
        comment.data = self.data
        comment.typeRaw = self.type.name()
        comment.rawExtra = self.rawExtra
        
        if self.type == .reply {
            comment.typeRaw = QCommentType.text.name()
        }
        
        var file:QFile? = nil
        
        if let fileRef = self.file {
            file = QFile()
            file!.id = uniqueID
            file!.roomId = roomId
            file!.url = fileRef.url
            file!.filename = fileRef.filename
            file!.senderEmail = Qiscus.client.email
            file!.localPath = fileRef.localPath
            file!.mimeType = fileRef.mimeType
            file!.localThumbPath = fileRef.localThumbPath
            file!.localMiniThumbPath = fileRef.localMiniThumbPath
            file!.pages = fileRef.pages
            file!.size = fileRef.size
        }
        
        if let room = QRoom.room(withId: roomId){
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            realm.refresh()
            if file != nil {
                try! realm.write {
                    realm.add(file!, update:true)
                }
            }
            room.addComment(newComment: comment)
            room.post(comment: comment)
        }
        
    }
    
    // MARK: Class Func
    public class func comment(withBeforeId id:Int)->QComment?{
        if Thread.isMainThread {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            realm.refresh()
            let data =  realm.objects(QComment.self).filter("beforeId == \(id) && id != 0")
            
            if data.count > 0 {
                let commentData = data.first!
                return QComment.comment(withUniqueId: commentData.uniqueId)
            }
        }
        return nil
    }
    
    public class func threadSaveComment(withUniqueId uniqueId:String)->QComment?{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        let comments = realm.objects(QComment.self).filter("uniqueId == '\(uniqueId)'")
        if comments.count > 0 {
            let comment = comments.first!
            return comment
        }
        return nil
    }
    
    public class func comments(onRoom roomId: String) -> [QComment] {
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        
        let comments = realm.objects(QComment.self).filter("roomId == '\(roomId)'")
        
        return Array(comments)
    }
    
    public class func comment(withUniqueId uniqueId:String)->QComment?{
        if Thread.isMainThread {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            realm.refresh()
            if let comment = QComment.cache[uniqueId] {
                if !comment.isInvalidated{
                    return comment
                }
            }
            let comments = realm.objects(QComment.self).filter("uniqueId == '\(uniqueId)'")
            if comments.count > 0 {
                let comment = comments.first!
                let _ = comment.textSize
                comment.cacheObject()
                return comment
            }
        }
        return nil
    }
    
    public class func comment(withId id:Int)->QComment?{
        if Thread.isMainThread {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            realm.refresh()
            let data =  realm.objects(QComment.self).filter("id == \(id) && id != 0")
            
            if data.count > 0 {
                let commentData = data.first!
                return QComment.comment(withUniqueId: commentData.uniqueId)
            }
        }
        return nil
    }
    
    // MARK: Helper
    fileprivate func isAttachment(text:String) -> Bool {
        var check:Bool = false
        if(text.hasPrefix("[file]")){
            check = true
        }
        return check
    }
    
    private func fileExtension(fromURL url:String) -> String{
        var ext = ""
        if url.range(of: ".") != nil{
            let fileNameArr = url.split(separator: ".")
            ext = String(fileNameArr.last!).lowercased()
            if ext.contains("?"){
                let newArr = ext.split(separator: "?")
                ext = String(newArr.first!).lowercased()
            }
        }
        return ext
    }
}
