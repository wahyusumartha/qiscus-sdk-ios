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
import ContactsUI
import CoreLocation

//
import RealmSwift
open class QiscusChatVC: UIViewController{
    
    // MARK: - IBOutlet Properties
    @IBOutlet weak var inputBar: UIView!
    @IBOutlet public weak var backgroundView: UIImageView!
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
    @IBOutlet public weak var collectionView: UICollectionView!
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
    @IBOutlet public weak var collectionViewTopMargin: NSLayoutConstraint!
    
    var isPresence:Bool = false
    public var titleLabel = UILabel()
    public var subtitleLabel = UILabel()
    var roomAvatarImage:UIImage?
    public var roomAvatar = UIImageView()
    var roomAvatarLabel = UILabel()
    public var titleView = UIView()
    
    var isBeforeTranslucent = false
    // MARK: - shared Properties
    var commentClient = QiscusCommentClient.sharedInstance
    var archived:Bool = QiscusUIConfiguration.sharedInstance.readOnly
    
    var selectedCellIndex:IndexPath? = nil
    let locationManager = CLLocationManager()
    var didFindLocation = true
    var topComment:QComment?
    
    var replyData:QComment? = nil {
        didSet{
            if replyData == nil {
                Qiscus.uiThread.async { autoreleasepool{
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
                }}
            }
            else{
                Qiscus.uiThread.async {autoreleasepool{
                    print()
                    switch self.replyData!.type {
                    case .text:
                        self.linkDescription.text = self.replyData!.text
                        self.linkImageWidth.constant = 0
                        break
                    case .video, .image:
                        self.linkImage.contentMode = .scaleAspectFill
                        if let file = self.replyData!.file {
                            if self.replyData!.type == .video || self.replyData!.type == .image {
                                if QFileManager.isFileExist(inLocalPath: file.localThumbPath){
                                    self.linkImage.loadAsync(fromLocalPath: file.localThumbPath, onLoaded: { (image, _) in
                                        self.linkImage.image = image
                                    })
                                }
                                else if QFileManager.isFileExist(inLocalPath: file.localMiniThumbPath){
                                    self.linkImage.loadAsync(fromLocalPath: file.localMiniThumbPath, onLoaded: { (image, _) in
                                        self.linkImage.image = image
                                    })
                                }
                                else{
                                    self.linkImage.loadAsync(file.thumbURL, onLoaded: { (image, _) in
                                        self.linkImage.image = image
                                    })
                                }
                                self.linkImageWidth.constant = 55
                            }
                            self.linkDescription.text = file.filename
                        }
                        break
                    case .location:
                        let payload = JSON(parseJSON: self.replyData!.data)
                        self.linkImage.contentMode = .scaleAspectFill
                        self.linkImage.image = Qiscus.image(named: "map_ico")
                        self.linkImageWidth.constant = 55
                        self.linkDescription.text = "\(payload["name"].stringValue) - \(payload["address"].stringValue)"
                        break
                    case .contact:
                        let payload = JSON(parseJSON: self.replyData!.data)
                        self.linkImage.contentMode = .top
                        self.linkImage.image = Qiscus.image(named: "contact")
                        self.linkImageWidth.constant = 55
                        self.linkDescription.text = "\(payload["name"].stringValue) - \(payload["value"].stringValue)"
                        break
                    default:
                        break
                    }
                    
                    if let user = self.replyData!.sender {
                        self.linkTitle.text = user.fullname
                    }else{
                        self.linkTitle.text = self.replyData!.senderName
                    }
                    self.linkPreviewTopMargin.constant = -65
                    
                    UIView.animate(withDuration: 0.35, animations: {
                        self.view.layoutIfNeeded()
                        if self.lastVisibleRow != nil {
                            self.collectionView.scrollToItem(at: self.lastVisibleRow!, at: .bottom, animated: true)
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
                }}
            }
        }
    }
    
    public var defaultBack:Bool = true
    
    // MARK: - Data Properties
    var hasMoreComment = true // rmove
    var loadMoreControl = UIRefreshControl()
    
    // MARK: -  Data load configuration
    public var chatRoom:QRoom?{
        didSet{
            if oldValue == nil && self.chatRoom != nil {
                if Qiscus.shared.connected {
                    self.chatRoom?.sync()
                }
                //self.chatRoom!.delegate = self
                let delay = 0.5 * Double(NSEC_PER_SEC)
                let time = DispatchTime.now() + delay / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: time, execute: {
                    self.dismissLoading()
                    self.dataLoaded = true
                })
            }
        }
    }
    public var chatMessage:String?
    public var chatRoomId:Int?
    public var chatUser:String?
    public var chatTitle:String?{
        didSet{
            self.loadTitle()
        }
    }
    public var chatSubtitle:String?
    public var chatNewRoomUsers:[String] = [String]()
    var chatDistinctId:String?
    var chatData:String?
    public var chatRoomUniqueId:String?
    public var chatTarget:QComment?
    
    var chatAvatarURL = ""
    var chatService = QChatService()
    var collectionWidth:CGFloat = 0
    
    var topicId:Int? // will be removed
    
    var users:[String]? // will be removed
    var roomId:Int? // will be removed
    var distincId:String = "" // will be removed
    var optionalData:String? // will be removed
    var message:String? // will be removed
    var newRoom = false // will be removed
    var uniqueId = "" // will be removed
    var avatarURL = "" // will be removed
    var roomTitle = "" // will be removed
    
    var topColor = Qiscus.shared.styleConfiguration.color.topColor
    var bottomColor = Qiscus.shared.styleConfiguration.color.bottomColor
    var tintColor = Qiscus.shared.styleConfiguration.color.tintColor
    
    // MARK: Galery variable
    var galleryItems:[QiscusGalleryItem] = [QiscusGalleryItem]()
    
    var imagePreview:GalleryViewController?
    var loadWithUser:Bool = false // will be removed
    
    //MARK: - external action
    @objc public var unlockAction:(()->Void) = {}
    @objc public var titleAction:(()->Void) = {}
    @objc public var backAction:(()->Void)? = nil
    @objc public var forwardAction:((QComment)->Void)? = nil
    @objc public var infoAction:((QComment)->Void)? = nil
    
    var audioPlayer: AVAudioPlayer?
    var audioTimer: Timer?
    var activeAudioCell: QCellAudio?
    
    var cellDelegate:QiscusChatCellDelegate?
    var loadingView = QLoadingViewController.sharedInstance
    var typingIndicatorUser:String = ""
    var isTypingOn:Bool = false
    var linkData:QiscusLinkData?
    var roomName:String? // will be removed
    
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
    var publishStatusTimer:Timer? = nil
    var defaultBackButtonVisibility = true
    var defaultNavBarVisibility = true
    var defaultLeftButton:[UIBarButtonItem]? = nil
    
    // navigation
    public var navTitle:String = ""
    public var navSubtitle:String = ""
    var dataLoaded = false
    
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
    
    var isLastRowVisible: Bool = false {
        didSet{
            bottomButton.isHidden = isLastRowVisible
            if self.chatRoom!.unreadCommentCount > 0 {
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
    var contactVC = CNContactPickerViewController()
    
    public init() {
        super.init(nibName: "QiscusChatVC", bundle: Qiscus.bundle)
        let _ = self.view
        self.collectionView.register(UINib(nibName: "QChatHeaderCell",bundle: Qiscus.bundle), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "cellHeader")
        self.collectionView.register(UINib(nibName: "QChatFooterLeft",bundle: Qiscus.bundle), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "cellFooterLeft")
        self.collectionView.register(UINib(nibName: "QChatFooterRight",bundle: Qiscus.bundle), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "cellFooterRight")
        self.collectionView.register(UINib(nibName: "QCellSystem",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellSystem")
        self.collectionView.register(UINib(nibName: "QCellCardLeft",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellCardLeft")
        self.collectionView.register(UINib(nibName: "QCellCardRight",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellCardRight")
        self.collectionView.register(UINib(nibName: "QCellTextLeft",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellTextLeft")
        self.collectionView.register(UINib(nibName: "QCellPostbackLeft",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellPostbackLeft")
        self.collectionView.register(UINib(nibName: "QCellTextRight",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellTextRight")
        self.collectionView.register(UINib(nibName: "QCellMediaLeft",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellMediaLeft")
        self.collectionView.register(UINib(nibName: "QCellMediaRight",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellMediaRight")
        self.collectionView.register(UINib(nibName: "QCellAudioLeft",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellAudioLeft")
        self.collectionView.register(UINib(nibName: "QCellAudioRight",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellAudioRight")
        self.collectionView.register(UINib(nibName: "QCellFileLeft",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellFileLeft")
        self.collectionView.register(UINib(nibName: "QCellFileRight",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellFileRight")
        self.collectionView.register(UINib(nibName: "QCellContactRight",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellContactRight")
        self.collectionView.register(UINib(nibName: "QCellContactLeft",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellContactLeft")
        self.collectionView.register(UINib(nibName: "QCellLocationRight",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellLocationRight")
        self.collectionView.register(UINib(nibName: "QCellLocationLeft",bundle: Qiscus.bundle), forCellWithReuseIdentifier: "cellLocationLeft")
        let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        layout?.sectionHeadersPinToVisibleBounds = true
        layout?.sectionFootersPinToVisibleBounds = true
        
        self.loadMoreControl.addTarget(self, action: #selector(QiscusChatVC.loadMore), for: UIControlEvents.valueChanged)
        self.collectionView.addSubview(self.loadMoreControl)
        
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
        
        self.emptyChatImage.image = QiscusAssetsConfiguration.shared.emptyChat
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
        self.bottomButton.isHidden = true
        
        sendButton.addTarget(self, action: #selector(QiscusChatVC.sendMessage), for: .touchUpInside)
        recordButton.addTarget(self, action: #selector(QiscusChatVC.recordVoice), for: .touchUpInside)
        cancelRecordButton.addTarget(self, action: #selector(QiscusChatVC.cancelRecordVoice), for: .touchUpInside)
        
        
        self.unlockButton.addTarget(self, action: #selector(QiscusChatVC.confirmUnlockChat), for: .touchUpInside)
        
        self.welcomeText.text = QiscusTextConfiguration.sharedInstance.emptyTitle
        self.welcomeSubtitle.text = QiscusTextConfiguration.sharedInstance.emptyMessage
        self.emptyChatImage.image = Qiscus.style.assets.emptyChat
        self.inputText.placeholder = QiscusTextConfiguration.sharedInstance.textPlaceholder
        self.inputText.chatInputDelegate = self
        
        // Keyboard stuff.
        self.hideKeyboardWhenTappedAround()
        
        unreadIndexPath = [IndexPath]()
        bottomButton.isHidden = true
        
        
        if self.loadMoreControl.isRefreshing {
            self.loadMoreControl.endRefreshing()
        }
        
        self.inputBarBottomMargin.constant = 0
        
        self.archievedNotifView.backgroundColor = QiscusColorConfiguration.sharedInstance.lockViewBgColor
        self.archievedNotifLabel.textColor = QiscusColorConfiguration.sharedInstance.lockViewTintColor
        let unlockImage = Qiscus.image(named: "ic_open_archived")?.withRenderingMode(.alwaysTemplate)
        self.unlockButton.setBackgroundImage(unlockImage, for: UIControlState())
        self.unlockButton.tintColor = QiscusColorConfiguration.sharedInstance.lockViewTintColor
        
        self.view.layoutIfNeeded()
        
        let titleWidth = QiscusHelper.screenWidth()
        
        titleLabel = UILabel(frame:CGRect(x: 40, y: 7, width: titleWidth, height: 17))
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = self.tintColor
        titleLabel.font = UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)
        titleLabel.text = self.chatTitle
        titleLabel.textAlignment = .left
        
        subtitleLabel = UILabel(frame:CGRect(x: 40, y: 25, width: titleWidth, height: 13))
        subtitleLabel.backgroundColor = UIColor.clear
        subtitleLabel.textColor = self.tintColor
        subtitleLabel.font = UIFont.systemFont(ofSize: 11)
        subtitleLabel.text = self.chatSubtitle
        subtitleLabel.textAlignment = .left
        
        self.roomAvatarLabel = UILabel(frame:CGRect(x: 0,y: 6,width: 32,height: 32))
        self.roomAvatarLabel.font = UIFont.boldSystemFont(ofSize: 25)
        self.roomAvatarLabel.textColor = UIColor.white
        self.roomAvatarLabel.backgroundColor = UIColor.clear
        self.roomAvatarLabel.text = "Q"
        self.roomAvatarLabel.textAlignment = .center
        
        self.roomAvatar = UIImageView()
        self.roomAvatar.contentMode = .scaleAspectFill
        self.roomAvatar.backgroundColor = UIColor.white
        
        let bgColor = QiscusColorConfiguration.sharedInstance.avatarBackgroundColor
        
        self.roomAvatar.frame = CGRect(x: 0,y: 6,width: 32,height: 32)
        self.roomAvatar.layer.cornerRadius = 16
        self.roomAvatar.clipsToBounds = true
        self.roomAvatar.backgroundColor = bgColor[0]
        
        self.titleView = UIView(frame: CGRect(x: 0, y: 0, width: titleWidth + 40, height: 44))
        self.titleView.addSubview(self.titleLabel)
        self.titleView.addSubview(self.subtitleLabel)
        self.titleView.addSubview(self.roomAvatar)
        self.titleView.addSubview(self.roomAvatarLabel)
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Lifecycle
    override open func viewDidLoad() {
        super.viewDidLoad()
        
    }
    private func firstLoadSetup(){
        self.chatService.delegate = self
        
        let resendMenuItem: UIMenuItem = UIMenuItem(title: "Resend", action: #selector(QChatCell.resend))
        let deleteMenuItem: UIMenuItem = UIMenuItem(title: "Delete", action: #selector(QChatCell.deleteComment))
        let replyMenuItem: UIMenuItem = UIMenuItem(title: "Reply", action: #selector(QChatCell.reply))
        
        var menuItems:[UIMenuItem] = [resendMenuItem,deleteMenuItem,replyMenuItem]
        if self.forwardAction != nil {
            let forwardMenuItem: UIMenuItem = UIMenuItem(title: "Forward", action: #selector(QChatCell.forward))
            menuItems.append(forwardMenuItem)
        }
        if self.infoAction != nil {
            let infoMenuItem: UIMenuItem = UIMenuItem(title: "Info", action: #selector(QChatCell.info))
            menuItems.append(infoMenuItem)
        }
        let shareMenuItem: UIMenuItem = UIMenuItem(title: "Share", action: #selector(QChatCell.share))
        menuItems.append(shareMenuItem)

        UIMenuController.shared.menuItems = menuItems
        
        //self.navigationController?.navigationBar.verticalGradientColor(topColor, bottomColor: bottomColor)
        //self.navigationController?.navigationBar.tintColor = tintColor
        
        if let _ = self.navigationController {
            //self.isBeforeTranslucent = navController.navigationBar.isTranslucent
            self.navigationController?.navigationBar.isTranslucent = false
            self.defaultNavBarVisibility = self.navigationController!.isNavigationBarHidden
        }
        
        setupNavigationTitle()
        
        setupPage()
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        self.isPresence = false
        self.dataLoaded = false
        super.viewWillDisappear(animated)
        view.endEditing(true)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        view.endEditing(true)
        
        self.dismissLoading()
    }
    override open func viewDidDisappear(_ animated: Bool) {
        //self.scrollToBottom()
    }
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
        
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.removeAllDeliveredNotifications() // To remove all delivered notifications
            center.removeAllPendingNotificationRequests()
        }else{
            UIApplication.shared.cancelAllLocalNotifications()
        }
        
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(QiscusChatVC.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        center.addObserver(self, selector: #selector(QiscusChatVC.keyboardChange(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        
        view.endEditing(true)
        center.addObserver(self, selector: #selector(QiscusChatVC.appDidEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        if firstLoad {
            self.firstLoadSetup()
            self.collectionView.isHidden = true
            self.showLoading("Load data ...")
        }
        if inputText.value == "" {
            sendButton.isEnabled = false
            sendButton.isHidden = true
            recordButton.isHidden = false
        }else{
            sendButton.isEnabled = true
        }
        self.chatRoom?.updateUnreadCommentCount(count: 0)
    }
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.chatRoom == nil {
            self.collectionView.isHidden = true
            self.loadData()
        }else if self.firstLoad {
            self.loadRoomView()
            if self.chatRoom!.commentsGroupCount == 0 {
                self.showLoading("Load Data ...")
                self.chatRoom!.sync()
            }else{
                if let target = self.chatTarget {
                    if let indexPath = self.chatRoom?.getIndexPath(ofComment: target){
                        self.selectedCellIndex = indexPath
                        self.collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.top, animated: true)
                    }else{
                        QToasterSwift.toast(target: self, text: "Can't find message", backgroundColor: UIColor(red: 0.9, green: 0,blue: 0,alpha: 0.8), textColor: UIColor.white)
                    }
                    self.chatTarget = nil
                }
            }
            
        }else{
            self.collectionView.reloadData()
            self.chatRoom?.updateUnreadCommentCount {
                if self.chatRoom!.unreadCommentCount > 0 {
                    self.isLastRowVisible = false
                    var unreadText = "\(self.chatRoom!.unreadCommentCount)"
                    if self.chatRoom!.unreadCommentCount > 99 {
                        unreadText = "99+"
                    }
                    self.unreadIndicator.text = unreadText
                    self.unreadIndicator.isHidden = false
                    self.dataLoaded = true
                    self.chatRoom!.delegate = self
                }else{
                    self.dataLoaded = true
                    self.chatRoom!.delegate = self
                }
            }
            if let target = self.chatTarget {
                if let indexPath = self.chatRoom?.getIndexPath(ofComment: target){
                    self.selectedCellIndex = indexPath
                    self.collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.top, animated: true)
                }else{
                    QToasterSwift.toast(target: self, text: "Can't find message", backgroundColor: UIColor(red: 0.9, green: 0,blue: 0,alpha: 0.8), textColor: UIColor.white)
                }
                self.chatTarget = nil
            }
            self.chatService.delegate = self
            self.chatRoom!.subscribeRealtimeStatus()
            
            self.chatRoom!.sync()
        }
        
        self.isPresence = true
        self.firstLoad = false
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
        
        let bgColor = QiscusColorConfiguration.sharedInstance.avatarBackgroundColor
        
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(QiscusChatVC.goToTitleAction))
        self.titleView.addGestureRecognizer(tapRecognizer)
        
        let containerWidth = QiscusHelper.screenWidth() - 49
        let titleWidth = QiscusHelper.screenWidth() - CGFloat(49 * totalButton) - 40
        
        self.titleLabel.frame = CGRect(x: 40, y: 7, width: titleWidth, height: 17)
        self.subtitleLabel.frame = CGRect(x: 40, y: 25, width: titleWidth, height: 13)
        self.roomAvatarLabel.frame = CGRect(x: 0,y: 6,width: 32,height: 32)
        self.roomAvatar.frame = CGRect(x: 0,y: 6,width: 32,height: 32)
        self.titleView.frame = CGRect(x: 0, y: 0, width: containerWidth, height: 44)
        if self.chatTitle != nil {
            let roomTitle = self.chatTitle!.trimmingCharacters(in: .whitespacesAndNewlines)
            if roomTitle != "" {
                self.roomAvatarLabel.text = String(roomTitle.characters.first!).uppercased()
                let colorIndex = roomTitle.characters.count % bgColor.count
                self.roomAvatar.backgroundColor = bgColor[colorIndex]
            }
            self.titleLabel.text = self.chatTitle
        }
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
                self.collectionView.scrollToItem(at: goToRow!, at: .bottom, animated: true)
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
                self.collectionView.scrollToItem(at: goToRow!, at: .bottom, animated: true)
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
        if let room = self.chatRoom {
            room.unsubscribeRealtimeStatus()
            room.delegate = nil
        }
//        audioPlayer?.pause()
//        stopTimer()
//        updateAudioDisplay()
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
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    @IBAction func doNothing(_ sender: Any) {}
    
    public func loadRoomView(){
        self.chatRoom?.delegate = self
        self.chatRoom!.subscribeRealtimeStatus()
        self.loadTitle()
        self.loadSubtitle()
        self.unreadIndicator.isHidden = true
        if firstLoad {
            if self.chatRoom!.commentsGroupCount > 0 {
                self.collectionView.reloadData()
                let section = self.chatRoom!.commentsGroupCount - 1
                let row = self.chatRoom!.commentGroup(index: section)!.commentsCount - 1
                let indexPath = IndexPath(item: row, section: section)
                self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
                self.dismissLoading()
                self.dataLoaded = true
                self.collectionView.isHidden = false
            }else{
                self.dismissLoading()
                self.dataLoaded = true
                self.collectionView.isHidden = false
            }
        }else{
            if self.chatRoom!.commentsGroupCount > 0 {
                let delay = 0.5 * Double(NSEC_PER_SEC)
                let time = DispatchTime.now() + delay / Double(NSEC_PER_SEC)
                let section = self.chatRoom!.commentsGroupCount - 1
                let group = self.chatRoom!.commentGroup(index: section)!
                let row = group.commentsCount - 1
                let indexPath = IndexPath(item: row, section: section)
                self.collectionView.reloadData()
                DispatchQueue.main.asyncAfter(deadline: time, execute: {
                    self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
                    self.dismissLoading()
                    self.dataLoaded = true
                    self.collectionView.isHidden = false
                })
                
            }else{
                let delay = 0.5 * Double(NSEC_PER_SEC)
                let time = DispatchTime.now() + delay / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: time, execute: {
                    self.dismissLoading()
                    self.dataLoaded = true
                    self.collectionView.isHidden = false
                })
            }
        }
        
        if self.chatMessage != nil && self.chatMessage != "" {
            let newMessage = self.chatRoom!.newComment(text: self.chatMessage!)
            self.chatRoom!.post(comment: newMessage)
            self.chatMessage = nil
        }
    }
}

extension QiscusChatVC:QChatServiceDelegate{
    public func chatService(didFinishLoadRoom inRoom: QRoom, withMessage message: String?) {
        self.chatRoom = inRoom
        self.chatRoom?.delegate = self
        self.loadRoomView()
        Qiscus.shared.chatViews[inRoom.id] = self
        if let target = self.chatTarget {
            if let indexPath = self.chatRoom?.getIndexPath(ofComment: target){
                self.selectedCellIndex = indexPath
                self.collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.top, animated: true)
            }else{
                QToasterSwift.toast(target: self, text: "Can't find message", backgroundColor: UIColor(red: 0.9, green: 0,blue: 0,alpha: 0.8), textColor: UIColor.white)
            }
            self.chatTarget = nil
        }
    }
    public func chatService(didFailLoadRoom error: String) {
        let delay = 1.5 * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + delay / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time, execute: {
            self.dismissLoading()
        })
        QToasterSwift.toast(target: self, text: "Can't load chat room", backgroundColor: UIColor(red: 0.9, green: 0,blue: 0,alpha: 0.8), textColor: UIColor.white)
        self.dataLoaded = false
    }
}
extension QiscusChatVC:QRoomDelegate{
    public func room(didChangeName room: QRoom) {
        if self.chatTitle == nil || self.chatTitle == ""{
            self.loadTitle()
        }
    }
    public func room(didFinishSync room: QRoom) {
        let delay = 0.5 * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + delay / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time, execute: {
            self.dismissLoading()
            if let target = self.chatTarget {
                if let indexPath = self.chatRoom?.getIndexPath(ofComment: target){
                    self.selectedCellIndex = indexPath
                    self.collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.top, animated: true)
                }else{
                    QToasterSwift.toast(target: self, text: "Can't find message", backgroundColor: UIColor(red: 0.9, green: 0,blue: 0,alpha: 0.8), textColor: UIColor.white)
                }
                self.chatTarget = nil
            }
        })
    }
    public func room(didChangeAvatar room: QRoom) {
        self.roomAvatar.loadAsync(room.avatarURL, onLoaded: { (image, _) in
            self.roomAvatarImage = image
            self.roomAvatar.backgroundColor = UIColor.clear
            self.roomAvatarLabel.isHidden = true
            self.chatRoom?.saveAvatar(image: image)
            self.roomAvatar.image = image
        })
    }
    public func room(didFailUpdate error: String) {
        
    }
    public func room(didChangeUser room: QRoom, user: QUser) {
        if self.chatRoom!.type == .single {
            if user.email != QiscusMe.sharedInstance.email && self.chatRoom!.typingUser == ""{
                self.loadSubtitle()
            }
        }
    }
    public func room(didChangeParticipant room: QRoom) {
        if self.chatRoom?.type == .group && (self.chatSubtitle == "" || self.chatSubtitle == nil){
            self.loadSubtitle()
        }
    }
    public func room(didChangeGroupComment section: Int) {
        if let firstCell = self.collectionView.cellForItem(at: IndexPath(item: 0, section: section)) as? QChatCell {
            firstCell.updateUserName()
        }
    }
    public func room(didChangeComment section: Int, row: Int, action: String) {
        
    }
    public func room(gotNewComment comment: QComment) {
        self.collectionView.reloadData()
        self.chatRoom!.updateUnreadCommentCount(count: 0)
        if let indexPath = self.chatRoom!.getIndexPath(ofComment: comment){
            if self.isLastRowVisible || comment.senderEmail == QiscusMe.sharedInstance.email{
                self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
            }
        }
    }
    
    public func room(userDidTyping userEmail: String) {
        if userEmail == "" {
            self.stopTypingIndicator()
        }else{
            if let user = QUser.user(withEmail: userEmail) {
                self.startTypingIndicator(withUser: user.fullname)
            }
        }
    }
    public func room(didDeleteComment section: Int, row: Int) {
        self.collectionView.reloadData()
    }
    public func room(didDeleteGroupComment section: Int) {
        self.collectionView.reloadData()
    }
    public func room(didFinishLoadMore inRoom: QRoom, success: Bool, gotNewComment: Bool) {
        self.loadMoreControl.endRefreshing()
        if success && gotNewComment {
            self.collectionView.reloadData()
            if let targetComment = self.topComment {
                if let indexPath = self.chatRoom!.getIndexPath(ofComment: targetComment){
                    self.collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
                }
            }else{
                let section = self.chatRoom!.commentsGroupCount - 1
                let item = self.chatRoom!.commentGroup(index: section)!.commentsCount - 1
                let indexPath = IndexPath(item: item, section: section)
                self.collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
            }
            self.topComment = nil
        }
    }
    public func room(didChangeUnread lastReadCommentId:Int, unreadCount:Int) {
        if unreadCount > 0 {
            var unreadText = "\(unreadCount)"
            if unreadCount > 99 {
                unreadText = "99+"
            }
            self.unreadIndicator.text = unreadText
            self.unreadIndicator.isHidden = self.isLastRowVisible
        }else{
            self.unreadIndicator.text = ""
            self.unreadIndicator.isHidden = true
        }
    }
}

extension QiscusChatVC: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        QiscusBackgroundThread.async {autoreleasepool{
            manager.stopUpdatingLocation()
            if !self.didFindLocation {
                if let currentLocation = manager.location {
                    let geoCoder = CLGeocoder()
                    let latitude = currentLocation.coordinate.latitude
                    let longitude = currentLocation.coordinate.longitude
                    var address:String?
                    var title:String?
                    
                    geoCoder.reverseGeocodeLocation(currentLocation, completionHandler: { (placemarks, error) in
                        if error == nil {
                            let placeArray = placemarks
                            var placeMark: CLPlacemark!
                            placeMark = placeArray?[0]
                            
                            if let addressDictionary = placeMark.addressDictionary{
                                if let addressArray = addressDictionary["FormattedAddressLines"] as? [String] {
                                    address = addressArray.joined(separator: ", ")
                                }
                                title = addressDictionary["Name"] as? String
                                DispatchQueue.main.async { autoreleasepool{
                                    let comment = self.chatRoom!.newLocationComment(latitude: latitude, longitude: longitude, title: title, address: address)
                                    self.chatRoom?.post(comment: comment)
                                }}
                            }
                        }
                    })
                    
                }
                self.didFindLocation = true
                self.dismissLoading()
            }
        }}
    }
}
