//
//  QiscusChatVC.swift
//  QiscusSDK
//
//  Created by Ahmad Athaullah on 8/18/16.
//  Copyright © 2016 Ahmad Athaullah. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation
import Photos
import ImageViewer
import IQAudioRecorderController
import SwiftyJSON

public class QiscusChatVC: UIViewController{
    
    static let sharedInstance = QiscusChatVC()
    
    // MARK: - IBOutlet Properties
    @IBOutlet weak var inputBar: UIView!
    @IBOutlet weak var backgroundView: UIImageView!
    @IBOutlet weak var inputText: ChatInputText!
    @IBOutlet weak var welcomeView: UIView!
    @IBOutlet weak var welcomeText: UILabel!
    @IBOutlet weak var welcomeSubtitle: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var galeryButton: UIButton!
    @IBOutlet weak var archievedNotifView: UIView!
    @IBOutlet weak var archievedNotifLabel: UILabel!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var audioButton: UIButton!
    @IBOutlet weak var documentButton: UIButton!
    @IBOutlet weak var unlockButton: UIButton!
    @IBOutlet weak var emptyChatImage: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomButton: UIButton!
    @IBOutlet weak var unreadIndicator: UILabel!
    @IBOutlet weak var linkPreviewContainer: UIView!
    @IBOutlet weak var linkDescription: UITextView!
    @IBOutlet weak var linkImage: UIImageView!
    @IBOutlet weak var linkTitle: UILabel!
    
    // MARK: - Constrain
    @IBOutlet weak var minInputHeight: NSLayoutConstraint!
    @IBOutlet weak var archievedNotifTop: NSLayoutConstraint!
    @IBOutlet weak var inputBarBottomMargin: NSLayoutConstraint!
    @IBOutlet weak var collectionViewBottomConstrain: NSLayoutConstraint!
    @IBOutlet weak var linkPreviewTopMargin: NSLayoutConstraint!
    
    var isPresence:Bool = false
    var titleLabel = UILabel()
    var subtitleLabel = UILabel()
    
    // MARK: - shared Properties
    var commentClient = QiscusCommentClient.sharedInstance
    let dataPresenter = QiscusDataPresenter.shared
    var archived:Bool = QiscusUIConfiguration.sharedInstance.readOnly
    
