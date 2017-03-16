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
    var data = QiscusCommentPresenter()
    
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
    open func deleteComment(){
        if let presenterDelegate = QiscusDataPresenter.shared.delegate{
            presenterDelegate.dataPresenter(dataDeleted: self.data)
        }
    }
    open func showFile(){
        if data.isUploaded && (data.commentType == .document){
            let url = data.remoteURL!
            let fileName = data.fileName
            
            let preview = ChatPreviewDocVC()
            preview.fileName = fileName
            preview.url = url
            preview.roomName = QiscusTextConfiguration.sharedInstance.chatTitle
            QiscusChatVC.sharedInstance.navigationController?.pushViewController(preview, animated: true)
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
    open func downloadingMedia(withPercentage percentage:Int){
        // implementation will be overrided on child class
    }
    func clearContext(){
        
    }
}
