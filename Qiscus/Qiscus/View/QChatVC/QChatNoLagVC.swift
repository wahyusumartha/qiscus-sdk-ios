//
//  QChatNoLagVC.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 16/05/18.
//

import UIKit

open class QChatNoLagVC: UIViewController {
    @IBOutlet weak var tableViewConversation: UITableView!
    
    private var presenter: QChatPresenter!
    private var comments: [[CommentModel]] = []
    
    private var titleLabel = UILabel()
    private var subtitleLabel = UILabel()
    private var subtitleText:String = ""
    private var roomAvatar = UIImageView()
    private var titleView = UIView()
    
    public init() {
        super.init(nibName: "QChatNoLagVC", bundle: Qiscus.bundle)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.presenter = QChatPresenter(view: self)
        self.comments = presenter.getComments()
        self.setupTableView()
        self.setupNavigationTitle()
        // Do any additional setup after loading the view.
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
        self.titleLabel.textColor = QiscusChatVC.currentNavbarTint
        
        self.subtitleLabel.frame = CGRect(x: 40, y: 25, width: titleWidth, height: 13)
        self.subtitleLabel.textColor = QiscusChatVC.currentNavbarTint
        
        self.roomAvatar.frame = CGRect(x: 0,y: 6,width: 32,height: 32)
        self.roomAvatar.layer.cornerRadius = 16
        self.roomAvatar.contentMode = .scaleAspectFill
        self.roomAvatar.backgroundColor = UIColor.white
        let bgColor = QiscusColorConfiguration.sharedInstance.avatarBackgroundColor
        self.roomAvatar.frame = CGRect(x: 0,y: 6,width: 32,height: 32)
        self.roomAvatar.layer.cornerRadius = 16
        self.roomAvatar.clipsToBounds = true
        self.roomAvatar.backgroundColor = bgColor[0]
        
        self.titleView.frame = CGRect(x: 0, y: 0, width: containerWidth, height: 44)
        self.titleView.addSubview(self.titleLabel)
        self.titleView.addSubview(self.subtitleLabel)
        self.titleView.addSubview(self.roomAvatar)
        
        let backButton = QiscusChatVC.backButton(self, action: #selector(QChatVC.goBack))
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.navigationItem.leftBarButtonItems = [backButton]
        
        self.navigationItem.titleView = titleView
    }

    private func setupTableView() {
        self.tableViewConversation.dataSource = self
        self.tableViewConversation.delegate = self
        self.tableViewConversation.estimatedRowHeight = 30
        self.tableViewConversation.rowHeight = UITableViewAutomaticDimension
        
        self.tableViewConversation.register(UINib(nibName: "PlainTextCell", bundle: Qiscus.bundle), forCellReuseIdentifier: "PlainTextCell")
        self.tableViewConversation.register(UINib(nibName: "LeftTextCell", bundle: Qiscus.bundle), forCellReuseIdentifier: "LeftTextCell")
    }
}

extension QChatNoLagVC: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

extension QChatNoLagVC: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !self.comments.isEmpty {
            return self.comments[section].count
        }
        
        return 0
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.comments.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        if !self.comments.isEmpty {
//            let comment = self.comments[indexPath.section][indexPath.row]
////            let cell = tableView.dequeueReusableCell(withIdentifier: "PlainTextCell", for: indexPath) as! PlainTextCell
////            cell.label.text = comment.text
//            
//            
//            
//            cell.comment = comment
//            
//            return cell
//        }
//        
        return UITableViewCell()
    }
    
}

extension QChatNoLagVC: QChatViewDelegate {
    func onLoadRoomFinished(roomName: String, roomAvatar: UIImage?) {
        
    }
    
    func onLoadMessageFinished() {
        
    }
    
    func onSendMessageFinished(comment: CommentModel) {
        
    }
    
    func onGotNewComment(newSection: Bool, isMyComment: Bool) {
        
    }
}
