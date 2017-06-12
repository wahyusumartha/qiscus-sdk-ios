//
//  QVCDataPresenter.swift
//  Example
//
//  Created by Ahmad Athaullah on 5/16/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

// MARK: - QiscusDataPresenterDelegate
extension QiscusChatVC: QiscusDataPresenterDelegate{
    public func dataPresenter(gotNewData presenter: QiscusCommentPresenter, inRoom: QiscusRoom, realtime: Bool) {
        DispatchQueue.global().async {
            var indexPath = IndexPath()
            if self.comments.count == 0 {
                indexPath = IndexPath(row: 0, section: 0)
                var newGroup = [QiscusCommentPresenter]()
                presenter.cellPos = .single
                presenter.balloonImage = presenter.getBalloonImage()
                presenter.commentIndexPath = IndexPath(row: 0, section: 0)
                newGroup.append(presenter)
                self.comments.append(newGroup)
                Qiscus.uiThread.async {
                    self.welcomeView.isHidden = true
                    self.collectionView.reloadData()
                    if self.isLastRowVisible || presenter.userEmail == QiscusMe.sharedInstance.email {
                        self.scrollToBottom(true)
                    }
                }
                if presenter.toUpload {
                    self.dataPresenter.uploadData(fromPresenter: presenter)
                }
            }
            else{
                let lastComment = self.comments.last!.last!
                
                if lastComment.commentIndexPath == nil {
                    let lastSection = self.comments.count - 1
                    let lastRow = self.comments[lastSection].count - 1
                    lastComment.commentIndexPath = IndexPath(row: lastRow, section: lastSection)
                }
                if lastComment.userEmail == presenter.userEmail && lastComment.commentDate == presenter.commentDate{
                    indexPath = IndexPath(row: self.comments[self.comments.count - 1].count , section: self.comments.count - 1)
                    presenter.cellPos = .last
                    presenter.balloonImage = presenter.getBalloonImage()
                    presenter.commentIndexPath = indexPath
                    if lastComment.commentIndexPath?.row == 0 {
                        lastComment.cellPos = .first
                    }else{
                        lastComment.cellPos = .middle
                    }
                    lastComment.balloonImage = lastComment.getBalloonImage()
                    
                    self.comments[lastComment.commentIndexPath!.section][lastComment.commentIndexPath!.row] = lastComment
                    self.comments[indexPath.section].insert(presenter, at: indexPath.row)
                    if self.isPresence {
                        Qiscus.uiThread.sync {
                            self.collectionView.performBatchUpdates({
                                self.collectionView.insertItems(at: [indexPath])
                            }, completion: { (success) in
                                if success {
                                    self.collectionView.reloadItems(at: [lastComment.commentIndexPath!])
                                }
                            })
                            
                            if self.isLastRowVisible || presenter.userEmail == QiscusMe.sharedInstance.email {
                                self.scrollToBottom(true)
                            }
                        }
                    }else{
                        self.collectionView.reloadData()
                    }
                }
                else{
                    indexPath = IndexPath(row: 0, section: self.comments.count)
                    var newGroup = [QiscusCommentPresenter]()
                    presenter.cellPos = .single
                    presenter.balloonImage = presenter.getBalloonImage()
                    presenter.commentIndexPath = indexPath
                    newGroup.append(presenter)
                    
                    self.comments.insert(newGroup, at: indexPath.section)
                    if self.isPresence {
                        Qiscus.uiThread.sync {
                            self.collectionView.performBatchUpdates({
                                let indexSet = IndexSet(integer: indexPath.section)
                                self.collectionView.insertSections(indexSet)
                            }, completion: nil)
                            
                            if self.isLastRowVisible || presenter.userEmail == QiscusMe.sharedInstance.email {
                                self.scrollToBottom(true)
                            }
                        }
                    }else{
                        self.collectionView.reloadData()
                    }
                }
                if presenter.toUpload {
                    self.dataPresenter.uploadData(fromPresenter: presenter)
                }
            }
            if presenter.commentId > 0 {
                DispatchQueue.global().async {
                    QiscusCommentClient.sharedInstance.publishMessageStatus(onComment: presenter.commentId, roomId: inRoom.roomId, status: .read, withCompletion: {_ in })
                }
            }
        }
    }
    
