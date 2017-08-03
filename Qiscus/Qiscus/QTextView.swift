//
//  QTextView.swift
//  Example
//
//  Created by Ahmad Athaullah on 8/3/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

class QTextView: UITextView {
    var comment:QComment?
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
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
