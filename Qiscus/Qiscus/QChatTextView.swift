//
//  QChatTextView.swift
//  Example
//
//  Created by Ahmad Athaullah on 6/20/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

class QChatTextView: UITextView {

    override func becomeFirstResponder() -> Bool {
        return false
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if !isEditable {
            if let gesture = gestureRecognizer as? UILongPressGestureRecognizer, gesture.minimumPressDuration == 0.5 {
                print("gestureRecognizer minimumPD: \(gesture.minimumPressDuration)")
                
                return false
            }
        }
        return true
    }
}
