//
//  QTextView.swift
//  Example
//
//  Created by Ahmad Athaullah on 8/3/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

class QTextView: UITextView {
    var commentLinkTextAttributes:[String: Any]{
        get{
            var foregroundColorAttributeName = QiscusColorConfiguration.sharedInstance.leftBaloonLinkColor
            var underlineColorAttributeName = QiscusColorConfiguration.sharedInstance.leftBaloonLinkColor
            if self.comment?.senderEmail == QiscusMe.sharedInstance.email{
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
    var comment:QComment?{
        didSet{
            self.tintColor = .clear
            self.attributedText = self.comment?.attributedText
            self.linkTextAttributes = self.commentLinkTextAttributes
        }
    }
    
    override func copy(_ sender: Any?) {
        UIPasteboard.general.string = comment?.text
        if !NSEqualRanges(self.selectedRange, NSRange(location: 0, length: 0)){
            self.selectedRange = NSRange(location: 0, length: 0)
        }
    }
    override func selectionRects(for range: UITextRange) -> [Any] {
        return []
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        print("action description: \(action.description)")
        switch action.description {
        case "cut:","select:","selectAll:","paste:","_lookup:","_define:","_addShortcut:","_share:":
            return false
        default:
            return super.canPerformAction(action, withSender: sender)
        }
        
    }
}
