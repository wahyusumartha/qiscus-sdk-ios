//
//  QCellTextLeft.swift
//  Example
//
//  Created by Ahmad Athaullah on 1/3/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

class QCellTextLeft: QChatCell, UITextViewDelegate {
    let maxWidth:CGFloat = 190
    let minWidth:CGFloat = 80
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var balloonView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var balloonTopMargin: NSLayoutConstraint!
    @IBOutlet weak var leftMargin: NSLayoutConstraint!
    @IBOutlet weak var cellHeight: NSLayoutConstraint!
    @IBOutlet weak var textLeading: NSLayoutConstraint!
    @IBOutlet weak var textViewWidth: NSLayoutConstraint!
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    @IBOutlet weak var balloonWidth: NSLayoutConstraint!
    
    @IBOutlet weak var LinkContainer: UIView!
    @IBOutlet weak var linkDescription: UITextView!
    @IBOutlet weak var linkTitle: UILabel!
    @IBOutlet weak var linkImage: UIImageView!
    
    @IBOutlet weak var linkHeight: NSLayoutConstraint!
    @IBOutlet weak var textTopMargin: NSLayoutConstraint!
    @IBOutlet weak var ballonHeight: NSLayoutConstraint!
    
    
    var linkTextAttributes:[String: Any]{
        get{
            return [
                NSForegroundColorAttributeName: QiscusColorConfiguration.sharedInstance.leftBaloonLinkColor,
                NSUnderlineColorAttributeName: QiscusColorConfiguration.sharedInstance.leftBaloonLinkColor,
                NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue,
                NSFontAttributeName: UIFont.systemFont(ofSize: 13)
            ]
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        textView.contentInset = UIEdgeInsets.zero
        textView.delegate = self
        textView.isUserInteractionEnabled = true
        
        LinkContainer.isHidden = true
        LinkContainer.layer.cornerRadius = 4
        LinkContainer.clipsToBounds = true
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(QCellTextLeft.openLink))
        LinkContainer.addGestureRecognizer(tapRecognizer)
        linkImage.clipsToBounds = true
    }
    
    open override func setupCell(){
        let user = self.comment.sender
        let emptyString = " "
        let range = (emptyString as NSString).range(of: " ")
        let attributedString = NSMutableAttributedString(string: emptyString)
        attributedString.removeAttribute(NSLinkAttributeName, range: range)
        for (stringAttribute,_) in linkTextAttributes {
            attributedString.removeAttribute(stringAttribute, range: range)
        }
        textView.attributedText = attributedString
        textView.font = UIFont.systemFont(ofSize: 13)
        switch cellPos {
        case .first:
            let balloonEdgeInset = UIEdgeInsetsMake(13, 13, 13, 13)
            balloonView.image = Qiscus.image(named:"text_balloon_first")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
            break
        case .middle:
            let balloonEdgeInset = UIEdgeInsetsMake(13, 13, 13, 13)
            balloonView.image = Qiscus.image(named:"text_balloon_mid")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
            break
        case .last:
            let balloonEdgeInset = UIEdgeInsetsMake(13, 28, 13, 13)
            balloonView.image = Qiscus.image(named:"text_balloon_last_l")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
            break
        case .single:
            let balloonEdgeInset = UIEdgeInsetsMake(13, 28, 13, 13)
            balloonView.image = Qiscus.image(named:"text_balloon_left")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
            break
        }
        var attributedText:NSMutableAttributedString?
        
        if comment.showLink{
            if let url = comment.commentLink{
                self.linkTitle.text = "Load data ..."
                self.linkDescription.text = "Load url description"
                self.linkImage.image = Qiscus.image(named: "link")
                self.LinkContainer.isHidden = false
                self.ballonHeight.constant = 83
                self.textTopMargin.constant = 73
                self.linkHeight.constant = 65
                textViewWidth.constant = maxWidth
                
                var urlToCheck = url.lowercased()
                if !urlToCheck.contains("http"){
                    urlToCheck = "http://\(url.lowercased())"
                }
                
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
                        let allRange = (text as NSString).range(of: text)
                        attributedText?.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 13), range: allRange)
                        let url = NSURL(string: linkData.linkURL)!
                        attributedText?.addAttribute(NSLinkAttributeName, value: url, range: titleRange)
                        if comment.commentCellHeight != comment.calculateTextSizeForCommentLink(linkURL: linkData.linkURL, linkTitle: linkData.linkTitle).height {
                            self.comment.updateCommentCellWithLinkSize(linkURL: linkData.linkURL, linkTitle: linkData.linkTitle)
                            self.chatCellDelegate?.didChangeSize(onCell: self)
                        }
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
                            //NSLinkAttributeName: NSURL(string: "https://www.apple.com")!
                            attributedText?.addAttributes(self.linkTextAttributes, range: titleRange)
                            let url = NSURL(string: linkData.linkURL)!
                            attributedText?.addAttribute(NSLinkAttributeName, value: url, range: titleRange)
                            let allRange = (text as NSString).range(of: text)
                            attributedText?.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 13), range: allRange)
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
            self.ballonHeight.constant = 10
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
        textView.textColor = QiscusColorConfiguration.sharedInstance.leftBaloonTextColor
        textView.linkTextAttributes = linkTextAttributes
        
        let textSize = textView.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        
        var textWidth = comment.commentTextWidth
        if textSize.width > minWidth {
            textWidth = textSize.width
        }else{
            textWidth = minWidth
        }
        
        textViewWidth.constant = textWidth
        if comment.showLink {
            textViewWidth.constant = maxWidth
        }
        textViewHeight.constant = textSize.height
        userNameLabel.textAlignment = .left
        
        dateLabel.text = comment.commentTime.lowercased()
        balloonView.tintColor = QiscusColorConfiguration.sharedInstance.leftBaloonColor
        
        dateLabel.textColor = QiscusColorConfiguration.sharedInstance.leftBaloonTextColor
        
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
            leftMargin.constant = 42
            textLeading.constant = 23
            balloonWidth.constant = 31
        }else{
            textLeading.constant = 8
            leftMargin.constant = 57
            balloonWidth.constant = 16
        }
        
        
        textView.layoutIfNeeded()
        
    }
    override func clearContext() {
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
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        return true
    }
}
