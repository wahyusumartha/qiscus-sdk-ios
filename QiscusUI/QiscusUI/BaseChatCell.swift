//
//  BaseChatCell.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 09/05/18.
//

import Foundation
import Qiscus

protocol ChatCellDelegate {
    func onImageCellDidTap(imageSlideShow: UIViewController)
    func onSaveContactCellDidTap(comment: CommentModel)
}

protocol ChatCellAudioDelegate {
    func didTapPlayButton(_ button: UIButton, onCell cell: BaseChatCell)
    func didTapPauseButton(_ button: UIButton, onCell cell: BaseChatCell)
    func didTapDownloadButton(_ button: UIButton, onCell cell: BaseChatCell)
    func didStartSeekTimeSlider(_ slider: UISlider, onCell cell: BaseChatCell)
    func didEndSeekTimeSlider(_ slider: UISlider, onCell cell: BaseChatCell)
}

class BaseChatCell: UITableViewCell {
    var audioCellDelegate: ChatCellAudioDelegate?
    var _timeFormatter: DateComponentsFormatter?
    var currentTime = TimeInterval()
    var timeFormatter: DateComponentsFormatter? {
        get {
            if _timeFormatter == nil {
                _timeFormatter = DateComponentsFormatter()
                _timeFormatter?.zeroFormattingBehavior = .pad;
                _timeFormatter?.allowedUnits = [.minute, .second]
                _timeFormatter?.unitsStyle = .positional;
            }
            
            return _timeFormatter
        }
        
        set {
            _timeFormatter = newValue
        }
    }
    
    // MARK: cell data source
    var comment: CommentModel! {
        didSet {
            configureInteractino()
            bindDataToView()
        }
    }
    var indexPath: IndexPath!
    var firstInSection: Bool = false
    
    // MARK: Delegate
    var delegate: ChatCellDelegate?
    
    // MARK: UI Flag
    var didLongPressed: Bool = false
    
    // MARK: UI Variable
    let maxProgressHeight:CGFloat = 40.0
    let longPress = UILongPressGestureRecognizer(target: self, action: #selector(BaseChatCell.handleLongPress))
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.configureUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configureUI()
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    /// configure ui element when init cell
    func configureUI() {
        // MARK: configure long press on cell
        self.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
    }
    
    func configureInteractino() {
        if self.comment.commentType != .system {
            self.contentView.addGestureRecognizer(longPress)
        }
    }
    
    
    /// bind data to view when comment did set
    func bindDataToView() {
        preconditionFailure("this func must be override")
        // no default implementation for now
    }
    
    
    /// view to become center focus for menu item
    ///
    /// - Returns: UIView
    func menuResponderView() -> UIView {
        preconditionFailure("this func must be override")
        return UIView()
    }
    
    func downloadMedia() {
        if let qComment = QComment.comment(withId: self.comment.id), let qRoom = QRoom.room(withId: self.comment.roomId) {
            qRoom.downloadMedia(onComment: qComment, isAudioFile: self.comment.commentType == .audio, onSuccess: { (qComment) in
                guard let image = qComment.displayImage else {return}
                QCacheManager.shared.cacheImage(image: image, onCommentUniqueId: qComment.uniqueId)
                self.displayDownloadedImage(image: image)
            }, onError: { (error) in
                
            }, onProgress: { (progress) in
                self.updateDownloadProgress(progress: progress)
                print("download progress \(progress)")
            })
        }
    }
    
    func displayDownloadedImage(image: UIImage?) {
        
    }
    
    func updateDownloadProgress(progress: Double) {
        // MARK: download func implemented on file or image cell
    }
    
    /// filter menu for cell's menu
    ///
    /// - Parameters:
    ///   - action: menu action selector
    ///   - sender:
    /// - Returns: bool contain menu or not
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(BaseChatCell.resend) || action == #selector(BaseChatCell.deleteComment) || action == #selector(BaseChatCell.deleteForMe) || action == #selector(BaseChatCell.reply) || action == #selector(BaseChatCell.forward) || action == #selector(BaseChatCell.share) || action == #selector(BaseChatCell.info) || action == #selector(BaseChatCell.copyComment) {
            return true
        }
        
        return false
    }
}

// MARK: cell menu action
extension BaseChatCell {
    @objc open func handleLongPress() {
        if !self.didLongPressed {
            self.becomeFirstResponder()
            
            var menuItems: [UIMenuItem] = [UIMenuItem]()
            
            let resendMenuItem: UIMenuItem = UIMenuItem(title: "RESEND".getLocalize(), action: #selector(BaseChatCell.resend))
            let copyMenuItem: UIMenuItem = UIMenuItem(title: "COPY".getLocalize(), action: #selector(BaseChatCell.copyComment))
            let deleteMenuItem: UIMenuItem = UIMenuItem(title: "DELETE".getLocalize(), action: #selector(BaseChatCell.deleteComment))
            let deleteForMeMenuItem: UIMenuItem = UIMenuItem(title: "DELETE_FOR_ME".getLocalize(), action: #selector(BaseChatCell.deleteForMe))
            let replyMenuItem: UIMenuItem = UIMenuItem(title: "REPLY".getLocalize(), action: #selector(BaseChatCell.reply))
            let forwardMenuItem: UIMenuItem = UIMenuItem(title: "FORWARD".getLocalize(), action: #selector(BaseChatCell.forward))
            let shareMenuItem: UIMenuItem = UIMenuItem(title: "SHARE".getLocalize(), action: #selector(BaseChatCell.share))
            let infoMenuItem: UIMenuItem = UIMenuItem(title: "INFO".getLocalize(), action: #selector(BaseChatCell.info))
            
            if self.comment.commentStatus == .failed {menuItems.append(resendMenuItem)}
            menuItems.append(copyMenuItem)
            menuItems.append(replyMenuItem)
            menuItems.append(deleteMenuItem)
            menuItems.append(deleteForMeMenuItem)
            menuItems.append(forwardMenuItem)
            menuItems.append(shareMenuItem)
            menuItems.append(infoMenuItem)
            UIMenuController.shared.menuItems = menuItems
            
            UIMenuController.shared.setTargetRect(self.menuResponderView().frame, in: self.contentView)
            
            DispatchQueue.main.async {
                UIMenuController.shared.setMenuVisible(true, animated: true)
            }
            
            self.didLongPressed = true
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1, execute: {
                self.didLongPressed = false
            })
        }
    }
    
    @objc open func copyComment() {
        UIPasteboard.general.string = self.comment.text
    }
    
    @objc open func resend(){
        
    }
    
    @objc open func deleteComment(){
        
    }
    
    @objc open func deleteForMe(){
        
    }
    
    @objc open func reply(){
        
    }
    
    @objc open func forward(){
        
    }
    
    @objc open func share(){
        
    }
    
    @objc open func info(){
        
    }
}
