//
//  QRoomListDefaultCell.swift
//  Example
//
//  Created by Ahmad Athaullah on 9/15/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

class QRoomListDefaultCell: QRoomListCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var unreadLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.avatarView.layer.cornerRadius = 25.0
        self.avatarView.clipsToBounds = true
        self.unreadLabel.layer.cornerRadius = 12.5
        self.unreadLabel.clipsToBounds = true
    }
    
    var typingUser:QUser?{
        didSet{
            if typingUser != nil {
                self.descriptionLabel.text = "\(typingUser!.fullname) is typing ..."
                self.descriptionLabel.textColor = UIColor(red: 59/255, green: 147/255, blue: 61/255, alpha: 1)
            }else{
                if let lastComment = room!.lastComment{
                    self.descriptionLabel.text = "\(lastComment.senderName): \(lastComment.text)"
                    self.descriptionLabel.textColor = UIColor.black
                }
            }
        }
    }
   
    override func setupUI() {
        self.avatarView.image = Qiscus.image(named: "avatar")
        self.typingUser = nil
        if room != nil {
            self.descriptionLabel.textColor = UIColor.black
            if room!.unreadCount > 0 {
                self.unreadLabel.text = "\(room!.unreadCount)"
                if room!.unreadCount > 99 {
                    self.unreadLabel.text = "99+"
                }
                self.unreadLabel.isHidden = false
            }else{
                self.unreadLabel.isHidden = true
            }
            self.titleLabel.text = room!.name
            if let lastComment = room!.lastComment{
                self.descriptionLabel.text = "\(lastComment.senderName): \(lastComment.text)"
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
    override func searchTextChanged() {
        let boldAttr = [NSAttributedStringKey.foregroundColor: UIColor.red,
                        NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: self.titleLabel.font.pointSize)]
        let roomName = self.room!.name
        // check if label text contains search text
        if let matchRange: Range = roomName.lowercased().range(of: searchText.lowercased()) {
            
            let matchRangeStart: Int = roomName.distance(from: roomName.startIndex, to: matchRange.lowerBound)
            let matchRangeEnd: Int = roomName.distance(from: roomName.startIndex, to: matchRange.upperBound)
            let matchRangeLength: Int = matchRangeEnd - matchRangeStart
            
            let newLabelText = NSMutableAttributedString(string: roomName)
            newLabelText.setAttributes(boldAttr, range: NSMakeRange(matchRangeStart, matchRangeLength))
            
            // set label attributed text
            self.titleLabel.attributedText = newLabelText
        }
    }
    override func onUserTyping(user: QUser, typing: Bool) {
        if typing {
            self.typingUser = user
        }else{
            if user.email == self.typingUser?.email {
                self.typingUser = nil
            }
        }
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
