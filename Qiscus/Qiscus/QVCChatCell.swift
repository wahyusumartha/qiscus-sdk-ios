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
extension QiscusChatVC: ChatCellDelegate, ChatCellAudioDelegate, ChatCellPostbackDelegate{
    // MARK: ChatCellPostbackDelegate
    func didTapPostbackButton(withData data: JSON) {
        Qiscus.logicThread.async {
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
    func didTapCell(withData data:QiscusCommentPresenter){
        if data.commentType == .image || data.commentType == .video{
            self.galleryItems = [QiscusGalleryItem]()
            var totalIndex = 0
            var currentIndex = 0
            for dataGroup in self.comments {
                for targetData in dataGroup{
                    if targetData.commentType == .image || targetData.commentType == .video {
                        if targetData.localFileExist{
                            if data.localURL == targetData.localURL{
                                currentIndex = totalIndex
                            }
                            if targetData.commentType == .image{
                                let urlString = "file://\(targetData.localURL!)"
                                if let url = URL(string: urlString) {
                                    if let imageData = try? Data(contentsOf: url) {
                                        if targetData.fileType == "gif"{
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
                                    }
                                }
                            }else if targetData.commentType == .video{
                                let urlString = "file://\(targetData.localURL!)"
                                let urlThumb = "file://\(targetData.localThumbURL!)"
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
            QiscusChatVC.sharedInstance.presentImageGallery(gallery)
        }
    }
    
    // MARK: ChatCellAudioDelegate
    func didTapPlayButton(_ button: UIButton, onCell cell: QCellAudio) {
        let path = cell.data.localURL!
        if let url = URL(string: path) {
            if audioPlayer != nil {
                if audioPlayer!.isPlaying {
                    if let activeCell = activeAudioCell{
                        activeCell.data.audioIsPlaying = false
                        self.didChangeData(onCell: activeCell, withData: activeCell.data)
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
            audioPlayer?.currentTime = Double(cell.data.currentTimeSlider)
            
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
    func didTapPauseButton(_ button: UIButton, onCell cell: QCellAudio){
        audioPlayer?.pause()
        stopTimer()
        updateAudioDisplay()
    }
    func didTapDownloadButton(_ button: UIButton, onCell cell: QCellAudio){
        cell.displayAudioDownloading()
        self.commentClient.downloadMedia(data: cell.data, isAudioFile: true)
    }
    func didStartSeekTimeSlider(_ slider: UISlider, onCell cell: QCellAudio){
        if audioTimer != nil {
            stopTimer()
        }
    }
    func didEndSeekTimeSlider(_ slider: UISlider, onCell cell: QCellAudio){
        audioPlayer?.stop()
        let currentTime = cell.data.currentTimeSlider
        audioPlayer?.currentTime = Double(currentTime)
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
        audioTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(audioTimerFired(_:)), userInfo: nil, repeats: true)
    }
    func didChangeData(onCell cell: QCellAudio, withData data: QiscusCommentPresenter) {
        Qiscus.logicThread.async {
            if let indexPath = data.commentIndexPath{
                if indexPath.section < self.comments.count {
                    if indexPath.row < self.comments[indexPath.section].count{
                        self.comments[indexPath.section][indexPath.row] = data
                    }
                }
            }
        }
    }
}

