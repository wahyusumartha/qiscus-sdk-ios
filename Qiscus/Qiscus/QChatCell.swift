//
//  QChatCell.swift
//  Example
//
//  Created by Ahmad Athaullah on 1/6/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
protocol ChatCellDelegate {
    func didChangeSize(onCell cell:QChatCell)
}
class QChatCell: UICollectionViewCell {
    var indexPath:IndexPath?
    var cellPos = CellTypePosition.single
    var comment = QiscusComment()
    var chatCellDelegate:ChatCellDelegate?
    
    var file:QiscusFile?{
        get{
            return QiscusFile.getCommentFileWithComment(comment)
        }
    }
    var user:QiscusUser?{
        get{
            return comment.sender
        }
    }
    
    func setupCell(){
        // implementation will be overrided on child class
    }
    func prepareCell(withComment comment:QiscusComment, cellPos:CellTypePosition, indexPath: IndexPath, cellDelegate:ChatCellDelegate? = nil){
        self.cellPos = cellPos
        self.comment = comment
        self.indexPath = indexPath
        self.chatCellDelegate = cellDelegate
    }
    func updateStatus(toStatus status:QiscusCommentStatus){
        // implementation will be overrided on child class
    }
    open func resend(){
        if QiscusCommentClient.sharedInstance.commentDelegate != nil{
            QiscusCommentClient.sharedInstance.commentDelegate?.performResendMessage(onIndexPath: self.indexPath!)
        }
    }
    open func deleteComment(){
        if QiscusCommentClient.sharedInstance.commentDelegate != nil{
            QiscusCommentClient.sharedInstance.commentDelegate?.performDeleteMessage(onIndexPath: self.indexPath!)
        }
    }
    open func showFile(){
        let file = QiscusFile.getCommentFileWithComment(comment)!
        if !(file.isUploading){
            let url = file.fileURL
            let fileName = file.fileName
            
            let preview = ChatPreviewDocVC()
            preview.fileName = fileName
            preview.url = url
            preview.roomName = QiscusTextConfiguration.sharedInstance.chatTitle
            QiscusChatVC.sharedInstance.navigationController?.pushViewController(preview, animated: true)
        }
    }
    open func downloadingMedia(withPercentage percentage:Int){
        // implementation will be overrided on child class
    }
    func clearContext(){
        
    }
}
