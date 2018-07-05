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
    case location
    case contact
    case file
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
    case location
    case custom
    case document
    case carousel
    
    static let all = [text.name(), image.name(), video.name(), audio.name(),file.name(),postback.name(),account.name(), reply.name(), system.name(), card.name(), contact.name(), location.name(), custom.name()]
    
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
            case .contact   : return "contact_person"
            case .location  : return "location"
            case .custom    : return "custom"
            case .document  : return "document"
            case .carousel  : return "carousel"
        }
    }
    init(name:String) {
        switch name {
            case "text","button_postback_response"     : self = .text ; break
            case "image"            : self = .image ; break
            case "video"            : self = .video ; break
            case "audio"            : self = .audio ; break
            case "file"             : self = .file ; break
            case "postback"         : self = .postback ; break
            case "account"          : self = .account ; break
            case "reply"            : self = .reply ; break
            case "system"           : self = .system ; break
            case "card"             : self = .card ; break
            case "contact_person"   : self = .contact ; break
            case "location"         : self = .location; break
            case "document"         : self = .document; break
            case "carousel"         : self = .carousel; break
            default                 : self = .custom ; break
        }
    }
}
@objc public enum QCommentStatus:Int{
    case sending
    case pending
    case sent
    case delivered
    case read
    case failed
    case deleting
    case deletePending
    case deleted
}
@objc public protocol QCommentDelegate {
    func comment(didChangeStatus comment:QComment, status:QCommentStatus)
    func comment(didChangePosition comment:QComment, position:QCellPosition)
    
    // Audio comment delegate
    @objc optional func comment(didChangeDurationLabel comment:QComment, label:String)
    @objc optional func comment(didChangeCurrentTimeSlider comment:QComment, value:Float)
    @objc optional func comment(didChangeSeekTimeLabel comment:QComment, label:String)
    @objc optional func comment(didChangeAudioPlaying comment:QComment, playing:Bool)
    
    // File comment delegate
    @objc optional func comment(didDownload comment:QComment, downloading:Bool)
    @objc optional func comment(didUpload comment:QComment, uploading:Bool)
    @objc optional func comment(didChangeProgress comment:QComment, progress:CGFloat)
}
@objc public enum QCommentProperty:Int{
    case status
    case uploading
    case downloading
    case uploadProgress
    case downloadProgress
    case cellPosition
    case cellSize
}
public class QComment:Object {
    static var cache = [String: QComment]()
    
    @objc public dynamic var uniqueId: String = ""
    @objc public dynamic var id:Int = 0
    @objc public dynamic var roomId:String = ""
    @objc public dynamic var beforeId:Int = 0
    @objc public dynamic var text:String = ""
    @objc public dynamic var createdAt: Double = 0
    @objc public dynamic var senderEmail:String = ""
    @objc public dynamic var senderName:String = ""
    @objc public dynamic var senderAvatarURL:String = ""
    @objc public dynamic var statusRaw:Int = QCommentStatus.sending.rawValue
    @objc public dynamic var typeRaw:String = QCommentType.text.name()
    @objc public dynamic var data:String = ""
    @objc public dynamic var cellPosRaw:Int = 0
    
    @objc public dynamic var roomName:String = ""
    @objc internal dynamic var roomTypeRaw:Int = 0
    @objc public dynamic var roomAvatar:String = ""
    
    @objc private dynamic var cellWidth:Float = 0
    @objc private dynamic var cellHeight:Float = 0
    @objc internal dynamic var textFontName:String = ""
    @objc internal dynamic var textFontSize:Float = 0
    @objc internal dynamic var rawExtra:String = ""
    // MARK : - Ignored Parameters
    var displayImage:UIImage?
    public var delegate:QCommentDelegate?{
        didSet{
            if Thread.isMainThread {
                if !self.isInvalidated {
                    QComment.cache[self.uniqueId] = self
                }
            }
        }
    }
    
    // audio variable
    @objc public dynamic var durationLabel = ""
    @objc public dynamic var currentTimeSlider = Float(0)
    @objc public dynamic var seekTimeLabel = "00:00"
    @objc public dynamic var audioIsPlaying = false
    // file variable
    public var isDownloading = false
    public var isUploading = false
    public var progress = CGFloat(0)
    
    
    // read mark
    @objc internal dynamic var isRead:Bool = false
    
    override public static func primaryKey() -> String? {
        return "uniqueId"
    }
    override public static func ignoredProperties() -> [String] {
        return ["displayImage","delegate", "isDownloading","isUploading","progress"]
    }
    
