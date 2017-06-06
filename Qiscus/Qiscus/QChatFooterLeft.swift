//
//  QChatFooterLeft.swift
//  QiscusSDK
//
//  Created by Ahmad Athaullah on 1/9/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

class QChatFooterLeft: UICollectionReusableView {

    @IBOutlet weak var avatarLabel: UILabel!
    @IBOutlet weak var avatarImage: UIImageView!
    
    public var comment:QiscusCommentPresenter?{
        didSet{
            if let data = comment {
                avatarImage.image = nil
                avatarLabel.isHidden = false
                avatarImage.backgroundColor = UIColor.clear
                let bgColor = QiscusColorConfiguration.sharedInstance.avatarBackgroundColor
                let colorIndex = data.userFullName.characters.count % bgColor.count
                avatarImage.backgroundColor = bgColor[colorIndex]
                avatarLabel.text = String(data.userFullName.characters.first!)
                
                //avatarImage.image = Qiscus.image(named: "in_chat_avatar")
                if QiscusHelper.isFileExist(inLocalPath: data.userAvatarLocalPath){
                    avatarImage.loadAsync(fromLocalPath: data.userAvatarLocalPath, onLoaded: {
                        self.avatarLabel.isHidden = true
                        self.avatarImage.backgroundColor = UIColor.clear
                    })
                }else{
                    avatarImage.loadAsync(data.userAvatarURL,onLoaded: {
                        self.avatarLabel.isHidden = true
                        self.avatarImage.backgroundColor = UIColor.clear
                    })
                    avatarImage.loadAsync(data.userAvatarURL)
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        avatarImage.layer.cornerRadius = 19
        avatarImage.clipsToBounds = true
        avatarImage.contentMode = .scaleAspectFill
        self.isUserInteractionEnabled = false
    }
    
    func setup(withComent comment:QiscusCommentPresenter){
        
    }
}
