//
//  QVCAction.swift
//  Example
//
//  Created by Ahmad Athaullah on 5/16/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices
import SwiftyJSON

extension QiscusChatVC {
    @objc public func showLoading(_ text:String = "Loading"){
        self.showQiscusLoading(withText: text, isBlocking: true)
    }
    @objc public func dismissLoading(){
        self.dismissQiscusLoading()
    }
    @objc public func unlockChat(){
        self.archievedNotifTop.constant = 65
        UIView.animate(withDuration: 0.6, animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.archievedNotifView.isHidden = true
        })
    }
    @objc public func lockChat(){
        self.archievedNotifView.isHidden = false
        self.archievedNotifTop.constant = 0
        UIView.animate(withDuration: 0.6, animations: {
            self.view.layoutIfNeeded()
        }
        )
    }
    func confirmUnlockChat(){
        self.unlockAction()
    }
    func showAlert(alert:UIAlertController){
        self.present(alert, animated: true, completion: nil)
    }
    func showAttachmentMenu(){
        let actionSheetController = UIAlertController(title: "Share Files", message: "Share your photo, video, sound, or document by choosing the source", preferredStyle: .actionSheet)
        
        let cancelActionButton = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)
        
        let cameraActionButton = UIAlertAction(title: "Camera", style: .default) { action -> Void in
            self.uploadFromCamera()
        }
        
        actionSheetController.addAction(cameraActionButton)
        
        let galeryActionButton = UIAlertAction(title: "Galery", style: .default) { action -> Void in
            self.uploadImage()
        }
        actionSheetController.addAction(galeryActionButton)
        
        if Qiscus.sharedInstance.iCloudUpload {
            let iCloudActionButton = UIAlertAction(title: "iCloud", style: .default) { action -> Void in
                self.iCloudOpen()
            }
            actionSheetController.addAction(iCloudActionButton)
        }
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
    func getLinkPreview(url:String){
//        var urlToCheck = url.lowercased()
//        if !urlToCheck.contains("http"){
//            urlToCheck = "http://\(url.lowercased())"
//        }
//        commentClient.getLinkMetadata(url: urlToCheck, withCompletion: {linkData in
//            Qiscus.uiThread.async {
//                self.linkImage.loadAsync(linkData.linkImageURL, placeholderImage: Qiscus.image(named: "link"))
//                self.linkDescription.text = linkData.linkDescription
//                self.linkTitle.text = linkData.linkTitle
//                self.linkData = linkData
//                self.linkPreviewTopMargin.constant = -65
//                UIView.animate(withDuration: 0.65, animations: {
//                    self.view.layoutIfNeeded()
//                }, completion: nil)
//            }
//        }, withFailCompletion: {
//            self.showLink = false
//        })
    }
    func hideLinkContainer(){
        Qiscus.uiThread.async {
            self.linkPreviewTopMargin.constant = 0
            UIView.animate(withDuration: 0.65, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    func startTypingIndicator(withUser user:String){
        self.typingIndicatorUser = user
        self.isTypingOn = true
        let typingText = "\(user) is typing ..."
        self.subtitleLabel.text = typingText
        if self.remoteTypingTimer != nil {
            if self.remoteTypingTimer!.isValid {
                self.remoteTypingTimer?.invalidate()
            }
        }
        //self.remoteTypingTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(self.stopTypingIndicator), userInfo: nil, repeats: false)
    }
    
    func stopTypingIndicator(){
        self.typingIndicatorUser = ""
        self.isTypingOn = false
        if self.remoteTypingTimer != nil {
            self.remoteTypingTimer?.invalidate()
            self.remoteTypingTimer = nil
        }
        self.loadSubtitle()
    }
    
    func showNoConnectionToast(){
        QToasterSwift.toast(target: self, text: QiscusTextConfiguration.sharedInstance.noConnectionText, backgroundColor: UIColor(red: 0.9, green: 0,blue: 0,alpha: 0.8), textColor: UIColor.white)
    }
    // MARK: - Overriding back action
    public func setBackButton(withAction action:@escaping (()->Void)){
        self.backAction = action
    }
    func publishRead(){
        /*
        DispatchQueue.global().async {
            if self.isPresence{
                if self.comments.count > 0 {
                    let lastComment = self.comments.last!.last!.comment!
                    if let lastComentInTopic = QiscusComment.getLastSentComent(inRoom: lastComment.roomId){
                        if let participant = QiscusParticipant.getParticipant(withEmail: QiscusConfig.sharedInstance.USER_EMAIL, roomId: lastComentInTopic.roomId){
                            if participant.lastReadCommentId < lastComentInTopic.commentId{
                                Qiscus.printLog(text: "publishRead onCommentId: \(lastComentInTopic.commentId)")
                                self.commentClient.publishMessageStatus(onComment: lastComentInTopic.commentId, roomId: lastComentInTopic.roomId, status: .read, withCompletion: {
                                    lastComentInTopic.updateCommentStatus(.read, email: QiscusConfig.sharedInstance.USER_EMAIL)
                                })
                            }
                        }
                    }
                }
            }
        }
         */
    }
    func setTitle(title:String = "", withSubtitle:String? = nil){
        QiscusUIConfiguration.sharedInstance.copyright.chatTitle = title
        if withSubtitle != nil {
            QiscusUIConfiguration.sharedInstance.copyright.chatSubtitle = withSubtitle!
        }
        self.loadTitle()
    }
    
    
    func subscribeRealtime(){
        if let room = self.chatRoom {
            let delay = 3 * Double(NSEC_PER_SEC)
            let time = DispatchTime.now() + delay / Double(NSEC_PER_SEC)
            
            DispatchQueue.main.asyncAfter(deadline: time, execute: {
                let typingChannel:String = "r/\(room.id)/\(room.id)/+/t"
                let readChannel:String = "r/\(room.id)/\(room.id)/+/r"
                let deliveryChannel:String = "r/\(room.id)/\(room.id)/+/d"
                Qiscus.shared.mqtt?.subscribe(typingChannel, qos: .qos1)
                Qiscus.shared.mqtt?.subscribe(readChannel, qos: .qos1)
                Qiscus.shared.mqtt?.subscribe(deliveryChannel, qos: .qos1)
                for participant in room.participants {
                    let userChannel = "u/\(participant.email)/s"
                    Qiscus.shared.mqtt?.subscribe(userChannel, qos: .qos1)
                }
            })
        }
    }
    func unsubscribeTypingRealtime(onRoom room:QiscusRoom?){
        if room != nil {
            let channel = "r/\(room!.roomId)/\(room!.roomLastCommentTopicId)/+/t"
            Qiscus.shared.mqtt?.unsubscribe(channel)
        }
    }
    func iCloudOpen(){
        if Qiscus.sharedInstance.connected{
            let documentPicker = UIDocumentPickerViewController(documentTypes: self.UTIs, in: UIDocumentPickerMode.import)
            documentPicker.delegate = self
            documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
            self.present(documentPicker, animated: true, completion: nil)
        }else{
            self.showNoConnectionToast()
        }
    }
    
    func goToIPhoneSetting(){
        UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    func loadTitle(){
        DispatchQueue.main.async {
            if self.chatTitle == nil || self.chatTitle == "" {
                if let room = self.chatRoom {
                    self.titleLabel.text = room.name
                    if self.roomAvatarImage == nil {
                        let bgColor = QiscusColorConfiguration.sharedInstance.avatarBackgroundColor
                        self.roomAvatarLabel.text = String(room.name.characters.first!).uppercased()
                        let colorIndex = room.name.characters.count % bgColor.count
                        self.roomAvatar.backgroundColor = bgColor[colorIndex]
                        if QiscusHelper.isFileExist(inLocalPath: room.avatarLocalPath){
                            self.roomAvatar.loadAsync(fromLocalPath: room.avatarLocalPath, onLoaded: { (image, _) in
                                self.roomAvatarImage = image
                                self.roomAvatar.image = image
                            })
                        }else{
                            self.roomAvatar.loadAsync(room.avatarURL, onLoaded: { (image, _) in
                                self.roomAvatarImage = image
                                self.roomAvatar.image = image
                                self.roomAvatar.backgroundColor = UIColor.clear
                                self.roomAvatarLabel.isHidden = true
                            })
                        }
                    }
                    
                }
            }
        }
    }
    func loadSubtitle(){
        DispatchQueue.main.async {
            if self.chatSubtitle == nil || self.chatSubtitle == ""{
                if let room = self.chatRoom {
                    var subtitleString = "You"
                    if room.type == .group{
                        for participant in room.participants{
                            if participant.email != QiscusMe.sharedInstance.email {
                                if let user = participant.user {
                                    subtitleString += ", \(user.fullname)"
                                }
                            }
                        }
                    }else{
                        if room.participants.count > 0 {
                            for participant in room.participants {
                                if participant.email != QiscusMe.sharedInstance.email{
                                    if let user = participant.user{
                                        if user.lastSeen == Double(0){
                                            subtitleString = "is offline"
                                        }else{
                                            if user.lastSeenString == "online" {
                                                subtitleString = "is online"
                                            }else{
                                                subtitleString = "last seen: \(user.lastSeenString)"
                                            }
                                        }
                                    }
                                    break
                                }
                            }
                        }else{
                            subtitleString = "not available"
                        }
                    }
                    if subtitleString != "not available" {
                        if subtitleString == "online" || subtitleString.contains("minute") || subtitleString.contains("hours") {
                            var delay = 60.0 * Double(NSEC_PER_SEC)
                            if subtitleString.contains("hours"){
                                delay = 3600.0 * Double(NSEC_PER_SEC)
                            }
                            let time = DispatchTime.now() + delay / Double(NSEC_PER_SEC)
                            DispatchQueue.main.asyncAfter(deadline: time, execute: {
                                self.loadSubtitle()
                            })
                        }
                    }
                    self.subtitleLabel.text = subtitleString
                }
            }
        }
    }
    
    func showPhotoAccessAlert(){
        DispatchQueue.main.async(execute: {
            let text = QiscusTextConfiguration.sharedInstance.galeryAccessAlertText
            let cancelTxt = QiscusTextConfiguration.sharedInstance.alertCancelText
            let settingTxt = QiscusTextConfiguration.sharedInstance.alertSettingText
            QPopUpView.showAlert(withTarget: self, message: text, firstActionTitle: settingTxt, secondActionTitle: cancelTxt,
                                 doneAction: {
                                    self.goToIPhoneSetting()
            },
                                 cancelAction: {}
            )
        })
    }
    func showCameraAccessAlert(){
        DispatchQueue.main.async(execute: {
            let text = QiscusTextConfiguration.sharedInstance.cameraAccessAlertText
            let cancelTxt = QiscusTextConfiguration.sharedInstance.alertCancelText
            let settingTxt = QiscusTextConfiguration.sharedInstance.alertSettingText
            QPopUpView.showAlert(withTarget: self, message: text, firstActionTitle: settingTxt, secondActionTitle: cancelTxt,
                                 doneAction: {
                                    self.goToIPhoneSetting()
            },
                                 cancelAction: {}
            )
        })
    }
    func showMicrophoneAccessAlert(){
        DispatchQueue.main.async(execute: {
            let text = QiscusTextConfiguration.sharedInstance.microphoneAccessAlertText
            let cancelTxt = QiscusTextConfiguration.sharedInstance.alertCancelText
            let settingTxt = QiscusTextConfiguration.sharedInstance.alertSettingText
            QPopUpView.showAlert(withTarget: self, message: text, firstActionTitle: settingTxt, secondActionTitle: cancelTxt,
                                 doneAction: {
                                    self.goToIPhoneSetting()
            },
                                 cancelAction: {}
            )
        })
    }
    func goToGaleryPicker(){
        DispatchQueue.main.async(execute: {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.allowsEditing = false
            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            picker.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
            self.present(picker, animated: true, completion: nil)
        })
    }
    func goToTitleAction(){
        self.inputBarBottomMargin.constant = 0
        self.view.layoutIfNeeded()
        self.titleAction()
    }
    func scrollToBottom(_ animated:Bool = false){
        if self.chatRoom!.comments.count > 0 {
            let section = self.numberOfSections(in: self.collectionView) - 1
            let row = self.collectionView(self.collectionView, numberOfItemsInSection: section) - 1
            let lastIndexPath = IndexPath(row: row, section: section)
            self.collectionView.scrollToItem(at: lastIndexPath, at: .bottom, animated: animated)
        }
    }
    func scrollToIndexPath(_ indexPath:IndexPath, position: UICollectionViewScrollPosition, animated:Bool, delayed:Bool = true){
        
        if !delayed {
            self.collectionView.scrollToItem(at: indexPath, at: position, animated: false)
        }else{
            let delay = 0.1 * Double(NSEC_PER_SEC)
            let time = DispatchTime.now() + delay / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: time, execute: {
                if self.comments.count > 0 {
                    self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
                }
            })
        }
    }
    func setNavigationColor(_ color:UIColor, tintColor:UIColor){
        self.topColor = color
        self.bottomColor = color
        self.tintColor = tintColor
        self.navigationController?.navigationBar.verticalGradientColor(topColor, bottomColor: bottomColor)
        self.navigationController?.navigationBar.tintColor = tintColor
        let _ = self.view
        self.sendButton.tintColor = self.topColor
        if self.inputText.value == "" {
            self.sendButton.isEnabled = false
        }
        self.attachButton.tintColor = self.topColor
        self.bottomButton.tintColor = self.topColor
        self.recordButton.tintColor = self.topColor
        self.cancelRecordButton.tintColor = self.topColor
        self.emptyChatImage.tintColor = self.bottomColor
    }
    
    func sendMessage(){
        if Qiscus.shared.connected{
            if !self.isRecording {
                let value = self.inputText.value.trimmingCharacters(in: .whitespacesAndNewlines)
                var type:QCommentType = .text
                var payload:JSON? = nil
                if let reply = self.replyData {
                    var senderName = reply.senderName
                    if let user = reply.sender{
                        senderName = user.fullname
                    }
                    let payloadArray: [(String,Any)] = [
                        ("replied_comment_sender_email",reply.senderEmail),
                        ("replied_comment_id", reply.id),
                        ("text", value),
                        ("replied_comment_message", reply.text),
                        ("replied_comment_sender_username", senderName)
                    ]
                    payload = JSON(dictionaryLiteral: payloadArray)
                    type = .reply
                    self.replyData = nil
                }
                let comment = chatRoom!.newComment(text: value, payload: payload, type: type)
                chatRoom?.post(comment: comment)
                
                self.inputText.clearValue()
                
                DispatchQueue.main.async {
                    self.inputText.text = ""
                    self.minInputHeight.constant = 32
                    self.sendButton.isEnabled = false
                    self.inputText.layoutIfNeeded()
                }
            }else{
                self.finishRecording()
            }
        }else{
            self.showNoConnectionToast()
            if self.isRecording {
                self.cancelRecordVoice()
            }
        }
    }
    func uploadImage(){
        view.endEditing(true)
        if Qiscus.sharedInstance.connected{
            let photoPermissions = PHPhotoLibrary.authorizationStatus()
            
            if(photoPermissions == PHAuthorizationStatus.authorized){
                self.goToGaleryPicker()
            }else if(photoPermissions == PHAuthorizationStatus.notDetermined){
                PHPhotoLibrary.requestAuthorization({(status:PHAuthorizationStatus) in
                    switch status{
                    case .authorized:
                        self.goToGaleryPicker()
                        break
                    case .denied:
                        self.showPhotoAccessAlert()
                        break
                    default:
                        self.showPhotoAccessAlert()
                        break
                    }
                })
            }else{
                self.showPhotoAccessAlert()
            }
        }else{
            self.showNoConnectionToast()
        }
    }
    func uploadFromCamera(){
        view.endEditing(true)
        if Qiscus.sharedInstance.connected{
            if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) ==  AVAuthorizationStatus.authorized
            {
                DispatchQueue.main.async(execute: {
                    let picker = UIImagePickerController()
                    picker.delegate = self
                    picker.allowsEditing = false
                    picker.mediaTypes = [(kUTTypeImage as String),(kUTTypeMovie as String)]
                    
                    picker.sourceType = UIImagePickerControllerSourceType.camera
                    self.present(picker, animated: true, completion: nil)
                })
            }else{
                AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in
                    if granted {
                        let picker = UIImagePickerController()
                        picker.delegate = self
                        picker.allowsEditing = false
                        picker.mediaTypes = [(kUTTypeImage as String),(kUTTypeMovie as String)]
                        
                        picker.sourceType = UIImagePickerControllerSourceType.camera
                        self.present(picker, animated: true, completion: nil)
                    }else{
                        DispatchQueue.main.async(execute: {
                            self.showCameraAccessAlert()
                        })
                    }
                })
            }
        }else{
            self.showNoConnectionToast()
        }
    }
    func recordVoice(){
        self.prepareRecording()
    }
    func startRecording(){
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let time = Double(Date().timeIntervalSince1970)
        let timeToken = UInt64(time * 10000)
        let fileName = "audio-\(timeToken).m4a"
        let audioURL = documentsPath.appendingPathComponent(fileName)
        print ("audioURL: \(audioURL)")
        self.recordingURL = audioURL
        let settings:[String : Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: Float(44100),
            AVNumberOfChannelsKey: Int(2),
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        self.recordButton.isHidden = true
        self.sendButton.isHidden = false
        self.recordBackground.clipsToBounds = true
        let inputWidth = self.inputText.frame.width
        let recorderWidth = inputWidth + 17
        self.recordViewLeading.constant = 0 - recorderWidth
        
        Qiscus.uiThread.async {
            UIView.animate(withDuration: 0.5, animations: {
                self.inputText.isHidden = true
                self.cancelRecordButton.isHidden = false
                self.view.layoutIfNeeded()
            }, completion: { success in
                
                var timerLabel = self.recordBackground.viewWithTag(543) as? UILabel
                if timerLabel == nil {
                    timerLabel = UILabel(frame: CGRect(x: 34, y: 5, width: 40, height: 20))
                    timerLabel!.backgroundColor = UIColor.clear
                    timerLabel!.textColor = UIColor.white
                    timerLabel!.tag = 543
                    timerLabel!.font = UIFont.systemFont(ofSize: 12)
                    self.recordBackground.addSubview(timerLabel!)
                }
                timerLabel!.text = "00:00"
                
                var waveView = self.recordBackground.viewWithTag(544) as? QSiriWaveView
                if waveView == nil {
                    let backgroundFrame = self.recordBackground.bounds
                    waveView = QSiriWaveView(frame: CGRect(x: 76, y: 2, width: backgroundFrame.width - 110, height: 28))
                    waveView!.waveColor = UIColor.white
                    waveView!.numberOfWaves = 6
                    waveView!.primaryWaveWidth = 1.0
                    waveView!.secondaryWaveWidth = 0.75
                    waveView!.tag = 544
                    waveView!.layer.cornerRadius = 14.0
                    waveView!.clipsToBounds = true
                    waveView!.backgroundColor = UIColor.clear
                    self.recordBackground.addSubview(waveView!)
                }
                do {
                    self.recorder = nil
                    if self.recorder == nil {
                        self.recorder = try AVAudioRecorder(url: audioURL, settings: settings)
                    }
                    self.recorder?.prepareToRecord()
                    self.recorder?.isMeteringEnabled = true
                    self.recorder?.record()
                    self.sendButton.isEnabled = true
                    self.recordDuration = 0
                    if self.recordTimer != nil {
                        self.recordTimer?.invalidate()
                        self.recordTimer = nil
                    }
                    self.recordTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(QiscusChatVC.updateTimer), userInfo: nil, repeats: true)
                    self.isRecording = true
                    let displayLink = CADisplayLink(target: self, selector: #selector(QiscusChatVC.updateAudioMeter))
                    displayLink.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
                } catch {
                    print("error recording")
                }
            })
            
        }
    }
    func prepareRecording(){
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                if allowed {
                    self.startRecording()
                } else {
                    Qiscus.uiThread.async {
                        self.showMicrophoneAccessAlert()
                    }
                }
            }
        } catch {
            Qiscus.uiThread.async {
                self.showMicrophoneAccessAlert()
            }
        }
    }
    func updateTimer(){
        if let timerLabel = self.recordBackground.viewWithTag(543) as? UILabel {
            self.recordDuration += 1
            let minutes = Int(self.recordDuration / 60)
            let seconds = self.recordDuration % 60
            var minutesString = "\(minutes)"
            if minutes < 10 {
                minutesString = "0\(minutes)"
            }
            var secondsString = "\(seconds)"
            if seconds < 10 {
                secondsString = "0\(seconds)"
            }
            timerLabel.text = "\(minutesString):\(secondsString)"
        }
    }
    func updateAudioMeter(){
        if let audioRecorder = self.recorder{
            audioRecorder.updateMeters()
            let normalizedValue:CGFloat = pow(10.0, CGFloat(audioRecorder.averagePower(forChannel: 0)) / 20)
            Qiscus.uiThread.async {
                if let waveView = self.recordBackground.viewWithTag(544) as? QSiriWaveView {
                    waveView.update(withLevel: normalizedValue)
                }
            }
        }
    }
    func finishRecording(){
        self.recorder?.stop()
        self.recorder = nil
        self.recordViewLeading.constant = 0 - 2
        Qiscus.uiThread.async {
            UIView.animate(withDuration: 0.5, animations: {
                self.inputText.isHidden = false
                self.cancelRecordButton.isHidden = true
                self.view.layoutIfNeeded()
            }) { (_) in
                self.recordButton.isHidden = false
                self.sendButton.isHidden = true
                if self.recordTimer != nil {
                    self.recordTimer?.invalidate()
                    self.recordTimer = nil
                    self.recordDuration = 0
                }
                self.isRecording = false
            }
        }
        if let audioURL = self.recordingURL {
            var fileContent: Data?
            fileContent = try! Data(contentsOf: audioURL)
            
            let fileName = audioURL.lastPathComponent
            
            let newComment = self.chatRoom!.newFileComment(type: .audio, filename: fileName, data: fileContent!)
            
            self.chatRoom!.upload(comment: newComment, onSuccess: { (roomResult, commentResult) in
                self.chatRoom!.post(comment: commentResult)
            }, onError: { (roomResult, commentResult, error) in
                print("Error: \(error)")
            })
        }
    }
    func cancelRecordVoice(){
        self.recordViewLeading.constant = 0 - 2
        Qiscus.uiThread.async {
            UIView.animate(withDuration: 0.5, animations: {
                self.inputText.isHidden = false
                self.cancelRecordButton.isHidden = true
                self.view.layoutIfNeeded()
            }) { (_) in
                self.recordButton.isHidden = false
                self.sendButton.isHidden = true
                if self.recordTimer != nil {
                    self.recordTimer?.invalidate()
                    self.recordTimer = nil
                    self.recordDuration = 0
                }
                self.isRecording = false
            }
        }
    }
    
    func postFile(filename:String, data:Data? = nil, type:QiscusFileType, thumbImage:UIImage? = nil){
        if Qiscus.sharedInstance.connected {
            let newComment = self.chatRoom!.newFileComment(type: type, filename: filename, data: data, thumbImage: thumbImage)
            
            self.chatRoom!.upload(comment: newComment, onSuccess: { (roomResult, commentResult) in
                self.chatRoom!.post(comment: commentResult)
            }, onError: { (roomResult, commentResult, error) in
                print("Error: \(error)")
            })
        }else{
            self.showNoConnectionToast()
        }
    }
    
    // MARK: - Load More Control
    func loadMore(){
        if let room = self.chatRoom {
            room.loadMore()
        }
    }
    
    
    // MARK: - Back Button
    class func backButton(_ target: UIViewController, action: Selector) -> UIBarButtonItem{
        let backIcon = UIImageView()
        backIcon.contentMode = .scaleAspectFit
        
        let image = Qiscus.image(named: "ic_back")
        backIcon.image = image
        
        //let backButtons = UIBarButtonItem(barButtonSystemItem: , target: <#T##Any?#>, action: <#T##Selector?#>)
        if UIApplication.shared.userInterfaceLayoutDirection == .leftToRight {
            backIcon.frame = CGRect(x: 0,y: 11,width: 13,height: 22)
        }else{
            backIcon.frame = CGRect(x: 22,y: 11,width: 13,height: 22)
        }
        
        let backButton = UIButton(frame:CGRect(x: 0,y: 0,width: 23,height: 44))
        backButton.addSubview(backIcon)
        backButton.addTarget(target, action: action, for: UIControlEvents.touchUpInside)
        return UIBarButtonItem(customView: backButton)
    }
    
    func setGradientChatNavigation(withTopColor topColor:UIColor, bottomColor:UIColor, tintColor:UIColor){
        self.topColor = topColor
        self.bottomColor = bottomColor
        self.tintColor = tintColor
        self.navigationController?.navigationBar.verticalGradientColor(self.topColor, bottomColor: self.bottomColor)
        self.navigationController?.navigationBar.tintColor = self.tintColor
        let _ = self.view
        self.sendButton.tintColor = self.topColor
        if self.inputText.value == "" {
            self.sendButton.isEnabled = false
        }
        self.attachButton.tintColor = self.topColor
        self.bottomButton.tintColor = self.topColor
        self.recordButton.tintColor = self.topColor
        self.cancelRecordButton.tintColor = self.topColor
        self.emptyChatImage.tintColor = self.bottomColor
        
    }
    // MARK: - Load DataSource on firstTime
    func loadData(){
        self.showLoading("Load data ...")
        
        if self.chatRoomId != nil {
            self.chatService.room(withId: self.chatRoomId!, withMessage: self.chatMessage)
        }else if self.chatUser != nil {
            self.chatService.room(withUser: self.chatUser!, distincId: self.chatDistinctId, optionalData: self.chatData, withMessage: self.chatMessage)
        }else if self.chatNewRoomUsers.count > 0 {
            self.chatService.createRoom(withUsers: self.chatNewRoomUsers, roomName: self.chatTitle!, optionalData: optionalData, withMessage: self.chatMessage)
        }else if self.chatRoomUniqueId != nil {
            self.chatService.room(withUniqueId: self.chatRoomUniqueId!, title: self.chatTitle!, avatarURL: self.chatAvatarURL, withMessage: self.chatMessage)
        }
    }
    
}
