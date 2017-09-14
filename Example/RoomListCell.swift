//
//  RoomListCell.swift
//  Example
//
//  Created by Ahmad Athaullah on 9/8/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
import Qiscus

class RoomListCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var avatarView: UIImageView!
    
    var typingUser:QUser?{
        didSet{
            if typingUser != nil {
                self.commentLabel.text = "\(typingUser!.fullname) is typing ..."
                self.commentLabel.textColor = UIColor(red: 59/255, green: 147/255, blue: 61/255, alpha: 1)
            }else{
                if let lastComment = room!.lastComment{
                    self.commentLabel.text = "\(lastComment.senderName): \(lastComment.text)"
                    self.commentLabel.textColor = UIColor.black
                }
            }
        }
    }
    var room:QRoom? {
        didSet{
            self.typingUser = nil
            if room != nil {
                self.unreadLabel.isHidden = true
                self.commentLabel.textColor = UIColor.black
                if room!.unreadCount > 0 {
                    self.unreadLabel.text = "\(room!.unreadCount)"
                    if room!.unreadCount > 99 {
                        self.unreadLabel.text = "99+"
                    }
                    self.unreadLabel.isHidden = false
                }
                self.nameLabel.text = room!.name
                if let lastComment = room!.lastComment{
                    self.commentLabel.text = "\(lastComment.senderName): \(lastComment.text)"
                }
                if room!.avatarURL != "" {
                    let roomAvatar = room!.avatarURL
                    self.avatarView.loadAsync(roomAvatar, onLoaded: { (image, _) in
                        if !self.room!.isInvalidated {
                            if roomAvatar == self.room!.avatarURL {
                                self.avatarView.image = image
                            }
                        }
                    })
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.avatarView.layer.cornerRadius = 25.0
        self.avatarView.clipsToBounds = true
        self.unreadLabel.layer.cornerRadius = 12.5
        self.unreadLabel.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    public func userStartTyping(user:QUser) {
        self.typingUser = user
    }
    public func userStopTyping(user:QUser){
        if user.email == self.typingUser?.email {
            self.typingUser = nil
        }
    }
    public func updateDescription(description:String){
        self.commentLabel.text = description
    }
}
