//
//  QChatFooterLeft.swift
//  QiscusSDK
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
        avatarImage.contentMode = .scaleAspectFill
        self.isUserInteractionEnabled = false
    }
    
    func setup(withComent comment:QiscusComment){
        avatarImage.image = Qiscus.image(named: "in_chat_avatar")
        self.comment = comment
        
        if let user = comment.sender{
            if let image = user.avatar{
                avatarImage.image = image
            }
        }
    }
    func setup(withImage image:UIImage){
        avatarImage.image = image
    }
}
