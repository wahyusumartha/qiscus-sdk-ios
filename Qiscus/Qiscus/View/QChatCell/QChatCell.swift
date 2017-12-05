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
    func didTapSaveContact(withData data:QComment)
    func didShare(comment: QComment)
    func didForward(comment: QComment)
    func didReply(comment:QComment)
    func getInfo(comment:QComment)
    func didTapFile(comment:QComment)
}
class QChatCell: UICollectionViewCell, QCommentDelegate {
    
    var delegate: ChatCellDelegate?

    var comment:QComment?{
        didSet{
            if comment != nil {
                self.comment?.delegate = self
                self.commentChanged()
            }
        }
    }
    var linkTextAttributes:[String: Any]{
        get{
            var foregroundColorAttributeName = QiscusColorConfiguration.sharedInstance.leftBaloonLinkColor
            var underlineColorAttributeName = QiscusColorConfiguration.sharedInstance.leftBaloonLinkColor
            if self.comment?.senderEmail == QiscusMe.shared.email{
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
    override func awakeFromNib() {
        super.awakeFromNib()
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(QChatCell.messageStatusNotif(_:)), name: QiscusNotification.MESSAGE_STATUS, object: nil)
    }
    @objc private func messageStatusNotif(_ notification: Notification){
        if let userInfo = notification.userInfo {
            if let commentData = userInfo["comment"] as? QComment {
                if let currentComment = self.comment {
                    if commentData.isInvalidated || currentComment.isInvalidated{ return }
                    if self.comment?.uniqueId == commentData.uniqueId {
                        self.updateStatus(toStatus: commentData.status)
                    }
                }
            }
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
                        if QFileManager.isFileExist(inLocalPath: file.localPath) {
                            room.upload(comment: self.comment!, onSuccess: { (roomTarget, commentTarget) in
                                roomTarget.post(comment: commentTarget)
                            }, onError: { (_, _, error) in
                                Qiscus.printLog(text: "error reupload file")
                            })
                        }
                    }
                }
            }
        }
    }
    open func reply(){
        self.delegate?.didReply(comment: self.comment!)
    }
    public func forward(){
        self.delegate?.didForward(comment: self.comment!)
        if let chatView = Qiscus.shared.chatViews[self.comment!.roomId]{
            chatView.forward(comment: self.comment!)
        }
    }
    open func deleteComment(){
        if let room = QRoom.room(withId: self.comment!.roomId){
            room.deleteComment(comment: self.comment!)
        }
    }
    open func info(){
        self.delegate?.getInfo(comment: self.comment!)
    }
    open func share(){
        if let comment = self.comment {
            self.delegate?.didShare(comment: comment)
        }
    }
    open func showFile(){
        if let c = self.comment {
            self.delegate?.didTapCell(withData: c)
        }
    }
    
    func clearContext(){
        
    }
    
    public func commentChanged(){
        //print("comment changed")
    }

    public func getBallon()->UIImage?{
        var balloonImage:UIImage? = nil
        var edgeInset = UIEdgeInsetsMake(13, 13, 13, 28)
        
        switch self.comment!.cellPos {
        case .single, .last:
            if self.comment?.senderEmail == QiscusMe.shared.email {
                balloonImage = Qiscus.style.assets.rightBallonLast
            }else{
                edgeInset = UIEdgeInsetsMake(13, 28, 13, 13)
                balloonImage = Qiscus.style.assets.leftBallonLast
            }
            break
        default:
            if self.comment?.senderEmail == QiscusMe.shared.email {
                balloonImage = Qiscus.style.assets.rightBallonNormal
            }else{
                edgeInset = UIEdgeInsetsMake(13, 28, 13, 13)
                balloonImage = Qiscus.style.assets.leftBallonNormal
            }
            break
        }
        
        return balloonImage?.resizableImage(withCapInsets: edgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
    }
    public func willDisplayCell(){
        
    }
    public func endDisplayingCell(){
    
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
    internal func unbindData(){
        if let data = self.comment {
            data.delegate = nil
        }
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
