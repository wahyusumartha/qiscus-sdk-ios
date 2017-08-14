//
//  QComment.swift
//  Example
//
//  Created by Ahmad Athaullah on 7/5/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftyJSON

public enum QReplyType:Int{
    case text
    case image
    case video
    case audio
    case document
    case other
}
@objc public enum QCellPosition:Int {
    case single,first,middle,last
}
@objc public enum QCommentType:Int {
    case text
    case image
    case video
    case audio
    case file
    case postback
    case account
    case reply
    case system
    case card
    case contact
    case custom
    
    func name() -> String{
        switch self {
            case .text      : return "text"
            case .image     : return "image"
            case .video     : return "video"
            case .audio     : return "audio"
            case .file      : return "file"
            case .postback  : return "postback"
            case .account   : return "account"
            case .reply     : return "reply"
            case .system    : return "system"
            case .card      : return "card"
            case .contact   : return "contact"
            case .custom    : return "custom type"
        }
    }
    init(name:String) {
        switch name {
            case "text","button_postback_response"     : self = .text ; break
            case "image"    : self = .image ; break
            case "video"    : self = .video ; break
            case "audio"    : self = .audio ; break
            case "file"     : self = .file ; break
            case "postback" : self = .postback ; break
            case "account"  : self = .account ; break
            case "reply"    : self = .reply ; break
            case "system"   : self = .system ; break
            case "card"     : self = .card ; break
            case "contact"  : self = .contact ; break
            default         : self = .custom ; break
        }
    }
}
@objc public enum QCommentStatus:Int{
    case sending
    case sent
    case delivered
    case read
    case failed
}
@objc public protocol QCommentDelegate {
    func comment(didChangeStatus status:QCommentStatus)
    func comment(didChangePosition position:QCellPosition)
    
    // Audio comment delegate
    @objc optional func comment(didChangeDurationLabel label:String)
    @objc optional func comment(didChangeCurrentTimeSlider value:Float)
    @objc optional func comment(didChangeSeekTimeLabel label:String)
    @objc optional func comment(didChangeAudioPlaying playing:Bool)
    
    // File comment delegate
    @objc optional func comment(didDownload downloading:Bool)
    @objc optional func comment(didUpload uploading:Bool)
    @objc optional func comment(didChangeProgress progress:CGFloat)
}
public class QComment:Object {
    static var cache = [String: QComment]()
    
    public dynamic var uniqueId: String = ""
    public dynamic var id:Int = 0
    public dynamic var roomId:Int = 0
    public dynamic var beforeId:Int = 0
    public dynamic var text:String = ""
    public dynamic var createdAt: Double = 0
    public dynamic var senderEmail:String = ""
    public dynamic var senderName:String = ""
    public dynamic var statusRaw:Int = QCommentStatus.sending.rawValue
    public dynamic var typeRaw:String = QCommentType.text.name()
    public dynamic var data:String = ""
    public dynamic var cellPosRaw:Int = 0
    
    private dynamic var cellWidth:Float = 0
    private dynamic var cellHeight:Float = 0
    internal dynamic var textFontName:String = ""
    internal dynamic var textFontSize:Float = 0
    
    // MARK : - Ignored Parameters
    var displayImage:UIImage?
    public var delegate:QCommentDelegate?
    
    // audio variable
    public dynamic var durationLabel = ""
    public dynamic var currentTimeSlider = Float(0)
    public dynamic var seekTimeLabel = "00:00"
    public dynamic var audioIsPlaying = false
    // file variable
    public dynamic var isDownloading = false
    public dynamic var isUploading = false
    public dynamic var progress = CGFloat(0)
    
    
    override public static func ignoredProperties() -> [String] {
        return ["displayImage","delegate"]
    }
    
    //MARK : - Getter variable
    
