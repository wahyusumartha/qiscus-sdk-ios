//
//  QiscusChatVC.swift
//  Example
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

open class QiscusChatVC: UIViewController, ChatInputTextDelegate, QCommentDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate, GalleryItemsDatasource, IQAudioRecorderViewControllerDelegate, AVAudioPlayerDelegate, ChatCellDelegate,ChatCellAudioDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
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
    
    
    // MARK: - View Attributes
    var defaultViewHeight:CGFloat = 0
    var isPresence:Bool = false
    
    // MARK: - Data Properties
    var hasMoreComment = true
    var loadMoreControl = UIRefreshControl()
    var commentClient = QiscusCommentClient.sharedInstance
    var topicId = QiscusUIConfiguration.sharedInstance.topicId
    var users:[String] = QiscusUIConfiguration.sharedInstance.chatUsers
    var consultantId: Int = 0
    var consultantRate:Int = 0
    //var comment = [[QiscusComment]]()
    var comments = [[QiscusComment]]()
    var archived:Bool = QiscusUIConfiguration.sharedInstance.readOnly
    var rowHeight:[IndexPath: CGFloat] = [IndexPath: CGFloat]()
    var firstLoad = true
    
    var topColor = UIColor(red: 8/255.0, green: 153/255.0, blue: 140/255.0, alpha: 1.0)
    var bottomColor = UIColor(red: 23/255.0, green: 177/255.0, blue: 149/255.0, alpha: 1)
    var tintColor = UIColor.white
    var syncTimer:Timer?
    var selectedImage:UIImage = UIImage()
    var imagePreview:GalleryViewController?
    var loadWithUser:Bool = false
    var distincId:String = ""
    var optionalData:String?
    var galleryItems:[QiscusGalleryItem] = [QiscusGalleryItem]()
    var roomId:Int = 0
    
    //MARK: - external action
    open var unlockAction:(()->Void) = {}
    open var cellDelegate:QiscusChatCellDelegate?
    open var optionalDataCompletion:((String)->Void)?
    open var titleAction:(()->Void) = {}
    
    var audioPlayer: AVAudioPlayer?
    var audioTimer: Timer?
    var activeAudioCell: QCellAudio?
    
    var loadingView = QLoadingViewController.sharedInstance
    var typingIndicatorUser:String = ""
    var isTypingOn:Bool = false
    var linkData:QiscusLinkData?
    var message:String?
    var newChat:Bool = false
    var roomName:String?
    var roomAvatar = UIImageView()
    
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
                print("url: \(linkToPreview)")
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
    var nextIndexPath:IndexPath{
        get{
            let indexPath = QiscusHelper.getNextIndexPathIn(groupComment:self.comments)
            return IndexPath(row: indexPath.row, section: indexPath.section)
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
            return ["public.jpeg", "public.png"/*,"com.compuserve.gif"*/,"public.text", "public.archive", "com.microsoft.word.doc", "com.microsoft.excel.xls", "com.microsoft.powerpoint.​ppt", "com.adobe.pdf","public.mpeg-4"]
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

        self.emptyChatImage.image = Qiscus.image(named: "empty_messages")?.withRenderingMode(.alwaysTemplate)
        self.emptyChatImage.tintColor = self.bottomColor
        
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
        commentClient.commentDelegate = nil
        super.viewWillDisappear(animated)
        self.view.endEditing(true)
        //self.syncTimer?.invalidate()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        self.view.endEditing(true)
        if let room = QiscusRoom.getRoom(withLastTopicId: self.topicId){
            self.unsubscribeTypingRealtime(onRoom: room)
        }
        if audioPlayer != nil{
            audioPlayer?.stop()
        }
        self.comments = [[QiscusComment]]()
        self.collectionView.reloadData()
    }
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        unreadIndexPath = [IndexPath]()
        bottomButton.isHidden = true
        commentClient.commentDelegate = self
        self.isPresence = true
        self.comments = [[QiscusComment]]()
        self.collectionView.reloadData()
        self.navigationController?.setNavigationBarHidden(false , animated: false)
        self.isPresence = true
        firstLoad = true
        self.topicId = QiscusUIConfiguration.sharedInstance.topicId
        self.archived = QiscusUIConfiguration.sharedInstance.readOnly
        self.users = QiscusUIConfiguration.sharedInstance.chatUsers
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
        setupPage()
        loadData()
    }
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.comments = [[QiscusComment]]()
    }
    // MARK: - Memory Warning
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Setup UI
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

        self.navigationItem.setTitleWithSubtitle(title: QiscusTextConfiguration.sharedInstance.chatTitle, subtitle:QiscusTextConfiguration.sharedInstance.chatSubtitle)
        self.navigationController?.navigationBar.verticalGradientColor(topColor, bottomColor: bottomColor)
        self.navigationController?.navigationBar.tintColor = tintColor
        
        let backButton = QiscusChatVC.backButton(self, action: #selector(QiscusChatVC.goBack))
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.navigationItem.leftBarButtonItems = [
            backButton,
            self.roomAvatarButton()
        ]
        
        // loadMoreControl
        self.loadMoreControl.addTarget(self, action: #selector(QiscusChatVC.loadMore), for: UIControlEvents.valueChanged)
        
        self.collectionView.addSubview(self.loadMoreControl)
        
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
        self.defaultViewHeight = self.view.frame.height - (self.navigationController?.navigationBar.frame.height)! - QiscusHelper.statusBarSize().height
        
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
    
    // MARK: - ChatInputTextDelegate Delegate
    open func chatInputTextDidChange(chatInput input: ChatInputText, height: CGFloat) {
        if self.minInputHeight.constant != height {
            input.layoutIfNeeded()
            self.minInputHeight.constant = height
        }
        if let room = QiscusRoom.getRoom(withLastTopicId: self.topicId){
            DispatchQueue.main.async {
                let message: String = "1";
                let data: Data = message.data(using: .utf8)!
                let channel = "r/\(room.roomId)/\(self.topicId)/\(QiscusMe.sharedInstance.email)/t"
                Qiscus.printLog(text: "Realtime publish to channel: \(channel)")
                Qiscus.sharedInstance.mqtt?.publish(data, in: channel, delivering: .atLeastOnce, retain: false, completion: nil)
            }
            
        }
    }
    open func valueChanged(value:String){
        if value == "" {
            linkToPreview = ""
        }else{
            sendButton.isEnabled = true
            if let link = QiscusHelper.getFirstLinkInString(text: value){
                if link != linkToPreview{
                    linkToPreview = link
                }
            }else{
                linkToPreview = ""
            }
        }
    }
    open func chatInputDidEndEditing(chatInput input: ChatInputText) {
        if let room = QiscusRoom.getRoom(withLastTopicId: self.topicId){
            DispatchQueue.main.async {
                let message: String = "0";
                let data: Data = message.data(using: .utf8)!
                let channel = "r/\(room.roomId)/\(self.topicId)/\(QiscusMe.sharedInstance.email)/t"
                Qiscus.printLog(text: "Realtime publish to channel: \(channel)")
                Qiscus.sharedInstance.mqtt?.publish(data, in: channel, delivering: .atLeastOnce, retain: false, completion: nil)
            }
        }
    }
    
    func scrollToBottom(_ animated:Bool = false){
        let bottomPoint = CGPoint(x: 0, y: collectionView.contentSize.height - collectionView.bounds.size.height)
        
        if collectionView.contentSize.height > collectionView.bounds.size.height{
            collectionView.setContentOffset(bottomPoint, animated: animated)
        }
        let delay = 0.1 * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time, execute: {
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
        if Qiscus.sharedInstance.isPushed {
            let _ = self.navigationController?.popViewController(animated: true)
        }else{
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - Load DataSource
    func loadData(){
        if newChat {
            self.showLoading("Load Data ...")
            commentClient.createNewRoom(withUsers: users, optionalData: self.optionalData, withMessage: self.message)
        }else{
            if(self.topicId > 0){
                self.comments = QiscusComment.grouppedComment(inTopicId: self.topicId, firstLoad: true)
                Qiscus.printLog(text: "self comments: \n\(self.comments)")
                
                let room = QiscusRoom.getRoom(withLastTopicId: self.topicId)
                if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                    roomDelegate.didFinishLoadRoom(onRoom: room!)
                }
                if self.optionalDataCompletion != nil && room != nil{
                    self.optionalDataCompletion!(room!.optionalData)
                }
                if room != nil {
                    if QiscusUIConfiguration.sharedInstance.copyright.chatTitle == ""{
                        self.setTitle(title: room!.roomName)
                    }
                    if let avatar = room!.avatarImage {
                        self.roomAvatar.image = avatar
                    }else{
                        self.roomAvatar.loadAsync(room!.roomAvatarURL)
                        room!.downloadThumbAvatar()
                    }
                }
                self.subscribeRealtime(onRoom: room)
                if self.comments.count > 0 {
                    self.collectionView.reloadData()
                    scrollToBotomFromNoData()
                    self.welcomeView.isHidden = true
                    commentClient.syncMessage(self.topicId)
                    if message != nil {
                        commentClient.postMessage(message: self.message!, topicId: self.topicId)
                        self.message = nil
                    }
                }else{
                    self.welcomeView.isHidden = false
                    self.showLoading("Load Data ...")
                    commentClient.getListComment(topicId: self.topicId, commentId: 0, triggerDelegate: true, message:self.message)
                    self.message = nil
                }
            }
            else{
                if self.users.count > 0 {
                    loadWithUser = true
                    if self.users.count == 1 {
                        if let room = QiscusRoom.getRoom(self.distincId, andUserEmail: self.users.first!){
                            if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                                roomDelegate.didFinishLoadRoom(onRoom: room)
                            }
                            if QiscusUIConfiguration.sharedInstance.copyright.chatTitle == ""{
                                self.setTitle(title: room.roomName)
                            }
                            if let avatar = room.avatarImage {
                                self.roomAvatar.image = avatar
                            }else{
                                self.roomAvatar.loadAsync(room.roomAvatarURL)
                                room.downloadThumbAvatar()
                            }
                            self.topicId = room.roomLastCommentTopicId
                            self.comments = QiscusComment.grouppedComment(inTopicId: self.topicId, firstLoad: true)
                            Qiscus.printLog(text: "self comments: \n\(self.comments)")
                            self.subscribeRealtime(onRoom: room)
                            
                            if self.comments.count > 0 {
                                self.collectionView.isHidden = true
                                self.collectionView.reloadData()
                                scrollToBotomFromNoData()
                                self.welcomeView.isHidden = true
                                if self.optionalDataCompletion != nil{
                                    self.optionalDataCompletion!(room.optionalData)
                                }
                                commentClient.syncMessage(self.topicId)
                            }else{
                                self.welcomeView.isHidden = false
                                if self.optionalDataCompletion != nil{
                                    self.optionalDataCompletion!(room.optionalData)
                                }
                                self.showLoading("Load Data ...")
                                commentClient.getListComment(topicId: self.topicId, commentId: 0, triggerDelegate: true)
                            }
                            if message != nil {
                                commentClient.postMessage(message: self.message!, topicId: self.topicId)
                                self.message = nil
                            }
                        }
                        else{
                            self.showLoading("Load Data ...")
                            commentClient.getListComment(withUsers: users, triggerDelegate: true, distincId: self.distincId, optionalData:self.optionalData, withMessage: self.message, optionalDataCompletion: {optionalData
                                in
                                if self.optionalDataCompletion != nil{
                                    self.optionalDataCompletion!(optionalData)
                                }
                                Qiscus.printLog(text: "optional data from getListComment: \(optionalData)")
                            })
                        }
                    }else{
                        self.showLoading("Load Data ...")
                        commentClient.getListComment(withUsers: users, triggerDelegate: true, distincId: self.distincId, optionalData:self.optionalData, withMessage: self.message, optionalDataCompletion: {optionalData
                            in
                            if self.optionalDataCompletion != nil{
                                self.optionalDataCompletion!(optionalData)
                            }
                        })
                    }
                }else{
                    if let room = QiscusRoom.getRoomById(self.roomId){
                        if QiscusUIConfiguration.sharedInstance.copyright.chatTitle == ""{
                            self.setTitle(title: room.roomName)
                        }
                        if let avatar = room.avatarImage {
                            self.roomAvatar.image = avatar
                        }else{
                            self.roomAvatar.loadAsync(room.roomAvatarURL)
                            room.downloadThumbAvatar()
                        }
                        if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                            roomDelegate.didFinishLoadRoom(onRoom: room)
                        }
                        self.comments = QiscusComment.grouppedComment(inTopicId: room.roomLastCommentTopicId, firstLoad: true)
                        if self.comments.count > 0 {
                            self.topicId = room.roomLastCommentTopicId
                            self.collectionView.reloadData()
                            scrollToBotomFromNoData()
                            self.welcomeView.isHidden = true
                            if self.optionalDataCompletion != nil{
                                self.optionalDataCompletion!(room.optionalData)
                            }
                            if message != nil {
                                commentClient.postMessage(message: self.message!, topicId: self.topicId)
                                self.message = nil
                            }
                            commentClient.syncMessage(self.topicId)
                        }else{
                            self.welcomeView.isHidden = false
                            if self.optionalDataCompletion != nil{
                                self.optionalDataCompletion!(room.optionalData)
                            }
                            self.showLoading("Load Data ...")
                            commentClient.getRoom(withID: self.roomId, triggerDelegate: true, withMessage: self.message, optionalDataCompletion: {optionalData in
                                if self.optionalDataCompletion != nil{
                                    self.optionalDataCompletion!(optionalData)
                                }
                            })
                        }
                    }
                    else{
                        self.welcomeView.isHidden = false
                        self.showLoading("Load Data ...")
                        commentClient.getRoom(withID: self.roomId, triggerDelegate: true, withMessage: self.message, optionalDataCompletion: {optionalData in
                            if self.optionalDataCompletion != nil{
                                self.optionalDataCompletion!(optionalData)
                            }
                        })
                    }
                }
            }
        }
    }
    func syncData(){
        if Qiscus.sharedInstance.connected{
        if self.topicId > 0 {
            if self.comments.count > 0 {
                commentClient.syncMessage(self.topicId)
            }else{
                if self.users.count > 0 {
                    //commentClient.getListComment(withUsers:users, triggerDelegate: true)
                }else{
                    commentClient.getListComment(topicId: self.topicId, commentId: 0, triggerDelegate: true)
                }
            }
        }
        }else{
            self.showNoConnectionToast()
        }
    }
    // MARK: - Qiscus Comment Delegate
    open func performDeleteMessage(onIndexPath: IndexPath) {
        let deletedComment = self.comments[onIndexPath.section][onIndexPath.row]
        if comments[onIndexPath.section].count == 1{
            let indexSet = IndexSet(integer: onIndexPath.section)
            comments.remove(at: onIndexPath.section)
            collectionView.performBatchUpdates({
                self.collectionView.deleteSections(indexSet)
            }, completion: nil)
            if onIndexPath.section > 0 {
                let row = self.comments[onIndexPath.section - 1].count - 1
                let reloadIndexPath = IndexPath(row: row, section: onIndexPath.section - 1)
                collectionView.reloadItems(at: [reloadIndexPath])
            }
        }else{
            var last = false
            if onIndexPath.row == (self.comments[onIndexPath.section].count - 1){
                last = true
            }else{
                let commentAfter = self.comments[onIndexPath.section][onIndexPath.row + 1]
                if (commentAfter.commentSenderEmail as String) != (deletedComment.commentSenderEmail as String){
                    last = true
                }
            }
            self.comments[onIndexPath.section].remove(at: onIndexPath.row)
            collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: [onIndexPath])
            }, completion: nil)
            if last {
                let reloadIndexPath = IndexPath(row: onIndexPath.row - 1, section: onIndexPath.section)
                collectionView.reloadItems(at: [reloadIndexPath])
            }
        }
        deletedComment.deleteComment()
    }
    open func performResendMessage(onIndexPath: IndexPath) {
        let resendComment = self.comments[onIndexPath.section][onIndexPath.row]
        resendComment.updateCommentStatus(.sending)
        self.comments[onIndexPath.section][onIndexPath.row] = resendComment
        collectionView.reloadItems(at: [onIndexPath])
        if resendComment.commentType == .text{
            self.commentClient.postComment(resendComment)
        }else{
            if let file = QiscusFile.getCommentFileWithComment(resendComment){
                if file.isUploaded {
                    self.commentClient.postComment(resendComment)
                }else if file.isOnlyLocalFileExist{
                    self.commentClient.reUploadFile(onComment: resendComment)
                }
            }
        }
    }
    open func commentDidChangeStatus(Comments comments: [QiscusComment], toStatus: QiscusCommentStatus) {
        for comment in comments{
            if comment.commentTopicId == self.topicId{
                let indexPath = comment.commentIndexPath
                if indexPath.section < self.comments.count{
                    if indexPath.row < self.comments[indexPath.section].count{
                        self.comments[indexPath.section][indexPath.row] = comment
                        if comment.isOwnMessage {
                            if let cell = collectionView.cellForItem(at: indexPath) as? QChatCell{
                                cell.updateStatus(toStatus: toStatus)
                            }
                            if indexPath.section == self.comments.count - 1 && indexPath.row == self.comments[self.comments.count - 1].count{
                                isLastRowVisible = true
                            }
                        }
                    }
                }
            }
        }
    }
    open func didSuccesPostComment(_ comment:QiscusComment){
        if comment.commentTopicId == self.topicId {
            let indexPath = comment.commentIndexPath
            DispatchQueue.main.async {
                self.comments[indexPath.section][indexPath.row] = comment
                self.collectionView.reloadItems(at: [indexPath])
                if indexPath.section == self.comments.count - 1 && indexPath.row == self.comments[self.comments.count - 1].count - 1{
                    self.isLastRowVisible = true
                }
            }
        }
    }
    open func didFailedPostComment(_ comment:QiscusComment){
        if comment.commentTopicId == self.topicId {
            let indexPath = comment.commentIndexPath
            DispatchQueue.main.async {
                self.comments[indexPath.section][indexPath.row] = comment
                self.collectionView.reloadItems(at: [indexPath])
            }
        }
        
    }
    open func downloadingMedia(_ comment:QiscusComment){
        let file = QiscusFile.getCommentFileWithComment(comment)!
        let indexPath = comment.commentIndexPath
        
        if self.comments.count > indexPath.section{
            if self.comments[indexPath.section].count > indexPath.row {
                let targetCell = collectionView.cellForItem(at: indexPath)
                let downloadProgress:Int = Int(file.downloadProgress * 100)
                if let cell = targetCell as? QChatCell {
                    cell.downloadingMedia(withPercentage: downloadProgress)
                }
            }
        }
    }
    open func didDownloadMedia(_ comment: QiscusComment){
        if Qiscus.sharedInstance.connected{
            let file = QiscusFile.getCommentFileWithComment(comment)!
            let indexPath = comment.commentIndexPath
            if self.comments.count > indexPath.section{
                if self.comments[indexPath.section].count > indexPath.row {
                    let targetCell = collectionView.cellForItem(at: indexPath)
                    if let cell = targetCell as? QCellMediaLeft {
                        cell.comment = comment
                        cell.setupImageView()
                    }else if let cell = targetCell as? QCellMediaRight {
                        cell.comment = comment
                        cell.setupImageView()
                    }else if let cell = targetCell as? QCellAudioLeft {
                        cell.progressContainer.isHidden = true
                        cell.filePath = file.fileLocalPath
                        collectionView.reloadItems(at: [indexPath])
                    }else if let cell = targetCell as? QCellAudioRight {
                        cell.progressContainer.isHidden = true
                        cell.filePath = file.fileLocalPath
                        collectionView.reloadItems(at: [indexPath])
                    }
                }
            }
        }else{
            self.showNoConnectionToast()
        }
    }
    open func didUploadFile(_ comment:QiscusComment){
        let file = QiscusFile.getCommentFileWithComment(comment)!
        let indexPath = comment.commentIndexPath
        
        if self.comments.count > indexPath.section{
            if self.comments[indexPath.section].count > indexPath.row {
                if let cell = collectionView.cellForItem(at: indexPath) as? QCellMediaRight{
                    cell.comment = comment
                    cell.setupImageView()
                }else if let cell = collectionView.cellForItem(at: indexPath) as? QCellAudioRight{
                    cell.filePath = file.fileLocalPath
                    cell.progressContainer.isHidden = true
                    collectionView.reloadItems(at: [indexPath])
                }else{
                    collectionView.reloadItems(at: [indexPath])
                }
            }
        }
    }
    open func uploadingFile(_ comment:QiscusComment){
        let file = QiscusFile.getCommentFileWithComment(comment)!
        let indexPath = comment.commentIndexPath
        
        if self.comments.count > indexPath.section{
            if self.comments[indexPath.section].count > indexPath.row {
                let uploadProgres:Int = Int(file.uploadProgress * 100)
                let uploading = QiscusTextConfiguration.sharedInstance.uploadingText
                if let cell = collectionView.cellForItem(at: indexPath) as? QCellMediaRight{
                    if file.uploadProgress > 0 {
                        cell.downloadButton.isHidden = true
                        cell.progressLabel.text = "\(uploadProgres) %"
                        cell.progressLabel.isHidden = false
                        cell.progressContainer.isHidden = false
                        cell.progressView.isHidden = false
                        
                        let newHeight = file.uploadProgress * cell.maxProgressHeight
                        cell.progressHeight.constant = newHeight
                        cell.progressView.layoutIfNeeded()
                    }
                }else if let cell = collectionView.cellForItem(at: indexPath) as? QCellAudioRight{
                    if file.uploadProgress > 0 {
                        cell.progressContainer.isHidden = false
                        cell.progressHeight.constant = file.uploadProgress * 30
                        cell.dateLabel.text = "\(uploading) \(QChatCellHelper.getFormattedStringFromInt(uploadProgres)) %"
                        cell.progressContainer.layoutIfNeeded()
                    }
                }else if let cell = collectionView.cellForItem(at: indexPath) as? QCellFileRight{
                    if file.uploadProgress > 0 {
                        cell.dateLabel.text = "\(uploading) \(QChatCellHelper.getFormattedStringFromInt(uploadProgres)) %"
                    }
                }
            }
        }

    }
    
    open func didFailedUploadFile(_ comment:QiscusComment){
        let indexPath = comment.commentIndexPath
        if indexPath.section < self.comments.count && indexPath.row < self.comments[indexPath.section].count{
            collectionView.reloadItems(at: [indexPath])
        }
    }
    open func didSuccessPostFile(_ comment:QiscusComment){
        
    }
    open func didFailedPostFile(_ comment:QiscusComment){
        
    }
    open func didFinishLoadMore(){
        if comments.count > 0{
            let first = comments[0][0]
            let newComments = QiscusComment.grouppedComment(inTopicId: topicId, fromComment: first)
            var mergeLastGroup = false
            if newComments.count > 0{
                let lastGroupComment = newComments.last!
                let lastComment = lastGroupComment.last!
                if lastComment.commentDate == first.commentDate && lastComment.commentSenderEmail == first.commentSenderEmail{
                    mergeLastGroup = true
                }
                collectionView.performBatchUpdates({
                    var i = 0
                    for newGroupComment in newComments{
                        if i == (newComments.count - 1) && mergeLastGroup {
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
                }, completion: nil)
            }
        }else{
            loadData()
        }
        self.loadMoreControl.endRefreshing()
    }
    open func finishedLoadFromAPI(_ topicId: Int){
        let room = QiscusRoom.getRoom(withLastTopicId: self.topicId)
        if newChat {
            newChat = false
        }
        self.subscribeRealtime(onRoom: room)
        self.topicId = topicId
        self.comments = QiscusComment.grouppedComment(inTopicId: topicId, firstLoad: true)
        collectionView.isHidden = true
        collectionView.reloadData()
        if self.comments.count > 0{
            welcomeView.isHidden = true
        }
        scrollToBotomFromNoData()
        self.dismissLoading()
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
    open func didFailedLoadDataFromAPI(_ error: String, data:JSON?){
        self.dismissLoading()
        var errorMessage = "Failed to load room data"
        print("error data: \(data)")
        if data != nil{
            if let error = data!["detailed_messages"].array {
                if let message = error[0].string {
                    errorMessage = message
                }
            }else if let error = data!["message"].string {
                errorMessage = error
            }
        }
        QToasterSwift.toast(target: self, text: errorMessage, backgroundColor: UIColor(red: 0.9, green: 0,blue: 0,alpha: 0.8), textColor: UIColor.white)
    }
    open func gotNewComment(_ comments:[QiscusComment]){
        var refresh = false
        
        if self.comments.count > 0 {
            var needScroolToBottom = false
            
            if firstLoad{
                needScroolToBottom = true
                firstLoad = false
                refresh = true
            }
            if isLastRowVisible{
                needScroolToBottom = true
            }
            if comments.count == 1 && !needScroolToBottom{
                let firstComment = comments[0]
                if firstComment.commentSenderEmail == QiscusConfig.sharedInstance.USER_EMAIL{
                    needScroolToBottom = true
                }
            }
            self.welcomeView.isHidden = true
            if self.comments.count == 0 {
                refresh = true
                needScroolToBottom = false
            }
            for singleComment in comments{
                if singleComment.commentTopicId == self.topicId {
                    let indexPathData = QiscusHelper.properIndexPathOf(comment: singleComment, inGroupedComment: self.comments)
                    
                    let indexPath = IndexPath(row: indexPathData.row, section: indexPathData.section)
                    let indexSet = IndexSet(integer: indexPathData.section)
                    singleComment.updateCommmentIndexPath(indexPath: indexPath)
                    
                    if indexPathData.newGroup {
                        var newCommentGroup = [QiscusComment]()
                        newCommentGroup.append(singleComment)
                        self.comments.insert(newCommentGroup, at: indexPathData.section)
                        if !singleComment.isOwnMessage{
                            unreadIndexPath.append(indexPath)
                        }
                        self.collectionView.performBatchUpdates({
                            self.collectionView.insertSections(indexSet)
                            self.collectionView.insertItems(at: [indexPath])
                        }, completion: nil)
                    }else{
                        self.comments[indexPathData.section].insert(singleComment, at: indexPathData.row)
                        if !singleComment.isOwnMessage{
                            unreadIndexPath.append(indexPath)
                        }
                        self.collectionView.performBatchUpdates({
                            self.collectionView.insertItems(at: [indexPath])
                        }, completion: nil)
                    }
                    
                    var indexPathToReload = [IndexPath]()
                    
                    if indexPath.row > 0 {
                        let indexPathBefore = IndexPath(row: indexPath.row - 1, section: indexPath.section)
                        indexPathToReload.append(indexPathBefore)
                    }else if indexPath.section > 0 {
                        let rowBefore = self.comments[indexPath.section - 1].count - 1
                        let indexPathBefore = IndexPath(row: rowBefore, section: indexPath.section)
                        indexPathToReload.append(indexPathBefore)
                    }
                    if indexPath.row < (self.comments[indexPath.section].count - 1){
                        let indexPathAfter = IndexPath(row: indexPath.row + 1, section: indexPath.section)
                        indexPathToReload.append(indexPathAfter)
                    }else if indexPath.section < (self.comments.count - 1){
                        let indexPathAfter = IndexPath(row: 0, section: indexPath.section + 1)
                        indexPathToReload.append(indexPathAfter)
                    }
                    if indexPathToReload.count > 0 {
                        for reloadIndexPath in indexPathToReload{
                            if self.comments.count > reloadIndexPath.section{
                                if self.comments[reloadIndexPath.section].count > reloadIndexPath.row{
                                    self.collectionView.reloadItems(at: [reloadIndexPath])
                                    
                                }
                            }
                        }
                    }
                }
            }
            if refresh {
                self.collectionView.reloadData()
            }
            if needScroolToBottom{
                let delay = 0.1 * Double(NSEC_PER_SEC)
                let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: time, execute: {
                    self.scrollToBottom()
                })
            }
        }else{
            self.comments = QiscusComment.grouppedComment(inTopicId: self.topicId, firstLoad: true)
            collectionView.reloadData()
            welcomeView.isHidden = true
            let delay = 0.1 * Double(NSEC_PER_SEC)
            let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: time, execute: {
                self.scrollToBottom()
                self.collectionView.isHidden = false
            })
        }
    }
    
    // MARK: - Button Action
    open func showLoading(_ text:String = "Loading"){
        self.showQiscusLoading(withText: text, isBlocking: true)
    }
    open func dismissLoading(){
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
        if Qiscus.sharedInstance.connected{
            let value = inputText.value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            commentClient.postMessage(message: value, topicId: self.topicId, linkData: self.linkData)
            inputText.clearValue()
            inputText.text = ""
            sendButton.isEnabled = false
            showLink = false
            
            self.scrollToBottom()
            self.minInputHeight.constant = 25
            self.inputText.layoutIfNeeded()
        }else{
            self.showNoConnectionToast()
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
                            self.continueImageUpload(image, imageName: fileName, imagePath: imagePath)
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
    func goToIPhoneSetting(){
        UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Upload Action
    func continueImageUpload(_ image:UIImage? = nil,imageName:String,imagePath:URL? = nil, imageNSData:Data? = nil, videoFile:Bool = false, audioFile:Bool = false){
        if Qiscus.sharedInstance.connected{
            Qiscus.printLog(text: "come here")
            commentClient.uploadImage(self.topicId, image: image, imageName: imageName, imagePath: imagePath, imageNSData: imageNSData, videoFile: videoFile, audioFile:audioFile)
        }else{
            self.showNoConnectionToast()
        }
    }
    
    // MARK: UIImagePicker Delegate
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
            
            QPopUpView.showAlert(withTarget: self, image: image, message: text, firstActionTitle: okText, secondActionTitle: cancelText,
                doneAction: {
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
    
    // MARK: - Load More Control
    func loadMore(){
        if self.comments.count > 0 {
            if Qiscus.sharedInstance.connected{
                let firstComment = self.comments[0][0]
                
                if firstComment.commentBeforeId > 0 {
                    commentClient.getListComment(topicId: topicId, commentId: firstComment.commentId, loadMore: true)
                }else{
                    self.loadMoreControl.endRefreshing()
                    self.loadMoreControl.isEnabled = false
                }
            }else{
                self.showNoConnectionToast()
                self.loadMoreControl.endRefreshing()
            }
        }else{
            self.loadData()
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
        self.roomAvatar.contentMode = .scaleAspectFit
        self.roomAvatar.backgroundColor = UIColor.white
        
        let image = Qiscus.image(named: "room_avatar")
        self.roomAvatar.image = image
        
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
    public func itemCount() -> Int {
        return self.galleryItems.count
    }
    public func provideGalleryItem(_ index: Int) -> GalleryItem {
        let item = self.galleryItems[index]
        if item.isVideo{
            return GalleryItem.video(fetchPreviewImageBlock: { $0(item.image)}, videoURL: URL(string: item.url)! )
        }else{
            return GalleryItem.image { $0(item.image) }
        }
    }
    func saveImageToGalery(){
        Qiscus.printLog(text: "saving image")
        UIImageWriteToSavedPhotosAlbum(self.selectedImage, self, #selector(QiscusChatVC.succesSaveImage), nil)
    }
    func succesSaveImage(){
         QToasterSwift.toast(target: self.imagePreview!, text: "Successfully save image to your galery", backgroundColor: UIColor(red: 0, green: 0.8,blue: 0,alpha: 0.8), textColor: UIColor.white)
    }
    func setTitle(title:String = "", withSubtitle:String? = nil){
        QiscusUIConfiguration.sharedInstance.copyright.chatTitle = title
        if withSubtitle != nil {
            QiscusUIConfiguration.sharedInstance.copyright.chatSubtitle = withSubtitle!
        }
        var navTitle = ""
        if title != ""{
            navTitle = title
        }else{
            if let room = QiscusRoom.getRoom(withLastTopicId: self.topicId){
               navTitle = room.roomName
               QiscusTextConfiguration.sharedInstance.chatTitle = navTitle
            }
        }
        self.navigationItem.setTitleWithSubtitle(title: navTitle, subtitle:QiscusTextConfiguration.sharedInstance.chatSubtitle)
    }
    func startTypingIndicator(withUser user:String){
        self.typingIndicatorUser = user
        self.isTypingOn = true
        let typingText = "\(user) is typing ..."
        self.navigationItem.setTitleWithSubtitle(title: QiscusTextConfiguration.sharedInstance.chatTitle, subtitle:typingText)
    }
    func stopTypingIndicator(){
        self.typingIndicatorUser = ""
        self.isTypingOn = false
        self.navigationItem.setTitleWithSubtitle(title: QiscusTextConfiguration.sharedInstance.chatTitle, subtitle:QiscusTextConfiguration.sharedInstance.chatSubtitle)
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
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            if let activeCell = activeAudioCell as? QCellAudioLeft{
                activeCell.isPlaying = false
            }
            stopTimer()
            updateAudioDisplay()
        } catch _ as NSError {}
    }
    
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let activeCell = activeAudioCell as? QCellAudioLeft{
            activeCell.isPlaying = false
        }
        stopTimer()
        updateAudioDisplay()
    }
    
    
    // MARK: IQAudioRecorderViewControllerDelegate
    
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
    
    // MARK: - Audio Methods
    
    func audioTimerFired(_ timer: Timer) {
        self.updateAudioDisplay()
    }
    
    func stopTimer() {
        audioTimer?.invalidate()
        audioTimer = nil
    }
    
    func updateAudioDisplay() {
        if let cell = activeAudioCell as? QCellAudioLeft{
            if let currentTime = audioPlayer?.currentTime {
                cell.currentTimeSlider.setValue(Float(currentTime), animated: true)
                cell.seekTimeLabel.text = cell.timeFormatter?.string(from: currentTime)
            }
        }else if let cell = activeAudioCell as? QCellAudioRight{
            if let currentTime = audioPlayer?.currentTime {
                cell.currentTimeSlider.setValue(Float(currentTime), animated: true)
                cell.seekTimeLabel.text = cell.timeFormatter?.string(from: currentTime)
            }
        }
    }
    
    // MARK: - ChatCellAudioDelegate
    func didTapDownloadButton(_ button: UIButton, onCell cell: UICollectionViewCell) {
        if let targetCell = cell as? QCellAudioLeft{
            targetCell.isDownloading = true
            targetCell.playButton.removeTarget(nil, action: nil, for: .allEvents)
            let selectedComment = self.comments[(targetCell.indexPath?.section)!][(targetCell.indexPath?.row)!]
            self.commentClient.downloadMedia(selectedComment, isAudioFile: true)
        }else if let targetCell = cell as? QCellAudioRight{
            targetCell.isDownloading = true
            targetCell.playButton.removeTarget(nil, action: nil, for: .allEvents)
            let selectedComment = self.comments[(targetCell.indexPath?.section)!][(targetCell.indexPath?.row)!]
            self.commentClient.downloadMedia(selectedComment, isAudioFile: true)
        }
        Qiscus.printLog(text: "downloading")
    }
        
    func didTapPlayButton(_ button: UIButton, onCell cell: UICollectionViewCell) {
        if let targetCell = cell as? QCellAudioLeft{
            let path = targetCell.filePath
            if let url = URL(string: path) {
                if audioPlayer != nil {
                    if audioPlayer!.isPlaying {
                        if let activeCell = activeAudioCell as? QCellAudioLeft{
                            activeCell.isPlaying = false
                        }else if let activeCell = activeAudioCell as? QCellAudioRight{
                            activeCell.isPlaying = false
                        }
                        audioPlayer?.stop()
                        stopTimer()
                        updateAudioDisplay()
                    }
                }
                
                activeAudioCell = targetCell
                
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: url)
                }
                catch let error as NSError {
                    Qiscus.printLog(text: error.localizedDescription)
                }
                
                audioPlayer?.delegate = self
                audioPlayer?.currentTime = Double(targetCell.currentTimeSlider.value)
                
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
                        //Qiscus.printLog(text: error.localizedDescription)
                    }
                } catch _ as NSError {
                    //Qiscus.printLog(text: error.localizedDescription)
                }
            }
        }else if let targetCell = cell as? QCellAudioRight{
            let path = targetCell.filePath
            if let url = URL(string: path) {
                if audioPlayer != nil {
                    if audioPlayer!.isPlaying {
                        if let activeCell = activeAudioCell as? QCellAudioRight{
                            activeCell.isPlaying = false
                        }else if let activeCell = activeAudioCell as? QCellAudioLeft{
                            activeCell.isPlaying = false
                        }
                        audioPlayer?.stop()
                        stopTimer()
                        updateAudioDisplay()
                    }
                }
                
                activeAudioCell = targetCell
                
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: url)
                }
                catch let error as NSError {
                    Qiscus.printLog(text: error.localizedDescription)
                }
                
                audioPlayer?.delegate = self
                audioPlayer?.currentTime = Double(targetCell.currentTimeSlider.value)
                
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
                        //Qiscus.printLog(text: error.localizedDescription)
                    }
                } catch _ as NSError {
                    //Qiscus.printLog(text: error.localizedDescription)
                }
            }
        }
        
    }
    
    func didTapPauseButton(_ button: UIButton, onCell cell: UICollectionViewCell) {
        audioPlayer?.pause()
        stopTimer()
        updateAudioDisplay()
    }
    
    func didStartSeekTimeSlider(_ slider: UISlider, onCell cell: UICollectionViewCell) {
        if audioTimer != nil {
            stopTimer()
        }
    }
    
    func didEndSeekTimeSlider(_ slider: UISlider, onCell cell: UICollectionViewCell) {
        audioPlayer?.stop()
        if let targetCell = cell as? QCellAudioLeft{
            let currentTime = targetCell.currentTimeSlider.value
            audioPlayer?.currentTime = Double(currentTime)
        }
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
        
        audioTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(audioTimerFired(_:)), userInfo: nil, repeats: true)
    }
    
    // MARK: - UICollectionViewDelegate
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {

        if let targetCell = cell as? QChatCell{
//            targetCell.setupCell()
            if !targetCell.comment.isOwnMessage && targetCell.comment.commentStatusRaw != QiscusCommentStatus.read.rawValue{
                publishRead(comment: targetCell.comment)
                var i = 0
                for index in unreadIndexPath{
                    if index.row == indexPath.row && index.section == indexPath.section{
                        unreadIndexPath.remove(at: i)
                        updateComment(onIndexPath: indexPath)
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
                if let file = QiscusFile.getCommentFileWithComment(comment){
                    if file.isUploaded || file.isOnlyLocalFileExist{
                        show = true
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
        
    // MARK: - UICollectionViewDataSource
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.comments[section].count
    }
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.comments.count
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let comment = self.comments[indexPath.section][indexPath.row]
        comment.updateCommmentIndexPath(indexPath: indexPath)
        
        let cellTypePosition = QChatCellHelper.getCellPosition(ofIndexPath: indexPath, inGroupOfComment: self.comments)
        var cellIdentifier = ""
        var position:String = "Left"
        if comment.isOwnMessage{
            position = "Right"
        }
        switch comment.commentType {
        case .text:
            cellIdentifier = "cellText\(position)"
            break
        default:
            if let file = QiscusFile.getCommentFile(comment.commentFileId) {
                switch file.fileType {
                case .media:
                    cellIdentifier = "cellMedia\(position)"
                    break
                case .video:
                    cellIdentifier = "cellMedia\(position)"
                    break
                case .audio:
                    cellIdentifier = "cellAudio\(position)"
                    break
                default:
                    cellIdentifier = "cellFile\(position)"
                    break
                }
            }
            break
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! QChatCell
        cell.prepareCell(withComment: comment, cellPos: cellTypePosition, indexPath: indexPath, cellDelegate: self)
        cell.setupCell()
        if let audioCell = cell as? QCellAudio{
            audioCell.delegate = self
            return audioCell
        }else{
            return cell
        }
    }
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let comment = self.comments[indexPath.section].first!
        
        if kind == UICollectionElementKindSectionFooter{
            if comment.isOwnMessage{
                let footerCell = self.collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "cellFooterRight", for: indexPath) as! QChatFooterRight
                footerCell.setup(withComent: comment)
                return footerCell
            }else{
                let footerCell = self.collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "cellFooterLeft", for: indexPath) as! QChatFooterLeft
                footerCell.setup(withComent: comment)
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
        if !firstComment.isOwnMessage{
            height = 44
            width = 44
        }
        return CGSize(width: width, height: height)
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let firstComment = self.comments[section][0]
        if firstComment.isOwnMessage{
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }else{
            return UIEdgeInsets(top: 0, left: 0, bottom: -44, right: 0)
        }
    }
    // MARK: - UICollectionViewDelegateFlowLayout
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height = CGFloat(50)
        if self.comments.count > 0 {
            let comment = self.comments[indexPath.section][indexPath.row]
            let cellTypePosition = QChatCellHelper.getCellPosition(ofIndexPath: indexPath, inGroupOfComment: self.comments)
            height = comment.commentCellHeight
            if cellTypePosition == .first || cellTypePosition == .single{
                height += 20
            }
        }
        return CGSize(width: collectionView.bounds.size.width, height: height)
    }
    @IBAction func goToBottomTapped(_ sender: UIButton) {
        scrollToBottom(true)
    }
    func publishRead(comment:QiscusComment){
        commentClient.publishMessageStatus(onComment: comment.commentId, roomId: comment.roomId, status: .read, withCompletion: {
            comment.updateCommentStatus(.read)
        })
    }
    func updateComment(onIndexPath indexPath:IndexPath){
        let comment = self.comments[indexPath.section][indexPath.row]
        if let updatedComment = QiscusComment.getCommentById(comment.commentId){
            self.comments[indexPath.section][indexPath.row] = updatedComment
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
            print("LinkData: \(linkData)")
            self.linkImage.loadAsync(linkData.linkImageURL)
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
        self.linkPreviewTopMargin.constant = 0
        UIView.animate(withDuration: 0.65, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    // MARK: - ChatCellDelegate
    func didChangeSize(onCell cell:QChatCell){
        if let indexPath = cell.indexPath {
            if indexPath.section < self.comments.count{
                if indexPath.row < self.comments[indexPath.section].count{
                    collectionView.reloadItems(at: [indexPath])
                }
            }
        }
    }
}
