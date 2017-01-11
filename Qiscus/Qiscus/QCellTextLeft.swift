//
//  QCellTextLeft.swift
//  Example
//
//  Created by Ahmad Athaullah on 1/3/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

class QCellTextLeft: QChatCell {
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
    
    var linkTextAttributes:[String: Any]{
        get{
            return [
                NSForegroundColorAttributeName: QiscusColorConfiguration.sharedInstance.leftBaloonLinkColor,
                NSUnderlineColorAttributeName: QiscusColorConfiguration.sharedInstance.leftBaloonLinkColor,
                NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue
            ]
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        textView.contentInset = UIEdgeInsets.zero
    }
    
    open override func setupCell(){
        let user = self.comment.sender
        
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
        
        textView.isUserInteractionEnabled = false
        textView.text = comment.commentText as String
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
        }else{
            textLeading.constant = 8
            leftMargin.constant = 57
        }
        
        textView.layoutIfNeeded()
    }
}
