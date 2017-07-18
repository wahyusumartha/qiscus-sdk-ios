//
//  QCellTextRight.swift
//  QiscusSDK
//
//  Created by Ahmad Athaullah on 1/3/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
import SwiftyJSON

class QCellTextRight: QChatCell {
    let maxWidth:CGFloat = QiscusUIConfiguration.chatTextMaxWidth
    let minWidth:CGFloat = 80
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var balloonView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var statusImage: UIImageView!
    
    //@IBOutlet weak var balloonWidth: NSLayoutConstraint!
    @IBOutlet weak var linkContainerWidth: NSLayoutConstraint!
    @IBOutlet weak var cellHeight: NSLayoutConstraint!
    //@IBOutlet weak var rightMargin: NSLayoutConstraint!
    @IBOutlet weak var balloonTopMargin: NSLayoutConstraint!
    //@IBOutlet weak var textTrailing: NSLayoutConstraint!
    //@IBOutlet weak var statusTrailing: NSLayoutConstraint!
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    @IBOutlet weak var textViewWidth: NSLayoutConstraint!
    @IBOutlet weak var linkImageWidth: NSLayoutConstraint!

    @IBOutlet weak var LinkContainer: UIView!
    @IBOutlet weak var linkDescription: UITextView!
    @IBOutlet weak var linkTitle: UILabel!
    @IBOutlet weak var linkImage: UIImageView!
    
