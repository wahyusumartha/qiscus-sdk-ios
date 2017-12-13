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
import ContactsUI

extension QiscusChatVC:CNContactPickerDelegate{
    //func shareContact
    public func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        func share(name:String, value:String){
            let newComment = self.chatRoom!.newContactComment(name: name, value: value)
            let section = self.chatRoom!.comments.count - 1
            let group = self.chatRoom!.comments[section]
            let item = group.comments.count - 1
            self.collectionView.reloadData()
            self.postComment(comment: newComment)
            
            self.chatRoom!.post(comment: newComment)
            let indexPath = IndexPath(item: item, section: section)
            self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
        }
        let contactName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespacesAndNewlines)
        let contactSheetController = UIAlertController(title: contactName, message: "select contact you want to share", preferredStyle: .actionSheet)
        
        let cancelActionButton = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            
        }
        contactSheetController.addAction(cancelActionButton)
        
        for phoneNumber in contact.phoneNumbers {
            let value = phoneNumber.value.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            var title = "\(value)"
            if let label = phoneNumber.label {
                let labelString = CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: label)
                title = "\(labelString): \(value)"
            }
            let phoneButton = UIAlertAction(title: title, style: .default) { action -> Void in
                share(name: contactName, value: value)
            }
            contactSheetController.addAction(phoneButton)
        }
        for email in contact.emailAddresses {
            let value = email.value as String
            var title = "\(value)"
            if let label = email.label {
                let labelString = CNLabeledValue<NSString>.localizedString(forLabel: label)
                title = "\(labelString): \(value)"
            }
            let emailButton = UIAlertAction(title: title, style: .default) { action -> Void in
                share(name: contactName, value: value)
            }
            contactSheetController.addAction(emailButton)
        }
        picker.dismiss(animated: true, completion: nil)
        self.present(contactSheetController, animated: true, completion: nil)
    }
}
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
        self.archived = true
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
    func shareContact(){
        self.contactVC.delegate = self
        self.present(self.contactVC, animated: true, completion: nil)
    }
    func showAttachmentMenu(){
        let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cancelActionButton = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            Qiscus.printLog(text: "Cancel attach file")
        }
        actionSheetController.addAction(cancelActionButton)
        
        if Qiscus.shared.cameraUpload {
            let cameraActionButton = UIAlertAction(title: "Camera", style: .default) { action -> Void in
                self.uploadFromCamera()
            }
            actionSheetController.addAction(cameraActionButton)
        }
        
        if Qiscus.shared.galeryUpload {
            let galeryActionButton = UIAlertAction(title: "Gallery", style: .default) { action -> Void in
                self.uploadImage()
            }
            actionSheetController.addAction(galeryActionButton)
        }
        
        if Qiscus.sharedInstance.iCloudUpload {
            let iCloudActionButton = UIAlertAction(title: "Document", style: .default) { action -> Void in
                self.iCloudOpen()
            }
            actionSheetController.addAction(iCloudActionButton)
        }
        
        if Qiscus.shared.contactShare {
            let contactActionButton = UIAlertAction(title: "Contact", style: .default) { action -> Void in
                self.shareContact()
            }
            actionSheetController.addAction(contactActionButton)
        }
        if Qiscus.shared.locationShare {
            let contactActionButton = UIAlertAction(title: "Current Location", style: .default) { action -> Void in
                self.shareCurrentLocation()
            }
            actionSheetController.addAction(contactActionButton)
        }
        self.present(actionSheetController, animated: true, completion: nil)
    }
    func shareCurrentLocation(){
        
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .authorizedAlways, .authorizedWhenInUse:
                self.showLoading("Getting your current location")
                
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                self.didFindLocation = false
                self.locationManager.startUpdatingLocation()
                break
            case .denied:
                self.showLocationAccessAlert()
                break
            case .restricted:
                self.showLocationAccessAlert()
                break
            case .notDetermined:
                self.showLocationAccessAlert()
                break
            }
        }else{
            self.showLocationAccessAlert()
        }
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
        Qiscus.uiThread.async { autoreleasepool{
            self.linkPreviewTopMargin.constant = 0
            UIView.animate(withDuration: 0.65, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        }}
    }
    func startTypingIndicator(withUser user:String){
        self.typingIndicatorUser = user
        self.isTypingOn = true
        var typingText = ""
        if let subtitle = self.subtitleLabel.text{
            self.subtitleText = subtitle
        }
        if self.chatRoom?.type != .single {
            typingText = "\(user) "
        }
        typingText = "\(typingText) is typing ..."
        if self.subtitleText == "" {
            // reduce title height
            var frame = self.titleLabel.frame
            frame.size.height = 17
            UIView.animate(withDuration: 3.0, animations: {
                self.titleLabel.frame = frame
            }, completion: { (_) in
                self.subtitleLabel.text = typingText
            })
        }else{
            self.subtitleLabel.text = typingText
        }
        if self.remoteTypingTimer != nil {
            if self.remoteTypingTimer!.isValid {
                self.remoteTypingTimer?.invalidate()
            }
        }
        self.remoteTypingTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(QiscusChatVC.stopTypingIndicator), userInfo: nil, repeats: false)
    }
    
    func stopTypingIndicator(){
        var frame = self.titleLabel.frame
        frame.size.height = 30
        if self.subtitleText == "" {
            // increase title height
            self.subtitleLabel.text = self.subtitleText
            UIView.animate(withDuration: 0.5, animations: {
                self.titleLabel.frame = frame
            })
        }else{
            self.subtitleLabel.text = self.subtitleText
            self.subtitleText = ""
        }
        
        self.typingIndicatorUser = ""
        self.isTypingOn = false
        if self.remoteTypingTimer != nil {
            self.remoteTypingTimer?.invalidate()
            self.remoteTypingTimer = nil
        }
    }
    
    func showNoConnectionToast(){
        QToasterSwift.toast(target: self, text: QiscusTextConfiguration.sharedInstance.noConnectionText, backgroundColor: UIColor(red: 0.9, green: 0,blue: 0,alpha: 0.8), textColor: UIColor.white)
    }
    // MARK: - Overriding back action
    public func setBackButton(withAction action:@escaping (()->Void)){
        self.backAction = action
    }
    
    func setTitle(title:String = "", withSubtitle:String? = nil){
        QiscusUIConfiguration.sharedInstance.copyright.chatTitle = title
        if withSubtitle != nil {
            QiscusUIConfiguration.sharedInstance.copyright.chatSubtitle = withSubtitle!
        }
        self.loadTitle()
    }
    
    
    func subscribeRealtime(){
//        if let room = self.chatRoom {
//            let delay = 3 * Double(NSEC_PER_SEC)
//            let time = DispatchTime.now() + delay / Double(NSEC_PER_SEC)
//            
//            DispatchQueue.main.asyncAfter(deadline: time, execute: {
//                let typingChannel:String = "r/\(room.id)/\(room.id)/+/t"
//                let readChannel:String = "r/\(room.id)/\(room.id)/+/r"
//                let deliveryChannel:String = "r/\(room.id)/\(room.id)/+/d"
//                Qiscus.shared.mqtt?.subscribe(typingChannel, qos: .qos1)
//                Qiscus.shared.mqtt?.subscribe(readChannel, qos: .qos1)
//                Qiscus.shared.mqtt?.subscribe(deliveryChannel, qos: .qos1)
//                for participant in room.participants {
//                    let userChannel = "u/\(participant.email)/s"
//                    Qiscus.shared.mqtt?.subscribe(userChannel, qos: .qos1)
//                }
//            })
//        }
    }
    func unsubscribeTypingRealtime(onRoom room:QRoom?){
//        if room != nil {
//            let channel = "r/\(room!.id)/\(room!.id)/+/t"
//            Qiscus.shared.mqtt?.unsubscribe(channel)
//        }
    }
    func iCloudOpen(){        
        if Qiscus.sharedInstance.connected{
            UINavigationBar.appearance().tintColor = UIColor.blue
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
        DispatchQueue.main.async {autoreleasepool{
            if self.chatTitle == nil || self.chatTitle == "" {
                if let room = self.chatRoom {
                    self.titleLabel.text = room.name
                    if self.roomAvatarImage == nil {
                        self.roomAvatar.image = Qiscus.image(named: "avatar")
                        room.loadAvatar(onSuccess: { (avatar) in
                            self.roomAvatar.image = avatar
                        }, onError: { (_) in
                            room.downloadRoomAvatar()
                        })
                    }
                }
            }
            else{
                self.titleLabel.text = self.chatTitle
                
                if let room = self.chatRoom {
                    self.roomAvatar.image = Qiscus.image(named: "avatar")
                    room.loadAvatar(onSuccess: { (avatar) in
                        self.roomAvatar.image = avatar
                    }, onError: { (_) in
                        room.downloadRoomAvatar()
                    })
                }
            }
        }}
    }
    func loadSubtitle(){
        
        if self.chatRoom != nil{
            if self.chatRoom!.isInvalidated {return}
        DispatchQueue.main.async {autoreleasepool{
            var prevSubtitle = ""
            if let currentSubtitle = self.subtitleLabel.text {
                prevSubtitle = currentSubtitle
            }
            if self.chatSubtitle == nil || self.chatSubtitle == ""{
                if let room = self.chatRoom {
                    if room.isInvalidated { return }
                    var subtitleString = ""
                    if room.type == .group{
                        subtitleString = "You"
                        for participant in room.participants{
                            if participant.email != QiscusMe.shared.email {
                                if let user = participant.user {
                                    subtitleString += ", \(user.fullname)"
                                }
                            }
                        }
                    }else{
                        if room.participants.count > 0 {
                            for participant in room.participants {
                                if participant.email != QiscusMe.shared.email{
                                    if let user = participant.user{
                                        if user.presence == .offline{
                                            let lastSeenString = user.lastSeenString
                                            if lastSeenString != "" {
                                                subtitleString = "last seen: \(user.lastSeenString)"
                                            }
                                        }else{
                                            subtitleString = "online"
                                        }
                                    }
                                    break
                                }
                            }
                        }else{
                            subtitleString = ""
                        }
                    }
                    var frame = self.titleLabel.frame
                    
                    if subtitleString == "" && prevSubtitle == "" && frame.size.height == 17 && room.type == .single{
                        self.subtitleLabel.text = ""
                        frame.size.height = 30
                        UIView.animate(withDuration: 0.5, animations: {
                            self.titleLabel.frame = frame
                        })
                    }
                    else if subtitleString == "" && prevSubtitle != "" && room.type == .single{
                        // increase title height
                        self.subtitleLabel.text = ""
                        frame.size.height = 30
                        UIView.animate(withDuration: 0.5, animations: {
                            self.titleLabel.frame = frame
                        })
                    }else if subtitleString != "" && prevSubtitle == "" && room.type == .single{
                        // reduce titleHeight
                        frame.size.height = 17
                        UIView.animate(withDuration: 0.5, animations: {
                            self.titleLabel.frame = frame
                        }, completion: { (_) in
                            self.subtitleLabel.text = subtitleString
                        })
                    }else{
                        self.subtitleLabel.text = subtitleString
                    }
                    if subtitleString.contains("minute") || subtitleString.contains("hours") || subtitleString.contains("seconds"){
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
            }else{
                self.subtitleLabel.text = self.chatSubtitle!
            }
        }}
        }
    }
    func showLocationAccessAlert(){
        DispatchQueue.main.async{autoreleasepool{
            let text = QiscusTextConfiguration.sharedInstance.locationAccessAlertText
            let cancelTxt = QiscusTextConfiguration.sharedInstance.alertCancelText
            let settingTxt = QiscusTextConfiguration.sharedInstance.alertSettingText
            QPopUpView.showAlert(withTarget: self, message: text, firstActionTitle: settingTxt, secondActionTitle: cancelTxt,
                                 doneAction: {
                                    self.goToIPhoneSetting()
            },
                                 cancelAction: {}
            )
        }}
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
        if self.chatRoom != nil {
            if self.collectionView.numberOfSections > 0 {
                let section = self.collectionView.numberOfSections - 1
                if self.collectionView.numberOfItems(inSection: section) > 0 {
                    let item = self.collectionView.numberOfItems(inSection: section) - 1
                    let lastIndexPath = IndexPath(row: item, section: section)
                    self.collectionView.scrollToItem(at: lastIndexPath, at: .bottom, animated: animated)
                    if self.isPresence {
                        self.chatRoom!.readAll()
                    }
                }
            }
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
        //if Qiscus.shared.connected{
            if !self.isRecording {
                let value = self.inputText.value.trimmingCharacters(in: .whitespacesAndNewlines)
                if value != "" {
                    var type:QCommentType = .text
                    var payload:JSON? = nil
                    if let reply = self.replyData {
                        var senderName = reply.senderName
                        if let user = reply.sender{
                            senderName = user.fullname
                        }
                        var payloadArray: [(String,Any)] = [
                            ("replied_comment_sender_email",reply.senderEmail),
                            ("replied_comment_id", reply.id),
                            ("text", value),
                            ("replied_comment_message", reply.text),
                            ("replied_comment_sender_username", senderName),
                            ("replied_comment_payload", reply.data)
                        ]
                        if reply.type == .location || reply.type == .contact {
                            payloadArray.append(("replied_comment_type",reply.typeRaw))
                        }
                        payload = JSON(dictionaryLiteral: payloadArray)
                        type = .reply
                        self.replyData = nil
                    }
                    let comment = chatRoom!.newComment(text: value, payload: payload, type: type)
                    self.postComment(comment: comment)
                    
                    self.inputText.clearValue()
                    
                    DispatchQueue.main.async { autoreleasepool{
                        self.inputText.text = ""
                        self.minInputHeight.constant = 32
                        self.sendButton.isEnabled = false
                        self.inputText.layoutIfNeeded()
                    }}
                }
            }else{
                if !self.processingAudio {
                    self.processingAudio = true
                    self.finishRecording()
                }
            }
//        }else{
//            self.showNoConnectionToast()
//            if self.isRecording {
//                self.cancelRecordVoice()
//            }
//        }
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
        
        Qiscus.uiThread.async {autoreleasepool{
            self.recordButton.isHidden = true
            self.sendButton.isHidden = false
            self.recordBackground.clipsToBounds = true
            let inputWidth = self.inputText.frame.width
            let recorderWidth = inputWidth + 17
            self.recordViewLeading.constant = 0 - recorderWidth
            
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
                    Qiscus.printLog(text: "error recording")
                }
            })
        }}
    }
    func prepareRecording(){
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                if allowed {
                    self.startRecording()
                } else {
                    Qiscus.uiThread.async { autoreleasepool{
                        self.showMicrophoneAccessAlert()
                    }}
                }
            }
        } catch {
            Qiscus.uiThread.async { autoreleasepool{
                self.showMicrophoneAccessAlert()
            }}
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
            Qiscus.uiThread.async {autoreleasepool{
                if let waveView = self.recordBackground.viewWithTag(544) as? QSiriWaveView {
                    waveView.update(withLevel: normalizedValue)
                }
            }}
        }
    }
    func finishRecording(){
        self.recorder?.stop()
        self.recorder = nil
        self.recordViewLeading.constant = 8
        Qiscus.uiThread.async {autoreleasepool{
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
                self.processingAudio = false
            }
        }}
        if let audioURL = self.recordingURL {
            var fileContent: Data?
            fileContent = try! Data(contentsOf: audioURL)
            let mediaSize = Double(fileContent!.count) / 1024.0
            if mediaSize > Qiscus.maxUploadSizeInKB {
                self.showFileTooBigAlert()
                return
            }
            let fileName = audioURL.lastPathComponent
            
            let newComment = self.chatRoom!.newFileComment(type: .audio, filename: fileName, data: fileContent!)
            
            self.chatRoom!.upload(comment: newComment, onSuccess: { (roomResult, commentResult) in
                self.postComment(comment: commentResult)
            }, onError: { (roomResult, commentResult, error) in
                Qiscus.printLog(text: "Error: \(error)")
            })
        }
    }
    func cancelRecordVoice(){
        self.recordViewLeading.constant = 8
        Qiscus.uiThread.async { autoreleasepool{
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
        }}
    }
    
    func postFile(filename:String, data:Data? = nil, type:QiscusFileType, thumbImage:UIImage? = nil){
        if Qiscus.sharedInstance.connected {
            let newComment = self.chatRoom!.newFileComment(type: type, filename: filename, data: data, thumbImage: thumbImage)
            
            self.chatRoom!.upload(comment: newComment, onSuccess: { (roomResult, commentResult) in
                self.postComment(comment: commentResult)
            }, onError: { (roomResult, commentResult, error) in
                Qiscus.printLog(text: "Error: \(error)")
            })
        }else{
            self.showNoConnectionToast()
        }
    }
    
    // MARK: - Load More Control
    func loadMore(){
        if let room = self.chatRoom {
            if room.comments.count > 0 {
                if let firstGroup = room.comments.first {
                    if let firstComment = firstGroup.comments.first {
                        if firstComment.id > 0 && firstComment.beforeId == 0 {
                            self.loadMoreControl.endRefreshing()
                            self.loadMoreControl.removeFromSuperview()
                            return
                        }
                        self.topComment = firstComment
                    }
                }
            }
            room.loadMore()
        }else{
            self.loadMoreControl.endRefreshing()
        }
    }
    
    
    // MARK: - Back Button
    class func backButton(_ target: UIViewController, action: Selector) -> UIBarButtonItem{
        let backIcon = UIImageView()
        backIcon.contentMode = .scaleAspectFit
        
        let image = Qiscus.image(named: "ic_back")?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        backIcon.image = image
        backIcon.tintColor = UINavigationBar.appearance().tintColor

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
        if self.chatRoomId != nil {
            self.chatService.room(withId: self.chatRoomId!, withMessage: self.chatMessage)
        }else if self.chatUser != nil {
            self.chatService.room(withUser: self.chatUser!, distincId: self.chatDistinctId, optionalData: self.chatData, withMessage: self.chatMessage)
        }else if self.chatNewRoomUsers.count > 0 {
            
            self.chatService.createRoom(withUsers: self.chatNewRoomUsers, roomName: self.chatTitle!, optionalData: optionalData, withMessage: self.chatMessage)
        }else if self.chatRoomUniqueId != nil {
            self.chatService.room(withUniqueId: self.chatRoomUniqueId!, title: self.chatTitle!, avatarURL: self.chatAvatarURL, withMessage: self.chatMessage)
        }else {
            self.dismissLoading()
        }
    }
    func forward(comment:QComment){
        if self.forwardAction != nil {
            self.forwardAction!(comment)
        }
    }
    func info(comment:QComment){
        if self.infoAction != nil {
            self.infoAction!(comment)
        }
    }
}
