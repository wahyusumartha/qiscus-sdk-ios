//
//  QChatCell.swift
//  QiscusSDK
//
//  Created by Ahmad Athaullah on 1/6/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
import SwiftyJSON

protocol ChatCellDelegate {
    func didChangeSize(onCell cell:QChatCell)
    func didTapCell(withData data:QComment)
    func didTouchLink(onCell cell:QChatCell)
    func didTapPostbackButton(withData data: JSON)
    func didTapAccountLinking(withData data: JSON)
}
class QChatCell: UICollectionViewCell, QCommentDelegate {
    
    var chatCellDelegate:ChatCellDelegate?
    var delegate: ChatCellDelegate?

    var comment:QComment?{
        didSet{
            if comment != nil {
                self.comment!.delegate = self
                self.commentChanged()
            }
        }
    }
    var linkTextAttributes:[String: Any]{
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
    func setupCell(){
        // implementation will be overrided on child class
    }


    func updateStatus(toStatus status:QCommentStatus){
        // implementation will be overrided on child class
    }
    open func resend(){
        if let room = QRoom.room(withId: self.comment!.roomId) {
            if self.comment!.type == .text {
                room.updateCommentStatus(inComment: self.comment!, status: .sending)
                room.post(comment: self.comment!)
            }else{
                if let file = self.comment!.file {
                    if file.url.contains("http") {
                        room.updateCommentStatus(inComment: self.comment!, status: .sending)
                        room.post(comment: self.comment!)
                    }else{
                        if QiscusHelper.isFileExist(inLocalPath: file.localPath) {
                            room.upload(comment: self.comment!, onSuccess: { (roomTarget, commentTarget) in
                                roomTarget.post(comment: commentTarget)
                            }, onError: { (_, _, error) in
                                print("error reupload file")
                            })
                        }
                    }
                }
            }
        }
    }
    open func reply(){
        if let chatView = Qiscus.shared.chatViews[self.comment!.roomId]{
            chatView.replyData = self.comment!
        }
    }
    public func forward(){
        if let chatView = Qiscus.shared.chatViews[self.comment!.roomId]{
            chatView.forward(comment: self.comment!)
        }
    }
    open func deleteComment(){
        if let room = QRoom.room(withId: self.comment!.roomId){
            room.deleteComment(comment: self.comment!)
        }
    }
    open func showFile(){
        if let chatView = Qiscus.shared.chatViews[self.comment!.roomId] {
            if let file = self.comment!.file {
                if file.ext == "pdf" || file.ext == "pdf_" || file.ext == "doc" || file.ext == "docx" || file.ext == "ppt" || file.ext == "pptx" || file.ext == "xls" || file.ext == "xlsx" || file.ext == "txt" {
                    let url = file.url
                    let filename = file.filename
                    
                    let preview = ChatPreviewDocVC()
                    preview.fileName = filename
                    preview.url = url
                    preview.roomName = chatView.chatRoom!.name
                    let backButton = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
                    chatView.navigationItem.backBarButtonItem = backButton
                    chatView.navigationController?.pushViewController(preview, animated: true)
                }else{
                    if let url = URL(string: file.url){
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(url, completionHandler: { success in
                                if !success {
                                    Qiscus.printLog(text: "fail to open file")
                                }
                            })
                        } else {
                            UIApplication.shared.openURL(url)
                        }
                    }else{
                        Qiscus.printLog(text: "cant open file url")
                    }
                }
            }
        }
    }
    
    func clearContext(){
        
    }
    
    public func commentChanged(){
        print("comment changed")
    }

    public func getBallon()->UIImage?{
        var imageName = ""
        var edgeInset = UIEdgeInsetsMake(13, 13, 13, 28)
        
        switch self.comment!.cellPos {
        case .single, .last:
            if self.comment?.senderEmail == QiscusMe.sharedInstance.email {
                imageName = "text_balloon_last_r"
            }else{
                edgeInset = UIEdgeInsetsMake(13, 28, 13, 13)
                imageName = "text_balloon_last_l"
            }
            break
        default:
            if self.comment?.senderEmail == QiscusMe.sharedInstance.email {
                imageName = "text_balloon_right"
            }else{
                edgeInset = UIEdgeInsetsMake(13, 28, 13, 13)
                imageName = "text_balloon_left"
            }
            break
        }

        
        return Qiscus.image(named:imageName)?.resizableImage(withCapInsets: edgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
    }
    
    public func cellWidthChanged(){
    
    }
    public func downloadingMedia(){
        // implementation will be overrided on child class
    }
    public func downloadFinished(){
    
    }
    public func uploadingMedia(){
    
    }
    public func uploadFinished(){
        
    }
    public func positionChanged(){
    
    }
    public func updateUserName(){
    
    }
    // MARK: - commentDelegate
    func comment(didChangeStatus status:QCommentStatus){
        self.updateStatus(toStatus: status)
    }
    func comment(didChangePosition position:QCellPosition){}
    
    // Audio comment delegate
    func comment(didChangeDurationLabel label:String){}
    func comment(didChangeCurrentTimeSlider value:Float){}
    func comment(didChangeSeekTimeLabel label:String){}
    func comment(didChangeAudioPlaying playing:Bool){}
    
    // File comment delegate
    func comment(didDownload downloading:Bool){}
    func comment(didUpload uploading:Bool){}
    func comment(didChangeProgress progress:CGFloat){}
}
