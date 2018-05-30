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
    
    var menuItems: [UIMenuItem] = [UIMenuItem]()
    
    let resendMenuItem: UIMenuItem = UIMenuItem(title: "RESEND".getLocalize(), action: #selector(BaseChatCell.resend))
    let copyMenuItem: UIMenuItem = UIMenuItem(title: "COPY".getLocalize(), action: #selector(BaseChatCell.copyComment))
    let deleteMenuItem: UIMenuItem = UIMenuItem(title: "DELETE".getLocalize(), action: #selector(BaseChatCell.deleteComment))
    let deleteForMeMenuItem: UIMenuItem = UIMenuItem(title: "DELETE_FOR_ME".getLocalize(), action: #selector(BaseChatCell.deleteForMe))
    let replyMenuItem: UIMenuItem = UIMenuItem(title: "REPLY".getLocalize(), action: #selector(BaseChatCell.reply))
    let forwardMenuItem: UIMenuItem = UIMenuItem(title: "FORWARD".getLocalize(), action: #selector(BaseChatCell.forward))
    let shareMenuItem: UIMenuItem = UIMenuItem(title: "SHARE".getLocalize(), action: #selector(BaseChatCell.share))
    let infoMenuItem: UIMenuItem = UIMenuItem(title: "INFO".getLocalize(), action: #selector(BaseChatCell.info))
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.configureUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configureUI()
    }
    
    func configureUI() {
        self.menuItems.append(copyMenuItem)
        self.menuItems.append(resendMenuItem)
        self.menuItems.append(deleteMenuItem)
        self.menuItems.append(deleteForMeMenuItem)
        self.menuItems.append(replyMenuItem)
        self.menuItems.append(forwardMenuItem)
        self.menuItems.append(shareMenuItem)
        self.menuItems.append(infoMenuItem)
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func awakeFromNib() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(BaseChatCell.handleLongPress))
        
        self.contentView.addGestureRecognizer(longPress)
    }
    
    func bindDataToView() {
        
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(BaseChatCell.resend) || action == #selector(BaseChatCell.deleteComment) || action == #selector(BaseChatCell.deleteForMe) || action == #selector(BaseChatCell.reply) || action == #selector(BaseChatCell.forward) || action == #selector(BaseChatCell.share) || action == #selector(BaseChatCell.info) || action == #selector(BaseChatCell.copyComment) {
            return true
        }
        
        return false
    }
    
    @objc open func handleLongPress() {
        self.contentView.becomeFirstResponder()
        UIMenuController.shared.menuItems = menuItems
        
        let frame = CGRect(x: 0, y: 0, width: 150, height: 50)
        
        UIMenuController.shared.setTargetRect(frame, in: self.contentView)
        
        DispatchQueue.main.async {
            UIMenuController.shared.setMenuVisible(true, animated: true)
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