    private var linkTextAttributes:[String: Any]{
        get{
            var foregroundColorAttributeName = QiscusColorConfiguration.sharedInstance.leftBaloonLinkColor
            var underlineColorAttributeName = QiscusColorConfiguration.sharedInstance.leftBaloonLinkColor
            if self.senderEmail == QiscusMe.sharedInstance.email{
                foregroundColorAttributeName = QiscusColorConfiguration.sharedInstance.rightBaloonLinkColor
                underlineColorAttributeName = QiscusColorConfiguration.sharedInstance.rightBaloonLinkColor
            }
            return [
                NSForegroundColorAttributeName: foregroundColorAttributeName,
                NSUnderlineColorAttributeName: underlineColorAttributeName,
                NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue,
                NSFontAttributeName: Qiscus.style.chatFont
            ]
        }
    }
    public var file:QFile? {
        get{
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            return realm.object(ofType: QFile.self, forPrimaryKey: self.uniqueId)
        }
    }
    public var sender:QUser? {
        get{
            if let cache = QUser.cache[self.senderEmail] {
                return cache
            }else{
                let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                if let result = realm.object(ofType: QUser.self, forPrimaryKey: self.senderEmail) {
                    QUser.cache[self.senderEmail] = result
                    return result
                }else{
                    return nil
                }
            }
        }
    }
    public var cellPos:QCellPosition {
        get{
            return QCellPosition(rawValue: self.cellPosRaw)!
        }
    }
    public var type:QCommentType {
        get{
            return QCommentType(name: self.typeRaw)
        }
    }
    public var status:QCommentStatus {
        get{
            return QCommentStatus(rawValue: self.statusRaw)!
        }
    }
    public var date: String {
        get {
            let date = Date(timeIntervalSince1970: self.createdAt)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d MMMM yyyy"
            let dateString = dateFormatter.string(from: date)
            
            return dateString
        }
    }
    public var cellIdentifier:String{
        get{
            var position = "Left"
            if self.senderEmail == QiscusMe.sharedInstance.email {
                position = "Right"
            }
            switch self.type {
            case .system:
                return "cellSystem"
            case .card:
                return "cellCard\(position)"
            case .postback,.account:
                return "cellPostbackLeft"
            case .image, .video:
                return "cellMedia\(position)"
            case .audio:
                return "cellAudio\(position)"
            case .file:
                return "cellFile\(position)"
            case .contact:
                return "cellContactRight"
            default:
                return "cellText\(position)"
            }
        }
    }
    
    public var time: String {
        get {
            let date = Date(timeIntervalSince1970: self.createdAt)
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            let timeString = timeFormatter.string(from: date)
            
            return timeString
        }
    }
    public var textSize:CGSize {
        var recalculate = false
        
        func recalculateSize()->CGSize{
            let textView = UITextView()
            textView.font = Qiscus.style.chatFont
            textView.dataDetectorTypes = .all
            textView.linkTextAttributes = self.linkTextAttributes
            
            let maxWidth:CGFloat = QiscusUIConfiguration.chatTextMaxWidth
            textView.attributedText = attributedText
            
            var size = textView.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
            
            if self.type == .postback && self.data != ""{
                
                let payload = JSON(parseJSON: self.data)
                
                if let buttonsPayload = payload.array {
                    let heightAdd = CGFloat(35 * buttonsPayload.count)
                    size.height += heightAdd
                }else{
                    size.height += 35
                }
            }else if self.type == .account && self.data != ""{
                size.height += 35
            }else if self.type == .card {
                let payload = JSON(parseJSON: self.data)
                let buttons = payload["buttons"].arrayValue
                size.height = CGFloat(240 + (buttons.count * 45)) + 5
            }else if self.type == .contact {
                size.height = 93
            }
            return size
        }
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        if Float(Qiscus.style.chatFont.pointSize) != self.textFontSize || Qiscus.style.chatFont.familyName != self.textFontName{
            recalculate = true
            try! realm.write {
                self.textFontSize = Float(Qiscus.style.chatFont.pointSize)
                self.textFontName = Qiscus.style.chatFont.familyName
            }
        }else if self.cellWidth == 0 || self.cellHeight == 0 {
            recalculate = true
        }
        if recalculate {
            let newSize = recalculateSize()
            try! realm.write {
                self.cellHeight = Float(newSize.height)
                self.cellWidth = Float(newSize.width)
            }
            return newSize
        }else{
            return CGSize(width: CGFloat(self.cellWidth), height: CGFloat(self.cellHeight))
        }
    }
    
