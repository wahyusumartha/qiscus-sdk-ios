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
        Qiscus.logicThread.async {
            if currentHeight != height {
                Qiscus.uiThread.async {
                    self.minInputHeight.constant = height
                    input.layoutIfNeeded()
                }
            }
            if !self.isSelfTyping{
                if self.room != nil {
                    let message: String = "1";
                    let data: Data = message.data(using: .utf8)!
                    let channel = "r/\(self.room!.roomId)/\(self.room!.roomLastCommentTopicId)/\(QiscusMe.sharedInstance.email)/t"
                    Qiscus.uiThread.async {
                        Qiscus.sharedInstance.mqtt?.publish(data, in: channel, delivering: .atLeastOnce, retain: false, completion: { (succeeded, error) -> Void in
                            if succeeded {
                                self.isSelfTyping = true
                                Qiscus.printLog(text: "publish typing message in topic: \(channel)")
                            }else{
                                Qiscus.printLog(text: "publish typing error: \(error)")
                            }
                        })
                    }
                }
            }
        }
    }
    open func valueChanged(value:String){
        let sendButtonEnabled =  self.sendButton.isEnabled
        Qiscus.logicThread.async {
            if value == "" {
                self.linkToPreview = ""
            }else{
                if !sendButtonEnabled{
                    Qiscus.uiThread.async {
                        self.sendButton.isEnabled = true
                    }
                }
                if let link = QiscusHelper.getFirstLinkInString(text: value){
                    if link != self.linkToPreview{
                        self.linkToPreview = link
                    }
                }else{
                    self.linkToPreview = ""
                }
            }
        }
    }
    open func chatInputDidEndEditing(chatInput input: ChatInputText) {
        Qiscus.logicThread.async {
            if self.isSelfTyping{
                if self.room != nil {
                    let message: String = "0";
                    let data: Data = message.data(using: .utf8)!
                    let channel = "r/\(self.room!.roomId)/\(self.room!.roomLastCommentTopicId)/\(QiscusMe.sharedInstance.email)/t"
                    Qiscus.uiThread.async {
                        Qiscus.sharedInstance.mqtt?.publish(data, in: channel, delivering: .atLeastOnce, retain: false, completion: {  (succeeded, error) -> Void in
                            if succeeded {
                                self.isSelfTyping = false
                                Qiscus.printLog(text: "publish typing message in topic: \(channel)")
                            }else{
                                Qiscus.printLog(text: "publish typing error: \(error)")
                            }
                        })
                    }
                }
                
            }
        }
    }
}
