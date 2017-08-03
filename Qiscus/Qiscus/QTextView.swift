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
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
//    func textViewDidChangeSelection(_ textView: UITextView) {
//        if !NSEqualRanges(self.selectedRange, NSRange(location: 0, length: 0)){
//            self.selectedRange = NSRange(location: 0, length: 0)
//        }
//        let menuController = UIMenuController.shared
//        menuController.isMenuVisible = true
//    }
    
    override func copy(_ sender: Any?) {
        UIPasteboard.general.string = comment?.text
    }
    override func selectionRects(for range: UITextRange) -> [Any] {
        return []
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        print("action description: \(action.description)")
//        if !NSEqualRanges(self.selectedRange, NSRange(location: 0, length: 0)){
//            self.selectedRange = NSRange(location: 0, length: 0)
//        }
        switch action.description {
        case "cut:","select:","selectAll:","paste:","_lookup:","_define:","_addShortcut:","_share:":
            return false
        default:
            return super.canPerformAction(action, withSender: sender)
        }
        
    }
//    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
//        //var show = false
//        //print("action description: \(action.description)")
//        return false
//        var show = false
//        switch action.description {
//        case "copy:":
//            if comment?.type == .text{
//                show = true
//            }
//            break
//        case "resend":
//            if comment?.status == .failed && Qiscus.sharedInstance.connected {
//                if comment?.type == .text{
//                    show = true
//                }else if comment!.type == .video || comment!.type == .image || comment!.type == .audio || comment!.type == .file {
//                    if let file = comment!.file {
//                        if QFileManager.isFileExist(inLocalPath: file.localPath){
//                            show = true
//                        }
//                    }
//                }
//                //                else{
//                //                    if let file = QiscusFile.file(forComment: commentData){
//                //                        if file.isUploaded || file.isOnlyLocalFileExist{
//                //                            show = true
//                //                        }
//                //                    }
//                //                }
//            }
//            break
//        case "deleteComment":
//            if comment?.status == .failed  {
//                show = true
//            }
//            break
//        case "reply":
//            if Qiscus.sharedInstance.connected && comment?.type != .postback && comment?.type != .account && comment?.status != .failed && comment?.type != .system && comment?.status != .sending && comment?.type != .card{
//                show = true
//            }
//            break
////        case "forward":
////            if self.forwardAction != nil && Qiscus.sharedInstance.connected && comment?.type != .postback && comment?.type != .account && comment?.status != .failed && comment?.type != .system && comment?.status != .sending && comment?.type != .card {
////                show = true
////            }
////            break
////        case "info":
////            if self.infoAction != nil && Qiscus.sharedInstance.connected && comment?.type != .postback && comment?.type != .account && comment?.status != .failed && comment?.type != .system && comment?.status != .sending && comment?.type != .card && self.chatRoom!.type == .group && comment?.senderEmail == QiscusMe.sharedInstance.email{
////                show = true
////            }
////            break
//        default:
//            break
//        }
//        return super.canPerformAction(action, withSender: sender)
//    }
}
