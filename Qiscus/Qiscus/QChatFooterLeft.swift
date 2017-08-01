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
                    let colorIndex = sender.fullname.characters.count % bgColor.count
                    avatarImage.backgroundColor = bgColor[colorIndex]
                    
                    if let fullName = sender.fullname.characters.first{
                        avatarLabel.text = String(fullName).uppercased()
                    }
                    if QFileManager.isFileExist(inLocalPath: user!.avatarLocalPath){
                        if let cachedImage = UIImage.cachedImage(withPath: sender.avatarLocalPath){
                            if sender.email == self.user!.email {
                                self.avatarLabel.isHidden = true
                                self.avatarImage.image = cachedImage
                                self.avatarImage.backgroundColor = UIColor.clear
                            }
                        }else{
                            avatarImage.loadAsync(fromLocalPath: user!.avatarLocalPath, onLoaded: { (image, _) in
                                if sender.email == self.user!.email {
                                    self.avatarLabel.isHidden = true
                                    self.avatarImage.image = image
                                    self.avatarImage.backgroundColor = UIColor.clear
                                }
                            })
                        }
                    }else{
                        if let cachedImage = UIImage.cachedImage(withPath: sender.avatarURL){
                            sender.saveAvatar(withImage: cachedImage)
                        }else{
                            avatarImage.loadAsync(user!.avatarURL, onLoaded: { (image,_) in
                                sender.saveAvatar(withImage: image)
                            })
                        }
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
