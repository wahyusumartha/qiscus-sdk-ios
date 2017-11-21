//
//  QRoom+PublicProperty.swift
//  Qiscus
//
//  Created by Ahmad Athaullah on 21/11/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import RealmSwift

public extension QRoom {
    public var isPinned:Bool {
        get{
            return self.pinned != 0
        }
    }
    public var name:String{
        get{
            if self.definedname != "" {
                return self.definedname
            }else{
                return self.storedName
            }
        }
    }
    public var avatarURL:String{
        get{
            if self.definedAvatarURL != "" {
                return self.definedAvatarURL
            }else{
                return self.storedAvatarURL
            }
        }
    }
    
    public var lastCommentGroup:QCommentGroup?{
        get{
            if let group = self.comments.last {
                return QCommentGroup.commentGroup(withId: group.id)
            }else{
                return nil
            }
        }
    }
    public var lastComment:QComment?{
        get{
            if let comment = QComment.comment(withUniqueId: self.lastCommentUniqueId){
                return comment
            }else{
                if self.lastCommentId > 0 {
                    let comment = QComment()
                    comment.id = self.lastCommentId
                    comment.uniqueId = self.lastCommentUniqueId
                    comment.roomId = self.id
                    comment.text = self.lastCommentText
                    comment.senderName = self.lastCommentSenderName
                    comment.createdAt = self.lastCommentCreatedAt
                    comment.beforeId = self.lastCommentBeforeId
                    comment.senderEmail = self.lastCommentSenderName
                    comment.roomName = self.name
                    comment.cellPosRaw = QCellPosition.single.rawValue
                    comment.typeRaw = self.lastCommentTypeRaw
                    comment.data = self.lastCommentData
                    comment.rawExtra = self.lastCommentRawExtras
                    return comment
                }
            }
            return nil
        }
    }
    public var commentsGroupCount:Int{
        return self.comments.count
    }
    public var type:QRoomType {
        get{
            return QRoomType(rawValue: self.typeRaw)!
        }
    }
    
    public var listComment:[QComment]{
        get{
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            var comments = [QComment]()
            let data =  realm.objects(QComment.self).filter("roomId == '\(self.id)'").sorted(byKeyPath: "createdAt", ascending: true)
            for comment in data {
                let data = QComment.comment(withUniqueId: comment.uniqueId)!
                comments.append(data)
            }
            return comments
        }
    }
}
