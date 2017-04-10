//
//  QCellTextRight.swift
//  QiscusSDK
//
//  Created by Ahmad Athaullah on 1/3/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

class QCellTextRight: QChatCell {
    let maxWidth:CGFloat = QiscusUIConfiguration.chatTextMaxWidth
    let minWidth:CGFloat = 80
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var balloonView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var statusImage: UIImageView!
    
    @IBOutlet weak var balloonWidth: NSLayoutConstraint!
    @IBOutlet weak var linkContainerWidth: NSLayoutConstraint!
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
    
    open override func setupCell(){
        textView.attributedText = data.commentAttributedText
        textView.linkTextAttributes = data.linkTextAttributes
        balloonView.image = data.balloonImage
        
        let textSize = data.cellSize
        var textWidth = data.cellSize.width
        
        if textWidth > minWidth {
            textWidth = textSize.width
        }else{
            textWidth = minWidth
        }
        
        self.linkTitle.text = ""
        self.linkDescription.text = ""
        self.linkImage.image = data.linkImage
        self.LinkContainer.isHidden = true
        self.balloonHeight.constant = 10
        self.textTopMargin.constant = 0
        
        if data.showLink {
            self.linkTitle.text = data.linkTitle
            self.linkDescription.text = data.linkDescription
            self.linkImage.image = data.linkImage
            self.LinkContainer.isHidden = false
            self.balloonHeight.constant = 83
            self.textTopMargin.constant = 73
            self.linkHeight.constant = 65
            textWidth = maxWidth
            
            if !data.linkSaved{
                QiscusDataPresenter.getLinkData(withData: data)
            }
        }
        textViewHeight.constant = textSize.height
        textViewWidth.constant = textWidth
        userNameLabel.textAlignment = .right
        
        balloonView.tintColor = QiscusColorConfiguration.sharedInstance.rightBaloonColor
        
        // first cell
        if data.cellPos == .first || data.cellPos == .single{
            userNameLabel.text = data.userFullName
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
        if data.cellPos == .last || data.cellPos == .single{
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
        self.updateStatus(toStatus: data.commentStatus)
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
        }
    }
}
