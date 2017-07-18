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
    
    public var sender:QUser?{
        didSet{
            if let user = self.sender {
                if let avatar = user.avatar {
                    avatarLabel.isHidden = true
                    avatarImage.image = avatar
                    avatarImage.backgroundColor = UIColor.clear
                }else{
                    avatarImage.image = nil
                    avatarLabel.isHidden = false
                    let bgColor = QiscusColorConfiguration.sharedInstance.avatarBackgroundColor
                    let colorIndex = user.fullname.characters.count % bgColor.count
                    avatarImage.backgroundColor = bgColor[colorIndex]
                    
                    if let fullName = user.fullname.characters.first{
                        avatarLabel.text = String(fullName).uppercased()
                    }
                    if QiscusHelper.isFileExist(inLocalPath: user.avatarLocalPath){
                        if let cachedImage = UIImage.cachedImage(withPath: user.avatarLocalPath){
                            self.avatarLabel.isHidden = true
                            self.avatarImage.image = cachedImage
                            self.avatarImage.backgroundColor = UIColor.clear
                            user.avatar = cachedImage
                        }else{
                            avatarImage.loadAsync(fromLocalPath: user.avatarLocalPath, onLoaded: { (image, _) in
                                user.avatar = image
                            })
                        }
                    }else{
                        if let cachedImage = UIImage.cachedImage(withPath: user.avatarURL){
                            self.avatarLabel.isHidden = true
                            self.avatarImage.image = cachedImage
                            self.avatarImage.backgroundColor = UIColor.clear
                            user.avatar = cachedImage
                        }else{
                            avatarImage.loadAsync(user.avatarURL, onLoaded: { (image,_) in
                                user.avatar = image
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
    
    func setup(withComent comment:QiscusCommentPresenter){
        
    }
}
