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
    public override func dataChanged(oldValue: QiscusCommentPresenter, new: QiscusCommentPresenter) {
        Qiscus.uiThread.async {
            self.textView.attributedText = self.data.commentAttributedText
            self.textView.linkTextAttributes = self.data.linkTextAttributes
            
            let textSize = self.data.cellSize
            var textWidth = self.data.cellSize.width
            
            if textWidth > self.minWidth {
                textWidth = textSize.width
            }else{
                textWidth = self.minWidth
            }
            
            self.textWidth.constant = textWidth
            self.textHeight.constant = textSize.height
            print("system height: \(textSize.height)")
            self.textView.layoutIfNeeded()
        }
    }
}
