//
//  QCellTextLeft.swift
//  QiscusSDK
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
        
        if data.showLink{
            self.linkTitle.text = data.linkTitle
            self.linkDescription.text = data.linkDescription
            self.linkImage.image = data.linkImage
            self.LinkContainer.isHidden = false
            self.ballonHeight.constant = 83
            self.textTopMargin.constant = 73
            self.linkHeight.constant = 65
            textWidth = maxWidth
            
            if !data.linkSaved{
                QiscusDataPresenter.getLinkData(withData: data)
            }
        }else{
            self.linkTitle.text = ""
            self.linkDescription.text = ""
            self.linkImage.image = Qiscus.image(named: "link")
            self.LinkContainer.isHidden = true
            self.ballonHeight.constant = 10
            self.textTopMargin.constant = 0
        }
        
        textViewWidth.constant = textWidth
        textViewHeight.constant = textSize.height
        
        userNameLabel.textAlignment = .left
        
        dateLabel.text = data.commentTime.lowercased()
        balloonView.tintColor = QiscusColorConfiguration.sharedInstance.leftBaloonColor
        dateLabel.textColor = QiscusColorConfiguration.sharedInstance.leftBaloonTextColor
        
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
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        return true
    }
}
