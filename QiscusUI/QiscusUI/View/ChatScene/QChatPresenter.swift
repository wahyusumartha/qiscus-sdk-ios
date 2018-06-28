//
//  File.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 07/05/18.
//

import Foundation
import AlamofireImage
import Qiscus

protocol QChatUserInteraction {
    func sendMessage(withText text: String)
    func loadRoom(withId roomId: String)
    func getMessage(inRoom roomId: String)
    func getAvatarImage(section: Int, imageView: UIImageView)
}

protocol QChatViewDelegate {
    func onLoadRoomFinished(roomName: String, roomAvatar: UIImage?)
    func onLoadMessageFinished()
    func onSendMessageFinished(comment: CommentModel)
    func onGotNewComment(newSection: Bool, isMyComment: Bool)
}

class QChatPresenter: QChatUserInteraction {
    private let view: QChatViewDelegate!
    private let chatService: QChatService = QChatService()
    private let imageCache: AutoPurgingImageCache = AutoPurgingImageCache(memoryCapacity: 100_000_000,
                                                                          preferredMemoryUsageAfterPurge: 60_000_000)
    private var comments: [[CommentModel]] = [[]]
    private var room: QRoom?

    init(view: QChatViewDelegate) {
        self.view = view
        chatService.delegate = self
    }
    
    func getComments() -> [[CommentModel]] {
        return self.comments
    }
    
    func loadRoom(withId roomId: String) {
        if let room = QRoom.room(withId: roomId) {
            self.room = room
            self.comments = self.generateComments(qComments: room.comments)
            DispatchQueue.main.async {
                self.view.onLoadRoomFinished(roomName: room.name, roomAvatar: room.avatar)
                self.loadRoomAvatar(room: room)
                self.view.onLoadMessageFinished()
            }
        }

        DispatchQueue.main.async {
            self.chatService.room(withId: roomId)
        }
        
        let center: NotificationCenter = NotificationCenter.default
        center.removeObserver(self, name: QiscusNotification.ROOM_CHANGE(onRoom: roomId), object: nil)

        center.addObserver(self, selector: #selector(QChatPresenter.newCommentNotif(_:)), name: QiscusNotification.ROOM_CHANGE(onRoom: roomId), object: nil)
    }
    
    func sendMessage(withText text: String) {
        if let room = self.room {
            let comment = room.newComment(text: text.trimmingCharacters(in: .whitespacesAndNewlines), type: .text)
            room.post(comment: comment)
            
            let commentModel = CommentModel(uniqueId: comment.uniqueId, id: comment.id, roomId: comment.roomId, text: comment.text, time: comment.time, date: comment.date, senderEmail: comment.senderEmail, senderName: comment.senderName, senderAvatarURL: comment.senderAvatarURL, roomName: comment.roomName, textFontName: "", textFontSize: 0, displayImage: QCacheManager.shared.getImage(onCommentUniqueId: comment.uniqueId), additionalData: comment.data, durationLabel: comment.durationLabel, currentTimeSlider: comment.currentTimeSlider, seekTimeLabel: comment.seekTimeLabel, audioIsPlaying: comment.audioIsPlaying, isDownloading: comment.isDownloading, isUploading: comment.isUploading, progress: comment.progress, isRead: comment.isRead, extras: comment.extras, isMyComment: comment.senderEmail == Qiscus.client.email, commentType: comment.type, commentStatus: comment.status, file: comment.file)
            
            if let latestCommentSection = self.comments.first {
                if let latestComment = latestCommentSection.first {
                    if commentModel.senderName != latestComment.senderName || commentModel.date != latestComment.date {
                        self.comments.insert([commentModel], at: 0)
                        self.view.onGotNewComment(newSection: true, isMyComment: commentModel.isMyComment)
                    } else {
                        self.comments[0].insert(commentModel, at: 0)
                        self.view.onGotNewComment(newSection: false, isMyComment: commentModel.isMyComment)
                    }
                }
            } else {
                self.comments.insert([commentModel], at: 0)
                self.view.onGotNewComment(newSection: true, isMyComment: false)
            }
        }
    }
    
    func getMessage(inRoom roomId: String) {
        if let comments = QRoom.room(withId: roomId)?.comments {
            self.comments = self.generateComments(qComments: comments)
            self.view.onLoadMessageFinished()
        }
        
        self.chatService.room(withId: roomId)
    }
    
    func getDate(section:Int, labelView : UILabel) {
        if let comment = self.comments[section].first{
            labelView.text = comment.date
           
        }
    }
    
    func getAvatarImage(section: Int, imageView: UIImageView) {
        if let comment  = self.comments[section].first {
            if comment.senderEmail == Qiscus.client.email {
                guard let imageURL = URL(string: Qiscus.client.avatarUrl) else {
                    imageView.image = UIImage(named: "avatar", in: QiscusUI.bundle, compatibleWith: nil)
                    return
                }
                
                imageView.af_setImage(withURL: imageURL, placeholderImage: UIImage(named: "avatar", in: QiscusUI.bundle, compatibleWith: nil), runImageTransitionIfCached: true, completion: { (response) in
                    if let image = response.result.value {
                        self.imageCache.add(image, withIdentifier: Qiscus.client.avatarUrl)
                        
                        DispatchQueue.main.async {
                            imageView.image = image
                        }
                    }
                })
                
            } else {
                DispatchQueue.global(qos: .background).async {
                    guard let imageURL = URL(string: comment.senderAvatarURL) else {
                        imageView.image = UIImage(named: "avatar", in: QiscusUI.bundle, compatibleWith: nil)
                        return
                    }
                    
                    if let cachedAvatar = self.imageCache.image(withIdentifier: comment.senderAvatarURL) {
                        DispatchQueue.main.async {
                            imageView.image = cachedAvatar
                        }
                    } else {
                        let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
                            size: imageView.frame.size,
                            radius: 20.0
                        )
                        imageView.af_setImage(withURL: imageURL, placeholderImage: UIImage(named: "avatar", in: QiscusUI.bundle, compatibleWith: nil)!, filter: filter, runImageTransitionIfCached: true, completion: { (response) in
                            print("is main \(Thread.isMainThread)")
                            if let image = response.result.value {
                                self.imageCache.add(image, withIdentifier: comment.senderAvatarURL)
                                
                                DispatchQueue.main.async {
                                    imageView.image = image
                                }
                            }
                        })
                    }
                }
            }
        } else {
            imageView.image = UIImage(named: "avatar", in: QiscusUI.bundle, compatibleWith: nil)
        }
    }
    