    // MARK: - Data Properties
    var room:QiscusRoom?{
        didSet{
            if room != nil{
                let backButton = QiscusChatVC.backButton(self, action: #selector(QiscusChatVC.goBack))
                self.navigationItem.setHidesBackButton(true, animated: false)
                self.navigationItem.leftBarButtonItems = [
                    backButton,
                    self.roomAvatarButton()
                ]
                self.loadMoreControl.removeFromSuperview()
                if room!.hasLoadMore{
                    self.loadMoreControl = UIRefreshControl()
                    self.loadMoreControl.addTarget(self, action: #selector(QiscusChatVC.loadMore), for: UIControlEvents.valueChanged)
                    self.collectionView.addSubview(self.loadMoreControl)
                }
                self.loadTitle()
                self.subscribeRealtime(onRoom: room)
            }else{
                self.titleLabel.text = ""
                self.subtitleLabel.text = ""
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
                room = QiscusRoom.getRoom(withLastTopicId: topicId!)
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
                    room = QiscusRoom.getRoom(distincId, andUserEmail: user)
                }
            }
        }
    }
    var roomId:Int?{
        didSet{
            if roomId != nil {
                room = QiscusRoom.getRoomById(roomId!)
            }else{
                room = nil
            }
        }
    }
    var distincId:String = ""
    var optionalData:String?
    var message:String?
    var newRoom = false
    
    var topColor = UIColor(red: 8/255.0, green: 153/255.0, blue: 140/255.0, alpha: 1.0)
    var bottomColor = UIColor(red: 23/255.0, green: 177/255.0, blue: 149/255.0, alpha: 1)
    var tintColor = UIColor.white
    
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
    
    fileprivate init() {
        super.init(nibName: "QiscusChatVC", bundle: Qiscus.bundle)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Lifecycle
    override open func viewDidLoad() {
        super.viewDidLoad()
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
        self.emptyChatImage.image = Qiscus.image(named: "empty_messages")?.withRenderingMode(.alwaysTemplate)
        self.emptyChatImage.tintColor = self.bottomColor
        
        let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        layout?.sectionHeadersPinToVisibleBounds = true
        layout?.sectionFootersPinToVisibleBounds = true
        let resendMenuItem: UIMenuItem = UIMenuItem(title: "Resend", action: #selector(QChatCell.resend))
        let deleteMenuItem: UIMenuItem = UIMenuItem(title: "Delete", action: #selector(QChatCell.deleteComment))
        let menuItems:[UIMenuItem] = [resendMenuItem,deleteMenuItem]
        UIMenuController.shared.menuItems = menuItems
        setupNavigationTitle()
        //self.navigationItem.setTitleWithSubtitle(title: "Chat Room", subtitle: "chat subtitle")
    }
    override open func viewWillDisappear(_ animated: Bool) {
        self.isPresence = false
        dataPresenter.delegate = nil
        //commentClient.commentDelegate = nil
        super.viewWillDisappear(animated)
        //self.syncTimer?.invalidate()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        self.view.endEditing(true)
        if self.room != nil{
            self.unsubscribeTypingRealtime(onRoom: room!)
        }
    }
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        let sendImage = Qiscus.image(named: "ic_send_on")?.withRenderingMode(.alwaysTemplate)
        let documentImage = Qiscus.image(named: "ic_add_file")?.withRenderingMode(.alwaysTemplate)
        let galeryImage = Qiscus.image(named: "ic_add_image")?.withRenderingMode(.alwaysTemplate)
        let cameraImage = Qiscus.image(named: "ic_pick_picture")?.withRenderingMode(.alwaysTemplate)
        let audioImage = Qiscus.image(named: "ic_add_audio")?.withRenderingMode(.alwaysTemplate)
        self.sendButton.setImage(sendImage, for: .normal)
        self.documentButton.setImage(documentImage, for: .normal)
        self.galeryButton.setImage(galeryImage, for: .normal)
        self.cameraButton.setImage(cameraImage, for: .normal)
        self.audioButton.setImage(audioImage, for: .normal)
        if self.room != nil && !firstLoad {
            if let newRoom = QiscusRoom.getRoomById(room!.roomId){
                self.room = newRoom
            }
        }
        setupPage()
    }
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if firstLoad{
            self.room = nil
            loadData()
        }
    }
    // MARK: - Memory Warning
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Setup UI
    func setupNavigationTitle(){
        let titleWidth = QiscusHelper.screenWidth() - 160
        
        titleLabel = UILabel(frame:CGRect(x: 0, y: 0, width: titleWidth, height: 17))
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.text = ""
        titleLabel.textAlignment = .left
        
        subtitleLabel = UILabel(frame:CGRect(x: 0, y: 18, width: titleWidth, height: 12))
        subtitleLabel.backgroundColor = UIColor.clear
        subtitleLabel.textColor = UIColor.white
        subtitleLabel.font = UIFont.systemFont(ofSize: 11)
        subtitleLabel.text = ""
        subtitleLabel.textAlignment = .left
        
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: titleWidth, height: 30))
        titleView.addSubview(self.titleLabel)
        titleView.addSubview(self.subtitleLabel)
        
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
        if Qiscus.sharedInstance.iCloudUpload {
            self.documentButton.isHidden = false
        }else{
            self.documentButton.isHidden = true
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
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.navigationItem.leftBarButtonItems = [
            backButton,
            self.roomAvatarButton()
        ]
        
        if inputText.value == "" {
            sendButton.isEnabled = false
        }else{
            sendButton.isEnabled = true
        }
        sendButton.addTarget(self, action: #selector(QiscusChatVC.sendMessage), for: .touchUpInside)
        
        //welcomeView Setup
        self.unlockButton.addTarget(self, action: #selector(QiscusChatVC.confirmUnlockChat), for: .touchUpInside)
        
        
        self.welcomeText.text = QiscusTextConfiguration.sharedInstance.emptyTitle
        self.welcomeSubtitle.text = QiscusTextConfiguration.sharedInstance.emptyMessage
        
        self.inputText.textContainerInset = UIEdgeInsets.zero
        self.inputText.placeholder = QiscusTextConfiguration.sharedInstance.textPlaceholder
        self.inputText.chatInputDelegate = self
        //self.defaultViewHeight = self.view.frame.height - (self.navigationController?.navigationBar.frame.height)! - QiscusHelper.statusBarSize().height
        
        // upload button setup
        self.galeryButton.addTarget(self, action: #selector(self.uploadImage), for: .touchUpInside)
        self.cameraButton.addTarget(self, action: #selector(QiscusChatVC.uploadFromCamera), for: .touchUpInside)
        self.documentButton.addTarget(self, action: #selector(QiscusChatVC.iCloudOpen), for: .touchUpInside)
        self.audioButton.addTarget(self, action: #selector(QiscusChatVC.recordAudio), for: .touchUpInside)
        
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
                let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
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
            let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
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
        }else{
            if Qiscus.sharedInstance.isPushed {
                let _ = self.navigationController?.popViewController(animated: true)
            }else{
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - Load DataSource on firstTime
    func loadData(){
        self.showLoading("Load Data ...")
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
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
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
    func unlockChat(){
        self.archievedNotifTop.constant = 65
        UIView.animate(withDuration: 0.6, animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.archievedNotifView.isHidden = true
        })
    }
    func lockChat(){
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
                let value = self.inputText.value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                var indexPath = IndexPath(row: 0, section: 0)
                
                if self.comments.count > 0 {
                    let lastComment = self.comments.last!.last!
                    if lastComment.userEmail == QiscusMe.sharedInstance.email && lastComment.isToday {
                        indexPath.section = lastComment.commentIndexPath!.section
                        indexPath.row = lastComment.commentIndexPath!.row + 1
                    }else{
                        indexPath.section = lastComment.commentIndexPath!.section + 1
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
                    self.minInputHeight.constant = 25
                    self.sendButton.isEnabled = false
                    self.inputText.layoutIfNeeded()
                }
                
            }else{
                Qiscus.uiThread.async {
                    self.showNoConnectionToast()
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
    func recordAudio(){
        self.view.endEditing(true)
        if Qiscus.sharedInstance.connected{
            if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeAudio) == AVAuthorizationStatus.authorized{
                DispatchQueue.main.async(execute: {
                    let controller = IQAudioRecorderViewController()
                    controller.delegate = self
                    controller.title = NSLocalizedString("RECORDER", comment: "Recorder")
                    controller.allowCropping = true
                    self.presentBlurredAudioRecorderViewControllerAnimated(controller)
                })
            }else{
                AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeAudio, completionHandler: { (granted :Bool) -> Void in
                    if granted {
                        let controller = IQAudioRecorderViewController()
                        controller.delegate = self
                        controller.title = NSLocalizedString("RECORDER", comment: "Recorder")
                        controller.allowCropping = true
                        self.presentBlurredAudioRecorderViewControllerAnimated(controller)
                    }else{
                        DispatchQueue.main.async(execute: {
                            self.showMicrophoneAccessAlert()
                        })
                    }
                })
            }
        }else{
            self.showNoConnectionToast()
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
                var firstCommentId = Int64(0)
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
        
        
        if UIApplication.shared.userInterfaceLayoutDirection == .leftToRight {
            backIcon.frame = CGRect(x: 0,y: 0,width: 10,height: 15)
        }else{
            backIcon.frame = CGRect(x: 50,y: 0,width: 10,height: 15)
        }
        
        
        let backButton = UIButton(frame:CGRect(x: 0,y: 0,width: 10,height: 20))
        backButton.addSubview(backIcon)
        backButton.addTarget(target, action: action, for: UIControlEvents.touchUpInside)
        
        return UIBarButtonItem(customView: backButton)
    }
    func roomAvatarButton() -> UIBarButtonItem{
        self.roomAvatar = UIImageView()
        self.roomAvatar.contentMode = .scaleAspectFill
        self.roomAvatar.backgroundColor = UIColor.white
        
        let image = Qiscus.image(named: "room_avatar")
        self.roomAvatar.image = image
        if self.room != nil{
            if let avatar = room!.avatarImage {
                self.roomAvatar.image = avatar
            }else{
                room!.downloadThumbAvatar()
            }
        }
        if UIApplication.shared.userInterfaceLayoutDirection == .leftToRight {
            self.roomAvatar.frame = CGRect(x: 0,y: 0,width: 32,height: 32)
        }else{
            self.roomAvatar.frame = CGRect(x: 50,y: 0,width: 32,height: 32)
        }
        self.roomAvatar.layer.cornerRadius = 16
        self.roomAvatar.clipsToBounds = true
        
        let button = UIButton(frame:CGRect(x: 0,y: 0,width: 32,height: 32))
        button.addSubview(self.roomAvatar)
        
        return UIBarButtonItem(customView: button)
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
        self.bottomButton.tintColor = self.topColor
        self.documentButton.tintColor = self.bottomColor
        self.galeryButton.tintColor = self.bottomColor
        self.cameraButton.tintColor = self.bottomColor
        self.emptyChatImage.tintColor = self.bottomColor
        self.audioButton.tintColor = self.bottomColor
    }
    func setNavigationColor(_ color:UIColor, tintColor:UIColor){
        self.topColor = color
        self.bottomColor = color
        self.tintColor = tintColor
        self.navigationController?.navigationBar.verticalGradientColor(topColor, bottomColor: bottomColor)
        self.navigationController?.navigationBar.tintColor = tintColor
        let _ = self.view
        self.sendButton.tintColor = self.topColor
        self.bottomButton.tintColor = self.topColor
        self.documentButton.tintColor = self.bottomColor
        self.galeryButton.tintColor = self.bottomColor
        self.cameraButton.tintColor = self.bottomColor
        self.emptyChatImage.tintColor = self.bottomColor
        self.audioButton.tintColor = self.bottomColor
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
            
            var navSubtitle = ""
            if subtitle == "" {
                if self.room != nil {
                    if self.room!.roomType == .group {
                        if self.room!.participants.count > 0{
                            for participant in self.room!.participants {
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
                        if self.room!.participants.count > 0 {
                            for participant in self.room!.participants {
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
        }
    }
    func stopTypingIndicator(){
        Qiscus.logicThread.async {
            self.typingIndicatorUser = ""
            self.isTypingOn = false
            self.loadSubtitle()
        }
    }
    
    func subscribeRealtime(onRoom room:QiscusRoom?){
        if room != nil {
            let typingChannel:String = "r/\(room!.roomId)/\(room!.roomLastCommentTopicId)/+/t"
            let readChannel:String = "r/\(room!.roomId)/\(room!.roomLastCommentTopicId)/+/r"
            let deliveryChannel:String = "r/\(room!.roomId)/\(room!.roomLastCommentTopicId)/+/r"
            Qiscus.addMqttChannel(channel: typingChannel)
            Qiscus.addMqttChannel(channel: readChannel)
            Qiscus.addMqttChannel(channel: deliveryChannel)
        }
    }
    func unsubscribeTypingRealtime(onRoom room:QiscusRoom?){
        if room != nil {
            let channel = "r/\(room!.roomId)/\(room!.roomLastCommentTopicId)/+/t"
            Qiscus.deleteMqttChannel(channel: channel)
        }
    }
    func appDidEnterBackground(){
        self.view.endEditing(true)
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
                    let lastComment = QiscusComment.copyComment(comment: self.comments.last!.last!.comment!)
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
            
            self.linkImage.loadAsync(linkData.linkImageURL, placeholderImage: Qiscus.image(named: "link"))
            self.linkDescription.text = linkData.linkDescription
            self.linkTitle.text = linkData.linkTitle
            self.linkData = linkData
            self.linkPreviewTopMargin.constant = -65
            UIView.animate(withDuration: 0.65, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
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
        self.comments = [[QiscusCommentPresenter]]()
        self.backAction = nil
        self.titleAction = {}
        self.unlockAction = {}
        self.room = nil
        self.collectionView.reloadData()
    }
    
}

// MARK: - QiscusDataPresenterDelegate
extension QiscusChatVC: QiscusDataPresenterDelegate{
    public func dataPresenter(didFinishLoad comments: [[QiscusCommentPresenter]], inRoom: QiscusRoom) {
        self.dismissLoading()
        self.firstLoad = false
        self.room = inRoom
        if comments.count > 0 {
            self.comments = comments
            self.welcomeView.isHidden = true
            
            self.collectionView.reloadData()
            self.scrollToBottom()
        }
    }
    public func dataPresenter(didFinishLoadMore comments: [[QiscusCommentPresenter]], inRoom: QiscusRoom) {
        Qiscus.logicThread.async {
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
        Qiscus.logicThread.async {
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
        Qiscus.logicThread.async {
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
                                    Qiscus.logicThread.async {
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
                                    Qiscus.logicThread.async {
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
        Qiscus.logicThread.async {
            if let indexPath = data.commentIndexPath{
                if indexPath.section < self.comments.count{
                    if indexPath.row < self.comments[indexPath.section].count {
                        self.comments[indexPath.section][indexPath.row] = data
                        
                        if data.isDownloading {
                            let percentage = Int(data.downloadProgress * 100)
                            
                            if let cell = self.collectionView.cellForItem(at: indexPath) as? QChatCell{
                                Qiscus.uiThread.async {
                                    cell.downloadingMedia(withPercentage: percentage)
                                }
                            }
                        }else{
                            Qiscus.uiThread.async {
                                self.collectionView.reloadItems(at: [indexPath])
                            }
                        }
                    }
                }
            }
        }
    }
    public func dataPresenter(didChangeStatusFrom commentId: Int64, toStatus: QiscusCommentStatus, topicId: Int){
        Qiscus.logicThread.async {
            if let chatRoom = self.room{
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
    public func dataPresenter(gotNewData presenter: QiscusCommentPresenter, inRoom:QiscusRoom) {
        Qiscus.logicThread.async {
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
                    self.collectionView.performBatchUpdates({
                        self.collectionView.insertSections(IndexSet(integer: indexPath.section))
                        self.collectionView.insertItems(at: [indexPath])
                    }, completion: {_ in
                        if presenter.userIsOwn || self.isLastRowVisible{
                            self.welcomeView.isHidden = true
                            self.scrollToBottom()
                        }
                    })
                }
                if presenter.toUpload {
                    self.dataPresenter.uploadData(fromPresenter: presenter)
                }
            }else{
                let lastComment = self.comments.last!.last!
                if lastComment.createdAt < presenter.createdAt {
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
                        Qiscus.uiThread.async {
                            self.collectionView.performBatchUpdates({
                                self.collectionView.insertItems(at: [indexPath])
                            }, completion: {_ in
                                self.collectionView.reloadItems(at: [lastComment.commentIndexPath!])
                                self.scrollToBottom(true)
                            })
                        }
                    }else{
                        indexPath = IndexPath(row: 0, section: self.comments.count)
                        var newGroup = [QiscusCommentPresenter]()
                        presenter.cellPos = .single
                        presenter.balloonImage = presenter.getBalloonImage()
                        presenter.commentIndexPath = indexPath
                        newGroup.append(presenter)
                        self.comments.insert(newGroup, at: indexPath.section)
                        Qiscus.uiThread.async {
                            self.collectionView.performBatchUpdates({
                                self.collectionView.insertSections(IndexSet(integer: indexPath.section))
                                self.collectionView.insertItems(at: [indexPath])
                            }, completion: {_ in
                                self.scrollToBottom(true)
                            })
                        }
                    }
                    if presenter.toUpload {
                        self.dataPresenter.uploadData(fromPresenter: presenter)
                    }
                }else{
                
                }
            }
        }
    }
    public func dataPresenter(didChangeCellSize presenter:QiscusCommentPresenter, inRoom: QiscusRoom){
        Qiscus.logicThread.async {
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
        Qiscus.logicThread.async {
            var indexPathToReload = [IndexPath]()
            var imageIndexPath = [IndexPath]()
            var section = 0
            for dataGroup in self.comments{
                var row = 0
                for data in dataGroup{
                    if data.userEmail == email{
                        if data.userFullName != user.userFullName{
                            data.userFullName = user.userFullName
                            self.comments[section][row] = data
                            if row == 0 {
                                indexPathToReload.append(IndexPath(row: row, section: section))
                            }
                        }
                        if !data.userIsOwn{
                            if row == 0 {
                                imageIndexPath.append(IndexPath(row: row, section: section))
                            }
                        }
                    }
                    row += 1
                }
                section += 1
            }
            if indexPathToReload.count > 0 {
                Qiscus.uiThread.async {
                    self.collectionView.reloadItems(at: indexPathToReload)
                }
            }
            for indexPath in imageIndexPath.reversed(){
                if let footerCell = self.collectionView.supplementaryView(forElementKind: UICollectionElementKindSectionFooter, at: indexPath) as? QChatFooterLeft{
                    if let image = user.avatar{
                        footerCell.setup(withImage: image)
                    }
                }
            }
        }
    }
    public func dataPresenter(didChangeRoom room: QiscusRoom, onRoomWithId roomId: Int) {
        if let newRoom = QiscusRoom.getRoomById(roomId){
            if newRoom.roomName != room.roomName{
                newRoom.roomName = room.roomName
            }
            self.room = newRoom
        }
    }
    public func dataPresenter(didFailLoad error: String) {
        self.dismissLoading()
        QToasterSwift.toast(target: self, text: error, backgroundColor: UIColor(red: 0.9, green: 0,blue: 0,alpha: 0.8), textColor: UIColor.white)
    }
}

// MARK: - CollectionView dataSource, delegate, and delegateFlowLayout
extension QiscusChatVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    // MARK: CollectionView Data source
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.comments[section].count
    }
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.comments.count
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let data = self.comments[indexPath.section][indexPath.row]
        Qiscus.logicThread.async {
            data.commentIndexPath = indexPath
            data.balloonImage = data.getBalloonImage()
            self.comments[indexPath.section][indexPath.row] = data
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: data.cellIdentifier, for: indexPath) as! QChatCell
        cell.prepare(withData: data, andDelegate: self)
        cell.setupCell()
        
        if let audioCell = cell as? QCellAudio{
            audioCell.audioCellDelegate = self
            return audioCell
        }else{
            return cell
        }
    }
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let comment = self.comments[indexPath.section].first!
        
        if kind == UICollectionElementKindSectionFooter{
            if comment.userIsOwn{
                let footerCell = self.collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "cellFooterRight", for: indexPath) as! QChatFooterRight
                return footerCell
            }else{
                let footerCell = self.collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "cellFooterLeft", for: indexPath) as! QChatFooterLeft
                footerCell.setup(withComent: comment.comment!)
                return footerCell
            }
        }else{
            let headerCell = self.collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "cellHeader", for: indexPath) as! QChatHeaderCell
            
            let comment = self.comments[indexPath.section][0]
            var date:String = ""
            
            if comment.commentDate == QiscusHelper.thisDateString {
                date = QiscusTextConfiguration.sharedInstance.todayText
            }else{
                date = comment.commentDate
            }
            headerCell.setupHeader(withText: date)
            headerCell.clipsToBounds = true
            return headerCell
        }
    }
    
    // MARK: CollectionView delegate
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if let targetCell = cell as? QChatCell{
            if !targetCell.data.userIsOwn && targetCell.data.commentStatus != .read{
                publishRead()
                var i = 0
                for index in unreadIndexPath{
                    if index.row == indexPath.row && index.section == indexPath.section{
                        unreadIndexPath.remove(at: i)
                        break
                    }
                    i += 1
                }
            }
        }
        if indexPath.section == (comments.count - 1){
            if indexPath.row == comments[indexPath.section].count - 1{
                isLastRowVisible = true
            }
        }
    }
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.section == (comments.count - 1){
            
            if indexPath.row == comments[indexPath.section].count - 1{
                let visibleIndexPath = collectionView.indexPathsForVisibleItems
                if visibleIndexPath.count > 0{
                    var visible = false
                    for visibleIndex in visibleIndexPath{
                        if visibleIndex.row == indexPath.row && visibleIndex.section == indexPath.section{
                            visible = true
                            break
                        }
                    }
                    isLastRowVisible = visible
                }else{
                    isLastRowVisible = true
                }
            }
        }
    }
    public func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    public func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        let comment = self.comments[indexPath.section][indexPath.row]
        var show = false
        if action == #selector(UIResponderStandardEditActions.copy(_:)) && comment.commentType == .text{
            show = true
        }else if action == #selector(QChatCell.resend) && comment.commentStatus == .failed && Qiscus.sharedInstance.connected {
            if comment.commentType == .text{
                show = true
            }else{
                if let commentData = comment.comment{
                    if let file = QiscusFile.getCommentFileWithComment(commentData){
                        if file.isUploaded || file.isOnlyLocalFileExist{
                            show = true
                        }
                    }
                }
            }
        }else if action == #selector(QChatCell.deleteComment) && comment.commentStatus == .failed {
            show = true
        }
        return show
    }
    public func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        let textComment = self.comments[indexPath.section][indexPath.row]
        
        if action == #selector(UIResponderStandardEditActions.copy(_:)) && textComment.commentType == .text{
            UIPasteboard.general.string = textComment.commentText
        }
    }
    // MARK: CollectionView delegateFlowLayout
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        var height = CGFloat(0)
        if section > 0 {
            let firstComment = self.comments[section][0]
            let firstCommentBefore = self.comments[section - 1][0]
            if firstComment.commentDate != firstCommentBefore.commentDate{
                height = 35
            }
        }else{
            height = 35
        }
        return CGSize(width: collectionView.bounds.size.width, height: height)
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        var height = CGFloat(0)
        var width = CGFloat(0)
        let firstComment = self.comments[section][0]
        if !firstComment.userIsOwn{
            height = 44
            width = 44
        }
        return CGSize(width: width, height: height)
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let firstComment = self.comments[section][0]
        if firstComment.userIsOwn{
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }else{
            return UIEdgeInsets(top: 0, left: 0, bottom: -44, right: 0)
        }
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let comment = self.comments[indexPath.section][indexPath.row]
        var size = comment.cellSize
        if comment.commentType == .text{
            size.height += 15
            if comment.showLink {
                size.height += 75
            }
        }
        if comment.cellPos == .single || comment.cellPos == .first{
            size.height += 20
        }
        size.width = collectionView.bounds.size.width
        return size
    }
}
// MARK: - ChatCell Delegate
extension QiscusChatVC: ChatCellDelegate, ChatCellAudioDelegate{
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

// MARK: - GaleryItemDataSource
extension QiscusChatVC:GalleryItemsDatasource{
    public func itemCount() -> Int{
        return self.galleryItems.count
    }
    public func provideGalleryItem(_ index: Int) -> GalleryItem{
        let item = self.galleryItems[index]
        if item.isVideo{
            return GalleryItem.video(fetchPreviewImageBlock: { $0(item.image)}, videoURL: URL(string: item.url)! )
        }else{
            return GalleryItem.image { $0(item.image) }
        }
    }
}
// MARK: - UIImagePickerDelegate
extension QiscusChatVC:UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    open func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]){
        let time = Double(Date().timeIntervalSince1970)
        let timeToken = UInt64(time * 10000)
        let fileType:String = info[UIImagePickerControllerMediaType] as! String
        picker.dismiss(animated: true, completion: nil)
        
        if fileType == "public.image"{
            var imageName:String = ""
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            var imagePath:URL?
            if let imageURL = info[UIImagePickerControllerReferenceURL] as? URL{
                imageName = imageURL.lastPathComponent
                
                let imageNameArr = imageName.characters.split(separator: ".")
                let imageExt:String = String(imageNameArr.last!).lowercased()
                
                if imageExt.isEqual("gif") || imageExt.isEqual("gif_"){
                    imagePath = imageURL
                }
            }else{
                imageName = "\(timeToken).jpg"
            }
            let text = QiscusTextConfiguration.sharedInstance.confirmationImageUploadText
            let okText = QiscusTextConfiguration.sharedInstance.alertOkText
            let cancelText = QiscusTextConfiguration.sharedInstance.alertCancelText
            
            QPopUpView.showAlert(withTarget: self, image: image, message: text, firstActionTitle: okText, secondActionTitle: cancelText,doneAction: {
                 self.continueImageUpload(image, imageName: imageName, imagePath: imagePath)
            },
                 cancelAction: {}
            )
        }else if fileType == "public.movie" {
            let mediaURL = info[UIImagePickerControllerMediaURL] as! URL
            let fileName = mediaURL.lastPathComponent
            let fileNameArr = fileName.characters.split(separator: ".")
            let fileExt:NSString = String(fileNameArr.last!).lowercased() as NSString
            
            let mediaData = try? Data(contentsOf: mediaURL)
            
            Qiscus.printLog(text: "mediaURL: \(mediaURL)\nfileName: \(fileName)\nfileExt: \(fileExt)")
            
            //create thumb image
            let assetMedia = AVURLAsset(url: mediaURL)
            let thumbGenerator = AVAssetImageGenerator(asset: assetMedia)
            thumbGenerator.appliesPreferredTrackTransform = true
            
            let thumbTime = CMTimeMakeWithSeconds(0, 30)
            let maxSize = CGSize(width: QiscusHelper.screenWidth(), height: QiscusHelper.screenWidth())
            thumbGenerator.maximumSize = maxSize
            
            do{
                let thumbRef = try thumbGenerator.copyCGImage(at: thumbTime, actualTime: nil)
                let thumbImage = UIImage(cgImage: thumbRef)
                
                QPopUpView.showAlert(withTarget: self, image: thumbImage, message:"Are you sure to send this video?", isVideoImage: true,
                                     doneAction: {
                                        Qiscus.printLog(text: "continue video upload")
                                        self.continueImageUpload(thumbImage, imageName: fileName, imageNSData: mediaData, videoFile: true)
                },
                                     cancelAction: {
                                        Qiscus.printLog(text: "cancel upload")
                }
                )
            }catch{
                Qiscus.printLog(text: "error creating thumb image")
            }
        }
    }
    open func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
// MARK: - IQAudioRecorderViewControllerDelegate
extension QiscusChatVC:IQAudioRecorderViewControllerDelegate{
    public func audioRecorderController(_ controller: IQAudioRecorderViewController, didFinishWithAudioAtPath filePath: String) {
        let fileURL = URL(fileURLWithPath: filePath)
        Qiscus.printLog(text: "filePath \(filePath)")
        Qiscus.printLog(text: "fileURL \(fileURL)")
        var fileContent: Data?
        fileContent = try! Data(contentsOf: fileURL)
        
        let fileName = fileURL.lastPathComponent
        
        self.continueImageUpload(imageName: fileName, imageNSData: fileContent, audioFile: true)
        //commentClient.uploadAudio(self.room.roomLastCommentTopicId, fileName: fileName, filePath: fileURL, roomId: self.room.roomId)
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    public func audioRecorderControllerDidCancel(_ controller: IQAudioRecorderViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - UIDocumentPickerDelegate
extension QiscusChatVC: UIDocumentPickerDelegate{
    open func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        self.showLoading("Processing File")
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(readingItemAt: url, options: NSFileCoordinator.ReadingOptions.forUploading, error: nil) { (dataURL) in
            do{
                let data:Data = try Data(contentsOf: dataURL, options: NSData.ReadingOptions.mappedIfSafe)
                var fileName = dataURL.lastPathComponent.replacingOccurrences(of: "%20", with: "_")
                fileName = fileName.replacingOccurrences(of: " ", with: "_")
                
                let fileNameArr = (fileName as String).characters.split(separator: ".")
                let ext = String(fileNameArr.last!).lowercased()
                
                // get file extension
                let isGifImage:Bool = (ext == "gif" || ext == "gif_")
                let isJPEGImage:Bool = (ext == "jpg" || ext == "jpg_")
                let isPNGImage:Bool = (ext == "png" || ext == "png_")
                
                if isGifImage || isPNGImage || isJPEGImage{
                    var imagePath:URL?
                    let image = UIImage(data: data)
                    if isGifImage{
                        imagePath = dataURL
                    }
                    self.dismissLoading()
                    let text = QiscusTextConfiguration.sharedInstance.confirmationImageUploadText
                    let okText = QiscusTextConfiguration.sharedInstance.alertOkText
                    let cancelText = QiscusTextConfiguration.sharedInstance.alertCancelText
                    QPopUpView.showAlert(withTarget: self, image: image, message: text, firstActionTitle: okText, secondActionTitle: cancelText,
                                         doneAction: {
                                            self.continueImageUpload(image, imageName: fileName, imagePath: imagePath, imageNSData: data)
                                            
                    },
                                         cancelAction: {}
                    )
                }else{
                    self.dismissLoading()
                    let textFirst = QiscusTextConfiguration.sharedInstance.confirmationFileUploadText
                    let textMiddle = "\(fileName as String)"
                    let textLast = QiscusTextConfiguration.sharedInstance.questionMark
                    let text = "\(textFirst) \(textMiddle) \(textLast)"
                    let okText = QiscusTextConfiguration.sharedInstance.alertOkText
                    let cancelText = QiscusTextConfiguration.sharedInstance.alertCancelText
                    QPopUpView.showAlert(withTarget: self, message: text, firstActionTitle: okText, secondActionTitle: cancelText,
                                         doneAction: {
                                            self.continueImageUpload(imageName: fileName, imagePath: dataURL, imageNSData: data)
                    },
                                         cancelAction: {
                    }
                    )
                }
            }catch _{
                self.dismissLoading()
            }
        }
    }
}
// MARK: - AudioPlayer
extension QiscusChatVC:AVAudioPlayerDelegate{
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            if let activeCell = activeAudioCell {
                activeCell.data.audioIsPlaying = false
                self.didChangeData(onCell: activeCell, withData: activeCell.data)
            }
            stopTimer()
            updateAudioDisplay()
        } catch _ as NSError {}
    }
    
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let activeCell = activeAudioCell as? QCellAudioLeft{
            activeCell.data.audioIsPlaying = false
            self.didChangeData(onCell: activeCell, withData: activeCell.data)
        }
        stopTimer()
        updateAudioDisplay()
    }
    
    // MARK: - Audio Methods
    func audioTimerFired(_ timer: Timer) {
        self.updateAudioDisplay()
    }
    
    func stopTimer() {
        audioTimer?.invalidate()
        audioTimer = nil
    }
    
    func updateAudioDisplay() {
        if let cell = activeAudioCell{
            if let currentTime = audioPlayer?.currentTime {
                cell.updateAudioDisplay(withTimeInterval: currentTime)
            }
        }
    }
}
