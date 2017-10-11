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
import ContactsUI

// MARK: - ChatCell Delegate
extension QiscusChatVC: ChatCellDelegate, ChatCellAudioDelegate{
    // MARK: ChatCellPostbackDelegate
    func getInfo(comment: QComment) {
        self.info(comment: comment)
    }
    func didForward(comment: QComment) {
        self.forward(comment: comment)
    }
    func didReply(comment: QComment) {
        self.replyData = comment
    }
    func didTapAccountLinking(withData data: JSON) {
        Qiscus.uiThread.async { autoreleasepool{
            let webView = ChatPreviewDocVC()
            webView.accountLinking = true
            webView.accountData = data
            
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            self.navigationController?.pushViewController(webView, animated: true)
        }}
    }
    func didTapPostbackButton(withData data: JSON) {
        if Qiscus.sharedInstance.connected{
            let postbackType = data["type"]
            let payload = data["payload"]
            switch postbackType {
            case "link":
                let urlString = payload["url"].stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                let urlArray = urlString.components(separatedBy: "/")
                func openInBrowser(){
                    if let url = URL(string: urlString) {
                        UIApplication.shared.openURL(url)
                    }
                }
                
                if urlArray.count > 2 {
                    print("host = \(urlArray[2])")
                    if urlArray[2].lowercased().contains("instagram.com") {
                        print("arrayCount: \(urlArray.count)")
                        var instagram = "instagram://app"
                        if urlArray.count == 4 || (urlArray.count == 5 && urlArray[4] == ""){
                            let usernameIG = urlArray[3]
                            instagram = "instagram://user?username=\(usernameIG)"
                        }
                        if let instagramURL =  URL(string: instagram) {
                            if UIApplication.shared.canOpenURL(instagramURL) {
                                UIApplication.shared.openURL(instagramURL)
                            }else{
                                openInBrowser()
                            }
                        }
                    }else{
                        openInBrowser()
                    }
                }else{
                    openInBrowser()
                }
                
                
                break
            default:
                let text = data["label"].stringValue
                let type = "button_postback_response"
                
                if let room = self.chatRoom {
                    let newComment = room.newComment(text: text)
                    room.post(comment: newComment, type: type, payload: payload)
                }
                break
            }
            
        }else{
            Qiscus.uiThread.async { autoreleasepool{
                self.showNoConnectionToast()
            }}
        }
    }
    func didTouchLink(onCell cell: QChatCell) {
        if let comment = cell.comment {
            if comment.type == .reply{
                let replyData = JSON(parseJSON: comment.data)
                let commentId = replyData["replied_comment_id"].intValue
                if let targetComment = QComment.comment(withId: commentId){
                    if let indexPath = self.chatRoom!.getIndexPath(ofComment: targetComment){
                        if let selectIndex = self.selectedCellIndex {
                            if let selectedCell = self.collectionView.cellForItem(at: selectIndex){
                                selectedCell.backgroundColor = UIColor.clear
                            }
                        }
                        if let selectedCell = self.collectionView.cellForItem(at: indexPath){
                            selectedCell.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.15)
                        }
                        self.selectedCellIndex = indexPath
                        
                        self.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
                    }
                }
            }
        }
    }
    // MARK: ChatCellDelegate
    func didShare(comment: QComment) {
        switch comment.type {
        case .image, .video, .audio:
            if let file = comment.file {
                if QFileManager.isFileExist(inLocalPath: file.localPath){
                    var items:[Any] = [Any]()
                    switch file.type {
                    case .image:
                        let image = UIImage(contentsOfFile: file.localPath)!
                        items.append(image)
                        break
                    case.video:
                        let videoLink = NSURL(fileURLWithPath: file.localPath)
                        items.append(videoLink)
                        break
                    case.audio:
                        let audioLink = NSURL(fileURLWithPath: file.localPath)
                        items.append(audioLink)
                        break
                    default:
                        break
                    }
                    let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
                    
                    activityViewController.popoverPresentationController?.sourceView = self.view
                    self.present(activityViewController, animated: true, completion: nil)
                    
                }
            }
            break
        case .text:
            let activityViewController = UIActivityViewController(activityItems: [comment.text], applicationActivities: nil)
            
            activityViewController.popoverPresentationController?.sourceView = self.view
            self.present(activityViewController, animated: true, completion: nil)
            break
        default:
            
            break
        }
    }
    func didChangeSize(onCell cell:QChatCell){
        
    }
    func didTapCell(withData data:QComment){
        if (data.type == .image || data.type == .video) && data.file != nil{
            self.galleryItems = [QiscusGalleryItem]()
            let currentFile = data.file!
            var totalIndex = 0
            var currentIndex = 0
            for dataGroup in self.chatRoom!.comments {
                for targetData in dataGroup.comments{
                    if let file = targetData.file {
                        if QFileManager.isFileExist(inLocalPath: file.localPath){
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
                            DispatchQueue.main.async { autoreleasepool{
                                if let targetCell = activeCell as? QCellAudioRight{
                                    targetCell.isPlaying = false
                                }
                                if let targetCell = activeCell as? QCellAudioLeft{
                                    targetCell.isPlaying = false
                                }
                                activeCell.comment?.updatePlaying(playing: false)
                                self.didChangeData(onCell: activeCell, withData: activeCell.comment!, dataTypeChanged: "isPlaying")
                            }}
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
//        audioPlayer?.prepareToPlay()
//        audioPlayer?.play()
//        audioTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(audioTimerFired(_:)), userInfo: nil, repeats: true)
//        if let targetCell = cell as? QCellAudio {
//            targetCell.isPlaying = false
//        }
//        cell.comment?.updatePlaying(playing: false)
        if let targetCell = cell as? QCellAudioLeft{
            targetCell.isPlaying = false
        }
        if let targetCell = cell as? QCellAudioRight{
            targetCell.isPlaying = false
        }
    }
    func didChangeData(onCell cell:QCellAudio , withData comment:QComment, dataTypeChanged:String){

    }
    func didTapSaveContact(withData data: QComment) {
        let payloadString = data.data
        let payload = JSON(parseJSON: payloadString)
        let contactValue = payload["value"].stringValue
        
        let con = CNMutableContact()
        con.givenName = payload["name"].stringValue
        if contactValue.contains("@"){
            let email = CNLabeledValue(label: CNLabelHome, value: contactValue as NSString)
            con.emailAddresses.append(email)
        }else{
            let phone = CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: contactValue))
            con.phoneNumbers.append(phone)
        }
        
        let unkvc = CNContactViewController(forUnknownContact: con)
        unkvc.message = "Kiwari contact"
        unkvc.contactStore = CNContactStore()
        unkvc.delegate = self
        unkvc.allowsActions = false
        self.navigationController?.pushViewController(unkvc, animated: true)
    }
    
}
extension QiscusChatVC: CNContactViewControllerDelegate{

}