    // MARK: private function
    private func getReplyData(stringJSON: String) {
//        let replyData = JSON(parseJSON: self.comment!.data)
//        var text = replyData["replied_comment_message"].stringValue
//        var replyType = self.comment!.replyType(message: text)
//        if replyType == .text  {
//            switch replyData["replied_comment_type"].stringValue {
//            case "location":
//                replyType = .location
//                break
//            case "contact_person":
//                replyType = .contact
//                break
//            default:
//                break
//            }
//        }
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
            let comment = CommentModel(uniqueId: comment.uniqueId, id: comment.id, roomId: comment.roomId, text: comment.text, time: comment.time, date: comment.date, senderEmail: comment.senderEmail, senderName: comment.senderName, senderAvatarURL: comment.senderAvatarURL, roomName: comment.roomName, textFontName: "", textFontSize: 0, displayImage: QCacheManager.shared.getImage(onCommentUniqueId: comment.uniqueId), additionalData: comment.data, durationLabel: comment.durationLabel, currentTimeSlider: comment.currentTimeSlider, seekTimeLabel: comment.seekTimeLabel, audioIsPlaying: comment.audioIsPlaying, isDownloading: comment.isDownloading, isUploading: comment.isUploading, progress: comment.progress, isRead: comment.isRead, extras: comment.extras, isMyComment: comment.senderEmail == Qiscus.client.email, commentType: comment.type, commentStatus: comment.status, file: comment.file)
            
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
                if comment.senderEmail == Qiscus.client.email {
                    self.chatService.room(withId: room.id)
                    return
                }
                
                let commentModel = CommentModel(uniqueId: comment.uniqueId, id: comment.id, roomId: comment.roomId, text: comment.text, time: comment.time, date: comment.date, senderEmail: comment.senderEmail, senderName: comment.senderName, senderAvatarURL: comment.senderAvatarURL, roomName: comment.roomName, textFontName: "", textFontSize: 0, displayImage: QCacheManager.shared.getImage(onCommentUniqueId: comment.uniqueId), additionalData: comment.data, durationLabel: comment.durationLabel, currentTimeSlider: comment.currentTimeSlider, seekTimeLabel: comment.seekTimeLabel, audioIsPlaying: comment.audioIsPlaying, isDownloading: comment.isDownloading, isUploading: comment.isUploading, progress: comment.progress, isRead: comment.isRead, extras: comment.extras, isMyComment: comment.senderEmail == Qiscus.client.email, commentType: comment.type, commentStatus: comment.status, file: comment.file)
                
                if let latestCommentSection = self.comments.first {
                    if let latestComment = latestCommentSection.first {
                        if commentModel.senderName != latestComment.senderName || commentModel.date != latestComment.date {
                            self.comments.insert([commentModel], at: 0)
                            self.view.onGotNewComment(newSection: true, isMyComment: false)
                        } else {
                            self.comments[0].insert(commentModel, at: 0)
                            self.view.onGotNewComment(newSection: false, isMyComment: false)
                        }
                    }
                } else {
                    self.comments.insert([commentModel], at: 0)
                    self.view.onGotNewComment(newSection: true, isMyComment: false)
                }
                
            }
        }
    }
}

extension QChatPresenter: QChatServiceDelegate {
    func chatService(didFinishLoadRoom room:QRoom, withMessage message:String?) {
        self.room = room
        self.comments = self.generateComments(qComments: room.comments)
        self.view.onLoadMessageFinished()
        
        self.view.onLoadRoomFinished(roomName: room.name, roomAvatar: room.avatar)
        self.loadRoomAvatar(room: room)
    }
    
    func chatService(didFailLoadRoom error:String) {
        
    }
}