    public func syncRoom(){
        if !self.roomSynced {
            if let roomToSync = self.room {
                self.roomSynced = true
                QiscusCommentClient.shared.syncRoom(withID: roomToSync.roomId)
            }
        }
    }
    public func dataPresenter(didFinishLoad comments: [[QiscusCommentPresenter]], inRoom: QiscusRoom) {
        self.firstLoad = false
        self.room = inRoom
        var needScrollToBottom = true
        if self.comments.count > 0 {
            needScrollToBottom = false
        }
        DispatchQueue.global().async {
            if !inRoom.isGroup{
                self.users = [String]()
                for user in inRoom.participants {
                    if user.participantEmail != QiscusMe.sharedInstance.email {
                        self.users?.append(user.participantEmail)
                    }
                }
            }
        }
        if comments.count > 0 {
            self.comments = comments
            Qiscus.uiThread.async {
                self.collectionView.reloadData()
                if needScrollToBottom {
                    self.scrollToBottom()
                }
            }
            let commentId = comments.last!.last!.commentId
            let roomId = inRoom.roomId
            if Qiscus.shared.chatViews[inRoom.roomId] == nil {
                Qiscus.shared.chatViews[inRoom.roomId] = self
            }
            DispatchQueue.global().async {
                QiscusCommentClient.sharedInstance.publishMessageStatus(onComment: commentId, roomId: roomId, status: .read, withCompletion: {_ in })
            }
        }
        if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate{
            roomDelegate.didFinishLoadRoom(onRoom: inRoom)
        }
        self.dismissLoading()
    }
    public func dataPresenter(didFinishLoadMore comments: [[QiscusCommentPresenter]], inRoom: QiscusRoom) {
        DispatchQueue.global().async {
            if self.room != nil{
                if inRoom.hasLoadMore != self.room!.hasLoadMore{
                    self.room!.hasLoadMore = inRoom.hasLoadMore
                }
                if self.comments.count > 0 {
                    if comments.count > 0 {
                        let lastGroup = comments.last!
                        let lastData = lastGroup.last!
                        var mergeLastGroup = false
                        let firstCurrentComment = self.comments.first!.first!
                        
                        if lastData.commentDate == firstCurrentComment.commentDate && lastData.userEmail == firstCurrentComment.userEmail{
                            mergeLastGroup = true
                            if self.comments[0].count == 1 {
                                firstCurrentComment.cellPos = .last
                            }else{
                                firstCurrentComment.cellPos = .middle
                            }
                        }
                        var section = 0
                        var reloadIndexPath = [IndexPath]()
                        for currentDataGroup in self.comments{
                            var row = 0
                            var sectionAdd = comments.count
                            if mergeLastGroup{
                                sectionAdd -= 1
                            }
                            let rowAdd = comments.last!.count
                            for currentData in currentDataGroup{
                                if section == 0 && mergeLastGroup{
                                    currentData.commentIndexPath = IndexPath(row: row + rowAdd, section: section + sectionAdd)
                                    if row == 0{
                                        if currentDataGroup.count == 1 {
                                            currentData.cellPos = .last
                                        }else{
                                            currentData.cellPos = .middle
                                        }
                                        currentData.balloonImage = currentData.getBalloonImage()
                                        reloadIndexPath.append(currentData.commentIndexPath!)
                                    }
                                }else{
                                    currentData.commentIndexPath = IndexPath(row: row, section: (section + sectionAdd))
                                }
                                self.comments[section][row] = currentData
                                row += 1
                            }
                            section += 1
                        }
                        Qiscus.uiThread.async {
                            self.collectionView.performBatchUpdates({
                                var i = 0
                                for newGroupComment in comments{
                                    if i == (comments.count - 1) && mergeLastGroup {
                                        var indexPaths = [IndexPath]()
                                        var j = 0
                                        for newComment in newGroupComment{
                                            self.comments[i].insert(newComment, at: j)
                                            indexPaths.append(IndexPath(row: j, section: i))
                                            j += 1
                                        }
                                        self.collectionView.insertItems(at: indexPaths)
                                    }else{
                                        self.comments.insert(newGroupComment, at: i)
                                        var indexPaths = [IndexPath]()
                                        for j in 0..<newGroupComment.count{
                                            indexPaths.append(IndexPath(row: j, section: i))
                                        }
                                        self.collectionView.insertSections(IndexSet(integer: i))
                                        self.collectionView.insertItems(at: indexPaths)
                                    }
                                    i += 1
                                }
                            }, completion: { _ in
                                self.loadMoreControl.endRefreshing()
                                if reloadIndexPath.count > 0 {
                                    self.collectionView.reloadItems(at: reloadIndexPath)
                                }
                                if !inRoom.hasLoadMore{
                                    Qiscus.uiThread.async {
                                        self.loadMoreControl.removeFromSuperview()
                                    }
                                }
                            })
                        }
                    }
                    else{
                        Qiscus.uiThread.async {
                            self.loadMoreControl.endRefreshing()
                            self.loadMoreControl.removeFromSuperview()
                        }
                    }
                }else{
                    self.comments = comments
                    Qiscus.uiThread.async {
                        self.welcomeView.isHidden = true
                        self.collectionView.reloadData()
                        self.scrollToBottom()
                        self.loadMoreControl.endRefreshing()
                        if !inRoom.hasLoadMore{
                            self.loadMoreControl.removeFromSuperview()
                        }
                    }
                }
            }
        }
        
    }
    public func dataPresenter(didFailLoadMore inRoom: QiscusRoom) {
        Qiscus.uiThread.async {
            if self.loadMoreControl.isRefreshing{
                self.loadMoreControl.endRefreshing()
            }
            QToasterSwift.toast(target: self, text: "Fail to load more coometn, try again later", backgroundColor: UIColor(red: 0.9, green: 0,blue: 0,alpha: 0.8), textColor: UIColor.white)
        }
    }
    public func dataPresenter(willResendData data: QiscusCommentPresenter) {
        DispatchQueue.global().async {
            if let indexPath = data.commentIndexPath{
                if indexPath.section < self.comments.count{
                    if indexPath.row < self.comments[indexPath.section].count{
                        self.comments[indexPath.section][indexPath.row] = data
                        Qiscus.uiThread.async {
                            if let cell = self.collectionView.cellForItem(at: indexPath) as? QChatCell{
                                cell.updateStatus(toStatus: data.commentStatus)
                            }
                        }
                    }
                }
            }
        }
    }
    public func dataPresenter(dataDeleted data: QiscusCommentPresenter) {
        DispatchQueue.global().async {
            if let indexPath = data.commentIndexPath{
                if indexPath.section < self.comments.count{
                    if indexPath.row < self.comments[indexPath.section].count{
                        let deletedComment = self.comments[indexPath.section][indexPath.row].comment
                        if self.comments[indexPath.section].count == 1{
                            let indexSet = IndexSet(integer: indexPath.section)
                            Qiscus.uiThread.async {
                                self.collectionView.performBatchUpdates({
                                    self.comments.remove(at: indexPath.section)
                                    self.collectionView.deleteSections(indexSet)
                                }, completion: { _ in
                                    DispatchQueue.global().async {
                                        deletedComment?.deleteComment()
                                        var section = 0
                                        for dataGroup in self.comments{
                                            var row = 0
                                            for data in dataGroup{
                                                let newIndexPath = IndexPath(row: row, section: section)
                                                data.commentIndexPath = newIndexPath
                                                self.comments[section][row] = data
                                                row += 1
                                            }
                                            section += 1
                                        }
                                    }
                                })
                            }
                        }else{
                            Qiscus.uiThread.async {
                                self.collectionView.performBatchUpdates({
                                    self.comments[indexPath.section].remove(at: indexPath.row)
                                    self.collectionView.deleteItems(at: [indexPath])
                                }, completion: { _ in
                                    deletedComment?.deleteComment()
                                    DispatchQueue.global().async {
                                        var i = 0
                                        for data in self.comments[indexPath.section]{
                                            data.commentIndexPath = IndexPath(row: i, section: indexPath.section)
                                            if i == 0 && i == (self.comments[indexPath.section].count - 1){
                                                data.cellPos = .single
                                            }else if i == 0 {
                                                data.cellPos = .first
                                            }else if i == (self.comments[indexPath.section].count - 1){
                                                data.cellPos = .last
                                            }else{
                                                data.cellPos = .middle
                                            }
                                            data.balloonImage = data.getBalloonImage()
                                            self.comments[indexPath.section][i] = data
                                            i += 1
                                        }
                                        let indexSet = IndexSet(integer: indexPath.section)
                                        Qiscus.uiThread.async {
                                            self.collectionView.reloadSections(indexSet)
                                        }
                                    }
                                })
                            }
                        }
                    }
                }
            }
            
        }
    }
    public func dataPresenter(didChangeContent data: QiscusCommentPresenter, inRoom: QiscusRoom) {
        DispatchQueue.global().async {
            if self.room?.roomId == inRoom.roomId{
                if let indexPath = data.commentIndexPath{
                    if indexPath.section < self.comments.count{
                        if indexPath.row < self.comments[indexPath.section].count {
                            self.comments[indexPath.section][indexPath.row] = data
                            
                            if data.isDownloading {
                                Qiscus.uiThread.async {
                                    let percentage = Int(data.downloadProgress * 100)
                                    if let cell = self.collectionView.cellForItem(at: indexPath) as? QChatCell{
                                        cell.downloadingMedia(withPercentage: percentage)
                                    }
                                }
                            }else{
                                Qiscus.uiThread.async {
                                    self.comments[indexPath.section][indexPath.row] = data
                                    self.collectionView.reloadItems(at: [indexPath])
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    public func dataPresenter(didChangeStatusFrom commentId: Int, toStatus: QiscusCommentStatus, topicId: Int){
        DispatchQueue.global().async {
            if let chatRoom = self.room {
                if topicId == chatRoom.roomLastCommentTopicId{
                    var indexToReload = [IndexPath]()
                    
                    for dataGroup in self.comments {
                        for data in dataGroup {
                            if data.commentId <= commentId && data.commentStatus.rawValue < toStatus.rawValue {
                                if let indexPath = data.commentIndexPath {
                                    data.commentStatus = toStatus
                                    self.comments[indexPath.section][indexPath.row] = data
                                    indexToReload.append(indexPath)
                                }
                            }
                        }
                    }
                    if indexToReload.count > 0 {
                        Qiscus.uiThread.async {
                            self.collectionView.reloadItems(at: indexToReload)
                        }
                    }
                }
            }
        }
    }
    public func dataPresenter(didChangeCellSize presenter:QiscusCommentPresenter, inRoom: QiscusRoom){
        DispatchQueue.global().async {
            if let indexPath = presenter.commentIndexPath{
                if self.comments.count > indexPath.section{
                    if self.comments[indexPath.section].count > indexPath.row{
                        self.comments[indexPath.section][indexPath.row] = presenter
                        Qiscus.uiThread.async {
                            self.collectionView.reloadItems(at: [indexPath])
                        }
                    }
                }
            }
        }
    }
    public func dataPresenter(didChangeUser user: QiscusUser, onUserWithEmail email: String) {
       
    }
    public func dataPresenter(didChangeRoom room: QiscusRoom, onRoomWithId roomId: Int) {
        self.room = room
    }
    public func dataPresenter(didFailLoad error: String) {
        self.dismissLoading()
        QToasterSwift.toast(target: self, text: error, backgroundColor: UIColor(red: 0.9, green: 0,blue: 0,alpha: 0.8), textColor: UIColor.white)
        if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate{
            roomDelegate.didFailLoadRoom(withError: error)
        }
    }
}
