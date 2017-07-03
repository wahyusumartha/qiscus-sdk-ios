//
//  QiscusCommentPresenter.swift
//  Example
//
//  Created by Ahmad Athaullah on 2/15/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
import SwiftyJSON

public enum QiscusCommentPresenterType:Int {
    case text
    case image
    case video
    case audio
    case document
    case file
    case postback
    case accountLinking
    case reply
    case system
}
public enum QiscusReplyType:Int{
    case text
    case image
    case video
    case audio
    case document
    case other
}
@objc public class QiscusCommentPresenter: NSObject {
    // commentAttribute
    var localId:Int = 0
    var commentId:Int = 0
    var commentText = ""
    var commentAttributedText:NSMutableAttributedString?
    var commentDate = ""
    var commentTime = ""
    var commentStatus = QiscusCommentStatus.sent
    var commentType = QiscusCommentPresenterType.text
    var commentUniqueid = ""
    var commentBeforeId:Int = 0
    var commentIndexPath:IndexPath?
    var createdAt:Double = Double(0)
    var isToday:Bool = false
    
    var topicId:Int = 0
    
    // user attribute
    var userIsOwn = false
    var userFullName = ""
    var userAvatarLocalPath = ""
    var userAvatarURL = ""
    var userEmail = ""
    var userAvatar:UIImage?
    
    // link attribute
    var showLink = false
    var linkImage:UIImage?
    var linkTitle:String?
    var linkDescription:String?
    var linkImageURL:String?
    var linkSaved = false
    var linkURL = ""
    
    // processing attribute
    var isUploading = false
    var isUploaded = false
    var isDownloading = false
    var uploadProgress = CGFloat(0)
    var downloadProgress = CGFloat(0)
    
    var fromPresenter = true
    var cellIdentifier:String = ""
    var balloonImage:UIImage?
    var cellSize = CGSize()
    var cellPos = CellTypePosition.single
    var displayImage:UIImage?
    
    // url variable 
    var localFileExist = false
    var remoteURL: String?
    var remoteThumbURL:String?
    var localURL :String?
    var localThumbURL :String?
    var localMiniThumbURL:String?
    
    // audio variable
    var durationLabel = ""
    var currentTimeSlider = Float(0)
    var seekTimeLabel = "00:00"
    var audioFileExist = false
    var audioIsPlaying = false
    
    // other file variable
    var fileName = ""
    var fileType = ""
    
    // upload
    var toUpload = false
    var uploadData:Data?
    var uploadMimeType:String?
    
