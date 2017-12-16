//
//  QConversationCollectionView+QRoomDelegate.swift
//  Extension for conversation view for roomDelegate
//  Qiscus
//
//  Created by Ahmad Athaullah on 16/12/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

extension QConversationCollectionView: QRoomDelegate {
    public func room(didChangeName room: QRoom) {
        if let r = self.room {
            if r.id == room.id {
                let name = room.name
                self.roomDelegate?.roomDelegate?(didChangeName: room, name: name)
            }
        }
    }
    public func room(didFinishSync room: QRoom) {
        if let r = self.room {
            if r.id == room.id {
                self.messages = r.grouppedComments
                self.reloadData()
                self.roomDelegate?.roomDelegate?(didFinishSync: r)
            }
        }
    }
    public func room(didChangeAvatar room: QRoom) {
        if let r = self.room {
            if r.id == room.id {
                let roomId = r.id
                let roomName = r.name
                QiscusBackgroundThread.async {
                    if let rts = QRoom.threadSaveRoom(withId: roomId){
                        rts.loadAvatar(onSuccess: { (avatar) in
                            DispatchQueue.main.async {
                                self.roomDelegate?.roomDelegate?(didChangeAvatar: r, avatar: avatar)
                            }
                        }, onError: { (error) in
                            Qiscus.printLog(text: "fail to load room avatar on room \(roomName)")
                        })
                    }
                }
            }
        }
    }
    
    public func room(didChangeUser room: QRoom, user: QUser) {
        if let r = self.room {
            if r.id == room.id {
                self.roomDelegate?.roomDelegate?(didChangeUser: r, user: user)
            }
        }
    }
    public func room(didChangeParticipant room: QRoom) {
        if let r = self.room {
            if r.id == room.id {
                self.roomDelegate?.roomDelegate?(didChangeParticipant: r)
            }
        }
    }
    
    public func room(gotNewComment comment: QComment) {
        if let r = self.room {
            if r.id == comment.roomId {
                self.messages = r.grouppedComments
                self.reloadData()
                if comment.senderEmail == QiscusMe.shared.email {
                    self.scrollToBottom(true)
                }
            }
        }
    }
    
    public func room(didDeleteComment room:QRoom) {
        if let r = self.room {
            if r.id == room.id {
                self.messages = r.grouppedComments
                self.reloadData()
            }
        }
    }
    
    public func room(didFinishLoadMore inRoom: QRoom, success: Bool, gotNewComment: Bool) {
        if let r = self.room {
            if r.id == inRoom.id {
                if success && gotNewComment {
                    self.messages = r.grouppedComments
                    let contentHeight = self.contentSize.height
                    let offsetY = self.contentOffset.y
                    let bottomOffset = contentHeight - offsetY
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    self.reloadData()
                    self.layoutIfNeeded()
                    self.contentOffset = CGPoint(x: 0, y: self.contentSize.height - bottomOffset)
                    CATransaction.commit()
                }
            }
        }
    }
    public func room(didChangeUnread inRoom:QRoom) {
        if let r = self.room {
            if r.id == inRoom.id {
                self.roomDelegate?.roomDelegate?(didChangeUnread: r, unreadCount: r.unreadCount)
            }
        }
    }
}
