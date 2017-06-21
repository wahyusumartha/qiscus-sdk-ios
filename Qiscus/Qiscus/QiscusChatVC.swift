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
    @IBOutlet weak var linkCancelButton: UIButton!
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
    @IBOutlet weak var linkImageWidth: NSLayoutConstraint!
    
    var isPresence:Bool = false
    var titleLabel = UILabel()
    var subtitleLabel = UILabel()
    var isBeforeTranslucent = false
    // MARK: - shared Properties
    var commentClient = QiscusCommentClient.sharedInstance
    let dataPresenter = QiscusDataPresenter.shared
    var archived:Bool = QiscusUIConfiguration.sharedInstance.readOnly
    
    var replyData:QiscusCommentPresenter? = nil {
        didSet{
            if replyData == nil {
                Qiscus.uiThread.async {
                    self.linkPreviewTopMargin.constant = 0
                    UIView.animate(withDuration: 0.65, animations: {
                        self.view.layoutIfNeeded()
                    }, completion: {(_) in
                        if self.inputText.value == "" {
                            self.sendButton.isEnabled = false
                            self.sendButton.isHidden = true
                            self.recordButton.isHidden = false
                            self.linkImage.image = nil
                        }
                    })
                }
            }else{
                Qiscus.uiThread.async {

                    if self.replyData!.commentType == .text || self.replyData!.commentType == .reply {
                        self.linkDescription.text = self.replyData!.commentText
                        self.linkImageWidth.constant = 0
                    }else{
                        if self.replyData!.commentType == .video || self.replyData!.commentType == .image {
                            if QiscusHelper.isFileExist(inLocalPath: self.replyData!.localThumbURL!){
                                self.linkImage.loadAsync(fromLocalPath: self.replyData!.localThumbURL!, onLoaded: { (image, _) in
                                    self.linkImage.image = image
                                })
                            }else if QiscusHelper.isFileExist(inLocalPath: self.replyData!.localMiniThumbURL!){
                               self.linkImage.loadAsync(fromLocalPath: self.replyData!.localMiniThumbURL!, onLoaded: { (image, _) in
                                    self.linkImage.image = image
                                })
                            }else{
                                self.linkImage.loadAsync(self.replyData!.remoteThumbURL!, onLoaded: { (image, _) in
                                    self.linkImage.image = image
                                })
                            }
                            self.linkImageWidth.constant = 55
                        }else{
                        
                        }
                        self.linkDescription.text = self.replyData!.fileName
                    }
                    
                    self.linkTitle.text = self.replyData!.userFullName
                    self.linkPreviewTopMargin.constant = -65
                    UIView.animate(withDuration: 0.35, animations: {
                        self.view.layoutIfNeeded()
                        if let goToRow = self.lastVisibleRow {
                            self.scrollToIndexPath(goToRow, position: .bottom, animated: true, delayed: false)
                        }
                    }, completion: { (_) in
                        if self.inputText.value == "" {
                            self.sendButton.isEnabled = false
                        }else{
                            self.sendButton.isEnabled = true
                        }
                        self.sendButton.isHidden = false
                        self.recordButton.isHidden = true
                    })
                }
            }
        }
    }
    
    public var defaultBack:Bool = true
    
    // MARK: - Data Properties
    var room:QiscusRoom?{
        didSet{
            if oldValue == nil{
                if let chatRoom = room{
                    let _ = self.view
                    self.loadMoreControl.removeFromSuperview()
                    if chatRoom.hasLoadMore {
                        self.loadMoreControl = UIRefreshControl()
                        self.loadMoreControl.addTarget(self, action: #selector(QiscusChatVC.loadMore), for: UIControlEvents.valueChanged)
                        self.collectionView.addSubview(self.loadMoreControl)
                    }
                    self.loadTitle()
                    let image = Qiscus.image(named: "room_avatar")
                    if QiscusHelper.isFileExist(inLocalPath: chatRoom.roomAvatarLocalPath){
                        self.roomAvatar.loadAsync(fromLocalPath: chatRoom.roomAvatarLocalPath)
                    }else{
                        self.roomAvatar.loadAsync(chatRoom.roomAvatarURL, placeholderImage: image)
                    }
                    self.subscribeRealtime(onRoom: chatRoom)
                }
            }
        }
    }
    var hasMoreComment = true
    var comments = [[QiscusCommentPresenter]]()
    var loadMoreControl = UIRefreshControl()
    
    // MARK: - External data configuration
    var topicId:Int?
    
    var users:[String]?
    var roomId:Int?
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
    public var navTitle:String = ""
    public var navSubtitle:String = ""
    
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
            if indexPaths.count > 0 {
                var lastIndexpath = indexPaths.first!
                var i = 0
                for indexPath in indexPaths {
                    if indexPath.section > lastIndexpath.section {
                        lastIndexpath.section = indexPath.section
                        lastIndexpath.row = indexPath.row
                    }else if indexPath.section == lastIndexpath.section {
                        if indexPath.row > lastIndexpath.row {
                            lastIndexpath.row = indexPath.row
                        }
                    }
                    i += 1
                }
                return lastIndexpath
            }else{
                return nil
            }
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
        if self.comments.count == 0{
            self.showLoading("Load data ...")
            DispatchQueue.global().async {
                self.loadData()
            }
        }
        let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        layout?.sectionHeadersPinToVisibleBounds = true
        layout?.sectionFootersPinToVisibleBounds = true
        let resendMenuItem: UIMenuItem = UIMenuItem(title: "Resend", action: #selector(QChatCell.resend))
        let deleteMenuItem: UIMenuItem = UIMenuItem(title: "Delete", action: #selector(QChatCell.deleteComment))
        let replyMenuItem: UIMenuItem = UIMenuItem(title: "Reply", action: #selector(QChatCell.reply))
        let menuItems:[UIMenuItem] = [resendMenuItem,deleteMenuItem,replyMenuItem]
        UIMenuController.shared.menuItems = menuItems
        
        self.loadMoreControl.addTarget(self, action: #selector(QiscusChatVC.loadMore), for: UIControlEvents.valueChanged)
        self.collectionView.addSubview(self.loadMoreControl)
        
        self.navigationController?.navigationBar.verticalGradientColor(topColor, bottomColor: bottomColor)
        self.navigationController?.navigationBar.tintColor = tintColor
        
        
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
        linkCancelButton.tintColor = QiscusColorConfiguration.sharedInstance.rightBaloonColor
        linkCancelButton.setImage(Qiscus.image(named: "ar_cancel")?.withRenderingMode(.alwaysTemplate), for: .normal)
        roomAvatar.contentMode = .scaleAspectFill
        inputText.font = Qiscus.style.chatFont
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.emptyChatImage.tintColor = self.topColor
        
        if let _ = self.navigationController {
            //self.isBeforeTranslucent = navController.navigationBar.isTranslucent
            self.navigationController?.navigationBar.isTranslucent = false
            self.defaultNavBarVisibility = self.navigationController!.isNavigationBarHidden
        }
        self.roomSynced = false
        unreadIndexPath = [IndexPath]()
        bottomButton.isHidden = true
        
        
        if self.loadMoreControl.isRefreshing {
            self.loadMoreControl.endRefreshing()
        }
        
        self.inputBarBottomMargin.constant = 0
        self.view.layoutIfNeeded()
        //self.view.endEditing(true)
        
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
    override open func viewWillDisappear(_ animated: Bool) {
        self.isPresence = false
        dataPresenter.delegate = nil
        
        super.viewWillDisappear(animated)
        view.endEditing(true)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        view.endEditing(true)
        if self.room != nil{
            self.unsubscribeTypingRealtime(onRoom: room!)
        }
        self.roomSynced = false
        
        self.dismissLoading()
    }
    override open func viewDidDisappear(_ animated: Bool) {
        self.scrollToBottom()
    }
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.isPresence = true
        if self.comments.count > 0 {
            self.collectionView.reloadData()
            self.scrollToBottom()
        }
        if self.defaultBack {
            self.defaultBackButtonVisibility = self.navigationItem.hidesBackButton
        }
        if self.navigationItem.leftBarButtonItems != nil {
            self.defaultLeftButton = self.navigationItem.leftBarButtonItems
        }else{
            self.defaultLeftButton = nil
        }
        if let navController = self.navigationController {
            self.isBeforeTranslucent = navController.navigationBar.isTranslucent
            self.navigationController?.navigationBar.isTranslucent = false
            self.defaultNavBarVisibility = self.navigationController!.isNavigationBarHidden
        }
        self.navigationController?.setNavigationBarHidden(false , animated: false)
        
        if self.defaultBack {
            let backButton = QiscusChatVC.backButton(self, action: #selector(QiscusChatVC.goBack))

            self.navigationItem.setHidesBackButton(true, animated: false)
            self.navigationItem.leftBarButtonItems = [backButton]
        }
        if self.room != nil {
            self.loadTitle()
            self.subscribeRealtime(onRoom: self.room!)
        }
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.removeAllDeliveredNotifications() // To remove all delivered notifications
            center.removeAllPendingNotificationRequests()
        }else{
            UIApplication.shared.cancelAllLocalNotifications()
        }
        self.dataPresenter.delegate = self
        
        if Qiscus.shared.connected && self.room != nil{
            QiscusCommentClient.shared.syncRoom(withID: self.room!.roomId)
        }
        
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(QiscusChatVC.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        center.addObserver(self, selector: #selector(QiscusChatVC.keyboardChange(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        
        view.endEditing(true)
        center.addObserver(self, selector: #selector(QiscusChatVC.appDidEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
        self.collectionView.register(UINib(nibName: "QCellPostbackLeft",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellPostbackLeft")
        self.collectionView.register(UINib(nibName: "QCellTextRight",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellTextRight")
        self.collectionView.register(UINib(nibName: "QCellMediaLeft",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellMediaLeft")
        self.collectionView.register(UINib(nibName: "QCellMediaRight",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellMediaRight")
        self.collectionView.register(UINib(nibName: "QCellAudioLeft",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellAudioLeft")
        self.collectionView.register(UINib(nibName: "QCellAudioRight",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellAudioRight")
        self.collectionView.register(UINib(nibName: "QCellFileLeft",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellFileLeft")
        self.collectionView.register(UINib(nibName: "QCellFileRight",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellFileRight")
        
        
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
        self.inputText.placeholder = QiscusTextConfiguration.sharedInstance.textPlaceholder
        self.inputText.chatInputDelegate = self
        
        // Keyboard stuff.
        self.hideKeyboardWhenTappedAround()
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
        let goToRow = self.lastVisibleRow
        UIView.animate(withDuration: animateDuration, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.view.layoutIfNeeded()
            if goToRow != nil {
                self.scrollToIndexPath(goToRow!, position: .bottom, animated: true, delayed:  false)
            }
        }, completion: nil)
    }
    
    // MARK: - Navigation Action
    func rightLeftButtonAction(_ sender: AnyObject) {
    }
    func righRightButtonAction(_ sender: AnyObject) {
    }
    func goBack() {
        self.isPresence = false
        view.endEditing(true)
        if self.backAction != nil{
            self.backAction!()
        }else{
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - Button Action
    func appDidEnterBackground(){
        self.isPresence = false
        view.endEditing(true)
        self.dismissLoading()
    }
    open func resendMessage(){
        
    }
    
    @IBAction func goToBottomTapped(_ sender: UIButton) {
        scrollToBottom(true)
    }
    
    @IBAction func hideLinkPreview(_ sender: UIButton) {
        if replyData != nil {
            replyData = nil
        }else{
            permanentlyDisableLink = true
            showLink = false
        }
    }
    
    @IBAction func showAttcahMenu(_ sender: UIButton) {
        self.showAttachmentMenu()
    }
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionView.collectionViewLayout.invalidateLayout()
    }
}
