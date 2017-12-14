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
        if self.chatRoom == nil {return 0}
        if section < self.chatRoom!.comments.count {
            return self.chatRoom!.comments[section].comments.count
        }else{
            return 1
        }
    }
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        var sectionNumber = 0
        
        if let room = self.chatRoom {
            if room.comments.count > 0 {
                self.welcomeView.isHidden = true
            }else{
                self.welcomeView.isHidden = false
            }
            sectionNumber = room.comments.count
        }
        if self.typingUsers.count > 0 {
            sectionNumber += 1
        }
        return sectionNumber
    }
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section < self.chatRoom!.comments.count && indexPath.row < self.chatRoom!.comments[indexPath.section].comments.count {
            let comment = self.chatRoom!.comments[indexPath.section].comments[indexPath.row]
            var cell = collectionView.dequeueReusableCell(withReuseIdentifier: comment.cellIdentifier, for: indexPath) as! QChatCell
            cell.clipsToBounds = true
            cell.setData(comment: comment)
            cell.delegate = self
            if let audioCell = cell as? QCellAudio{
                audioCell.audioCellDelegate = self
                cell = audioCell
            }
            return cell
        }else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellTypingLeft", for: indexPath) as! QCellTypingLeft
            
            cell.users = typingUsers
            return cell
        }
        
    }
    open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if indexPath.section < self.chatRoom!.comments.count {
            let commentGroup = self.chatRoom!.comments[indexPath.section]
            
            if kind == UICollectionElementKindSectionFooter{
                if commentGroup.senderEmail == QiscusMe.shared.email{
                    let footerCell = self.collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "cellFooterRight", for: indexPath) as! QChatFooterRight
                    return footerCell
                }else{
                    let footerCell = self.collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "cellFooterLeft", for: indexPath) as! QChatFooterLeft
                    footerCell.user = commentGroup.sender
                    return footerCell
                }
            }else{
                let headerCell = self.collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "cellHeader", for: indexPath) as! QChatHeaderCell
            
                headerCell.dateString = commentGroup.date
                return headerCell
            }
        }else{
            if kind == UICollectionElementKindSectionFooter{
                let footerCell = self.collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "emptyFooter", for: indexPath) as! QChatEmptyFooter
                return footerCell
            }else{
                let headerCell = self.collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "emptyHeader", for: indexPath) as! QChatEmptyHeaderCell
                
                return headerCell
            }
        }
    }
    
    // MARK: CollectionView delegate
    open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let room = self.chatRoom {
            if room.comments.count > 0 {
                if indexPath.section < room.comments.count {
                    if let chatCell = cell as? QChatCell {
                        chatCell.willDisplayCell()
                    }
                    if let selectedIndex = self.selectedCellIndex {
                        if indexPath.section == selectedIndex.section && indexPath.item == selectedIndex.item{
                            DispatchQueue.main.async {
                                cell.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.15)
                            }
                        }
                    }
                }
            }
            if self.isPresence {
                if room.comments.count > 0 {
                    let lastCommentSection = room.comments.count - 1
                    if indexPath.section >= lastCommentSection {
                        if indexPath.section > lastCommentSection {
                            self.isLastRowVisible = true
                            room.readAll()
                        }else{
                            let item = self.collectionView.numberOfItems(inSection: lastCommentSection) - 1
                            if indexPath.row == item {
                                self.isLastRowVisible = true
                                room.readAll()
                            }
                        }
                    }
                }
            }
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let chatCell = cell as? QChatCell {
            DispatchQueue.main.async {
                chatCell.endDisplayingCell()
            }
        }
        if let room = self.chatRoom {
            if room.comments.count > 0 {
                QiscusBackgroundThread.async {
                    if let selIndex = self.selectedCellIndex {
                        if selIndex.section == indexPath.section && selIndex.item == indexPath.item{
                            DispatchQueue.main.async {
                                cell.backgroundColor = UIColor.clear
                            }
                            self.selectedCellIndex = nil
                        }
                        
                    }
                }
                let lastMessageSection = room.comments.count - 1
                let lastgroup = room.comments[lastMessageSection]
                let lastMessageRow = lastgroup.comments.count - 1
                QiscusBackgroundThread.async {
                    if indexPath.section >= lastMessageSection {
                        var visibleIndexPath = [IndexPath]()
                        DispatchQueue.main.sync {
                            visibleIndexPath = collectionView.indexPathsForVisibleItems
                        }
                        var visible = false
                        for visibleIndex in visibleIndexPath{
                            if visibleIndex.row == lastMessageRow && visibleIndex.section == lastMessageSection{
                                visible = true
                                break
                            }
                        }
                        if self.isLastRowVisible != visible {
                            DispatchQueue.main.async {
                                self.isLastRowVisible = visible
                            }
                        }
                    }
                }
            }
        }
    }
    open func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        if indexPath.section < self.chatRoom!.comments.count {
            return true
        }
        return false
    }
    open func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        if indexPath.section < self.chatRoom!.comments.count {
        let comment = self.chatRoom!.comment(onIndexPath: indexPath)!
        var show = false
        switch action.description {
        case "copy:":
            if comment.type == .text{
                show = true
            }
            break
        case "resend":
            if comment.status == .failed && Qiscus.sharedInstance.connected {
                if comment.type == .text{
                    show = true
                }else if comment.type == .video || comment.type == .image || comment.type == .audio || comment.type == .file {
                    if let file = comment.file {
                        if QFileManager.isFileExist(inLocalPath: file.localPath){
                            show = true
                        }
                    }
                }
            }
            break
        case "deleteComment":
            if comment.status == .failed  {
                show = true
            }
            break
        case "reply":
            if Qiscus.sharedInstance.connected && comment.type != .postback && comment.type != .account && comment.status != .failed && comment.type != .system && comment.status != .sending && comment.type != .card {
                show = true
            }
            break
        case "forward":
            if self.forwardAction != nil && Qiscus.sharedInstance.connected && comment.type != .postback && comment.type != .account && comment.status != .failed && comment.type != .system && comment.status != .sending{
                show = true
            }
            break
        case "info":
            if self.infoAction != nil && Qiscus.sharedInstance.connected && comment.type != .postback && comment.type != .account && comment.status != .failed && comment.type != .system && comment.status != .sending && comment.type != .card && self.chatRoom!.type == .group && comment.senderEmail == QiscusMe.shared.email{
                show = true
            }
            break
        case "share":
            if Qiscus.sharedInstance.connected && ( comment.type == .image || comment.type == .video || comment.type == .audio || comment.type == .text || comment.type == .file || comment.type == .document) {
                if comment.type == .text {
                    return true
                }
                if let file = comment.file {
                    if QFileManager.isFileExist(inLocalPath: file.localPath){
                        return true
                    }else if NSURL(string: file.url) != nil {
                        return true
                    }
                }
            }
            break
        default:
            break
        }
    
        return show
        }else{
            return false
        }
    }
    open func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        let comment = self.chatRoom!.comment(onIndexPath: indexPath)!
        
        if action == #selector(UIResponderStandardEditActions.copy(_:)) && comment.type == .text{
            UIPasteboard.general.string = comment.text
        }
    }
    // MARK: CollectionView delegateFlowLayout
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        var height = CGFloat(0)
        if let room = self.chatRoom {
            if section >= room.comments.count{
                height = 0
            }else if section > 0 {
                let commentGroup = room.comments[section]
                let commentGroupBefore = room.comments[section - 1]
                if commentGroup.date != commentGroupBefore.date{
                    height = 35
                }
            }else{
                height = 35
            }
        }
        return CGSize(width: collectionView.bounds.size.width, height: height)
    }
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        var height = CGFloat(0)
        var width = CGFloat(0)
        if let room = self.chatRoom {
            if section < room.comments.count && room.comments.count > 0 {
                let commentGroup = room.comments[section]
                if commentGroup.senderEmail != QiscusMe.shared.email{
                    let firstComment = commentGroup.comments[0]
                    if firstComment.type != .system {
                        height = 44
                        width = 44
                    }
                }
            }
        }
        return CGSize(width: width, height: height)
    }
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if let room = self.chatRoom {
            if section < room.comments.count {
                let commentGroup = room.comments[section]
                if commentGroup.senderEmail != QiscusMe.shared.email{
                    return UIEdgeInsets(top: 0, left: 6, bottom: -44, right: 0)
                }else{
                    return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                }
            }else{
                return UIEdgeInsets.zero
            }
        }else{
            return UIEdgeInsets.zero
        }
        
    }
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section < self.chatRoom!.comments.count {
            let comment = self.chatRoom!.comment(onIndexPath: indexPath)!
            var size = comment.textSize
            let firstInSection = indexPath.row == 0
            
            size.width = QiscusHelper.screenWidth() - 16
            size.height = self.qiscusChatView(cellHeightForComment: comment, defaultHeight: size.height, firstInSection: firstInSection)
            
            return size
        }else{
            return CGSize(width: QiscusHelper.screenWidth() - 16, height: CGFloat(54))
        }
    }
    
}
