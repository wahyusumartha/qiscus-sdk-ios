//
//  QiscusChatVC:InputTextDelegate
//  QiscusSDK
//
//  Created by Ahmad Athaullah on 2/15/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

extension QiscusChatVC: ChatInputTextDelegate {
    // MARK: - ChatInputTextDelegate Delegate
    open func chatInputTextDidChange(chatInput input: ChatInputText, height: CGFloat) {
        let currentHeight = self.minInputHeight.constant
        if currentHeight != height {
            Qiscus.uiThread.async {
                self.minInputHeight.constant = height
                input.layoutIfNeeded()
            }
        }
        if let room = self.chatRoom {
            room.publishStartTyping()
        }
    }
    open func valueChanged(value:String){
        DispatchQueue.global().async {
//            self.linkToPreview = ""
//            if value == "" {
//                self.linkToPreview = ""
//            }else{
//                if let link = QiscusHelper.getFirstLinkInString(text: value){
//                    if link != self.linkToPreview{
//                        self.linkToPreview = link
//                    }
//                }else{
//                    self.linkToPreview = ""
//                }
//            }
        }
    }
    open func chatInputDidEndEditing(chatInput input: ChatInputText) {
        DispatchQueue.global().async {
            self.sendStopTyping()
        }
    }
    public func sendStopTyping(){
        if let room = self.chatRoom {
            room.publishStopTyping()
        }
    }
}
