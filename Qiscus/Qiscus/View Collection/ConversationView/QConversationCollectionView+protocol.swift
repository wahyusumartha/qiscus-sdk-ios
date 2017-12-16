//
//  QConversationCollectionView+protocol.swift
//  Qiscus
//
//  Created by Ahmad Athaullah on 16/12/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//
import Foundation
import UIKit

@objc public class QChatCellHeight:NSObject{
    var height = CGFloat(0)
    
    public init(height:CGFloat) {
        super.init()
        self.height = height
    }
}
@objc public protocol QConversationViewDelegate{
    @objc optional func viewDelegate(view:QConversationCollectionView, cellForComment comment:QComment)->QChatCell?
    @objc optional func viewDelegate(view:QConversationCollectionView, heightForComment comment:QComment)->QChatCellHeight?
    @objc optional func viewDelegate(view:QConversationCollectionView, willDisplayCellForComment comment:QComment, cell:QChatCell)
    @objc optional func viewDelegate(view:QConversationCollectionView, didEndDisplayingCellForComment comment:QComment, cell:QChatCell)
    @objc optional func viewDelegate(didEndDisplayingLastMessage view:QConversationCollectionView, comment:QComment)
}
@objc public protocol QConversationViewRoomDelegate{
    @objc optional func roomDelegate(didChangeName room: QRoom, name:String)
    
    @objc optional func roomDelegate(didFinishSync room: QRoom)
    
    @objc optional func roomDelegate(didChangeAvatar room: QRoom, avatar:UIImage)
    
    @objc optional func roomDelegate(didFailUpdate error: String)
    
    @objc optional func roomDelegate(didChangeUser room: QRoom, user: QUser)
    
    @objc optional func roomDelegate(didChangeParticipant room: QRoom)
        
    @objc optional func roomDelegate(didChangeUnread room:QRoom, unreadCount:Int)
}

@objc public protocol QConversationViewDataDelegate{
    
}
@objc public protocol QConversationViewCellDelegate{
    
}
