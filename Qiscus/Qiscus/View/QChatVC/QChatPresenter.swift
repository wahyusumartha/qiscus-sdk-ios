//
//  File.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 07/05/18.
//

import Foundation

protocol QChatUserInteraction {
    func sendMessage(withText text: String)
    func loadRoom(withId roomId: String)
    func getMessage(inRoom roomId: String)
}

protocol QChatViewDelegate {
    func onLoadRoomFinished(roomName: String, roomAvatar: UIImage?)
    func onLoadMessageFinished(comments: [[CommentModel]])
    func onSendMessageFinished(comment: CommentModel)
    func onGotNewComment(comment: CommentModel)
}

class QChatPresenter: QChatUserInteraction {
    private let view: QChatViewDelegate!
    private let chatService: QChatService = QChatService()
    init(view: QChatViewDelegate) {
        self.view = view
        chatService.delegate = self
    }
    
    func loadRoom(withId roomId: String) {
        if let room = QRoom.room(withId: roomId) {
            DispatchQueue.main.async {
                self.view.onLoadRoomFinished(roomName: room.name, roomAvatar: room.avatar)
                self.loadRoomAvatar(room: room)
                self.view.onLoadMessageFinished(comments: self.generateComments(qComments: room.comments))
            }
        }

        DispatchQueue.main.async {
            self.chatService.room(withId: roomId)
        }
        
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(QChatPresenter.newCommentNotif(_:)), name: QiscusNotification.ROOM_CHANGE(onRoom: roomId), object: nil)
    }
    
    func sendMessage(withText text: String) {
        
    }
    
    func getMessage(inRoom roomId: String) {
        if let comments = QRoom.room(withId: roomId)?.comments {
            self.view.onLoadMessageFinished(comments: generateComments(qComments: comments))
        }
        
        self.chatService.room(withId: roomId)
    }
    
    private func loadRoomAvatar(room: QRoom) {
        room.loadAvatar(onSuccess: { (avatar) in
            self.view.onLoadRoomFinished(roomName: room.name, roomAvatar: room.avatar)
        }, onError: { (error) in
            room.downloadRoomAvatar(onSuccess: { room in
                self.loadRoomAvatar(room: room)
            })
        })
    }
    
    private func generateComments(qComments: [QComment]) -> [[CommentModel]] {
        var commentModels = qComments.map { (comment) -> CommentModel in
            let comment = CommentModel(uniqueId: comment.uniqueId, id: comment.id, roomId: comment.roomId, text: comment.text, time: comment.time, date: comment.date, senderEmail: comment.senderEmail, senderName: comment.senderName, senderAvatarURL: comment.senderAvatarURL, roomName: comment.roomName, textFontName: comment.textFontName, textFontSize: comment.textFontSize, displayImage: comment.displayImage, durationLabel: comment.durationLabel, currentTimeSlider: comment.currentTimeSlider, seekTimeLabel: comment.seekTimeLabel, audioIsPlaying: comment.audioIsPlaying, isDownloading: comment.isDownloading, isUploading: comment.isUploading, progress: comment.progress, isRead: comment.isRead, extras: comment.extras, isMyComment: comment.senderEmail == Qiscus.client.email, commentType: comment.type, commentStatus: comment.status)
            
            return comment
        }
        
        return self.groupingComments(comments: commentModels)
     }
    
    private func groupingComments(comments: [CommentModel]) -> [[CommentModel]]{
        var retVal = [[CommentModel]]()
        var uidList = [CommentModel]()
        var s = 0
        let date = Double(Date().timeIntervalSince1970)
        var prevComment:CommentModel?
        var group = [CommentModel]()
        var count = 0
//        func checkPosition(ids:[String]) {
//            var n = 0
//            for id in ids {
//                var position = QCellPosition.middle
//                if ids.count > 1 {
//                    switch n {
//                    case 0 :
//                        position = .first
//                        break
//                    case ids.count - 1 :
//                        position = .last
//                        break
//                    default:
//                        position = .middle
//                        break
//                    }
//                }else{
//                    position = .single
//                }
//                n += 1
//                if let c = QComment.threadSaveComment(withUniqueId: id){
//                    c.updateCellPos(cellPos: position)
//                }
//            }
//        }
        
        for comment in  comments.reversed() {
            if !uidList.contains(where: { (commentModel) -> Bool in
                return commentModel.uniqueId == comment.uniqueId
            }) {
                if let prev = prevComment{
                    if prev.date == comment.date && prev.senderEmail == comment.senderEmail {
                        uidList.append(comment)
                        group.append(comment)
                    }else{
                        retVal.append(group)
//                        checkPosition(ids: group)
                        group = [CommentModel]()
                        group.append(comment)
                        uidList.append(comment)
                        
                    }
                }else{
                    group.append(comment)
                    uidList.append(comment)
                }
                if count == comments.count - 1  {
                    retVal.append(group)
//                    checkPosition(ids: group)
                }else{
                    prevComment = comment
                }
            }
            count += 1
        }
        return retVal
    }
    
    // MARK : Notification center function
    @objc private func newCommentNotif(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            guard let property = userInfo["property"] as? QRoomProperty else {return}
            if property == .lastComment {
                guard let room = userInfo["room"] as? QRoom else {return}
                guard let comment = room.lastComment else {return}
                
                if room.isInvalidated { return }
                
                let commentModel = CommentModel(uniqueId: comment.uniqueId, id: comment.id, roomId: comment.roomId, text: comment.text, time: comment.time, date: comment.date, senderEmail: comment.senderEmail, senderName: comment.senderName, senderAvatarURL: comment.senderAvatarURL, roomName: comment.roomName, textFontName: comment.textFontName, textFontSize: comment.textFontSize, displayImage: comment.displayImage, durationLabel: comment.durationLabel, currentTimeSlider: comment.currentTimeSlider, seekTimeLabel: comment.seekTimeLabel, audioIsPlaying: comment.audioIsPlaying, isDownloading: comment.isDownloading, isUploading: comment.isUploading, progress: comment.progress, isRead: comment.isRead, extras: comment.extras, isMyComment: comment.senderEmail == Qiscus.client.email, commentType: comment.type, commentStatus: comment.status)
                self.view.onGotNewComment(comment: commentModel)
            }
        }
    }
}

extension QChatPresenter: QChatServiceDelegate {
    func chatService(didFinishLoadRoom room:QRoom, withMessage message:String?) {
        self.view.onLoadRoomFinished(roomName: room.name, roomAvatar: room.avatar)
        self.loadRoomAvatar(room: room)
        self.view.onLoadMessageFinished(comments: self.generateComments(qComments: room.comments))
    }
    
    func chatService(didFailLoadRoom error:String) {
        
    }
}
