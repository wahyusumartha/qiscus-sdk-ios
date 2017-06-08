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
                
                
                if let avatar = data.userAvatar {
                    avatarLabel.isHidden = true
                    avatarImage.image = avatar
                    avatarImage.backgroundColor = UIColor.clear
                }else{
                    avatarImage.image = nil
                    avatarLabel.isHidden = false
                    avatarImage.backgroundColor = UIColor.clear
                    let bgColor = QiscusColorConfiguration.sharedInstance.avatarBackgroundColor
                    let colorIndex = data.userFullName.characters.count % bgColor.count
                    avatarImage.backgroundColor = bgColor[colorIndex]
                    avatarLabel.text = String(data.userFullName.characters.first!).uppercased()
                    if QiscusHelper.isFileExist(inLocalPath: data.userAvatarLocalPath){
                        let commentId = data.commentId as AnyObject
                        if let cachedImage = UIImage.cachedImage(withPath: data.userAvatarLocalPath){
                            self.avatarLabel.isHidden = true
                            self.avatarImage.image = cachedImage
                            self.avatarImage.backgroundColor = UIColor.clear
                            self.comment?.userAvatar = cachedImage
                        }else{
                            avatarImage.loadAsync(fromLocalPath: data.userAvatarLocalPath, onLoaded: { (image, data) in
                                if let commentId = data as? Int {
                                    if self.comment?.commentId == commentId {
                                        self.avatarLabel.isHidden = true
                                        self.avatarImage.image = image
                                        self.avatarImage.backgroundColor = UIColor.clear
                                        self.comment?.userAvatar = image
                                    }
                                }
                            },optionalData:commentId)
                        }
                    }else{
                        let commentId = data.commentId as AnyObject
                        if let cachedImage = UIImage.cachedImage(withPath: data.userAvatarLocalPath){
                            self.avatarLabel.isHidden = true
                            self.avatarImage.image = cachedImage
                            self.avatarImage.backgroundColor = UIColor.clear
                            self.comment?.userAvatar = cachedImage
                        }else{
                            avatarImage.loadAsync(data.userAvatarURL, onLoaded: { (image,data) in
                                if let commentId = data as? Int {
                                    if self.comment?.commentId == commentId {
                                        self.avatarLabel.isHidden = true
                                        self.avatarImage.image = image
                                        self.avatarImage.backgroundColor = UIColor.clear
                                        self.comment?.userAvatar = image
                                    }
                                }
                            },optionalData:commentId)
                        }
                    }
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
