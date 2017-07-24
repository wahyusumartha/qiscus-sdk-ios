//
//  QVCChatCell.swift
//  Example
//
//  Created by Ahmad Athaullah on 5/16/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
import ImageViewer
import AVFoundation
import SwiftyJSON

// MARK: - ChatCell Delegate
extension QiscusChatVC: ChatCellDelegate, ChatCellAudioDelegate{
    // MARK: ChatCellPostbackDelegate
    func didTapAccountLinking(withData data: JSON) {
        Qiscus.uiThread.async {
            let webView = ChatPreviewDocVC()
            webView.accountLinking = true
            webView.accountData = data
            
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            self.navigationController?.pushViewController(webView, animated: true)
        }
    }
    func didTapPostbackButton(withData data: JSON) {
        DispatchQueue.global().async {
            if Qiscus.sharedInstance.connected{
                var indexPath = IndexPath(row: 0, section: 0)
                let text = data["label"].stringValue
                let payload = data["payload"]
                let type = "button_postback_response"
                if self.comments.count > 0 {
                    let lastComment = self.comments.last!.last!
                    if lastComment.userEmail == QiscusMe.sharedInstance.email && lastComment.isToday {
                        indexPath.section = self.comments.count - 1
                        indexPath.row = self.comments[indexPath.section].count
                    }else{
                        indexPath.section = self.comments.count
                        indexPath.row = 0
                    }
                }
                if let chatRoom = self.room {
                    self.commentClient.postMessage(message: text, topicId: chatRoom.roomLastCommentTopicId, linkData: self.linkData, indexPath: indexPath, payload: payload, type: type)
                }
                self.scrollToBottom()
            }else{
                Qiscus.uiThread.async {
                    self.showNoConnectionToast()
                }
            }
        }
    }
    func didTouchLink(onCell cell: QChatCell) {
        if let comment = cell.comment {
            if comment.type == .reply{
                let replyData = JSON(parseJSON: comment.data)
                let commentId = replyData["replied_comment_id"].intValue
                var found = false
                var indexPath:IndexPath? = nil
                var section = 0
                for commentGroup in self.chatRoom!.comments{
                    var row = 0
                    for commentTarget in commentGroup.comments {
                        if commentTarget.id == commentId {
                            found = true
                            indexPath = IndexPath(item: row, section: section)
                            break
                        }
                                row += 1
                    }
                    if found {
                        break
                    }else{
                        section += 1
                    }
                }
                if found {
                    if let selectIndex = self.selectedCellIndex {
                        if let selectedCell = self.collectionView.cellForItem(at: selectIndex){
                            selectedCell.backgroundColor = UIColor.clear
                        }
                    }
                    if let selectedCell = self.collectionView.cellForItem(at: indexPath!){
                        selectedCell.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.35)
                    }
                    self.selectedCellIndex = indexPath
                    
                    self.collectionView.scrollToItem(at: indexPath!, at: .top, animated: true)
                    
                }
            }
        }
    }
    // MARK: ChatCellDelegate
    func didChangeSize(onCell cell:QChatCell){
        if let indexPath = cell.data.commentIndexPath {
            if indexPath.section < self.comments.count{
                if indexPath.row < self.comments[indexPath.section].count{
                    collectionView.reloadItems(at: [indexPath])
                }
            }
        }
    }
    func didTapCell(withData data:QComment){
        if (data.type == .image || data.type == .video) && data.file != nil{
            self.galleryItems = [QiscusGalleryItem]()
            let currentFile = data.file!
            var totalIndex = 0
            var currentIndex = 0
            for dataGroup in self.chatRoom!.comments {
                for targetData in dataGroup.comments{
                    if targetData.type == .image || targetData.type == .video {
                        if let file = targetData.file {
                            if QiscusHelper.isFileExist(inLocalPath: file.localPath){
                                if file.localPath == currentFile.localPath {
                                    currentIndex = totalIndex
                                }
                                let urlString = "file://\(file.localPath)"
                                if let url = URL(string: urlString){
                                    if let imageData = try? Data(contentsOf: url) {
                                        if file.type == .image {
                                            if file.ext == "gif"{
                                                if let image = UIImage.gif(data: imageData){
                                                    let item = QiscusGalleryItem()
                                                    item.image = image
                                                    item.isVideo = false
                                                    self.galleryItems.append(item)
                                                    totalIndex += 1
                                                }
                                            }else{
                                                if let image = UIImage(data: imageData) {
                                                    let item = QiscusGalleryItem()
                                                    item.image = image
                                                    item.isVideo = false
                                                    self.galleryItems.append(item)
                                                    totalIndex += 1
                                                }
                                            }
                                        }else if file.type == .video{
                                            let urlString = "file://\(file.localPath)"
                                            let urlThumb = "file://\(file.localThumbPath)"
                                            if let url = URL(string: urlThumb) {
                                                if let data = try? Data(contentsOf: url) {
                                                    if let image = UIImage(data: data){
                                                        let item = QiscusGalleryItem()
                                                        item.image = image
                                                        item.isVideo = true
                                                        item.url = urlString
                                                        self.galleryItems.append(item)
                                                        totalIndex += 1
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            let closeButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 20, height: 20)))
            closeButton.setImage(Qiscus.image(named: "close")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
            closeButton.tintColor = UIColor.white
            closeButton.imageView?.contentMode = .scaleAspectFit
            
            let seeAllButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 20, height: 20)))
            seeAllButton.setTitle("", for: UIControlState())
            seeAllButton.setImage(Qiscus.image(named: "viewmode")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
            seeAllButton.tintColor = UIColor.white
            seeAllButton.imageView?.contentMode = .scaleAspectFit
            
            let gallery = GalleryViewController(startIndex: currentIndex, itemsDatasource: self, displacedViewsDatasource: nil, configuration: self.galleryConfiguration())
            self.presentImageGallery(gallery)
        }
    }
    
    // MARK: ChatCellAudioDelegate
    func didTapPlayButton(_ button: UIButton, onCell cell: QCellAudio) {
        if let file = cell.comment?.file {
            if let url = URL(string: file.localPath) {
                if audioPlayer != nil {
                    if audioPlayer!.isPlaying {
                        if let activeCell = activeAudioCell{
                            DispatchQueue.main.async {
                                if let targetCell = activeCell as? QCellAudioRight{
                                    targetCell.isPlaying = false
                                }
                                if let targetCell = activeCell as? QCellAudioLeft{
                                    targetCell.isPlaying = false
                                }
                                activeCell.comment!.updateAudioIsPlaying(playing: false)
                                self.didChangeData(onCell: activeCell, withData: activeCell.comment!, dataTypeChanged: "isPlaying")
                            }
                        }
                        audioPlayer?.stop()
                        stopTimer()
                        updateAudioDisplay()
                    }
                }
                activeAudioCell = cell
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: url)
                }
                catch let error as NSError {
                    Qiscus.printLog(text: error.localizedDescription)
                }
                
                audioPlayer?.delegate = self
                audioPlayer?.currentTime = Double(cell.comment!.currentTimeSlider)
                
                do {
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                    //Qiscus.printLog(text: "AVAudioSession Category Playback OK")
                    do {
                        try AVAudioSession.sharedInstance().setActive(true)
                        //Qiscus.printLog(text: "AVAudioSession is Active")
                        audioPlayer?.prepareToPlay()
                        audioPlayer?.play()
                        
                        audioTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(audioTimerFired(_:)), userInfo: nil, repeats: true)
                        
                    } catch _ as NSError {
                        Qiscus.printLog(text: "Audio player error")
                    }
                } catch _ as NSError {
                    Qiscus.printLog(text: "Audio player error")
                }
            }
        }
    }
    func didTapPauseButton(_ button: UIButton, onCell cell: QCellAudio){
        audioPlayer?.pause()
        stopTimer()
        updateAudioDisplay()
    }
    func didTapDownloadButton(_ button: UIButton, onCell cell: QCellAudio){
        cell.displayAudioDownloading()
        self.chatRoom!.downloadMedia(onComment: cell.comment!, isAudioFile: true)
    }
    func didStartSeekTimeSlider(_ slider: UISlider, onCell cell: QCellAudio){
        if audioTimer != nil {
            stopTimer()
        }
    }
    func didEndSeekTimeSlider(_ slider: UISlider, onCell cell: QCellAudio){
        audioPlayer?.stop()
        
        let currentTime = cell.comment!.currentTimeSlider
        audioPlayer?.currentTime = Double(currentTime)
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
        audioTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(audioTimerFired(_:)), userInfo: nil, repeats: true)
        
        cell.comment?.updateAudioIsPlaying(playing: false)
        if let targetCell = cell as? QCellAudioLeft{
            targetCell.isPlaying = false
        }
        if let targetCell = cell as? QCellAudioRight{
            targetCell.isPlaying = false
        }
    }
    func didChangeData(onCell cell:QCellAudio , withData comment:QComment, dataTypeChanged:String){
//        DispatchQueue.global().async {
//            if let indexPath = data.commentIndexPath{
//                if indexPath.section < self.comments.count {
//                    if indexPath.row < self.comments[indexPath.section].count{
//                        self.comments[indexPath.section][indexPath.row] = data
//                    }
//                }
//            }
//        }
    }
}

