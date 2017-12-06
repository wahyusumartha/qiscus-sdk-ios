//
//  QConversationCollectionView.swift
//  Qiscus
//
//  Created by Ahmad Athaullah on 06/12/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
@objc public protocol QConversationCollectionViewDelegate{
    @objc optional func conversationCollectionView(lastRowVisibilityChange visibility:Bool)
}
public class QConversationCollectionView: UICollectionView {
    public var room:QRoom?
    public var typingUsers = [String:QUser]()
    public var conversationDelegate:QConversationCollectionViewDelegate?
    public var typingUserTimer = [String:Timer]()
    
    public var processingTyping = false
    public var previewedTypingUsers = [String]()
    public var isPresence = false
    
    var isLastRowVisible: Bool = false {
        didSet{
            if oldValue != isLastRowVisible{
                self.conversationDelegate?.conversationCollectionView?(lastRowVisibilityChange: self.isLastRowVisible)
            }
        }
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        self.delegate = self
        self.dataSource = self
    }
 
    open func registerCell(){
        self.register(UINib(nibName: "QCellTypingLeft",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellTypingLeft")
        self.register(UINib(nibName: "QChatEmptyFooter",bundle: Qiscus.bundle), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "emptyFooter")
        self.register(UINib(nibName: "QChatEmptyHeaderCell",bundle: Qiscus.bundle), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "emptyHeader")
        self.register(UINib(nibName: "QChatHeaderCell",bundle: Qiscus.bundle), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "cellHeader")
        self.register(UINib(nibName: "QChatFooterLeft",bundle: Qiscus.bundle), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "cellFooterLeft")
        self.register(UINib(nibName: "QChatFooterRight",bundle: Qiscus.bundle), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "cellFooterRight")
        self.register(UINib(nibName: "QCellSystem",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellSystem")
        self.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "EmptyCell")
        self.register(UINib(nibName: "QCellCardLeft",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellCardLeft")
        self.register(UINib(nibName: "QCellCardRight",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellCardRight")
        self.register(UINib(nibName: "QCellTextLeft",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellTextLeft")
        self.register(UINib(nibName: "QCellPostbackLeft",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellPostbackLeft")
        self.register(UINib(nibName: "QCellTextRight",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellTextRight")
        self.register(UINib(nibName: "QCellMediaLeft",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellMediaLeft")
        self.register(UINib(nibName: "QCellMediaRight",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellMediaRight")
        self.register(UINib(nibName: "QCellAudioLeft",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellAudioLeft")
        self.register(UINib(nibName: "QCellAudioRight",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellAudioRight")
        self.register(UINib(nibName: "QCellFileLeft",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellFileLeft")
        self.register(UINib(nibName: "QCellFileRight",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellFileRight")
        self.register(UINib(nibName: "QCellContactRight",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellContactRight")
        self.register(UINib(nibName: "QCellContactLeft",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellContactLeft")
        self.register(UINib(nibName: "QCellLocationRight",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellLocationRight")
        self.register(UINib(nibName: "QCellLocationLeft",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellLocationLeft")
    }
    public func subscribeEvent(){
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(QConversationCollectionView.newCommentNotif(_:)), name: QiscusNotification.GOT_NEW_COMMENT, object: nil)
        center.addObserver(self, selector: #selector(QConversationCollectionView.commentDeleted(_:)), name: QiscusNotification.COMMENT_DELETE, object: nil)
        center.addObserver(self, selector: #selector(QConversationCollectionView.userTyping(_:)), name: QiscusNotification.USER_TYPING, object: nil)
    }
    public func unsubscribeEvent(){
        let center: NotificationCenter = NotificationCenter.default
        center.removeObserver(self, name: QiscusNotification.GOT_NEW_COMMENT, object: nil)
        center.removeObserver(self, name: QiscusNotification.COMMENT_DELETE, object: nil)
        center.removeObserver(self, name: QiscusNotification.USER_TYPING, object: nil)
    }
    // MARK: - Event handler
    open func onDeleteComment(){
        self.reloadData()
    }
    open func gotNewComment(comment: QComment, room:QRoom) {
        self.room = room
        self.reloadData()
        
        if self.isLastRowVisible || QiscusMe.shared.email == comment.senderEmail || !self.isPresence{
            self.layoutIfNeeded()
            self.scrollToBottom()
        }
    }
    open func userTypingChanged(user: QUser, typing:Bool){
        self.processingTyping = true
        if user.isInvalidated {return}
        let beforeEmpty = self.typingUsers.count == 0
        if !typing {
            if self.typingUsers[user.email] != nil {
                self.typingUsers[user.email] = nil
            }
            if let timer = self.typingUserTimer[user.email] {
                timer.invalidate()
                self.typingUserTimer[user.email] = nil
            }
        }else{
            if self.typingUsers[user.email] == nil {
                self.typingUsers[user.email] = user
                if let timer = self.typingUserTimer[user.email] {
                    timer.invalidate()
                }
                self.typingUserTimer[user.email] = Timer.scheduledTimer(timeInterval: 7.0, target: self, selector: #selector(QConversationCollectionView.publishStopTyping(timer:)), userInfo: user, repeats: false)
            }
        }
        var tempPreviewedUser = [String]()
        var i = 0
        var changed = false
        for (key, _) in self.typingUsers.reversed() {
            if i < 3 {
                if !self.previewedTypingUsers.contains(key){
                    changed = true
                }
                tempPreviewedUser.append(key)
            }
            i += 1
        }
        self.previewedTypingUsers = tempPreviewedUser
        func scroll(){
            if self.isLastRowVisible{
                let section = self.numberOfSections - 1
                let item = self.numberOfItems(inSection: section)
                let indexPath = IndexPath(item: item, section: section)
                self.scrollToItem(at: indexPath, at: .bottom, animated: true)
            }
        }
        if (beforeEmpty && self.typingUsers.count > 0) {
            self.reloadData()
            scroll()
        }else if (!beforeEmpty && self.typingUsers.count == 0) {
            self.reloadData()
        }
        else if changed && self.typingUsers.count > 0{
            let section = self.room!.comments.count
            let indexPath = IndexPath(item: 0, section: section)
            self.reloadItems(at: [indexPath])
            scroll()
        }
        self.processingTyping = false
    }
    
    
    // MARK: - Notification Listener
    @objc private func userTyping(_ notification: Notification){
        if let userInfo = notification.userInfo {
            let user = userInfo["user"] as! QUser
            let typing = userInfo["typing"] as! Bool
            let room = userInfo["room"] as! QRoom
            if room.isInvalidated || user.isInvalidated {
                return
            }
            if let currentRoom = self.room {
                if currentRoom.isInvalidated { return }
                if currentRoom.id == room.id {
                    if !processingTyping{
                        self.userTypingChanged(user: user, typing: typing)
                    }
                }
            }
        }
    }
    @objc private func newCommentNotif(_ notification: Notification){
        if let userInfo = notification.userInfo {
            let comment = userInfo["comment"] as! QComment
            let room = userInfo["room"] as! QRoom
            if room.isInvalidated { return }
            if let currentRoom = self.room {
                if !currentRoom.isInvalidated {
                    if currentRoom.id == comment.roomId {
                        self.gotNewComment(comment: comment, room: room)
                    }
                }
            }
        }
    }
    
    @objc private func commentDeleted(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            let room = userInfo["room"] as! QRoom
            
            if let currentRoom = self.room {
                if !currentRoom.isInvalidated && !room.isInvalidated{
                    if currentRoom.id == room.id {
                        self.onDeleteComment()
                    }
                }
            }
        }
    }
    
    // MARK: - Internal Method
    @objc private func publishStopTyping(timer:Timer){
        if let user = timer.userInfo as? QUser {
            if let room = self.room {
                QiscusNotification.publish(userTyping: user, room: room, typing: false )
            }
        }
    }
    
    // MARK: public Method
    func scrollToBottom(_ animated:Bool = false){
        if self.room != nil {
            if self.numberOfSections > 0 {
                let section = self.numberOfSections - 1
                if self.numberOfItems(inSection: section) > 0 {
                    let item = self.numberOfItems(inSection: section) - 1
                    let lastIndexPath = IndexPath(row: item, section: section)
                    self.scrollToItem(at: lastIndexPath, at: .bottom, animated: animated)
                }
            }
        }
    }
}
extension QConversationCollectionView:UICollectionViewDelegate{
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
    }
    public func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
    }
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
    }
    public func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }
    public func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        
    }
    public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        
    }
    public func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        
    }
}
extension QConversationCollectionView:UICollectionViewDataSource{
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        var sectionNumber = 0
        
        if let r = self.room {
            sectionNumber = r.comments.count
        }
        if self.typingUsers.count > 0 {
            sectionNumber += 1
        }
        return sectionNumber
    }
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var itemNumber = 0
        
        if let room = self.room {
            if section < room.comments.count {
                let group = room.comments[section]
                itemNumber = group.comments.count
            }else{
                return 1
            }
        }
        
        return itemNumber
    }
}
extension QConversationCollectionView:UICollectionViewDelegateFlowLayout{
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize.zero
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize.zero
    }
}
