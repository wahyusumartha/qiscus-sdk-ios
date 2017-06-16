//
//  QCellTextLeft.swift
//  QiscusSDK
//
//  Created by Ahmad Athaullah on 1/3/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
import SwiftyJSON

class QCellTextLeft: QChatCell, UITextViewDelegate {
    let maxWidth:CGFloat = QiscusUIConfiguration.chatTextMaxWidth
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
    @IBOutlet weak var linkContainerWidth: NSLayoutConstraint!
    
    @IBOutlet weak var LinkContainer: UIView!
    @IBOutlet weak var linkDescription: UITextView!
    @IBOutlet weak var linkTitle: UILabel!
    @IBOutlet weak var linkImage: UIImageView!
    @IBOutlet weak var linkImageWidth: NSLayoutConstraint!
    
    @IBOutlet weak var linkHeight: NSLayoutConstraint!
    @IBOutlet weak var textTopMargin: NSLayoutConstraint!
    @IBOutlet weak var ballonHeight: NSLayoutConstraint!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textView.contentInset = UIEdgeInsets.zero
        textView.delegate = self
        textView.isUserInteractionEnabled = true
        
        LinkContainer.isHidden = true
        LinkContainer.layer.cornerRadius = 4
        LinkContainer.clipsToBounds = true
        linkContainerWidth.constant = self.maxWidth + 2
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(QCellTextLeft.openLink))
        LinkContainer.addGestureRecognizer(tapRecognizer)
        linkImage.clipsToBounds = true
    }
    public override func dataChanged(oldValue: QiscusCommentPresenter, new: QiscusCommentPresenter) {
        Qiscus.uiThread.async {
            self.textView.attributedText = self.data.commentAttributedText
            self.textView.linkTextAttributes = self.data.linkTextAttributes
            self.balloonView.image = self.data.balloonImage
            
            let textSize = self.data.cellSize
            var textWidth = self.data.cellSize.width
            
            if textWidth > self.minWidth {
                textWidth = textSize.width
            }else{
                textWidth = self.minWidth
            }
            
            if self.data.showLink {
                self.linkTitle.text = self.data.linkTitle
                self.linkDescription.text = self.data.linkDescription
                self.linkImage.image = self.data.linkImage
                self.LinkContainer.isHidden = false
                self.ballonHeight.constant = 83
                self.textTopMargin.constant = 73
                self.linkHeight.constant = 65
                textWidth = self.maxWidth
                
                if !self.data.linkSaved{
                    QiscusDataPresenter.getLinkData(withData: self.data)
                }
            }else if self.data.commentType == .reply{
                let replyData = JSON(parseJSON: self.data.comment!.commentButton)
                let text = replyData["replied_comment_message"].stringValue
                let replyType = self.data.replyType(message: text)
                
                self.linkTitle.text = self.data.linkTitle
                self.linkDescription.text = self.data.linkDescription
                
                if replyType == .image || replyType == .video {
                    self.linkImageWidth.constant = 55
                    self.linkImage.isHidden = false
                    
                    self.linkImage.loadAsync(self.data.linkImageURL!)
                }else{
                    self.linkImageWidth.constant = 0
                    self.linkImage.isHidden = true
                    
                    self.layoutIfNeeded()
                }
                //self.linkImage.image = self.data.linkImage
                self.LinkContainer.isHidden = false
                self.ballonHeight.constant = 83
                self.textTopMargin.constant = 73
                self.linkHeight.constant = 65
                textWidth = self.maxWidth
            }else{
                self.linkTitle.text = ""
                self.linkDescription.text = ""
                self.linkImage.image = Qiscus.image(named: "link")
                self.LinkContainer.isHidden = true
                self.ballonHeight.constant = 10
                self.textTopMargin.constant = 0
            }
            
            self.textViewWidth.constant = textWidth
            self.textViewHeight.constant = textSize.height
            
            self.userNameLabel.textAlignment = .left
            
            self.dateLabel.text = self.data.commentTime.lowercased()
            self.balloonView.tintColor = QiscusColorConfiguration.sharedInstance.leftBaloonColor
            self.dateLabel.textColor = QiscusColorConfiguration.sharedInstance.leftBaloonTextColor
            
            if self.data.cellPos == .first || self.data.cellPos == .single{
                self.userNameLabel.text = self.data.userFullName
                self.userNameLabel.isHidden = false
                self.balloonTopMargin.constant = 20
                self.cellHeight.constant = 20
            }else{
                self.userNameLabel.text = ""
                self.userNameLabel.isHidden = true
                self.balloonTopMargin.constant = 0
                self.cellHeight.constant = 0
            }
            
            // last cell
            if self.data.cellPos == .last || self.data.cellPos == .single{
                self.leftMargin.constant = 35
                self.textLeading.constant = 23
                self.balloonWidth.constant = 31
            }else{
                self.textLeading.constant = 8
                self.leftMargin.constant = 50
                self.balloonWidth.constant = 16
            }
            
            self.textView.layoutIfNeeded()
        }
    }
    open override func setupCell(){
        
    }
    override func clearContext() {
        textView.layoutIfNeeded()
        LinkContainer.isHidden = true
    }
    func openLink(){
        if data.showLink{
            if data.linkURL != ""{
                let url = data.linkURL
                var urlToCheck = url.lowercased()
                if !urlToCheck.contains("http"){
                    urlToCheck = "http://\(url.lowercased())"
                }
                if let urlToOpen = URL(string: urlToCheck){
                    UIApplication.shared.openURL(urlToOpen)
                }
            }
        }
        else if data.commentType == .reply {
            DispatchQueue.global().sync {
                let replyData = JSON(parseJSON: self.data.comment!.commentButton)
                let commentId = replyData["replied_comment_id"].intValue
                var found = false
                if let comment = data.comment {
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
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        return true
    }
}
