//
//  QConversationCollectionView+CollectionView.swift
//  Qiscus
//
//  Created by Ahmad Athaullah on 16/12/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
extension QConversationCollectionView {
    
}
extension QConversationCollectionView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // MARK: CollectionView Data source
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.room == nil {return 0}
        if section < self.messages.count {
            return self.messages[section].count
        }else{
            return 1
        }
    }
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        var sectionNumber = 0
        if self.room != nil {
            sectionNumber = self.messages.count
            if self.typingUsers.count > 0 {
                sectionNumber += 1
            }
        }
        return sectionNumber
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section < self.messages.count && indexPath.row < self.messages[indexPath.section].count {
            let comment = self.messages[indexPath.section][indexPath.row]
            if let cell = self.viewDelegate?.viewDelegate?(view: self, cellForComment: comment){
                return cell
            }else{
                var cell = collectionView.dequeueReusableCell(withReuseIdentifier: comment.cellIdentifier, for: indexPath) as! QChatCell
                cell.clipsToBounds = true
                cell.setData(comment: comment)
                //TODO: cell.delegate = self
                if let audioCell = cell as? QCellAudio{
                    //TODO: audioCell.audioCellDelegate = self
                    cell = audioCell
                }
                return cell
            }
        }else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellTypingLeft", for: indexPath) as! QCellTypingLeft
            
            cell.users = typingUsers
            return cell
        }
        
    }
    open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if indexPath.section < self.messages.count {
            let commentGroup = self.messages[indexPath.section]
            let firsMessage = commentGroup.first!
            if kind == UICollectionElementKindSectionFooter{
                if firsMessage.senderEmail == QiscusMe.shared.email{
                    let footerCell = self.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "cellFooterRight", for: indexPath) as! QChatFooterRight
                    return footerCell
                }else{
                    let footerCell = self.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "cellFooterLeft", for: indexPath) as! QChatFooterLeft
                    footerCell.user = firsMessage.sender
                    return footerCell
                }
            }else{
                let headerCell = self.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "cellHeader", for: indexPath) as! QChatHeaderCell
                
                headerCell.dateString = firsMessage.date
                return headerCell
            }
        }else{
            if kind == UICollectionElementKindSectionFooter{
                let footerCell = self.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "emptyFooter", for: indexPath) as! QChatEmptyFooter
                return footerCell
            }else{
                let headerCell = self.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "emptyHeader", for: indexPath) as! QChatEmptyHeaderCell
                
                return headerCell
            }
        }
    }
    
    // MARK: CollectionView delegate
    open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if self.messages.count > indexPath.section {
            let group = self.messages[indexPath.section]
            if group.count > indexPath.item {
                let message = group[indexPath.item]
                if let chatCell = cell as? QChatCell {
                    DispatchQueue.main.async {
                        chatCell.willDisplayCell()
                    }
                    self.viewDelegate?.viewDelegate?(view: self, willDisplayCellForComment: message, cell: chatCell)
                }
            }
        }
        
        if let room = self.room {
            let roomId = room.id
            let lastSection = self.messages.count - 1
            let lastItem = self.messages[lastSection].count - 1
            QiscusBackgroundThread.async {
                if let r = QRoom.threadSaveRoom(withId: roomId) {
                    if (indexPath.section == lastSection && indexPath.item == lastItem) || indexPath.section == lastSection {
                        r.readAll()
                    }
                }
            }
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if self.messages.count > indexPath.section {
            let group = self.messages[indexPath.section]
            if group.count > indexPath.item {
                let message = group[indexPath.item]
                if let chatCell = cell as? QChatCell {
                    DispatchQueue.main.async {
                        chatCell.endDisplayingCell()
                    }
                    self.viewDelegate?.viewDelegate?(view: self, didEndDisplayingCellForComment: message, cell: chatCell)
                    let lastSection = self.messages.count - 1
                    if indexPath.section == lastSection {
                        let lastItem = self.messages[lastSection].count - 1
                        if indexPath.item == lastItem {
                            self.viewDelegate?.viewDelegate?(didEndDisplayingLastMessage: self, comment: message)
                        }
                    }
                }
            }
        }
    }
    open func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        if indexPath.section < self.messages.count {
            return true
        }
        return false
    }
    open func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        if indexPath.section < self.messages.count {
            let comment = self.messages[indexPath.section][indexPath.item]
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
                if self.infoAction != nil {
                    if self.room?.type == .group {
                        if comment.senderEmail == QiscusMe.shared.email && Qiscus.sharedInstance.connected && comment.type != .postback && comment.type != .account && comment.status != .failed && comment.type != .system && comment.status != .sending && comment.type != .card{
                            show = true
                        }
                    }
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
        if action == #selector(UIResponderStandardEditActions.copy(_:)) {
            if self.messages.count > indexPath.section {
                let group = self.messages[indexPath.section]
                if group.count > indexPath.item {
                    let message = group[indexPath.item]
                    if message.type == .text {
                        UIPasteboard.general.string = message.text
                    }
                }
            }
        }
    }
    // MARK: CollectionView delegateFlowLayout
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        var height = CGFloat(0)
        if self.messages.count > section {
            if section == 0 {
                height = 35
            }else{
                let group = self.messages[section].first!
                let groupBefore = self.messages[section - 1].first!
                if group.date != groupBefore.date {
                    height = 35
                }
            }
        }
        return CGSize(width: collectionView.bounds.size.width, height: height)
    }
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        var height = CGFloat(0)
        var width = CGFloat(0)
        if self.messages.count > section {
            let firstMessage = self.messages[section].first!
            if firstMessage.senderEmail != QiscusMe.shared.email && firstMessage.type != .system {
                height = 44
                width = 44
            }
        }
        return CGSize(width: width, height: height)
    }
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if self.messages.count > section {
            let firstMessage = self.messages[section].first!
            if firstMessage.senderEmail != QiscusMe.shared.email {
                return UIEdgeInsets(top: 0, left: 6, bottom: -44, right: 0)
            }
        }
        return UIEdgeInsets.zero
    }
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if self.messages.count > indexPath.section {
            let group = self.messages[indexPath.section]
            if group.count > indexPath.item {
                let message = group[indexPath.item]
                if let h = self.viewDelegate?.viewDelegate?(view: self, heightForComment: message) {
                    return CGSize(width: QiscusHelper.screenWidth() - 16, height: h.height)
                }else{
                    var size = message.textSize
                    
                    size.width = QiscusHelper.screenWidth() - 16
                    size.height = self.cellHeightForComment(comment: message, defaultHeight: size.height, firstInSection: indexPath.item == 0)
                    return size
                }
            }
            return CGSize.zero
        }else{
            return CGSize(width: QiscusHelper.screenWidth() - 16, height: CGFloat(54))
        }
    }
}
