//
//  QCellTextRight.swift
//  Example
//
//  Created by Ahmad Athaullah on 1/3/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

class QCellTextRight: QChatCell {
    let maxWidth:CGFloat = 190
    let minWidth:CGFloat = 80
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var balloonView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var statusImage: UIImageView!
    
    @IBOutlet weak var balloonWidth: NSLayoutConstraint!
    @IBOutlet weak var cellHeight: NSLayoutConstraint!
    @IBOutlet weak var rightMargin: NSLayoutConstraint!
    @IBOutlet weak var balloonTopMargin: NSLayoutConstraint!
    @IBOutlet weak var textTrailing: NSLayoutConstraint!
    @IBOutlet weak var statusTrailing: NSLayoutConstraint!
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    @IBOutlet weak var textViewWidth: NSLayoutConstraint!

    @IBOutlet weak var LinkContainer: UIView!
    @IBOutlet weak var linkDescription: UITextView!
    @IBOutlet weak var linkTitle: UILabel!
    @IBOutlet weak var linkImage: UIImageView!
    
    @IBOutlet weak var linkHeight: NSLayoutConstraint!
    @IBOutlet weak var textTopMargin: NSLayoutConstraint!
    @IBOutlet weak var balloonHeight: NSLayoutConstraint!
    
    
    var linkTextAttributes:[String: AnyObject]{
        get{
            return [
                NSForegroundColorAttributeName: QiscusColorConfiguration.sharedInstance.rightBaloonLinkColor,
                NSUnderlineColorAttributeName: QiscusColorConfiguration.sharedInstance.rightBaloonLinkColor,
                NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue as AnyObject
            ]
        }
    }

    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textView.contentInset = UIEdgeInsets.zero
        LinkContainer.isHidden = true
        LinkContainer.layer.cornerRadius = 4
        LinkContainer.clipsToBounds = true
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(QCellTextRight.openLink))
        LinkContainer.addGestureRecognizer(tapRecognizer)
    }
    
    open override func setupCell(){
        
        switch self.cellPos {
        case .first:
            let balloonEdgeInset = UIEdgeInsetsMake(13, 13, 13, 13)
            balloonView.image = Qiscus.image(named:"text_balloon_first")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
            break
        case .middle:
            let balloonEdgeInset = UIEdgeInsetsMake(13, 13, 13, 13)
            balloonView.image = Qiscus.image(named:"text_balloon_mid")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
            break
        case .last:
            let balloonEdgeInset = UIEdgeInsetsMake(13, 13, 13, 28)
            balloonView.image = Qiscus.image(named:"text_balloon_last_r")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
            break
        case .single:
            let balloonEdgeInset = UIEdgeInsetsMake(13, 13, 13, 28)
            balloonView.image = Qiscus.image(named:"text_balloon_right")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
            break
        }
        var attributedText:NSMutableAttributedString?
        if comment.showLink{
            if let url = comment.commentLink{
                var urlToCheck = url.lowercased()
                if !urlToCheck.contains("http"){
                    urlToCheck = "http://\(url.lowercased())"
                }
                self.linkTitle.text = "Load data ..."
                self.linkDescription.text = "Load url description"
                self.linkImage.image = Qiscus.image(named: "link")
                self.LinkContainer.isHidden = false
                self.balloonHeight.constant = 83
                self.textTopMargin.constant = 73
                self.linkHeight.constant = 65
                textViewWidth.constant = maxWidth
                if let linkData = QiscusLinkData.getLinkData(fromURL: urlToCheck){
                    // data already stored on local db
                    self.linkTitle.text = linkData.linkTitle
                    self.linkDescription.text = linkData.linkDescription
                    if let image = linkData.thumbImage{
                        self.linkImage.image = image
                    }else if linkData.linkImageURL != ""{
                        self.linkImage.loadAsync(linkData.linkImageURL, placeholderImage: Qiscus.image(named: "link"))
                        linkData.downloadThumbImage()
                    }else{
                        self.linkImage.image = Qiscus.image(named: "link")
                    }
                    if linkData.linkTitle != "" {
                        let text = comment.commentText.replacingOccurrences(of: linkData.linkURL, with: linkData.linkTitle)
                        let titleRange = (text as NSString).range(of: linkData.linkTitle)
                        attributedText = NSMutableAttributedString(string: text)
                        attributedText?.addAttributes(linkTextAttributes, range: titleRange)
                        let url = NSURL(string: linkData.linkURL)!
                        attributedText?.addAttribute(NSLinkAttributeName, value: url, range: titleRange)
                    }
                }else{
                    // call from API
                    QiscusCommentClient.sharedInstance.getLinkMetadata(url: urlToCheck, synchronous: false, withCompletion: { linkData in
                        self.linkTitle.text = linkData.linkTitle
                        self.linkDescription.text = linkData.linkDescription
                        self.linkImage.loadAsync(linkData.linkImageURL, placeholderImage: Qiscus.image(named: "link"))
                        linkData.saveLink()
                        if linkData.linkTitle != "" {
                            let text = self.comment.commentText.replacingOccurrences(of: linkData.linkURL, with: linkData.linkTitle)
                            let titleRange = (text as NSString).range(of: linkData.linkTitle)
                            attributedText = NSMutableAttributedString(string: text)
                            attributedText?.addAttributes(self.linkTextAttributes, range: titleRange)
                            let url = NSURL(string: linkData.linkURL)!
                            attributedText?.addAttribute(NSLinkAttributeName, value: url, range: titleRange)
                            self.comment.updateCommentCellWithLinkSize(linkURL: linkData.linkURL, linkTitle: linkData.linkTitle)
                            self.chatCellDelegate?.didChangeSize(onCell: self)
                        }
                    }, withFailCompletion: {
                        self.linkTitle.text = "Not Found"
                        self.linkDescription.text = "No description found"
                        self.linkImage.image = Qiscus.image(named: "link")
                        self.comment.updateCommmentShowLink(show: false)
                        self.chatCellDelegate?.didChangeSize(onCell: self)
                    })
                }
            }
        }else{
            self.linkTitle.text = ""
            self.linkDescription.text = ""
            self.linkImage.image = Qiscus.image(named: "link")
            self.LinkContainer.isHidden = true
            self.balloonHeight.constant = 10
            self.textTopMargin.constant = 0
            self.linkHeight.constant = 0
        }
        
        //textView.isUserInteractionEnabled = false
        textView.text = ""
        if attributedText == nil {
            textView.text = comment.commentText
        }else{
            textView.attributedText = attributedText
        }
        textView.textColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
        textView.linkTextAttributes = linkTextAttributes
        
        let textSize = textView.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        
        textViewHeight.constant = textSize.height
        userNameLabel.textAlignment = .right
        
        var textWidth = textSize.width
        
        if textSize.width > minWidth {
            textWidth = textSize.width
        }else{
            textWidth = minWidth
        }
        
        textViewWidth.constant = textWidth
        if comment.showLink {
            textViewWidth.constant = maxWidth
        }
        balloonView.tintColor = QiscusColorConfiguration.sharedInstance.rightBaloonColor
        
        // first cell
        if user != nil && (cellPos == .first || cellPos == .single){
            userNameLabel.text = user!.userFullName
            userNameLabel.isHidden = false
            balloonTopMargin.constant = 20
            cellHeight.constant = 20
        }else{
            userNameLabel.text = ""
            userNameLabel.isHidden = true
            balloonTopMargin.constant = 0
            cellHeight.constant = 0
        }
        
        // last cell
        if cellPos == .last || cellPos == .single{
            rightMargin.constant = -8
            textTrailing.constant = -23
            statusTrailing.constant = -20
            balloonWidth.constant = 31
        }else{
            textTrailing.constant = -8
            rightMargin.constant = -23
            statusTrailing.constant = -5
            balloonWidth.constant = 16
        }
        
        // comment status render
        self.updateStatus(toStatus: comment.commentStatus)
        
        textView.layoutIfNeeded()
    }
    open override func updateStatus(toStatus status:QiscusCommentStatus){
        switch status {
        case .sending:
            dateLabel.textColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            statusImage.tintColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            dateLabel.text = QiscusTextConfiguration.sharedInstance.sendingText
            statusImage.image = Qiscus.image(named: "ic_info_time")?.withRenderingMode(.alwaysTemplate)
            break
        case .sent:
            dateLabel.text = comment.commentTime.lowercased()
            dateLabel.textColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            statusImage.tintColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            statusImage.image = Qiscus.image(named: "ic_sending")?.withRenderingMode(.alwaysTemplate)
            break
        case .delivered:
            dateLabel.text = comment.commentTime.lowercased()
            dateLabel.textColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            statusImage.tintColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            statusImage.image = Qiscus.image(named: "ic_read")?.withRenderingMode(.alwaysTemplate)
            break
        case .read:
            dateLabel.text = comment.commentTime.lowercased()
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
        textView.text = ""
        textView.isEditable = true
        textView.isEditable = false
        textViewWidth.constant = 0
        textViewHeight.constant = 0
        textView.layoutIfNeeded()
        LinkContainer.isHidden = true
    }
    func openLink(){
        if comment.showLink{
            if let url = comment.commentLink{
                var urlToCheck = url.lowercased()
                if !urlToCheck.contains("http"){
                    urlToCheck = "http://\(url.lowercased())"
                }
                if let urlToOpen = URL(string: urlToCheck){
                    UIApplication.shared.openURL(urlToOpen)
                }
            }
        }
    }
}
