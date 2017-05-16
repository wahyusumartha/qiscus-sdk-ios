//
//  QiscusChatVC.swift
//  QiscusSDK
//
//  Created by Ahmad Athaullah on 8/18/16.
//  Copyright © 2016 Ahmad Athaullah. All rights reserved.
//

import UIKit
import MobileCoreServices
import Photos
import ImageViewer
import SwiftyJSON
import UserNotifications

public class QiscusChatVC: UIViewController{
    
    public static var sharedInstance = QiscusChatVC()
    
    // MARK: - IBOutlet Properties
    @IBOutlet weak var inputBar: UIView!
    @IBOutlet weak var backgroundView: UIImageView!
    @IBOutlet weak var inputText: ChatInputText!
    @IBOutlet weak var welcomeView: UIView!
    @IBOutlet weak var welcomeText: UILabel!
    @IBOutlet weak var welcomeSubtitle: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var attachButton: UIButton!
    @IBOutlet weak var archievedNotifView: UIView!
    @IBOutlet weak var archievedNotifLabel: UILabel!
    @IBOutlet weak var unlockButton: UIButton!
    @IBOutlet weak var emptyChatImage: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomButton: UIButton!
    @IBOutlet weak var unreadIndicator: UILabel!
    @IBOutlet weak var linkPreviewContainer: UIView!
    @IBOutlet weak var linkDescription: UITextView!
    @IBOutlet weak var linkImage: UIImageView!
    @IBOutlet weak var linkTitle: UILabel!
    @IBOutlet weak var recordBackground: UIView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var cancelRecordButton: UIButton!
    
    // MARK: - Constrain
    @IBOutlet weak var minInputHeight: NSLayoutConstraint!
    @IBOutlet weak var archievedNotifTop: NSLayoutConstraint!
    @IBOutlet weak var inputBarBottomMargin: NSLayoutConstraint!
    @IBOutlet weak var collectionViewBottomConstrain: NSLayoutConstraint!
    @IBOutlet weak var linkPreviewTopMargin: NSLayoutConstraint!
    @IBOutlet weak var recordViewLeading: NSLayoutConstraint!
    
    var isPresence:Bool = false
    var titleLabel = UILabel()
    var subtitleLabel = UILabel()
    var isBeforeTranslucent = false
    // MARK: - shared Properties
    var commentClient = QiscusCommentClient.sharedInstance
    let dataPresenter = QiscusDataPresenter.shared
    var archived:Bool = QiscusUIConfiguration.sharedInstance.readOnly
    