    // getter variable
    var comment:QiscusComment?{
        get{
            return QiscusCommentDB.comment(withLocalId: self.localId)
        }
    }
    var linkTextAttributes:[String: Any]{
        get{
            var foregroundColorAttributeName = QiscusColorConfiguration.sharedInstance.leftBaloonLinkColor
            var underlineColorAttributeName = QiscusColorConfiguration.sharedInstance.leftBaloonLinkColor
            if self.userIsOwn{
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
    var systemTextAttribute:[String:Any] {
        get{
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
        }
    }
    var textAttribute:[String: Any]{
        get{
            var foregroundColorAttributeName = QiscusColorConfiguration.sharedInstance.leftBaloonTextColor
            if self.userIsOwn{
                foregroundColorAttributeName = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            }
            return [
                NSForegroundColorAttributeName: foregroundColorAttributeName,
                NSFontAttributeName: Qiscus.style.chatFont
            ]
        }
    }
    // string checker
    fileprivate func isAttachment(text:String) -> Bool {
        var check:Bool = false
        if(text.hasPrefix("[file]")){
            check = true
        }
        return check
    }
    private func getAttachmentURL(message: String) -> String {
        let component1 = message.components(separatedBy: "[file]")
        let component2 = component1.last!.components(separatedBy: "[/file]")
        let mediaUrlString = component2.first?.trimmingCharacters(in: CharacterSet.whitespaces)
        return mediaUrlString!
    }
    public func replyType(message:String)->QiscusReplyType{
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
    fileprivate func fileName(text:String) ->String{
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
    
    class func getPresenter(forComment comment:QiscusComment)->QiscusCommentPresenter{
        let commentPresenter = QiscusCommentPresenter()
        commentPresenter.fromPresenter = true
        commentPresenter.localId = comment.localId
        commentPresenter.isToday = comment.isToday
        commentPresenter.commentId = comment.commentId
        commentPresenter.commentText = comment.commentText
        commentPresenter.commentDate = comment.commentDay
        commentPresenter.commentTime = comment.commentTime
        commentPresenter.commentStatus = comment.commentStatus
        commentPresenter.userIsOwn = comment.isOwnMessage
        commentPresenter.createdAt = comment.commentCreatedAt
        commentPresenter.userEmail = comment.commentSenderEmail
        commentPresenter.commentUniqueid = comment.commentUniqueId
        commentPresenter.topicId = comment.commentTopicId
        commentPresenter.commentBeforeId = comment.commentBeforeId
        
        if let user = comment.sender{
            commentPresenter.userFullName = user.userFullName
            commentPresenter.userAvatarLocalPath = user.userAvatarLocalPath
            commentPresenter.userAvatarURL = user.userAvatarURL
        }
        if comment.commentType == .system {
            commentPresenter.userIsOwn = true
        }
        var position:String = "Left"
        if comment.isOwnMessage{
            position = "Right"
        }
        switch comment.commentType {
        case .system :
            commentPresenter.cellIdentifier = "cellSystem"
            commentPresenter.commentType = .system
            let attributedText = NSMutableAttributedString(string: commentPresenter.commentText)
            
            let allRange = (commentPresenter.commentText as NSString).range(of: commentPresenter.commentText)
            attributedText.addAttributes(commentPresenter.systemTextAttribute, range: allRange)
            
            commentPresenter.commentAttributedText = attributedText
            
            let fontSize = Qiscus.shared.styleConfiguration.chatFont.pointSize
            let fontName = Qiscus.shared.styleConfiguration.chatFont.fontName
            
            var needCalculate = false
            if fontName != comment.commentFontName || fontSize != comment.commentFontSize{
                needCalculate = true
            }
            
            if comment.cellSize != nil && !needCalculate{
                commentPresenter.cellSize = comment.cellSize!
            }else{
                Qiscus.uiThread.sync {
                    let cellSize = QiscusCommentPresenter.calculateTextSize(attributedText: attributedText, postback: false, buttonPayload: comment.commentButton)
                    commentPresenter.cellSize = cellSize
                    comment.commentCellHeight = cellSize.height
                    comment.commentCellWidth = cellSize.width
                }
                comment.commentFontName = fontName
                comment.commentFontSize = fontSize
            }
            break
        case .postback, .account:
            if comment.commentType == .postback {
                commentPresenter.commentType = .postback
            }else{
                commentPresenter.commentType = .accountLinking
            }
            commentPresenter.cellIdentifier = "cellPostback\(position)"
            commentPresenter.showLink = false
            
            let attributedText = NSMutableAttributedString(string: commentPresenter.commentText)
            
            let allRange = (commentPresenter.commentText as NSString).range(of: commentPresenter.commentText)
            attributedText.addAttributes(commentPresenter.textAttribute, range: allRange)

            commentPresenter.commentAttributedText = attributedText
            
            let fontSize = Qiscus.shared.styleConfiguration.chatFont.pointSize
            let fontName = Qiscus.shared.styleConfiguration.chatFont.fontName
            
            var needCalculate = false
            if fontName != comment.commentFontName || fontSize != comment.commentFontSize{
                needCalculate = true
            }
            
            if comment.cellSize != nil && !needCalculate{
                commentPresenter.cellSize = comment.cellSize!
            }else{
                Qiscus.uiThread.sync {
                    let cellSize = QiscusCommentPresenter.calculateTextSize(attributedText: attributedText, postback: true, buttonPayload: comment.commentButton)
                    commentPresenter.cellSize = cellSize
                    comment.commentCellHeight = cellSize.height
                    comment.commentCellWidth = cellSize.width
                }
                comment.commentFontName = fontName
                comment.commentFontSize = fontSize
            }
            break
        case .text, .reply:
            var isReply = false
            if comment.commentType == .text {
                commentPresenter.commentType = .text
                //commentPresenter.showLink = comment.showLink
                commentPresenter.showLink = false
            }else{
                let replyData = JSON(parseJSON: comment.commentButton)
                commentPresenter.commentType = .reply
                commentPresenter.showLink = false
                commentPresenter.commentText = replyData["text"].stringValue
                isReply = true
            }
            commentPresenter.cellIdentifier = "cellText\(position)"
            
            
            var attributedText = NSMutableAttributedString(string: commentPresenter.commentText)
            
            let allRange = (commentPresenter.commentText as NSString).range(of: commentPresenter.commentText)
            attributedText.addAttributes(commentPresenter.textAttribute, range: allRange)
            
            if isReply {
                let replyData = JSON(parseJSON: comment.commentButton)
                var text = replyData["replied_comment_message"].stringValue
                let replyType = commentPresenter.replyType(message: text)
                
                var username = replyData["replied_comment_sender_username"].stringValue
                let repliedEmail = replyData["replied_comment_sender_email"].stringValue
                if repliedEmail == QiscusMe.sharedInstance.email {
                    username = "You"
                }
                
                switch replyType {
                case .text:
                    break
                case .image, .video:
                    let filename = commentPresenter.fileName(text: text)
                    let url = commentPresenter.getAttachmentURL(message: text)
                    text = filename
                    var thumbURL = url.replacingOccurrences(of: "/upload/", with: "/upload/w_30,c_scale/")
                    let thumbUrlArr = thumbURL.characters.split(separator: ".")
                    
                    var newThumbURL = ""
                    var i = 0
                    for thumbComponent in thumbUrlArr{
                        if i == 0{
                            newThumbURL += String(thumbComponent)
                        }else if i < (thumbUrlArr.count - 1){
                            newThumbURL += ".\(String(thumbComponent))"
                        }else{
                            newThumbURL += ".png"
                        }
                        i += 1
                    }
                    thumbURL = newThumbURL
                    commentPresenter.linkImageURL = thumbURL
                    break
                default:
                    let filename = commentPresenter.fileName(text: text)
                    text = filename
                    break
                }
                commentPresenter.linkTitle = username
                commentPresenter.linkDescription = text
            }
//            if comment.showLink {
//                if let url = comment.commentLink{
//                    commentPresenter.linkTitle = "Load data ..."
//                    commentPresenter.linkDescription = "Load url description"
//                    commentPresenter.linkImage = Qiscus.image(named: "link")
//                    
//                    var urlToCheck = url.lowercased()
//                    if !urlToCheck.contains("http"){
//                        urlToCheck = "http://\(url.lowercased())"
//                    }
//                    
//                    commentPresenter.linkURL = urlToCheck
//                    
//                    if let linkData = QiscusLinkData.getLinkData(fromURL: urlToCheck){
//                        commentPresenter.linkDescription = linkData.linkDescription
//                        commentPresenter.linkImageURL = linkData.linkImageURL
//                        commentPresenter.linkSaved = true
//                        
//                        if let image = linkData.thumbImage{
//                            commentPresenter.linkImage = image
//                        }
//                        if linkData.linkTitle != "" {
//                            commentPresenter.linkTitle = linkData.linkTitle
//                            let text = commentPresenter.commentText.replacingOccurrences(of: linkData.linkURL, with: linkData.linkTitle)
//                            
//                            let allRange = (text as NSString).range(of: text)
//                            let titleRange = (text as NSString).range(of: linkData.linkTitle)
//                            
//                            attributedText = NSMutableAttributedString(string: text)
//                            attributedText.addAttributes(commentPresenter.textAttribute, range: allRange)
//                            
//                            for (attribute,_) in commentPresenter.textAttribute {
//                                attributedText.removeAttribute(attribute, range: titleRange)
//                            }
//                            attributedText.addAttributes(commentPresenter.linkTextAttributes, range: titleRange)
//                            
//                            let url = NSURL(string: linkData.linkURL)!
//                            attributedText.addAttribute(NSLinkAttributeName, value: url, range: titleRange)
//                        }else{
//                            commentPresenter.showLink = false
//                            comment.showLink = false
//                            attributedText = NSMutableAttributedString(string: commentPresenter.commentText)
//                            attributedText.addAttributes(commentPresenter.textAttribute, range: allRange)
//                        }
//                    }
//                }
//                else{
//                    commentPresenter.showLink = false
//                    comment.showLink = false
//                    attributedText = NSMutableAttributedString(string: commentPresenter.commentText)
//                    attributedText.addAttributes(commentPresenter.textAttribute, range: allRange)
//                }
//            }
            //else{
                //commentPresenter.showLink = false
                comment.showLink = false
                attributedText = NSMutableAttributedString(string: commentPresenter.commentText)
                attributedText.addAttributes(commentPresenter.textAttribute, range: allRange)
            //}
            commentPresenter.commentAttributedText = attributedText
            
            let fontSize = Qiscus.shared.styleConfiguration.chatFont.pointSize
            let fontName = Qiscus.shared.styleConfiguration.chatFont.fontName
            
            var needCalculate = false
            if fontName != comment.commentFontName || fontSize != comment.commentFontSize{
                needCalculate = true
            }

            if comment.cellSize != nil && !needCalculate{
                commentPresenter.cellSize = comment.cellSize!
            }else{
                Qiscus.uiThread.sync {
                    let cellSize = QiscusCommentPresenter.calculateTextSize(attributedText: attributedText)
                    
                    commentPresenter.cellSize = cellSize
                    comment.commentCellHeight = cellSize.height
                    comment.commentCellWidth = cellSize.width
                }
                comment.commentFontName = fontName
                comment.commentFontSize = fontSize
            }
            break
        default:
            var file = QiscusFile()
            
            if let commentFile = QiscusFile.file(forComment: comment){
                file = commentFile
            }else{
                file = QiscusFile.newFile()
                file.fileURL = comment.getMediaURL()
                file.fileCommentId = comment.commentId
                comment.commentFileId = file.fileId
            }
            
            commentPresenter.localFileExist = file.isLocalFileExist()
            commentPresenter.isUploaded = file.isUploaded
            commentPresenter.remoteURL = file.fileURL
            commentPresenter.uploadMimeType = file.fileMimeType
            commentPresenter.fileType = file.fileExtension
            commentPresenter.fileName = file.fileName
            
            switch file.fileType {
            case .media:
                commentPresenter.commentType = .image
                commentPresenter.cellIdentifier = "cellMedia\(position)"
                commentPresenter.displayImage = Qiscus.image(named: "media_balloon")
                commentPresenter.cellSize.height = 188
                commentPresenter.remoteURL = file.fileURL.replacingOccurrences(of: " ", with: "%20")
                commentPresenter.localURL = file.fileLocalPath
                commentPresenter.localThumbURL = file.fileThumbPath
                commentPresenter.localMiniThumbURL = file.fileMiniThumbPath
                var thumbURL = commentPresenter.remoteURL!.replacingOccurrences(of: "/upload/", with: "/upload/w_30,c_scale/")
                if commentPresenter.fileType == "gif"{
                    let thumbUrlArr = thumbURL.characters.split(separator: ".")
                    
                    var newThumbURL = ""
                    var i = 0
                    for thumbComponent in thumbUrlArr{
                        if i == 0{
                            newThumbURL += String(thumbComponent)
                        }else if i < (thumbUrlArr.count - 1){
                            newThumbURL += ".\(String(thumbComponent))"
                        }else{
                            newThumbURL += ".png"
                        }
                        i += 1
                    }
                    thumbURL = newThumbURL
                }
                commentPresenter.remoteThumbURL = thumbURL
                
                break
            case .video:
                commentPresenter.commentType = .video
                commentPresenter.cellIdentifier = "cellMedia\(position)"
                commentPresenter.displayImage = Qiscus.image(named: "media_balloon")
                commentPresenter.cellSize.height = 188
                commentPresenter.remoteURL = file.fileURL.replacingOccurrences(of: " ", with: "%20")
                commentPresenter.localURL = file.fileLocalPath
                commentPresenter.localThumbURL = file.fileThumbPath
                commentPresenter.localMiniThumbURL = file.fileMiniThumbPath
                var thumbURL = commentPresenter.remoteURL!.replacingOccurrences(of: "/upload/", with: "/upload/w_30,c_scale/")
                let thumbUrlArr = thumbURL.characters.split(separator: ".")
                
                var newThumbURL = ""
                var i = 0
                for thumbComponent in thumbUrlArr{
                    if i == 0{
                        newThumbURL += String(thumbComponent)
                    }else if i < (thumbUrlArr.count - 1){
                        newThumbURL += ".\(String(thumbComponent))"
                    }else{
                        newThumbURL += ".png"
                    }
                    i += 1
                }
                thumbURL = newThumbURL
                commentPresenter.remoteThumbURL = thumbURL
                break
            case .audio:
                commentPresenter.commentType = .audio
                commentPresenter.cellIdentifier = "cellAudio\(position)"
                commentPresenter.localFileExist = file.localFileExist
                commentPresenter.cellSize.height = 83
                commentPresenter.audioFileExist = file.isOnlyLocalFileExist
                if file.isOnlyLocalFileExist {
                    commentPresenter.localURL = file.fileLocalPath
                }
                break
            case .document:
                commentPresenter.commentType = .document
                commentPresenter.cellIdentifier = "cellFile\(position)"
                commentPresenter.cellSize.height = 65
                commentPresenter.fileName = file.fileName
                break
            default:
                commentPresenter.commentType = .file
                commentPresenter.cellIdentifier = "cellFile\(position)"
                commentPresenter.cellSize.height = 65
                commentPresenter.fileName = file.fileName
                commentPresenter.fileType = "unknown file"
                break
            }
            break
        }
        
        commentPresenter.fromPresenter = false
        return commentPresenter
    }
    
    class func calculateTextSize(attributedText : NSMutableAttributedString, postback:Bool = false, buttonPayload:String? = nil) -> CGSize {
        var size = CGSize()
        let textView = UITextView()
        textView.font = Qiscus.style.chatFont
        textView.dataDetectorTypes = .all
        textView.linkTextAttributes = QiscusCommentPresenter().linkTextAttributes
        
        let maxWidth:CGFloat = QiscusUIConfiguration.chatTextMaxWidth
        textView.attributedText = attributedText
        
        size = textView.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        if postback && buttonPayload != nil{
            
            let payload = JSON(parseJSON: buttonPayload!)
            
            if let buttonsPayload = payload.array {
                let heightAdd = CGFloat(35 * buttonsPayload.count)
                size.height += heightAdd
            }else{
                size.height += 35
            }
        }
        
        return size
    }
    func getBalloonImage()->UIImage?{
        var balloonImage:UIImage?
        if self.userIsOwn{
            switch cellPos {
            case .single:
                let balloonEdgeInset = UIEdgeInsetsMake(13, 13, 13, 28)
                balloonImage = Qiscus.image(named:"text_balloon_right")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
                break
            case .first:
                let balloonEdgeInset = UIEdgeInsetsMake(13, 13, 13, 13)
                balloonImage = Qiscus.image(named:"text_balloon_first")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
                break
            case .middle:
                let balloonEdgeInset = UIEdgeInsetsMake(13, 13, 13, 13)
                balloonImage = Qiscus.image(named:"text_balloon_mid")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
                break
            case .last:
                let balloonEdgeInset = UIEdgeInsetsMake(13, 13, 13, 28)
                balloonImage = Qiscus.image(named:"text_balloon_last_r")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
                break
            }
        }else{
            switch cellPos {
            case .single:
                let balloonEdgeInset = UIEdgeInsetsMake(13, 28, 13, 13)
                balloonImage = Qiscus.image(named:"text_balloon_left")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
                break
            case .first:
                let balloonEdgeInset = UIEdgeInsetsMake(13, 13, 13, 13)
                balloonImage = Qiscus.image(named:"text_balloon_first")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
                break
            case .middle:
                let balloonEdgeInset = UIEdgeInsetsMake(13, 13, 13, 13)
                balloonImage = Qiscus.image(named:"text_balloon_mid")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
                break
            case .last:
                let balloonEdgeInset = UIEdgeInsetsMake(13, 28, 13, 13)
                balloonImage = Qiscus.image(named:"text_balloon_last_l")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
                break
            }
        }
        return balloonImage
    }
}
