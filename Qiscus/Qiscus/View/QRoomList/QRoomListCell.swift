//
//  QRoomListCell.swift
//  Example
//
//  Created by Ahmad Athaullah on 9/15/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

open class QRoomListCell: UITableViewCell {
    
    public var room:QRoom? {
        didSet{
            setupUI()
        }
    }
    public var comment:QComment? {
        didSet{
            setupUI()
        }
    }
    override open func awakeFromNib() {
        super.awakeFromNib()
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(QRoomListCell.userTyping(_:)), name: QiscusNotification.USER_TYPING, object: nil)
        // Initialization code
    }

    override open func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    open func setupUI(){}
    open func onUserTyping(user:QUser, typing:Bool){}
    open func onRoomChange(){}
    open func gotNewComment(comment:QComment){}
    
    @objc private func userTyping(_ notification: Notification){
        if let userInfo = notification.userInfo {
            let user = userInfo["user"] as! QUser
            let typing = userInfo["typing"] as! Bool
            let room = userInfo["room"] as! QRoom
            
            if self.room?.id == room.id {
                self.onUserTyping(user: user, typing: typing)
            }
        }
    }
}
