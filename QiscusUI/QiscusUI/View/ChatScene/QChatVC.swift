//
//  QChatVC.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 07/05/18.
//

import UIKit
import ContactsUI
import SwiftyJSON
open class QChatVC: UIViewController {
    
    @IBOutlet weak var tableViewConversation: UITableView!
    @IBOutlet weak var viewInput: NSLayoutConstraint!
    @IBOutlet weak var btnAttachment: UIButton!
    @IBOutlet weak var btnSend: UIButton!
    @IBOutlet weak var tfInput: UITextField!
    @IBOutlet weak var constraintViewInputBottom: NSLayoutConstraint!
    private var titleLabel = UILabel()
    private var subtitleLabel = UILabel()
    private var subtitleText:String = ""
    private var roomAvatar = UIImageView()
    private var titleView = UIView()
    private var presenter: QChatPresenter!
    var heightAtIndexPath: [String: CGFloat] = [:]
    
    var roomId: String = ""
    var tempSection = -1
    
    public init() {
        super.init(nibName: "QChatVC", bundle: QiscusUI.bundle)
        self.presenter = QChatPresenter(view: self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        // Do any additional setup after loading the view.
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.presenter.loadRoom(withId: self.roomId)
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(QChatVC.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        center.addObserver(self, selector: #selector(QChatVC.keyboardChange(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        view.endEditing(true)
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillChangeFrame, object: nil)
        
        view.endEditing(true)
    }
    
    //    MARK: View Event Listener
    @IBAction func send(_ sender: UIButton) {
        guard let text = self.tfInput.text else {return}
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.presenter.sendMessage(withText: text)
        }
        
        self.tfInput.text = ""
    }
    
    
    private func setupUI() {
        // config navBar
        self.setupNavigationTitle()
        self.qiscusAutoHideKeyboard()
        self.setupTableView()
    }
    
    private func setupNavigationTitle(){
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = false
        }
        var totalButton = 1
        if let leftButtons = self.navigationItem.leftBarButtonItems {
            totalButton += leftButtons.count
        }
        if let rightButtons = self.navigationItem.rightBarButtonItems {
            totalButton += rightButtons.count
        }
        
        //        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(QiscusChatVC.goToTitleAction))
        //        self.titleView.addGestureRecognizer(tapRecognizer)
        
        let containerWidth = QiscusHelper.screenWidth() - 49
        let titleWidth = QiscusHelper.screenWidth() - CGFloat(49 * totalButton) - 40
        
        self.titleLabel.frame = CGRect(x: 40, y: 7, width: titleWidth, height: 17)
        self.titleLabel.textColor = UINavigationBar.appearance().tintColor
        
        self.subtitleLabel.frame = CGRect(x: 40, y: 25, width: titleWidth, height: 13)
        self.subtitleLabel.textColor = UINavigationBar.appearance().tintColor
        
        self.roomAvatar.frame = CGRect(x: 0,y: 6,width: 32,height: 32)
        self.roomAvatar.layer.cornerRadius = 16
        self.roomAvatar.contentMode = .scaleAspectFill
        self.roomAvatar.backgroundColor = UIColor.white
        //        let bgColor = QiscusColorConfiguration.sharedInstance.avatarBackgroundColor
        self.roomAvatar.frame = CGRect(x: 0,y: 6,width: 32,height: 32)
        self.roomAvatar.layer.cornerRadius = 16
        self.roomAvatar.clipsToBounds = true
        //        self.roomAvatar.backgroundColor = bgColor[0]
        
        self.titleView.frame = CGRect(x: 0, y: 0, width: containerWidth, height: 44)
        self.titleView.addSubview(self.titleLabel)
        self.titleView.addSubview(self.subtitleLabel)
        self.titleView.addSubview(self.roomAvatar)
        
        let backButton = self.backButton(self, action: #selector(QChatVC.goBack))
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.navigationItem.leftBarButtonItems = [backButton]
        
        self.navigationItem.titleView = titleView
    }
    
    private func backButton(_ target: UIViewController, action: Selector) -> UIBarButtonItem{
        let backIcon = UIImageView()
        backIcon.contentMode = .scaleAspectFit
        
        let image = QiscusUI.image(named: "ic_back")?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
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
    
    private func setupTableView() {
        let rotate = CGAffineTransform(rotationAngle: CGFloat(M_PI))
        self.tableViewConversation.transform = rotate
        self.tableViewConversation.scrollIndicatorInsets = UIEdgeInsetsMake(0,0,0,self.tableViewConversation.bounds.size.width-10)
        self.tableViewConversation.rowHeight = UITableViewAutomaticDimension
        self.tableViewConversation.dataSource = self
        self.tableViewConversation.delegate = self
        self.tableViewConversation.scrollsToTop = false
        self.tableViewConversation.allowsSelection = false
        
        self.tableViewConversation.register(UINib(nibName: "LeftTextCell", bundle: QiscusUI.bundle), forCellReuseIdentifier: "LeftTextCell")
        self.tableViewConversation.register(UINib(nibName: "QImageCell", bundle: QiscusUI.bundle), forCellReuseIdentifier: "QImageCell")
        self.tableViewConversation.register(UINib(nibName: "QSystemCell", bundle: QiscusUI.bundle), forCellReuseIdentifier: "QSystemCell")
        self.tableViewConversation.register(UINib(nibName: "QContactCell", bundle: QiscusUI.bundle), forCellReuseIdentifier: "QContactCell")
        self.tableViewConversation.register(UINib(nibName: "QAudioCell", bundle: QiscusUI.bundle), forCellReuseIdentifier: "QAudioCell")
        self.tableViewConversation.register(UINib(nibName: "QDocumentCell", bundle: QiscusUI.bundle), forCellReuseIdentifier: "QDocumentCell")
        
        self.tableViewConversation.register(UINib(nibName: "QLocationCell", bundle: QiscusUI.bundle), forCellReuseIdentifier: "QLocationCell")

    }
    
    @objc func goBack() {
        view.endEditing(true)
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Keyboard Methode
    @objc func keyboardWillHide(_ notification: Notification){
        let info: NSDictionary = (notification as NSNotification).userInfo! as NSDictionary
        
        let animateDuration = info[UIKeyboardAnimationDurationUserInfoKey] as! Double
        //        let goToRow = self.lastVisibleRow
        self.constraintViewInputBottom.constant = 0
        UIView.animate(withDuration: animateDuration, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.view.layoutIfNeeded()
            //            if goToRow != nil {
            //                self.collectionView.scrollToItem(at: goToRow!, at: .bottom, animated: false)
            //            }
        }, completion: nil)
    }
    
    @objc func keyboardChange(_ notification: Notification){
        let info:NSDictionary = (notification as NSNotification).userInfo! as NSDictionary
        let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        let keyboardHeight: CGFloat = keyboardSize.height
        let animateDuration = info[UIKeyboardAnimationDurationUserInfoKey] as! Double
        
        self.constraintViewInputBottom.constant = 0 - keyboardHeight
        //        let goToRow = self.lastVisibleRow
        UIView.animate(withDuration: animateDuration, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.view.layoutIfNeeded()
            //            if goToRow != nil {
            //                self.collectionView.scrollToItem(at: goToRow!, at: .bottom, animated: true)
            //            }
        }, completion: nil)
    }
}

extension QChatVC: QChatViewDelegate {
    func onLoadRoomFinished(roomName: String, roomAvatar: UIImage?) {
        DispatchQueue.main.async {
            self.titleLabel.text = roomName
            self.roomAvatar.image = roomAvatar
        }
    }
    
