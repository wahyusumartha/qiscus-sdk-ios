//
//  BaseChatCell.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 09/05/18.
//

import Foundation

class BaseChatCell: UITableViewCell {
    var firstInSection: Bool = false
    var comment: CommentModel! {
        didSet {
            bindDataToView()
        }
    }
    var indexPath: IndexPath!
    var didLongPressed: Bool = false
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.configureUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configureUI()
    }
    
    func configureUI() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(BaseChatCell.handleLongPress))
        
        self.contentView.addGestureRecognizer(longPress)
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func awakeFromNib() {
        
    }
    
    func bindDataToView() {

    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(BaseChatCell.resend) || action == #selector(BaseChatCell.deleteComment) || action == #selector(BaseChatCell.deleteForMe) || action == #selector(BaseChatCell.reply) || action == #selector(BaseChatCell.forward) || action == #selector(BaseChatCell.share) || action == #selector(BaseChatCell.info) || action == #selector(BaseChatCell.copyComment) {
            return true
        }
        
        return false
    }
    
    func menuResponderView() -> UIView {
        return UIView()
    }
    
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