    //MARK : - Getter variable
    public var extras: [String:Any]? {
        get{
            if let data = self.rawExtra.data(using: .utf8) {
                do {
                    if let result = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        if result.count > 0 {
                            return result
                        }
                    }
                } catch {
                    Qiscus.printLog(text:error.localizedDescription)
                }
            }
            return nil
        }
    }
    private var linkTextAttributes:[String: Any]{
        get{
            var foregroundColorAttributeName = QiscusColorConfiguration.sharedInstance.leftBaloonLinkColor
            var underlineColorAttributeName = QiscusColorConfiguration.sharedInstance.leftBaloonLinkColor
            if self.senderEmail == Qiscus.client.email{
                foregroundColorAttributeName = QiscusColorConfiguration.sharedInstance.rightBaloonLinkColor
                underlineColorAttributeName = QiscusColorConfiguration.sharedInstance.rightBaloonLinkColor
            }
            return [
                NSAttributedStringKey.foregroundColor.rawValue: foregroundColorAttributeName,
                NSAttributedStringKey.underlineColor.rawValue: underlineColorAttributeName,
                NSAttributedStringKey.underlineStyle.rawValue: NSUnderlineStyle.styleSingle.rawValue,
                NSAttributedStringKey.font.rawValue: Qiscus.style.chatFont
            ]
        }
    }
    public var content:String?{
        if self.type == .custom {
            let contentData = JSON(parseJSON: self.data)
            return "\(contentData["content"].stringValue)"
        }
        return nil
    }
    public var messageId:String{
        get{
            return "\(self.id)"
        }
    }
    public var room:QRoom? {
        get{
            return QRoom.room(withId: self.roomId)
        }
    }
    public var file:QFile? {
        get{
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            realm.refresh()
            let files = realm.objects(QFile.self).filter("id == '\(self.uniqueId)'")
            if files.count > 0 {
                return files.first!
            }
            return nil
        }
    }
    public var sender:QUser? {
        get{
            return QUser.user(withEmail: self.senderEmail)
        }
    }
    public var cellPos:QCellPosition {
        get{
            return QCellPosition(rawValue: self.cellPosRaw)!
        }
    }
    public var roomType:QRoomType {
        get{
            return QRoomType(rawValue: self.roomTypeRaw)!
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
            if self.senderEmail == Qiscus.client.email {
                position = "Right"
            }
            if self.status == .deleted {
                return "cellDeleted\(position)"
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
                return "cellContact\(position)"
            case .location:
                return "cellLocation\(position)"
            case .document:
                return "cellDoc\(position)"
            case .carousel:
                return "cellCarousel"
            default:
                return "cellText\(position)"
            }
        }
    }
    
    public var time: String {
        get {
            let date = Date(timeIntervalSince1970: self.createdAt)
            let timeFormatter = DateFormatter()
            timeFormatter.timeZone = NSTimeZone.local
            timeFormatter.dateFormat = "h:mm a"
            let timeString = timeFormatter.string(from: date)
            
            return timeString
        }
    }
    public var textSize:CGSize {
        if !Thread.isMainThread { return CGSize() }
        var recalculate = false
        
        func recalculateSize()->CGSize{
            if self.isInvalidated {return CGSize()}
            let textView = UITextView()
            textView.font = Qiscus.style.chatFont
            if self.type == .carousel {
                textView.font = UIFont.systemFont(ofSize: 12)
            }
            textView.dataDetectorTypes = .all
            textView.linkTextAttributes = self.linkTextAttributes
            
            var maxWidth:CGFloat = QiscusUIConfiguration.chatTextMaxWidth
            if self.type == .location {
                maxWidth = 204
            }else if self.type == .carousel{
                maxWidth = (QiscusHelper.screenWidth() * 0.70) - 8
            }
            if self.type != .carousel {
                textView.attributedText = attributedText
            }
            var size = textView.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
            
            switch self.type {
            case .postback:
                let payload = JSON(parseJSON: self.data)
                
                if let buttonsPayload = payload.array {
                    let heightAdd = CGFloat(35 * buttonsPayload.count)
                    size.height += heightAdd
                }else{
                    size.height += 35
                }
                break
            case .account:
                size.height += 35
                break
            case .card:
                let payload = JSON(parseJSON: self.data)
                let buttons = payload["buttons"].arrayValue
                size.height = CGFloat(240 + (buttons.count * 45)) + 5
                break
            case .carousel:
                let payload = JSON(parseJSON: self.data)
                let cards = payload["cards"].arrayValue
                var maxHeight = CGFloat(0)
                for card in cards{
                    var height = CGFloat(0)
                    let desc = card["description"].stringValue
                    textView.text = desc
                    let buttons = card["buttons"].arrayValue
                    size = textView.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
                    height = CGFloat(180 + (buttons.count * 45)) + size.height
                    
                    if height > maxHeight {
                        maxHeight = height
                    }
                }
                size.height = maxHeight + 5
                break
            case .contact:
                size.height = 115
                break
            case .location:
                size.height += 168
                break
            case .image, .video:
                let payload = JSON(parseJSON: self.data)
                var height:CGFloat = 0
                if payload != JSON.null {
                    if let caption = payload["caption"].string {
                        if caption != "" {
                            height = size.height
                        }
                    }
                }
                size.height = height
                break
            case .document :
                size.height = 200
                break
            default:
                break
            }
            return size
        }
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        if self.isInvalidated {return CGSize()}
        if Float(Qiscus.style.chatFont.pointSize) != self.textFontSize || Qiscus.style.chatFont.familyName != self.textFontName{
            if self.type != .card && self.type != .carousel {
                recalculate = true
            }
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
    
    var textAttribute:[NSAttributedStringKey: Any]{
        get{
            if self.type == .location {
                let style = NSMutableParagraphStyle()
                style.alignment = NSTextAlignment.left
                let systemFont = UIFont.systemFont(ofSize: 14.0)
                var foregroundColorAttributeName = QiscusColorConfiguration.sharedInstance.leftBaloonTextColor
                if self.senderEmail == Qiscus.client.email{
                    foregroundColorAttributeName = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
                }
                
                return [
                    NSAttributedStringKey.foregroundColor: foregroundColorAttributeName,
                    NSAttributedStringKey.font: systemFont,
                    NSAttributedStringKey.paragraphStyle: style
                ]
            }
            else if self.type == .system {
                let style = NSMutableParagraphStyle()
                style.alignment = NSTextAlignment.center
                let fontSize = Qiscus.style.chatFont.pointSize
                let systemFont = Qiscus.style.chatFont.withSize(fontSize - 4.0)
                let foregroundColorAttributeName = QiscusColorConfiguration.sharedInstance.systemBalloonTextColor
                
                return [
                    NSAttributedStringKey.foregroundColor: foregroundColorAttributeName,
                    NSAttributedStringKey.font: systemFont,
                    NSAttributedStringKey.paragraphStyle: style
                ]
            }else{
                var foregroundColorAttributeName = QiscusColorConfiguration.sharedInstance.leftBaloonTextColor
                if self.senderEmail == Qiscus.client.email{
                    foregroundColorAttributeName = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
                }
                return [
                    NSAttributedStringKey.foregroundColor: foregroundColorAttributeName,
                    NSAttributedStringKey.font: Qiscus.style.chatFont
                ]
            }
        }
    }
    
    var attributedText:NSMutableAttributedString {
        get{
            var attributedText = NSMutableAttributedString(string: self.text)
            switch self.type {
            case .location:
                let payload = JSON(parseJSON: self.data)
                let address = payload["address"].stringValue
                attributedText = NSMutableAttributedString(string: address)
                let allRange = (address as NSString).range(of: address)
                attributedText.addAttributes(self.textAttribute, range: allRange)
                break
            case .image, .video:
                if self.data != "" {
                    let payload = JSON(parseJSON: self.data)
                    if let caption = payload["caption"].string {
                        attributedText = NSMutableAttributedString(string: caption)
                        let allRange = (caption as NSString).range(of: caption)
                        attributedText.addAttributes(self.textAttribute, range: allRange)
                    }
                }
                break
            default:
                let allRange = (self.text as NSString).range(of: self.text)
                attributedText.addAttributes(self.textAttribute, range: allRange)
                break
            }
            
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
                commentInfo.undeliveredUser = [QParticipant]()
                for participant in room.participants {
                    if participant.email != Qiscus.client.email{
                        if participant.lastReadCommentId >= self.id {
                            commentInfo.readUser.append(participant)
                        }else if participant.lastDeliveredCommentId >= self.id{
                            commentInfo.deliveredUser.append(participant)
                        }else{
                            commentInfo.undeliveredUser.append(participant)
                        }
                    }
                }
                return commentInfo
            }
            return nil
        }
    }
    
}
