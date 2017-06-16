//
//  QChatCell.swift
//  QiscusSDK
//
//  Created by Ahmad Athaullah on 1/6/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

@objc protocol ChatCellDelegate {
    func didChangeSize(onCell cell:QChatCell)
    @objc optional func didTapCell(withData data:QiscusCommentPresenter)
}
class QChatCell: UICollectionViewCell {
    var chatCellDelegate:ChatCellDelegate?
    var delegate: ChatCellDelegate?
    var data: QiscusCommentPresenter = QiscusCommentPresenter(){
        didSet{
            self.dataChanged(oldValue: oldValue, new: data)
        }
    }
    
    func setupCell(){
        // implementation will be overrided on child class
    }
    func prepare(withData data:QiscusCommentPresenter, andDelegate delegate:ChatCellDelegate){
        self.data = data
        self.delegate = delegate
    }

    func updateStatus(toStatus status:QiscusCommentStatus){
        // implementation will be overrided on child class
    }
    open func resend(){
        QiscusDataPresenter.shared.resend(DataPresenter: self.data)
    }
    open func reply(){
        print("Reply message")
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
    open func downloadingMedia(withPercentage percentage:Int){
        // implementation will be overrided on child class
    }
    func clearContext(){
        
    }
    public func dataChanged(oldValue: QiscusCommentPresenter, new: QiscusCommentPresenter){
        
    }
}