    var textAttribute:[String: Any]{
        get{
            if self.type == .system {
                let style = NSMutableParagraphStyle()
                style.alignment = NSTextAlignment.center
                let fontSize = Qiscus.style.chatFont.pointSize
                let systemFont = Qiscus.style.chatFont.withSize(fontSize - 4.0)
                let foregroundColorAttributeName = QiscusColorConfiguration.sharedInstance.systemBalloonTextColor
                
                return [
                    NSForegroundColorAttributeName: foregroundColorAttributeName,
                    NSFontAttributeName: systemFont,
                    NSParagraphStyleAttributeName: style
                ]
            }else{
                var foregroundColorAttributeName = QiscusColorConfiguration.sharedInstance.leftBaloonTextColor
                if self.senderEmail == QiscusMe.sharedInstance.email{
                    foregroundColorAttributeName = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
                }
                return [
                    NSForegroundColorAttributeName: foregroundColorAttributeName,
                    NSFontAttributeName: Qiscus.style.chatFont
                ]
            }
        }
    }
    
    var attributedText:NSMutableAttributedString {
        get{
            let attributedText = NSMutableAttributedString(string: self.text)
            let allRange = (self.text as NSString).range(of: self.text)
            attributedText.addAttributes(self.textAttribute, range: allRange)
            
            return attributedText
        }
    }
    public var statusInfo:QCommentInfo? {
        get{
            if let room = QRoom.room(withId: self.roomId) {
                let commentInfo = QCommentInfo()
                commentInfo.comment = self
                commentInfo.deliveredUser = [QParticipant]()
                commentInfo.readUser = [QParticipant]()
                for participant in room.participants {
                    if participant.email != QiscusMe.sharedInstance.email{
                        if participant.lastReadCommentId >= self.id {
                            commentInfo.readUser.append(participant)
                        }else{
                            commentInfo.deliveredUser.append(participant)
                        }
                    }
                }
                return commentInfo
            }
            return nil
        }
    }
    override open class func primaryKey() -> String {
        return "uniqueId"
    }
    
    public class func comment(withUniqueId uniqueId:String)->QComment?{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        if let comment = QComment.cache[uniqueId] {
            return comment
        }else{
            if let comment =  realm.object(ofType: QComment.self, forPrimaryKey: uniqueId) {
                let _ = comment.textSize
                QComment.cache[uniqueId] = comment
                return QComment.cache[uniqueId]
            }
        }
        return nil
    }
    public class func comment(withId id:Int)->QComment?{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let data =  realm.objects(QComment.self).filter("id == \(id) && id != 0")
        
        if data.count > 0 {
            let commentData = data.first!
            if let comment = QComment.cache[commentData.uniqueId] {
                return comment
            }else{
                QComment.cache[commentData.uniqueId] = commentData
                return QComment.cache[commentData.uniqueId]
            }
        }else{
            return nil
        }
    }
    internal class func countComments(afterId id:Int, roomId:Int)->Int{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let data =  realm.objects(QComment.self).filter("id > \(id) AND roomId = \(roomId)").sorted(byKeyPath: "createdAt", ascending: true)
        