    // MARK: - Data Properties
    var room:QiscusRoom?{
        didSet{
            if room != nil{
                let _ = self.view
                let backButton = QiscusChatVC.backButton(self, action: #selector(QiscusChatVC.goBack))
                self.navigationItem.setHidesBackButton(true, animated: false)
                self.navigationItem.leftBarButtonItems = [
                    backButton
                ]
                self.loadMoreControl.removeFromSuperview()
                if room!.hasLoadMore{
                    self.loadMoreControl = UIRefreshControl()
                    self.loadMoreControl.addTarget(self, action: #selector(QiscusChatVC.loadMore), for: UIControlEvents.valueChanged)
                    self.collectionView.addSubview(self.loadMoreControl)
                }
                self.loadTitle()
                let image = Qiscus.image(named: "room_avatar")
                if let avatar = self.room!.avatarImage {
                    self.roomAvatar.image = avatar
                }else{
                    self.roomAvatar.loadAsync(self.room!.roomAvatarURL, placeholderImage: image)
                }
                self.subscribeRealtime(onRoom: room)
                self.syncRoom()
            }else{
                self.titleLabel.text = QiscusTextConfiguration.sharedInstance.chatTitle
                self.subtitleLabel.text = QiscusTextConfiguration.sharedInstance.chatSubtitle
                self.roomSynced = false
            }
        }
    }
    var hasMoreComment = true
    var comments = [[QiscusCommentPresenter]]()
    
    var loadMoreControl = UIRefreshControl()
    
    // MARK: - External data configuration
    var topicId:Int?{
        didSet{
            if topicId != nil{
                room = QiscusRoom.room(withLastTopicId: topicId!)
            }else{
                room = nil
            }
        }
    }
    
    var users:[String]?{
        didSet{
            if users != nil && !newRoom{
                loadWithUser = true
                if users!.count == 1 {
                    let user = users![0]
                    room = QiscusRoom.room(withDistinctId: distincId, andUserEmail: user)
                }
            }
        }
    }
    var roomId:Int?{
        didSet{
            if roomId != nil {
                room = QiscusRoom.room(withId: self.roomId!)
            }else{
                room = nil
            }
        }
    }
    var distincId:String = ""
    var optionalData:String?
    var message:String?
    var newRoom = false
    
    var topColor = Qiscus.shared.styleConfiguration.color.topColor
    var bottomColor = Qiscus.shared.styleConfiguration.color.bottomColor
    var tintColor = Qiscus.shared.styleConfiguration.color.tintColor
    
    // MARK: Galery variable
    var galleryItems:[QiscusGalleryItem] = [QiscusGalleryItem]()
    
    var imagePreview:GalleryViewController?
    var loadWithUser:Bool = false
    
    //MARK: - external action
    @objc public var unlockAction:(()->Void) = {}
    @objc public var titleAction:(()->Void) = {}
    @objc public var backAction:(()->Void)? = nil
    
    var audioPlayer: AVAudioPlayer?
    var audioTimer: Timer?
    var activeAudioCell: QCellAudio?
    
    var cellDelegate:QiscusChatCellDelegate?
    var loadingView = QLoadingViewController.sharedInstance
    var typingIndicatorUser:String = ""
    var isTypingOn:Bool = false
    var linkData:QiscusLinkData?
    var roomName:String?
    var roomAvatar = UIImageView()
    var isSelfTyping = false
    var firstLoad = true
    
    // MARK: - Audio recording variable
    var isRecording = false
    var recordingURL:URL?
    var recorder:AVAudioRecorder?
    var recordingSession = AVAudioSession.sharedInstance()
    var recordTimer:Timer?
    var recordDuration:Int = 0
    
    
    //data flag
    var checkingData:Bool = false
    var roomSynced = false
    var remoteTypingTimer:Timer?
    var typingTimer:Timer?
    var defaultBackButtonVisibility = true
    var defaultNavBarVisibility = true
    var defaultLeftButton:[UIBarButtonItem]? = nil
    
    
    // navigation
    var navTitle:String = ""
    var navSubtitle:String = ""
    
    var showLink:Bool = false{
        didSet{
            if !showLink{
                hideLinkContainer()
                linkData = nil
            }else{
                getLinkPreview(url: linkToPreview)
            }
        }
    }
    var permanentlyDisableLink:Bool = false
    var linkToPreview:String = ""{
        didSet{
            if linkToPreview == ""{
                showLink = false
                permanentlyDisableLink = false
            }else{
                if !permanentlyDisableLink{
                    showLink = true
                }
            }
        }
    }
    
    var unreadIndexPath = [IndexPath](){
        didSet{
            if unreadIndexPath.count > 99 {
                unreadIndicator.text = "99+"
            }else{
                unreadIndicator.text = "\(unreadIndexPath.count)"
            }
            if unreadIndexPath.count == 0 {
                unreadIndicator.isHidden = true
            }else{
                unreadIndicator.isHidden = isLastRowVisible
            }
        }
    }
    
    var bundle:Bundle {
        get{
            return Qiscus.bundle
        }
    }
    var sendOnImage:UIImage?{
        get{
            return UIImage(named: "ic_send_on", in: self.bundle, compatibleWith: nil)?.localizedImage()
        }
    }
    var sendOffImage:UIImage?{
        get{
            return UIImage(named: "ic_send_off", in: self.bundle, compatibleWith: nil)?.localizedImage()
        }
    }
    
    var isLastRowVisible: Bool = false {
        didSet{
            bottomButton.isHidden = isLastRowVisible
            if unreadIndexPath.count > 0 {
                unreadIndicator.isHidden = isLastRowVisible
            }else{
                unreadIndicator.isHidden = true
            }
        }
    }
    
    var lastVisibleRow:IndexPath?{
        get{
            let indexPaths = collectionView.indexPathsForVisibleItems
            return indexPaths.last
        }
    }
    var UTIs:[String]{
        get{
            return ["public.jpeg", "public.png","com.compuserve.gif","public.text", "public.archive", "com.microsoft.word.doc", "com.microsoft.excel.xls", "com.microsoft.powerpoint.​ppt", "com.adobe.pdf","public.mpeg-4"]
        }
    }
    
    public init() {
        super.init(nibName: "QiscusChatVC", bundle: Qiscus.bundle)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Lifecycle
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        layout?.sectionHeadersPinToVisibleBounds = true
        layout?.sectionFootersPinToVisibleBounds = true
        let resendMenuItem: UIMenuItem = UIMenuItem(title: "Resend", action: #selector(QChatCell.resend))
        let deleteMenuItem: UIMenuItem = UIMenuItem(title: "Delete", action: #selector(QChatCell.deleteComment))
        let menuItems:[UIMenuItem] = [resendMenuItem,deleteMenuItem]
        UIMenuController.shared.menuItems = menuItems
        
    }
    override open func viewWillDisappear(_ animated: Bool) {
        self.isPresence = false
        dataPresenter.delegate = nil
        if self.navigationController != nil {
            self.navigationController?.navigationBar.isTranslucent = self.isBeforeTranslucent
            self.navigationController?.setNavigationBarHidden(self.defaultNavBarVisibility, animated: false)
            
        }
        self.navigationItem.setHidesBackButton(self.defaultBackButtonVisibility, animated: false)
        self.navigationItem.leftBarButtonItems = self.defaultLeftButton
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        self.view.endEditing(true)
        if self.room != nil{
            self.unsubscribeTypingRealtime(onRoom: room!)
        }
        self.roomSynced = false
        self.dismissLoading()
    }
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        QiscusChatVC.sharedInstance = self
        self.topColor = Qiscus.shared.styleConfiguration.color.topColor
        self.bottomColor = Qiscus.shared.styleConfiguration.color.bottomColor
        self.tintColor = Qiscus.shared.styleConfiguration.color.tintColor
        
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.removeAllDeliveredNotifications() // To remove all delivered notifications
            center.removeAllPendingNotificationRequests()
        }else{
            UIApplication.shared.cancelAllLocalNotifications()
        }
        let lightColor = self.topColor.withAlphaComponent(0.4)
        recordBackground.backgroundColor = lightColor
        recordBackground.layer.cornerRadius = 16
        bottomButton.setImage(Qiscus.image(named: "bottom")?.withRenderingMode(.alwaysTemplate), for: .normal)
        bottomButton.layer.cornerRadius = 17.5
        bottomButton.clipsToBounds = true
        unreadIndicator.isHidden = true
        unreadIndicator.layer.cornerRadius = 11.5
        unreadIndicator.clipsToBounds = true
        backgroundView.image = Qiscus.image(named: "chat_bg")
        collectionView.decelerationRate = UIScrollViewDecelerationRateNormal
        linkPreviewContainer.layer.shadowColor = UIColor.black.cgColor
        linkPreviewContainer.layer.shadowOpacity = 0.6
        linkPreviewContainer.layer.shadowOffset = CGSize(width: -5, height: 0)
        roomAvatar.contentMode = .scaleAspectFill
        inputText.font = Qiscus.style.chatFont
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.emptyChatImage.tintColor = self.topColor
        
        if let navController = self.navigationController {
            self.isBeforeTranslucent = navController.navigationBar.isTranslucent
            self.navigationController?.navigationBar.isTranslucent = false
            self.defaultNavBarVisibility = self.navigationController!.isNavigationBarHidden
        }
        self.roomSynced = false
        unreadIndexPath = [IndexPath]()
        bottomButton.isHidden = true
        dataPresenter.delegate = self
        
        if self.loadMoreControl.isRefreshing {
            self.loadMoreControl.endRefreshing()
        }
        
        self.inputBarBottomMargin.constant = 0
        self.view.layoutIfNeeded()
        self.view.endEditing(true)
        self.isPresence = true
        self.navigationController?.setNavigationBarHidden(false , animated: false)
        self.isPresence = true
        self.emptyChatImage.image = Qiscus.image(named: "empty_messages")?.withRenderingMode(.alwaysTemplate)
        self.emptyChatImage.tintColor = self.bottomColor
        
        let sendImage = Qiscus.image(named: "send")?.withRenderingMode(.alwaysTemplate)
        let attachmentImage = Qiscus.image(named: "share_attachment")?.withRenderingMode(.alwaysTemplate)
        let recordImage = Qiscus.image(named: "ar_record")?.withRenderingMode(.alwaysTemplate)
        let cancelRecordImage = Qiscus.image(named: "ar_cancel")?.withRenderingMode(.alwaysTemplate)
        
        self.sendButton.setImage(sendImage, for: .normal)
        self.attachButton.setImage(attachmentImage, for: .normal)
        self.recordButton.setImage(recordImage, for: .normal)
        self.cancelRecordButton.setImage(cancelRecordImage, for: .normal)
        
        self.cancelRecordButton.isHidden = true
        
        self.sendButton.tintColor = Qiscus.shared.styleConfiguration.color.topColor
        self.attachButton.tintColor = Qiscus.shared.styleConfiguration.color.topColor
        self.recordButton.tintColor = Qiscus.shared.styleConfiguration.color.topColor
        self.cancelRecordButton.tintColor = Qiscus.shared.styleConfiguration.color.topColor
        self.bottomButton.tintColor = Qiscus.shared.styleConfiguration.color.topColor
        
        if self.inputText.value == "" {
            self.sendButton.isHidden = true
            self.recordButton.isHidden = false
        }else{
            self.sendButton.isHidden = false
            self.recordButton.isHidden = true
        }
        
        if self.room != nil && !firstLoad {
            if let newRoom = QiscusRoom.room(withId: self.room!.roomId){
                self.room = newRoom
            }
        }
        if !self.isLastRowVisible {
            self.bottomButton.isHidden = false
        }else{
            self.bottomButton.isHidden = true
        }
        if self.comments.count > 0 {
            self.welcomeView.isHidden = true
        }
        setupNavigationTitle()
        setupPage()
    }
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.room == nil{
            self.showLoading("Load data ...")
            //            self.room = nil
            self.loadData()
        }
    }
    
    // MARK: - Memory Warning
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Setup UI
    func setupNavigationTitle(){
        var totalButton = 1
        if let leftButtons = self.navigationItem.leftBarButtonItems {
            totalButton += leftButtons.count
        }
        if let rightButtons = self.navigationItem.rightBarButtonItems {
            totalButton += rightButtons.count
        }
        
        let titleWidth = QiscusHelper.screenWidth() - CGFloat(49 * totalButton) - 40
        
        titleLabel = UILabel(frame:CGRect(x: 40, y: 7, width: titleWidth, height: 17))
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)
        titleLabel.text = self.navTitle
        titleLabel.textAlignment = .left
        
        subtitleLabel = UILabel(frame:CGRect(x: 40, y: 25, width: titleWidth, height: 13))
        subtitleLabel.backgroundColor = UIColor.clear
        subtitleLabel.textColor = UIColor.white
        subtitleLabel.font = UIFont.systemFont(ofSize: 11)
        subtitleLabel.text = self.navSubtitle
        subtitleLabel.textAlignment = .left
        
        self.roomAvatar = UIImageView()
        self.roomAvatar.contentMode = .scaleAspectFill
        self.roomAvatar.backgroundColor = UIColor.white
        
        let image = Qiscus.image(named: "room_avatar")
        
        
        if let chatRoom = self.room{
            if let avatar = chatRoom.avatarImage {
                self.roomAvatar.image = avatar
            }else{
                self.roomAvatar.loadAsync(chatRoom.roomAvatarURL, placeholderImage: image)
            }
        }
        
        self.roomAvatar.frame = CGRect(x: 0,y: 6,width: 32,height: 32)
        self.roomAvatar.layer.cornerRadius = 16
        self.roomAvatar.clipsToBounds = true
        
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: titleWidth + 40, height: 44))
        titleView.addSubview(self.titleLabel)
        titleView.addSubview(self.subtitleLabel)
        titleView.addSubview(self.roomAvatar)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(QiscusChatVC.goToTitleAction))
        titleView.addGestureRecognizer(tapRecognizer)
        
        self.navigationItem.titleView = titleView
    }
    func setupPage(){
        archievedNotifView.isHidden = !archived
        self.archievedNotifTop.constant = 0
        if archived {
            self.archievedNotifLabel.text = QiscusTextConfiguration.sharedInstance.readOnlyText
        }else{
            self.archievedNotifTop.constant = 65
        }
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        self.archievedNotifView.backgroundColor = QiscusColorConfiguration.sharedInstance.lockViewBgColor
        self.archievedNotifLabel.textColor = QiscusColorConfiguration.sharedInstance.lockViewTintColor
        let unlockImage = Qiscus.image(named: "ic_open_archived")?.withRenderingMode(.alwaysTemplate)
        self.unlockButton.setBackgroundImage(unlockImage, for: UIControlState())
        self.unlockButton.tintColor = QiscusColorConfiguration.sharedInstance.lockViewTintColor
        
        self.collectionView.register(UINib(nibName: "QChatHeaderCell",bundle: Qiscus.bundle), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "cellHeader")
        self.collectionView.register(UINib(nibName: "QChatFooterLeft",bundle: Qiscus.bundle), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "cellFooterLeft")
        self.collectionView.register(UINib(nibName: "QChatFooterRight",bundle: Qiscus.bundle), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "cellFooterRight")
        self.collectionView.register(UINib(nibName: "QCellTextLeft",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellTextLeft")
        self.collectionView.register(UINib(nibName: "QCellTextRight",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellTextRight")
        self.collectionView.register(UINib(nibName: "QCellMediaLeft",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellMediaLeft")
        self.collectionView.register(UINib(nibName: "QCellMediaRight",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellMediaRight")
        self.collectionView.register(UINib(nibName: "QCellAudioLeft",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellAudioLeft")
        self.collectionView.register(UINib(nibName: "QCellAudioRight",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellAudioRight")
        self.collectionView.register(UINib(nibName: "QCellFileLeft",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellFileLeft")
        self.collectionView.register(UINib(nibName: "QCellFileRight",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellFileRight")
        
        self.loadMoreControl.addTarget(self, action: #selector(QiscusChatVC.loadMore), for: UIControlEvents.valueChanged)
        self.collectionView.addSubview(self.loadMoreControl)
        
        self.navigationController?.navigationBar.verticalGradientColor(topColor, bottomColor: bottomColor)
        self.navigationController?.navigationBar.tintColor = tintColor
        
        let backButton = QiscusChatVC.backButton(self, action: #selector(QiscusChatVC.goBack))
        self.defaultBackButtonVisibility = self.navigationItem.hidesBackButton
        
        if self.navigationItem.leftBarButtonItems != nil {
            self.defaultLeftButton = self.navigationItem.leftBarButtonItems
        }else{
            self.defaultLeftButton = nil
        }
        
        self.navigationItem.setHidesBackButton(true, animated: false)
        
        self.navigationItem.leftBarButtonItems = [backButton]
        
        
        if inputText.value == "" {
            sendButton.isEnabled = false
        }else{
            sendButton.isEnabled = true
        }
        sendButton.addTarget(self, action: #selector(QiscusChatVC.sendMessage), for: .touchUpInside)
        recordButton.addTarget(self, action: #selector(QiscusChatVC.recordVoice), for: .touchUpInside)
        cancelRecordButton.addTarget(self, action: #selector(QiscusChatVC.cancelRecordVoice), for: .touchUpInside)
        
        //welcomeView Setup
        self.unlockButton.addTarget(self, action: #selector(QiscusChatVC.confirmUnlockChat), for: .touchUpInside)
        
        
        self.welcomeText.text = QiscusTextConfiguration.sharedInstance.emptyTitle
        self.welcomeSubtitle.text = QiscusTextConfiguration.sharedInstance.emptyMessage
        self.emptyChatImage.image = Qiscus.style.assets.emptyChat
        if self.comments.count == 0 {
            self.welcomeView.isHidden = false
        }
        self.inputText.placeholder = QiscusTextConfiguration.sharedInstance.textPlaceholder
        self.inputText.chatInputDelegate = self
        
        // Keyboard stuff.
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(QiscusChatVC.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        center.addObserver(self, selector: #selector(QiscusChatVC.keyboardChange(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        center.addObserver(self, selector: #selector(QiscusChatVC.appDidEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        self.hideKeyboardWhenTappedAround()
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
    // MARK: - Keyboard Methode
    func keyboardWillHide(_ notification: Notification){
        let info: NSDictionary = (notification as NSNotification).userInfo! as NSDictionary
        
        let animateDuration = info[UIKeyboardAnimationDurationUserInfoKey] as! Double
        let goToRow = self.lastVisibleRow
        self.inputBarBottomMargin.constant = 0
        UIView.animate(withDuration: animateDuration, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.view.layoutIfNeeded()
            if goToRow != nil {
                self.scrollToIndexPath(goToRow!, position: .bottom, animated: true, delayed:  false)
            }
        }, completion: nil)
    }
    func keyboardChange(_ notification: Notification){
        let info:NSDictionary = (notification as NSNotification).userInfo! as NSDictionary
        let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        let keyboardHeight: CGFloat = keyboardSize.height
        let animateDuration = info[UIKeyboardAnimationDurationUserInfoKey] as! Double
        self.inputBarBottomMargin.constant = 0 - keyboardHeight
        UIView.animate(withDuration: animateDuration, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.view.layoutIfNeeded()
            if self.isLastRowVisible {
                let delay = 0.1 * Double(NSEC_PER_SEC)
                let time = DispatchTime.now() + Double(Int(delay)) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: time, execute: {
                    if self.comments.count > 0 {
                        self.scrollToBottom()
                    }
                })
            }
        }, completion: nil)
    }
    
    
    
    func scrollToBottom(_ animated:Bool = false){
        self.collectionView.performBatchUpdates({}, completion: { _ in
            let bottomPoint = CGPoint(x: 0, y: self.collectionView.contentSize.height - self.collectionView.bounds.size.height)
            
            if self.collectionView.contentSize.height > self.collectionView.bounds.size.height{
                self.collectionView.setContentOffset(bottomPoint, animated: animated)
            }
            self.isLastRowVisible = true
        })
    }
    func scrollToIndexPath(_ indexPath:IndexPath, position: UICollectionViewScrollPosition, animated:Bool, delayed:Bool = true){
        
        if !delayed {
            self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
        }else{
            let delay = 0.1 * Double(NSEC_PER_SEC)
            let time = DispatchTime.now() + Double(Int(delay)) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: time, execute: {
                if self.comments.count > 0 {
                    self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
                }
            })
        }
    }
    // MARK: - Navigation Action
    func rightLeftButtonAction(_ sender: AnyObject) {
    }
    func righRightButtonAction(_ sender: AnyObject) {
    }
    func goBack() {
        self.isPresence = false
        if self.backAction != nil{
            self.backAction!()
            //self.reset()
        }else{
            if Qiscus.sharedInstance.isPushed {
                let _ = self.navigationController?.popViewController(animated: true)
            }else{
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
            //self.reset()
        }
    }
    
    // MARK: - Load DataSource on firstTime
    func loadData(){
        //self.showLoading("Load Data ...")
        if newRoom && (self.users != nil){
            dataPresenter.loadComments(inNewGroupChat: users!, optionalData: self.optionalData, withMessage: self.message)
        }else{
            if loadWithUser && users != nil{
                if users!.count == 1 {
                    dataPresenter.loadComments(inRoomWithUsers: users![0], optionalData: optionalData, withMessage: message, distinctId: distincId)
                }else{
                    self.dismissLoading()
                }
            }else if roomId != nil{
                dataPresenter.loadComments(inRoom: roomId!, withMessage: message)
            }
        }
    }
    
    open func scrollToBotomFromNoData(){
        let delay = 0.1 * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int(delay)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time, execute: {
            if self.comments.count > 0 {
                self.scrollToBottom()
                self.collectionView.isHidden = false
            }
        })
    }
    
    // MARK: - Button Action
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
    func sendMessage(){
        Qiscus.logicThread.async {
            if Qiscus.sharedInstance.connected{
                if !self.isRecording {
                    let value = self.inputText.value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    var indexPath = IndexPath(row: 0, section: 0)
                    
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
                        self.commentClient.postMessage(message: value, topicId: chatRoom.roomLastCommentTopicId, linkData: self.linkData, indexPath: indexPath)
                    }
                    self.inputText.clearValue()
                    self.showLink = false
                    Qiscus.uiThread.async {
                        self.inputText.text = ""
                        self.minInputHeight.constant = 32
                        self.sendButton.isEnabled = false
                        self.inputText.layoutIfNeeded()
                    }
                }else{
                    
                    self.finishRecording()
                }
            }else{
                Qiscus.uiThread.async {
                    self.showNoConnectionToast()
                    if self.isRecording {
                        self.cancelRecordVoice()
                    }
                }
            }
        }
    }
    func uploadImage(){
        self.view.endEditing(true)
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
        self.view.endEditing(true)
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
            self.continueImageUpload(imageName: fileName, imageNSData: fileContent, audioFile: true)
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
    
    // MARK: - Upload Action
    func continueImageUpload(_ image:UIImage? = nil,imageName:String,imagePath:URL? = nil, imageNSData:Data? = nil, videoFile:Bool = false, audioFile:Bool = false){
        if let chatRoom = self.room{
            if Qiscus.sharedInstance.connected{
                self.dataPresenter.newMediaMessage(chatRoom.roomLastCommentTopicId, image: image, imageName: imageName, imagePath: imagePath, imageNSData: imageNSData, videoFile: videoFile, audioFile:audioFile)
            }else{
                self.showNoConnectionToast()
            }
        }
    }
    
    // MARK: - Load More Control
    func loadMore(){
        if self.room != nil {
            if Qiscus.shared.connected{
                var firstCommentId = Int(0)
                if self.comments.count > 0 {
                    firstCommentId = self.comments.first!.first!.commentId
                }
                dataPresenter.loadMore(inRoom: self.room!, fromComment: firstCommentId)
            }else{
                self.showNoConnectionToast()
                self.loadMoreControl.endRefreshing()
            }
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
    
    func showAlert(alert:UIAlertController){
        self.present(alert, animated: true, completion: nil)
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
    func showNoConnectionToast(){
        QToasterSwift.toast(target: self, text: QiscusTextConfiguration.sharedInstance.noConnectionText, backgroundColor: UIColor(red: 0.9, green: 0,blue: 0,alpha: 0.8), textColor: UIColor.white)
    }
    
    // MARK: - Galery Function
    public func galleryConfiguration()-> GalleryConfiguration{
        let closeButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 20, height: 20)))
        closeButton.setImage(Qiscus.image(named: "close")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
        closeButton.tintColor = UIColor.white
        closeButton.imageView?.contentMode = .scaleAspectFit
        
        let seeAllButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 20, height: 20)))
        seeAllButton.setTitle("", for: UIControlState())
        seeAllButton.setImage(Qiscus.image(named: "viewmode")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
        seeAllButton.tintColor = UIColor.white
        seeAllButton.imageView?.contentMode = .scaleAspectFit
        
        return [
            GalleryConfigurationItem.closeButtonMode(.custom(closeButton)),
            GalleryConfigurationItem.thumbnailsButtonMode(.custom(seeAllButton))
        ]
    }
    
    
    func loadTitle(){
        Qiscus.logicThread.async {
            let title = QiscusUIConfiguration.sharedInstance.copyright.chatTitle
            var navTitle = ""
            if title != ""{
                navTitle = title
            }else{
                if self.room != nil{
                    navTitle = self.room!.roomName
                }
            }
            Qiscus.uiThread.async {
                self.titleLabel.text = navTitle
            }
            self.loadSubtitle()
        }
    }
    func loadSubtitle(){
        Qiscus.logicThread.async {
            let subtitle = QiscusTextConfiguration.sharedInstance.chatSubtitle
            
            var navSubtitle = subtitle
            if subtitle == "" {
                if let targetRoom = self.room {
                    if targetRoom.roomType == .group {
                        if targetRoom.participants.count > 0{
                            for participant in targetRoom.participants {
                                if participant.participantEmail != QiscusConfig.sharedInstance.USER_EMAIL{
                                    if let user = QiscusUser.getUserWithEmail(participant.participantEmail){
                                        if navSubtitle == "" {
                                            navSubtitle = "You, \(user.userFullName)"
                                        }else{
                                            navSubtitle += ", \(user.userFullName)"
                                        }
                                    }
                                }
                            }
                        }
                    }else{
                        if targetRoom.participants.count > 0 {
                            for participant in targetRoom.participants {
                                if participant.participantEmail != QiscusConfig.sharedInstance.USER_EMAIL{
                                    if let user = QiscusUser.getUserWithEmail(participant.participantEmail){
                                        if user.isOnline {
                                            navSubtitle = "is online"
                                        }else if user.userLastSeen == Double(0){
                                            navSubtitle = "is offline"
                                        }else{
                                            navSubtitle = "last seen: \(user.lastSeenString)"
                                        }
                                    }
                                    break
                                }
                            }
                        }else{
                            navSubtitle = "not available"
                        }
                    }
                }
            }
            Qiscus.uiThread.async {
                self.subtitleLabel.text = navSubtitle
            }
        }
    }
    func setTitle(title:String = "", withSubtitle:String? = nil){
        QiscusUIConfiguration.sharedInstance.copyright.chatTitle = title
        if withSubtitle != nil {
            QiscusUIConfiguration.sharedInstance.copyright.chatSubtitle = withSubtitle!
        }
        self.loadTitle()
    }
    func startTypingIndicator(withUser user:String){
        Qiscus.logicThread.async {
            self.typingIndicatorUser = user
            self.isTypingOn = true
            let typingText = "\(user) is typing ..."
            Qiscus.uiThread.async {
                self.subtitleLabel.text = typingText
            }
            if self.remoteTypingTimer != nil {
                if self.remoteTypingTimer!.isValid {
                    self.remoteTypingTimer?.invalidate()
                    //self.remoteTypingTimer = nil
                }
            }
            Qiscus.uiThread.sync {
                self.remoteTypingTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(self.stopTypingIndicator), userInfo: nil, repeats: false)
            }
        }
    }
    func stopTypingIndicator(){
        self.typingIndicatorUser = ""
        self.isTypingOn = false
        if self.remoteTypingTimer != nil {
            self.remoteTypingTimer?.invalidate()
            self.remoteTypingTimer = nil
        }
        Qiscus.logicThread.async {
            self.loadSubtitle()
        }
    }
    
    func subscribeRealtime(onRoom room:QiscusRoom?){
        if room != nil {
            let typingChannel:String = "r/\(room!.roomId)/\(room!.roomLastCommentTopicId)/+/t"
            let readChannel:String = "r/\(room!.roomId)/\(room!.roomLastCommentTopicId)/+/r"
            let deliveryChannel:String = "r/\(room!.roomId)/\(room!.roomLastCommentTopicId)/+/r"
            Qiscus.shared.mqtt?.subscribe(typingChannel, qos: .qos1)
            Qiscus.shared.mqtt?.subscribe(readChannel, qos: .qos1)
            Qiscus.shared.mqtt?.subscribe(deliveryChannel, qos: .qos1)
        }
    }
    func unsubscribeTypingRealtime(onRoom room:QiscusRoom?){
        if room != nil {
            let channel = "r/\(room!.roomId)/\(room!.roomLastCommentTopicId)/+/t"
            Qiscus.shared.mqtt?.unsubscribe(channel)
        }
    }
    func appDidEnterBackground(){
        self.view.endEditing(true)
        self.dismissLoading()
    }
    open func resendMessage(){
        
    }
    
    
    // MARK: AVAudioPlayerDelegate
    
    
    
    // MARK: - UICollectionViewDelegate
    
    @IBAction func goToBottomTapped(_ sender: UIButton) {
        scrollToBottom(true)
    }
    func publishRead(){
        Qiscus.logicThread.async {
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
    }
    @IBAction func hideLinkPreview(_ sender: UIButton) {
        permanentlyDisableLink = true
        showLink = false
    }
    func getLinkPreview(url:String){
        var urlToCheck = url.lowercased()
        if !urlToCheck.contains("http"){
            urlToCheck = "http://\(url.lowercased())"
        }
        commentClient.getLinkMetadata(url: urlToCheck, withCompletion: {linkData in
            Qiscus.uiThread.async {
                self.linkImage.loadAsync(linkData.linkImageURL, placeholderImage: Qiscus.image(named: "link"))
                self.linkDescription.text = linkData.linkDescription
                self.linkTitle.text = linkData.linkTitle
                self.linkData = linkData
                self.linkPreviewTopMargin.constant = -65
                UIView.animate(withDuration: 0.65, animations: {
                    self.view.layoutIfNeeded()
                }, completion: nil)
            }
        }, withFailCompletion: {
            self.showLink = false
        })
    }
    func hideLinkContainer(){
        Qiscus.uiThread.async {
            self.linkPreviewTopMargin.constant = 0
            UIView.animate(withDuration: 0.65, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    // MARK: - Overriding back action
    public func setBackButton(withAction action:@escaping (()->Void)){
        self.backAction = action
    }
    
    //MARK: -reset chat view
    func reset(){
        self.firstLoad = true
        self.topicId = nil
        self.users = nil
        self.roomId = nil
        self.distincId = ""
        self.optionalData = nil
        self.message = nil
        self.newRoom = false
        self.comments = [[QiscusCommentPresenter]]()
        if audioPlayer != nil{
            audioPlayer?.stop()
        }
        self.backAction = nil
        self.titleAction = {}
        self.unlockAction = {}
        self.room = nil
        self.collectionView.reloadData()
    }
    
    @IBAction func showAttcahMenu(_ sender: UIButton) {
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
}