    func onLoadMessageFinished() {
        self.tableViewConversation.reloadData()
    }
    
    func onSendMessageFinished(comment: CommentModel) {
        
    }
    
    func onGotNewComment(newSection: Bool, isMyComment: Bool) {
        if Thread.isMainThread {
            if newSection {
                self.tableViewConversation.beginUpdates()
                self.tableViewConversation.insertSections(IndexSet(integer: 0), with: .none)
                if isMyComment {
                    self.tableViewConversation.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
                }
                self.tableViewConversation.endUpdates()
            } else {
                let indexPath = IndexPath(row: 0, section: 0)
                self.tableViewConversation.beginUpdates()
                self.tableViewConversation.insertRows(at: [indexPath], with: .none)
                if isMyComment {
                    self.tableViewConversation.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
                }
                self.tableViewConversation.endUpdates()
            }
        }
    }
}

extension QChatVC: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionCount = self.presenter.getComments().count
        let rowCount = self.presenter.getComments()[section].count
        if sectionCount == 0 {
            return 0
        }
        return rowCount
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.presenter.getComments().count
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let commentId = self.presenter.getComments()[indexPath.section][indexPath.row].uniqueId
        if let cachedHeight = heightAtIndexPath[commentId] {
            return cachedHeight
        } else {
            return UITableViewAutomaticDimension
        }
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let commentId = self.presenter.getComments()[indexPath.section][indexPath.row].uniqueId
        if let cachedHeight = heightAtIndexPath[commentId] {
            return cachedHeight
        } else {
            return UITableViewAutomaticDimension
        }
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let commentId = self.presenter.getComments()[indexPath.section][indexPath.row].uniqueId
        if let height = self.heightAtIndexPath[commentId] {
            
        } else {
            heightAtIndexPath[commentId] = cell.frame.size.height
        }
    }
    
    // MARK: table cell confi
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let comment = self.presenter.getComments()[indexPath.section][indexPath.row]
        let commentType = comment.commentType
        
        tempSection = indexPath.section
        var cell = BaseChatCell()
        switch commentType {
        case .image:
            cell = tableView.dequeueReusableCell(withIdentifier: "QImageCell", for: indexPath) as! QImageCell
            break
        case .system:
            cell = tableView.dequeueReusableCell(withIdentifier: "QSystemCell", for: indexPath) as! QSystemCell
            break
        case .contact:
            cell = tableView.dequeueReusableCell(withIdentifier: "QContactCell",for: indexPath) as! QContactCell
            break
        case .audio:
            cell = tableView.dequeueReusableCell(withIdentifier: "QAudioCell",for: indexPath) as! QAudioCell
            break
        case .document:
            cell = tableView.dequeueReusableCell(withIdentifier: "QDocumentCell",for: indexPath) as! QDocumentCell
            break
        case .location:
            cell = tableView.dequeueReusableCell(withIdentifier: "QLocationCell",for: indexPath) as! QLocationCell
            break
        default:
            cell = tableView.dequeueReusableCell(withIdentifier: "LeftTextCell", for: indexPath) as! LeftTextCell
        }
        
        cell.firstInSection = indexPath.row == self.presenter.getComments()[indexPath.section].count - 1
        cell.comment = comment
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.main.scale
        cell.delegate = self
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let firstComment = self.presenter.getComments()[section].first {
            if firstComment.isMyComment {
                return 1
            } else {
                return 1
            }
        }
        
        return 1
    }
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        var label = UILabel(frame: CGRect(x: 30, y: 30, width: 200, height: 150))
        label.textAlignment = NSTextAlignment.center
        self.presenter.getDate(section: section,labelView: label)
        label.clipsToBounds = true
        label.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
        self.view.addSubview(label)
        return label
    }
    // MARK: chat avatar setup
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: QiscusHelper.screenWidth(), height: 0))
        view.backgroundColor = .clear
        view.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
        
        let viewAvatar = UIView(frame: CGRect(x: 5, y: -30, width: 30, height: 60))
        let avatar = UIImageView(frame: CGRect(x: 5, y: 0, width: 30, height: 30))
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = avatar.frame.width/2
        avatar.backgroundColor = .black
        avatar.contentMode = .scaleAspectFill
        
        viewAvatar.addSubview(avatar)
        
        self.presenter.getAvatarImage(section: section, imageView: avatar)
        
        
        view.addSubview(viewAvatar)
        
        if let firstComment = self.presenter.getComments()[section].first {
            if firstComment.isMyComment {
                return nil
            } else if firstComment.commentType != .system {
                return view
            }
        }
        return nil
    }
}

extension QChatVC: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
extension QChatVC:CNContactViewControllerDelegate{
    
}
extension QChatVC: ChatCellDelegate {
    func onSaveContactCellDidTap(comment: CommentModel) {
        let payloadString = comment.additionalData
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
    
    func onImageCellDidTap(imageSlideShow: UIViewController) {
        self.navigationController?.present(imageSlideShow, animated: true, completion: nil)
    }
}

