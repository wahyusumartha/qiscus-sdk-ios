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
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        avatarImage.layer.cornerRadius = 19
        avatarImage.clipsToBounds = true
        avatarImage.contentMode = .scaleAspectFill
        self.isUserInteractionEnabled = false
    }
    
    func setup(withComent comment:QiscusCommentPresenter){
        avatarImage.image = Qiscus.image(named: "in_chat_avatar")
        if QiscusHelper.isFileExist(inLocalPath: comment.userAvatarLocalPath){
            avatarImage.loadAsync(fromLocalPath: comment.userAvatarLocalPath)
        }else{
            avatarImage.loadAsync(comment.userAvatarURL)
        }
    }
}
