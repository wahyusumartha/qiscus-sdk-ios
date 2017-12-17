//
//  QVCCollectionView.swift
//  Example
//
//  Created by Ahmad Athaullah on 5/16/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

// MARK: - CollectionView dataSource, delegate, and delegateFlowLayout
//extension QiscusChatVC: QConversationViewCellDelegate{
//    
//}
extension QiscusChatVC: QConversationViewDelegate {
    open func viewDelegate(view:QConversationCollectionView, cellForComment comment:QComment)->QChatCell?{
        return nil
    }
    open func viewDelegate(view:QConversationCollectionView, heightForComment comment:QComment)->QChatCellHeight?{
        return nil
    }
    open func viewDelegate(view:QConversationCollectionView, willDisplayCellForComment comment:QComment, cell:QChatCell, indexPath: IndexPath){
        if let room = self.chatRoom {
            let roomId = room.id
            if !self.isPresence || self.prefetch { return }
            QiscusBackgroundThread.async {
                if let r = QRoom.threadSaveRoom(withId: roomId) {
                    var count = 0
                    var section = 0
                    var item = 0
                    var found = false
                    for group in r.comments {
                        item = 0
                        for _ in group.comments{
                            count += 1
                            if count == 15 {
                                found = true
                                break
                            }else{
                                item += 1
                            }
                        }
                        if found {
                            break
                        }else{
                            section += 1
                        }
                    }
                    if indexPath.section == section && indexPath.item == item {
                        DispatchQueue.main.async {
                            self.collectionView.loadMore()
                        }
                    }
                }
            }
        }
    }
    open func viewDelegate(view:QConversationCollectionView, didEndDisplayingCellForComment comment:QComment, cell:QChatCell, indexPath: IndexPath){
        
    }
    open func viewDelegate(didEndDisplayingLastMessage view:QConversationCollectionView, comment:QComment){
        self.bottomButton.isHidden = false
        
        if self.chatRoom?.unreadCount == 0 {
            self.unreadIndicator.isHidden = true
        }else{
            self.unreadIndicator.isHidden = true
            var unreadText = ""
            if self.chatRoom!.unreadCount > 0 {
                if self.chatRoom!.unreadCount > 99 {
                    unreadText = "99+"
                }else{
                    unreadText = "\(self.chatRoom!.unreadCount)"
                }
            }
            self.unreadIndicator.text = unreadText
            self.unreadIndicator.isHidden = false
        }
    }
    open func viewDelegate(willDisplayLastMessage view:QConversationCollectionView, comment:QComment){
        self.bottomButton.isHidden = true
        if self.isPresence && !self.prefetch {
            if let room = self.chatRoom {
                let rid = room.id
                QiscusBackgroundThread.async {
                    if let rts = QRoom.threadSaveRoom(withId: rid){
                        rts.readAll()
                    }
                }
            }
        }
    }
}