        return data.count
    }
    fileprivate func isAttachment(text:String) -> Bool {
        var check:Bool = false
        if(text.hasPrefix("[file]")){
            check = true
        }
        return check
    }
    public func getAttachmentURL(message: String) -> String {
        let component1 = message.components(separatedBy: "[file]")
        let component2 = component1.last!.components(separatedBy: "[/file]")
        let mediaUrlString = component2.first?.trimmingCharacters(in: CharacterSet.whitespaces).replacingOccurrences(of: " ", with: "%20")
        return mediaUrlString!
    }
    public func fileName(text:String) ->String{
        let url = getAttachmentURL(message: text)
        var fileName:String? = ""
        
        let remoteURL = url.replacingOccurrences(of: " ", with: "%20")
        let  mediaURL = URL(string: remoteURL)!
        fileName = mediaURL.lastPathComponent.replacingOccurrences(of: "%20", with: "_")
        
        return fileName!
    }
    private func fileExtension(fromURL url:String) -> String{
        var ext = ""
        if url.range(of: ".") != nil{
            let fileNameArr = url.characters.split(separator: ".")
            ext = String(fileNameArr.last!).lowercased()
            if ext.contains("?"){
                let newArr = ext.characters.split(separator: "?")
                ext = String(newArr.first!).lowercased()
            }
        }
        return ext
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
            case "pdf","pdf_","doc","docx","ppt","pptx","xls","xlsx","txt":
                return .document
            default:
                return .other
            }
        }else{
            return .text
        }
    }
    public func forward(toRoomWithId roomId: Int){
        let comment = QComment()
        let time = Double(Date().timeIntervalSince1970)
        let timeToken = UInt64(time * 10000)
        let uniqueID = "ios-\(timeToken)"
        
        comment.uniqueId = uniqueID
        comment.roomId = roomId
        comment.text = self.text
        comment.createdAt = Double(Date().timeIntervalSince1970)
        comment.senderEmail = QiscusMe.sharedInstance.email
        comment.senderName = QiscusMe.sharedInstance.userName
        comment.statusRaw = QCommentStatus.sending.rawValue
        
        print("commentType to forward : \(comment.type.rawValue)")
        
        if self.type == .reply {
            comment.typeRaw = QCommentType.text.name()
        }else{
            comment.typeRaw = self.type.name()
        }
        var file:QFile? = nil
        if let fileRef = self.file {
            file = QFile()
            file!.id = uniqueID
            file!.roomId = roomId
            file!.url = fileRef.url
            file!.senderEmail = QiscusMe.sharedInstance.email
            file!.localPath = fileRef.localPath
            file!.mimeType = fileRef.mimeType
            file!.localThumbPath = fileRef.localThumbPath
            file!.localMiniThumbPath = fileRef.localMiniThumbPath
        }
        
        if let room = QRoom.room(withId: roomId){
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            if file != nil {
                try! realm.write {
                    realm.add(file!)
                }
            }
            room.addComment(newComment: comment)
        }
        let service = QRoomService()
        service.postComment(onRoom: roomId, comment: comment)
    }
    
    
    // MARK : updater method
    public func updateStatus(status:QCommentStatus){
        
        if self.status != status && (self.statusRaw < status.rawValue || self.status == .failed){
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            try! realm.write {
                self.statusRaw = status.rawValue
            }
            let delay = 0.4 * Double(NSEC_PER_SEC)
            
            let time = DispatchTime.now() + delay / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: time, execute: {
                if let cache = QComment.cache[self.uniqueId] {
                    cache.delegate?.comment(didChangeStatus: status)
                }
            })
        }
    }
    public func updateCellPos(cellPos: QCellPosition){
        if self.cellPos != cellPos {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            try! realm.write {
                self.cellPosRaw = cellPos.rawValue
            }
            self.delegate?.comment(didChangePosition: cellPos)
        }
    }
    public func updateDurationLabel(label:String){
        if self.durationLabel != label {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            try! realm.write {
                self.durationLabel = label
            }
            self.delegate?.comment?(didChangeDurationLabel: label)
        }
    }
    public func updateTimeSlider(value:Float){
        if self.currentTimeSlider != value {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            try! realm.write {
                self.currentTimeSlider = value
            }
            self.delegate?.comment?(didChangeCurrentTimeSlider: value)
        }
    }
    public func updateSeekLabel(label:String){
        if self.seekTimeLabel != label {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            try! realm.write {
                self.seekTimeLabel = label
            }
            self.delegate?.comment?(didChangeSeekTimeLabel: label)
        }
    }
    public func updatePlaying(playing:Bool){
        if self.audioIsPlaying != playing {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            try! realm.write {
                self.audioIsPlaying = playing
            }
            self.delegate?.comment?(didChangeAudioPlaying: playing)
        }
    }
    public func updateUploading(uploading:Bool){
        if self.isUploading != uploading {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            try! realm.write {
                self.isUploading = uploading
            }
            self.delegate?.comment?(didUpload: uploading)
        }
    }
    public func updateDownloading(downloading:Bool){
        if self.isDownloading != downloading {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            try! realm.write {
                self.isDownloading = downloading
            }
            self.delegate?.comment?(didDownload: downloading)
        }
    }
    public func updateProgress(progress:CGFloat){
        if self.progress != progress {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            try! realm.write {
                self.progress = progress
            }
            self.delegate?.comment?(didChangeProgress: progress)
        }
    }
    internal class func tempComment(fromJSON json:JSON)->QComment{
        let temp = QComment()
        
        let commentId = json["id"].intValue
        let commentUniqueId = json["unique_temp_id"].stringValue
        var commentText = json["message"].stringValue
        let commentSenderName = json["username"].stringValue
        let commentCreatedAt = json["unix_timestamp"].doubleValue
        let commentBeforeId = json["comment_before_id"].intValue
        let senderEmail = json["email"].stringValue
        let commentType = json["type"].stringValue
        let roomId = json["room_id"].intValue
        
        if commentType == "reply" || commentType == "buttons" {
            commentText = json["payload"]["text"].stringValue
        }
        
        let avatarURL = json["user_avatar_url"].stringValue
        
        let _ = QUser.saveUser(withEmail: senderEmail, fullname: commentSenderName, avatarURL: avatarURL, lastSeen: commentCreatedAt)
        
        temp.uniqueId = commentUniqueId
        temp.id = commentId
        temp.roomId = roomId
        temp.text = commentText
        temp.senderName = commentSenderName
        temp.createdAt = commentCreatedAt
        temp.beforeId = commentBeforeId
        temp.senderEmail = senderEmail
        temp.cellPosRaw = QCellPosition.single.rawValue
        
        switch commentType {
        case "contact":
            temp.data = "\(json["payload"])"
            temp.typeRaw = QCommentType.contact.name()
            break
        case "buttons":
            temp.data = "\(json["payload"]["buttons"])"
            temp.typeRaw = QCommentType.postback.name()
            break
        case "account_linking":
            temp.data = "\(json["payload"])"
            temp.typeRaw = QCommentType.account.name()
            break
        case "reply":
            temp.data = "\(json["payload"])"
            temp.typeRaw = QCommentType.reply.name()
            break
        case "system_event":
            temp.data = "\(json["payload"])"
            temp.typeRaw = QCommentType.system.name()
            break
        case "card":
            temp.data = "\(json["payload"])"
            temp.typeRaw = QCommentType.card.name()
            break
        case "button_postback_response" :
            temp.data = "\(json["payload"])"
            temp.typeRaw = QCommentType.text.name()
            break
        case "text":
            if temp.text.hasPrefix("[file]"){
                var type = QiscusFileType.file
                let fileURL = QFile.getURL(fromString: temp.text)
                if temp.file == nil {
                    let file = QFile()
                    file.id = temp.uniqueId
                    file.url = fileURL
                    file.senderEmail = temp.senderEmail
                    type = file.type
                }
                switch type {
                case .image:
                    temp.typeRaw = QCommentType.image.name()
                    break
                case .video:
                    temp.typeRaw = QCommentType.video.name()
                    break
                case .audio:
                    temp.typeRaw = QCommentType.audio.name()
                    break
                default:
                    temp.typeRaw = QCommentType.file.name()
                    break
                }
            }else{
                temp.typeRaw = QCommentType.text.name()
            }
            break
            default:
                temp.data = "\(json["payload"])"
                temp.typeRaw = commentType
            break
        }
        return temp
    }
    internal func update(commentId:Int, beforeId:Int){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        try! realm.write {
            self.id = commentId
            self.beforeId = beforeId
        }
    }
    internal func update(text:String){
        if self.text != text {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            try! realm.write {
                self.text = text
            }
        }
    }
}
