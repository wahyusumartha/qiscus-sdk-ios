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
    func didTapCell(withData data:QiscusCommentPresenter)
    func didTouchLink(onCell cell:QChatCell)
    func didTapPostbackButton(withData data: JSON)
    func didTapAccountLinking(withData data: JSON)
}
class QChatCell: UICollectionViewCell {
    var chatCellDelegate:ChatCellDelegate?
    var delegate: ChatCellDelegate?
    var data: QiscusCommentPresenter = QiscusCommentPresenter(){ // will be removed
        didSet{
            self.dataChanged(oldValue: oldValue, new: data)
        }
    }
    var comment:QComment?{
        didSet{
            if comment != nil {
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
    func prepare(withData data:QiscusCommentPresenter, andDelegate delegate:ChatCellDelegate){
        self.data = data
        self.delegate = delegate
    }

    func updateStatus(toStatus status:QCommentStatus){
        // implementation will be overrided on child class
    }
    open func resend(){
        QiscusDataPresenter.shared.resend(DataPresenter: self.data)
    }
    open func reply(){
        if let comment = self.data.comment {
            if let chatView = Qiscus.shared.chatViews[comment.roomId] {
                chatView.replyData = self.data
            }
        }
    }
    open func deleteComment(){
        if let comment = self.data.comment {
            if let chatView = Qiscus.shared.chatViews[comment.roomId]{
                chatView.dataPresenter(dataDeleted: self.data)
            }
        }
        
    }
    open func showFile(){
        if let room = QiscusRoom.room(withLastTopicId: data.topicId) {
            if let chatView = Qiscus.shared.chatViews[room.roomId] {
                if data.isUploaded && (data.commentType == .document){
                    let url = data.remoteURL!
                    let fileName = data.fileName
                    
                    let preview = ChatPreviewDocVC()
                    preview.fileName = fileName
                    preview.url = url
                    preview.roomName = room.roomName
                    
                    let backButton = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
                    chatView.navigationItem.backBarButtonItem = backButton
                    
                    chatView.navigationController?.pushViewController(preview, animated: true)
                }else{
                    if let url = URL(string: data.remoteURL!){
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
    public func downloadingMedia(){
        // implementation will be overrided on child class
    }
    func clearContext(){
        
    }
    public func dataChanged(oldValue: QiscusCommentPresenter, new: QiscusCommentPresenter){
        
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
    public func downloadFinished(){
    
    }
    public func positionChanged(){
    
    }
}
