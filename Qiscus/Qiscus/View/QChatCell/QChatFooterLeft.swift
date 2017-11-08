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
    
    public var user:QUser?{
        didSet{
            if let sender = self.user{
                sender.delegate = self
                if let avatar = sender.avatar {
                    avatarLabel.isHidden = true
                    avatarImage.image = avatar
                    avatarImage.backgroundColor = UIColor.clear
                }else{
                    avatarImage.image = nil
                    avatarLabel.isHidden = false
                    let bgColor = QiscusColorConfiguration.sharedInstance.avatarBackgroundColor
                    let colorIndex = sender.fullname.count % bgColor.count
                    avatarImage.backgroundColor = bgColor[colorIndex]
                    if sender.fullname.count > 0 {
                        let index = sender.fullname.index(sender.fullname.startIndex, offsetBy: 0)
                        avatarLabel.text = String(sender.fullname[index]).uppercased()
                    }
                    
                    if QFileManager.isFileExist(inLocalPath: sender.avatarLocalPath){
                        UIImage.loadAsync(fromLocalPath: sender.avatarLocalPath, onSuccess: { image in
                            sender.avatar = image
                        },
                        onError: {
                            sender.clearLocalPath()
                        })
                    }else{
                        UIImage.loadAsync(url: sender.avatarURL, onSuccess: { (image) in
                            sender.saveAvatar(withImage: image)
                        }, onError: {
                            Qiscus.printLog(text: "can't load user avatar for user: \(sender.fullname)")
                        })
                    }
                }
            }else{
                avatarImage.image = nil
                avatarLabel.isHidden = false
                avatarLabel.text = "_"
                avatarImage.backgroundColor = UIColor.black
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
}

extension QChatFooterLeft:QUserDelegate{
    func user(didChangeAvatarURL avatarURL: String) {
        if let sender = self.user {
            avatarImage.loadAsync(user!.avatarURL, onLoaded: { (image,_) in
                sender.saveAvatar(withImage: image)
            })
        }
    }
    func user(didChangeAvatar avatar: UIImage) {
        self.avatarLabel.isHidden = true
        self.avatarImage.image = avatar
        self.avatarImage.backgroundColor = UIColor.clear
    }
}
