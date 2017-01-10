//
//  QChatFooterLeft.swift
//  Example
//
//  Created by Ahmad Athaullah on 1/9/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

class QChatFooterLeft: UICollectionReusableView {

    @IBOutlet weak var avatarImage: UIImageView!
    
    var comment = QiscusComment()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        avatarImage.layer.cornerRadius = 19
        avatarImage.clipsToBounds = true
        self.isUserInteractionEnabled = true
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(QChatFooterLeft.showMenu)))
    }
    
    func setup(withComent comment:QiscusComment){
        let avatar = Qiscus.image(named: "in_chat_avatar")
        self.comment = comment
        if let user = comment.sender{
            if QiscusHelper.isFileExist(inLocalPath: user.userAvatarLocalPath){
                avatarImage.image = UIImage.init(contentsOfFile: user.userAvatarLocalPath)
            }else{
                avatarImage.loadAsync(user.userAvatarURL, placeholderImage: avatar)
            }
        }
    }
    
    override func copy(_ sender: Any?) {
        let text = self.comment.commentText
        let board = UIPasteboard.general
        board.string = text
        let menu = UIMenuController.shared
        menu.setMenuVisible(false, animated: true)
    }
    
    func showMenu() {
        becomeFirstResponder()
        let menu = UIMenuController.shared
        if !menu.isMenuVisible {
            menu.setMenuVisible(true, animated: true)
        }
    }
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if comment.commentType == QiscusCommentType.text{
            if action == #selector(QChatFooterLeft.copy(_:)) {
                return true
            }
        }
        return false
    }
}