    @IBOutlet weak var linkHeight: NSLayoutConstraint!
    @IBOutlet weak var textTopMargin: NSLayoutConstraint!
    @IBOutlet weak var balloonHeight: NSLayoutConstraint!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textView.contentInset = UIEdgeInsets.zero
        LinkContainer.isHidden = true
        LinkContainer.layer.cornerRadius = 4
        LinkContainer.clipsToBounds = true
        linkContainerWidth.constant = self.maxWidth + 2
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(QCellTextRight.openLink))
        LinkContainer.addGestureRecognizer(tapRecognizer)
        linkImage.clipsToBounds = true
        
    }
    public override func commentChanged() {
        self.textView.attributedText = self.comment?.attributedText
        self.textView.linkTextAttributes = self.linkTextAttributes
        self.balloonView.image = self.getBallon()
        
        let textSize = self.comment!.textSize
        var textWidth = self.comment!.textSize.width
        
        if textWidth > self.minWidth {
            textWidth = textSize.width
        }else{
            textWidth = self.minWidth
        }
        
//        self.linkTitle.text = ""
//        self.linkDescription.text = ""
//        self.linkImage.image = self.data.linkImage
//        self.LinkContainer.isHidden = true
//        self.balloonHeight.constant = 10
//        self.textTopMargin.constant = 0
//        
//        if self.data.showLink {
//            self.linkTitle.text = self.data.linkTitle
//            self.linkDescription.text = self.data.linkDescription
//            self.linkImage.image = self.data.linkImage
//            self.LinkContainer.isHidden = false
//            self.balloonHeight.constant = 83
//            self.textTopMargin.constant = 73
//            self.linkHeight.constant = 65
//            textWidth = self.maxWidth
//            
//            if !self.data.linkSaved{
//                QiscusDataPresenter.getLinkData(withData: self.data)
//            }
//        }else
        
        if self.comment?.type == .reply{
            let replyData = JSON(parseJSON: self.comment!.data)
            var text = replyData["replied_comment_message"].stringValue
            let replyType = self.comment!.replyType(message: text)
            
            var username = replyData["replied_comment_sender_username"].stringValue
            let repliedEmail = replyData["replied_comment_sender_email"].stringValue
            if repliedEmail == QiscusMe.sharedInstance.email {
                username = "You"
            }
            switch replyType {
            case .text:
                self.linkImageWidth.constant = 0
                self.linkImage.isHidden = true
                break
            case .image, .video:
                self.linkImage.image = Qiscus.image(named: "link")
                let filename = self.comment!.fileName(text: text)
                let url = self.comment!.getAttachmentURL(message: text)
                
                self.linkImageWidth.constant = 55
                self.linkImage.isHidden = false
                
                if let file = QFile.file(withURL: url){
                    if QiscusHelper.isFileExist(inLocalPath: file.localThumbPath){
                        self.linkImage.loadAsync(fromLocalPath: file.localThumbPath, onLoaded: { (image, _) in
                            self.linkImage.image = image
                        })
                    }else if QiscusHelper.isFileExist(inLocalPath: file.localMiniThumbPath){
                        self.linkImage.loadAsync(fromLocalPath: data.localMiniThumbURL!, onLoaded: { (image, _) in
                            self.linkImage.image = image
                        })
                    }else{
                        self.linkImage.loadAsync(file.thumbURL, onLoaded: { (image, _) in
                            self.linkImage.image = image
                        })
                    }
                }else{
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
                    self.linkImage.loadAsync(thumbURL, onLoaded: { (image, _) in
                        self.linkImage.image = image
                    })
                }
                text = filename
                
                break
            default:
                let filename = self.comment!.fileName(text: text)
                text = filename
                self.linkImageWidth.constant = 0
                self.linkImage.isHidden = true
                break
            }
            
            
            self.linkTitle.text = username
            self.linkDescription.text = text
            
            //self.linkImage.image = self.data.linkImage
            self.LinkContainer.isHidden = false
            self.balloonHeight.constant = 83
            self.textTopMargin.constant = 73
            self.linkHeight.constant = 65
            textWidth = self.maxWidth
        }else{
            self.linkTitle.text = ""
            self.linkDescription.text = ""
            self.linkImage.image = Qiscus.image(named: "link")
            self.LinkContainer.isHidden = true
            self.balloonHeight.constant = 10
            self.textTopMargin.constant = 0
        }
        var size = self.textView.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        if self.comment?.type == .postback && self.comment?.data != ""{
            let payload = JSON(parseJSON: self.comment!.data)
            
            if let buttonsPayload = payload.array {
                let heightAdd = CGFloat(35 * buttonsPayload.count)
                size.height += heightAdd
            }else{
                size.height += 35
            }
        }
        self.textViewHeight.constant = size.height
        self.textViewWidth.constant = textWidth
        self.userNameLabel.textAlignment = .right
        
        self.balloonView.tintColor = QiscusColorConfiguration.sharedInstance.rightBaloonColor
        self.dateLabel.text = self.comment!.time.lowercased()
        self.dateLabel.textColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
        
        
        // first cell
        if self.comment?.cellPos == .first || self.comment?.cellPos == .single{
            self.userNameLabel.isHidden = false
            self.balloonTopMargin.constant = 20
            self.cellHeight.constant = 20
        }else{
            self.userNameLabel.text = ""
            self.userNameLabel.isHidden = true
            self.balloonTopMargin.constant = 0
            self.cellHeight.constant = 0
        }
        
        // comment status render
        self.updateStatus(toStatus: self.comment!.status)
        self.textView.layoutIfNeeded()
    }
    public override func dataChanged(oldValue: QiscusCommentPresenter, new: QiscusCommentPresenter) {
//        Qiscus.uiThread.async {
//            self.textView.attributedText = self.data.commentAttributedText
//            self.textView.linkTextAttributes = self.data.linkTextAttributes
//            self.balloonView.image = self.data.balloonImage
//            
//            let textSize = self.data.cellSize
//            var textWidth = self.data.cellSize.width
//            
//            if textWidth > self.minWidth {
//                textWidth = textSize.width
//            }else{
//                textWidth = self.minWidth
//            }
//            
//            self.linkTitle.text = ""
//            self.linkDescription.text = ""
//            self.linkImage.image = self.data.linkImage
//            self.LinkContainer.isHidden = true
//            self.balloonHeight.constant = 10
//            self.textTopMargin.constant = 0
//            
//            if self.data.showLink {
//                self.linkTitle.text = self.data.linkTitle
//                self.linkDescription.text = self.data.linkDescription
//                self.linkImage.image = self.data.linkImage
//                self.LinkContainer.isHidden = false
//                self.balloonHeight.constant = 83
//                self.textTopMargin.constant = 73
//                self.linkHeight.constant = 65
//                textWidth = self.maxWidth
//                
//                if !self.data.linkSaved{
//                    QiscusDataPresenter.getLinkData(withData: self.data)
//                }
//            }else if self.data.commentType == .reply{
//                let replyData = JSON(parseJSON: self.data.comment!.commentButton)
//                let text = replyData["replied_comment_message"].stringValue
//                let replyType = self.data.replyType(message: text)
//                
//                self.linkTitle.text = self.data.linkTitle
//                self.linkDescription.text = self.data.linkDescription
//                
//                if replyType == .image || replyType == .video {
//                    self.linkImageWidth.constant = 55
//                    self.linkImage.isHidden = false
//                    
//                    self.linkImage.loadAsync(self.data.linkImageURL!)
//                }else{
//                    self.linkImageWidth.constant = 0
//                    self.linkImage.isHidden = true
//                    
//                    self.layoutIfNeeded()
//                }
//                //self.linkImage.image = self.data.linkImage
//                self.LinkContainer.isHidden = false
//                self.balloonHeight.constant = 83
//                self.textTopMargin.constant = 73
//                self.linkHeight.constant = 65
//                textWidth = self.maxWidth
//            }else{
//                self.linkTitle.text = ""
//                self.linkDescription.text = ""
//                self.linkImage.image = Qiscus.image(named: "link")
//                self.LinkContainer.isHidden = true
//                self.balloonHeight.constant = 10
//                self.textTopMargin.constant = 0
//            }
//            
//            self.textViewHeight.constant = textSize.height
//            self.textViewWidth.constant = textWidth
//            self.userNameLabel.textAlignment = .right
//            
//            self.balloonView.tintColor = QiscusColorConfiguration.sharedInstance.rightBaloonColor
//            
//            // first cell
//            if self.data.cellPos == .first || self.data.cellPos == .single{
//                self.userNameLabel.text = self.data.userFullName
//                self.userNameLabel.isHidden = false
//                self.balloonTopMargin.constant = 20
//                self.cellHeight.constant = 20
//            }else{
//                self.userNameLabel.text = ""
//                self.userNameLabel.isHidden = true
//                self.balloonTopMargin.constant = 0
//                self.cellHeight.constant = 0
//            }
//            
//            // last cell
//            if self.data.cellPos == .last || self.data.cellPos == .single{
//                self.rightMargin.constant = -8
//                self.textTrailing.constant = -23
//                self.statusTrailing.constant = -20
//                self.balloonWidth.constant = 31
//            }else{
//                self.textTrailing.constant = -8
//                self.rightMargin.constant = -23
//                self.statusTrailing.constant = -5
//                self.balloonWidth.constant = 16
//            }
//            
//            // comment status render
//            self.updateStatus(toStatus: self.data.commentStatus)
//            self.textView.layoutIfNeeded()
//        }
    }
    open override func setupCell(){
        
    }
    open override func updateStatus(toStatus status:QCommentStatus){
        switch status {
        case .sending:
            dateLabel.textColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            statusImage.tintColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            dateLabel.text = QiscusTextConfiguration.sharedInstance.sendingText
            statusImage.image = Qiscus.image(named: "ic_info_time")?.withRenderingMode(.alwaysTemplate)
            break
        case .sent:
            dateLabel.text = data.commentTime.lowercased()
            dateLabel.textColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            statusImage.tintColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            statusImage.image = Qiscus.image(named: "ic_sending")?.withRenderingMode(.alwaysTemplate)
            break
        case .delivered:
            dateLabel.text = data.commentTime.lowercased()
            dateLabel.textColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            statusImage.tintColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            statusImage.image = Qiscus.image(named: "ic_read")?.withRenderingMode(.alwaysTemplate)
            break
        case .read:
            dateLabel.text = data.commentTime.lowercased()
            dateLabel.textColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            statusImage.tintColor = UIColor.green
            statusImage.image = Qiscus.image(named: "ic_read")?.withRenderingMode(.alwaysTemplate)
            break
        case . failed:
            dateLabel.textColor = QiscusColorConfiguration.sharedInstance.failToSendColor
            dateLabel.text = QiscusTextConfiguration.sharedInstance.failedText
            statusImage.image = Qiscus.image(named: "ic_warning")?.withRenderingMode(.alwaysTemplate)
            statusImage.tintColor = QiscusColorConfiguration.sharedInstance.failToSendColor
            break
        }
    }
    override func clearContext() {

        LinkContainer.isHidden = true
        textView.text = ""
        textView.font = UIFont.systemFont(ofSize: 14)
    }
    func openLink(){
        if data.showLink && data.linkURL != ""{
            let url = data.linkURL
            var urlToCheck = url.lowercased()
            if !urlToCheck.contains("http"){
                urlToCheck = "http://\(url.lowercased())"
            }
            if let urlToOpen = URL(string: urlToCheck){
                UIApplication.shared.openURL(urlToOpen)
            }
        }else if data.commentType == .reply {
            DispatchQueue.global().async {
                let replyData = JSON(parseJSON: self.data.comment!.commentButton)
                let commentId = replyData["replied_comment_id"].intValue
                var found = false
                if let comment = self.data.comment {
                    if let chatView = Qiscus.shared.chatViews[comment.roomId]{
                        var indexPath = IndexPath(item: 0, section: 0)
                        var section = 0
                        for commentGroup in chatView.comments{
                            var row = 0
                            for comment in commentGroup {
                                if comment.commentId == commentId {
                                    found = true
                                    indexPath = IndexPath(item: row, section: section)
                                    break
                                }
                                row += 1
                            }
                            if found {
                                break
                            }else{
                                section += 1
                            }
                        }
                        if found {
                            DispatchQueue.main.async {
                                chatView.scrollToIndexPath(indexPath, position: .top, animated: true, delayed: false)
                            }
                        }
                    }
                }
            }
        }
    }
}
