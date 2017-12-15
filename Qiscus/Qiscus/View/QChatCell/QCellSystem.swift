//
//  QCellSystem.swift
//  Example
//
//  Created by Ahmad Athaullah on 7/3/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

class QCellSystem: QChatCell {
    let maxWidth:CGFloat = QiscusUIConfiguration.chatTextMaxWidth
    let minWidth:CGFloat = 40

    @IBOutlet weak var textWidth: NSLayoutConstraint!
    @IBOutlet weak var textHeight: NSLayoutConstraint!
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var containerView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.containerView.clipsToBounds = true
        self.containerView.layer.cornerRadius = 14
        self.containerView.backgroundColor = Qiscus.style.color.systemBalloonColor
    }
    public override func commentChanged() {
        if self.comment!.text == "" {
            self.containerView.isHidden = true
        }else{
            self.containerView.isHidden = false
            self.textView.attributedText = self.comment!.attributedText
            self.textView.linkTextAttributes = self.linkTextAttributes
            
            let textSize = self.comment!.textSize
            var textWidth = textSize.width
            
            if textWidth > self.minWidth {
                textWidth = textSize.width
            }else{
                textWidth = self.minWidth
            }
            
            self.textWidth.constant = textWidth
            self.textHeight.constant = textSize.height
            self.textView.layoutIfNeeded()
        }
    }
}
