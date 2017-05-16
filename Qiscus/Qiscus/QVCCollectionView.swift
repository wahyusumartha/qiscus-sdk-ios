//
//  QVCCollectionView.swift
//  Example
//
//  Created by Ahmad Athaullah on 5/16/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

// MARK: - CollectionView dataSource, delegate, and delegateFlowLayout
extension QiscusChatVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    // MARK: CollectionView Data source
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.comments[section].count
    }
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.comments.count
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let data = self.comments[indexPath.section][indexPath.row]
        
        if data.commentIndexPath != indexPath {
            data.commentIndexPath = indexPath
            data.balloonImage = data.getBalloonImage()
            self.comments[indexPath.section][indexPath.row] = data
        }
        if data.balloonImage == nil {
            data.balloonImage = data.getBalloonImage()
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: data.cellIdentifier, for: indexPath) as! QChatCell
        cell.prepare(withData: data, andDelegate: self)
        cell.setupCell()
        
        if let audioCell = cell as? QCellAudio{
            audioCell.audioCellDelegate = self
            return audioCell
        }else{
            return cell
        }
    }
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let comment = self.comments[indexPath.section].first!
        
        if kind == UICollectionElementKindSectionFooter{
            if comment.userIsOwn{
                let footerCell = self.collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "cellFooterRight", for: indexPath) as! QChatFooterRight
                return footerCell
            }else{
                let footerCell = self.collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "cellFooterLeft", for: indexPath) as! QChatFooterLeft
                footerCell.setup(withComent: comment)
                return footerCell
            }
        }else{
            let headerCell = self.collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "cellHeader", for: indexPath) as! QChatHeaderCell
            
            var date:String = ""
            
            if comment.commentDate == QiscusHelper.thisDateString {
                date = QiscusTextConfiguration.sharedInstance.todayText
            }else{
                date = comment.commentDate
            }
            headerCell.setupHeader(withText: date)
            headerCell.clipsToBounds = true
            return headerCell
        }
    }
    
    // MARK: CollectionView delegate
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if let targetCell = cell as? QChatCell{
            if !targetCell.data.userIsOwn && targetCell.data.commentStatus != .read{
                publishRead()
                var i = 0
                for index in unreadIndexPath{
                    if index.row == indexPath.row && index.section == indexPath.section{
                        unreadIndexPath.remove(at: i)
                        break
                    }
                    i += 1
                }
            }
        }
        if indexPath.section == (comments.count - 1){
            if indexPath.row == comments[indexPath.section].count - 1{
                isLastRowVisible = true
            }
        }
    }
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.section == (comments.count - 1){
            
            if indexPath.row == comments[indexPath.section].count - 1{
                let visibleIndexPath = collectionView.indexPathsForVisibleItems
                if visibleIndexPath.count > 0{
                    var visible = false
                    for visibleIndex in visibleIndexPath{
                        if visibleIndex.row == indexPath.row && visibleIndex.section == indexPath.section{
                            visible = true
                            break
                        }
                    }
                    isLastRowVisible = visible
                }else{
                    isLastRowVisible = true
                }
            }
        }
    }
    public func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    public func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        let comment = self.comments[indexPath.section][indexPath.row]
        var show = false
        if action == #selector(UIResponderStandardEditActions.copy(_:)) && comment.commentType == .text{
            show = true
        }else if action == #selector(QChatCell.resend) && comment.commentStatus == .failed && Qiscus.sharedInstance.connected {
            if comment.commentType == .text{
                show = true
            }else{
                if let commentData = comment.comment{
                    if let file = QiscusFile.file(forComment: commentData){
                        if file.isUploaded || file.isOnlyLocalFileExist{
                            show = true
                        }
                    }
                }
            }
        }else if action == #selector(QChatCell.deleteComment) && comment.commentStatus == .failed {
            show = true
        }
        return show
    }
    public func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        let textComment = self.comments[indexPath.section][indexPath.row]
        
        if action == #selector(UIResponderStandardEditActions.copy(_:)) && textComment.commentType == .text{
            UIPasteboard.general.string = textComment.commentText
        }
    }
    // MARK: CollectionView delegateFlowLayout
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        var height = CGFloat(0)
        if section > 0 {
            let firstComment = self.comments[section][0]
            let firstCommentBefore = self.comments[section - 1][0]
            if firstComment.commentDate != firstCommentBefore.commentDate{
                height = 35
            }
        }else{
            height = 35
        }
        return CGSize(width: collectionView.bounds.size.width, height: height)
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        var height = CGFloat(0)
        var width = CGFloat(0)
        let firstComment = self.comments[section][0]
        if !firstComment.userIsOwn{
            height = 44
            width = 44
        }
        return CGSize(width: width, height: height)
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let firstComment = self.comments[section][0]
        if firstComment.userIsOwn{
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }else{
            return UIEdgeInsets(top: 0, left: 0, bottom: -44, right: 0)
        }
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let comment = self.comments[indexPath.section][indexPath.row]
        var size = comment.cellSize
        if comment.commentType == .text{
            size.height += 15
            if comment.showLink {
                size.height += 75
            }
        }
        if comment.cellPos == .single || comment.cellPos == .first{
            size.height += 20
        }
        size.width = collectionView.bounds.size.width
        return size
    }
}
