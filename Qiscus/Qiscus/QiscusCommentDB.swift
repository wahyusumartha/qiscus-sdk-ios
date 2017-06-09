//
//  QiscusCommentDB.swift
//  Example
//
//  Created by Ahmad Athaullah on 4/1/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
import RealmSwift

public class QiscusCommentDB: Object {
    public dynamic var localId:Int = 0
    public dynamic var commentId:Int = 0
    public dynamic var commentText:String = ""
    public dynamic var commentCreatedAt: Double = 0
    public dynamic var commentUniqueId: String = ""
    public dynamic var commentTopicId:Int = 0
    public dynamic var commentSenderEmail:String = ""
    public dynamic var commentFileId:Int = 0
    public dynamic var commentStatusRaw:Int = QiscusCommentStatus.sending.rawValue
    public dynamic var commentIsSynced:Bool = false
    public dynamic var commentBeforeId:Int = 0
    public dynamic var commentCellHeight:CGFloat = 0
    public dynamic var commentCellWidth:CGFloat = 0
    public dynamic var showLink:Bool = false
    public dynamic var commentLinkPreviewed:String = ""
    public dynamic var commentFontSize:CGFloat = 0
    public dynamic var commentFontName:String = ""
    public dynamic var commentButton:String = ""
    public dynamic var dummyVariableV2:Bool = true
    
    // MARK: - Primary Key
    override open class func primaryKey() -> String {
        return "localId"
    }
    public class var lastId:Int{
        get{
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            let RetNext = realm.objects(QiscusCommentDB.self).sorted(byKeyPath: "localId")
            
            if RetNext.count > 0 {
                let last = RetNext.last!
                return last.localId
            } else {
                return 0
            }
        }
    }
        
    // MARK : - QiscusComment
    public func comment()->QiscusComment{
        let newComment = QiscusComment()
        newComment.copyProcess = true
        newComment.localId = self.localId
        newComment.commentId = self.commentId
        newComment.commentButton = self.commentButton
        newComment.commentText = self.commentText
        newComment.commentCreatedAt = self.commentCreatedAt
        newComment.commentUniqueId = self.commentUniqueId
        newComment.commentTopicId = self.commentTopicId
        newComment.commentSenderEmail = self.commentSenderEmail
        newComment.commentFileId = self.commentFileId
        newComment.commentStatusRaw = self.commentStatusRaw
        newComment.commentBeforeId = self.commentBeforeId
        newComment.commentIsSynced = self.commentIsSynced
        newComment.commentCellHeight = self.commentCellHeight
        newComment.commentCellWidth = self.commentCellWidth
        newComment.showLink = self.showLink
        newComment.commentLinkPreviewed = self.commentLinkPreviewed
        newComment.copyProcess = false
        return newComment
    }
    public class func comment(withId commentId:Int, andUniqueId uniqueId:String? = nil)->QiscusComment?{
        if let commentDB = QiscusCommentDB.commentDB(withId: commentId, andUniqueId: uniqueId){
            return commentDB.comment()
        }else{
            return nil
        }
    }
    public class func comment(withLocalId localId:Int)->QiscusComment?{
        if let commentDB = QiscusCommentDB.commentDB(withLocalId: localId){
            return commentDB.comment()
        }else{
            return nil
        }
    }
    public class func comment(withUniqueId uniqueId: String)->QiscusComment?{
        if let commentDB = QiscusCommentDB.commentDB(withUniqueId: uniqueId){
            return commentDB.comment()
        }else{
            return nil
        }
    }
    
    // MARK: - QiscusCommentDB
    public class func commentDB(withId commentId:Int, andUniqueId uniqueId:String? = nil)->QiscusCommentDB?{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let searchQuery:NSPredicate?
        var query = "commentId == \(commentId)"
        if uniqueId != nil {
            query = "commentId == \(commentId) OR commentUniqueId == '\(uniqueId!)'"
        }
        searchQuery = NSPredicate(format: query)
        let commentData = realm.objects(QiscusCommentDB.self).filter(searchQuery!)
        
        if commentData.count == 0 {
            return nil
        }else{
            return commentData.first!
        }
    }
    public class func commentDB(withLocalId localId:Int)->QiscusCommentDB?{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let searchQuery:NSPredicate = NSPredicate(format: "localId == \(localId)")
        let RetNext = realm.objects(QiscusCommentDB.self).filter(searchQuery)
        
        if RetNext.count > 0 {
            return RetNext.last!
        } else {
            return nil
        }
    }
    public class func commentDB(withUniqueId uniqueId: String)->QiscusCommentDB?{
        
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        
        let searchQuery:NSPredicate = NSPredicate(format: "commentUniqueId == '\(uniqueId)'")
        let commentData = realm.objects(QiscusCommentDB.self).filter(searchQuery)
        
        if(commentData.count == 0){
            return nil
        }else{
            return commentData.first!
        }
    }
    
    // MARK: - add newComment to DB
    public class func new(commentWithId commentId:Int, andUniqueId uniqueId:String)->QiscusCommentDB{
        var commentDB = QiscusCommentDB()
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        if let comment = QiscusCommentDB.commentDB(withId: commentId, andUniqueId: uniqueId) {
            commentDB = comment
            try! realm.write {
                commentDB.commentId = commentId
                commentDB.commentUniqueId = uniqueId
            }
        }else{
            do {
                try realm.write {
                    commentDB.localId = commentId
                    commentDB.commentId = commentId
                    commentDB.commentUniqueId = uniqueId
                    realm.create(QiscusCommentDB.self, value: commentDB, update: true)
                    
                }
            } catch let error {
                print("\(error)")
            }
        }
        return commentDB
    }
    public class func newComment()->QiscusCommentDB{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let commentDB = QiscusCommentDB()
        try! realm.write {
            commentDB.localId = QiscusCommentDB.lastId + 1
            realm.add(commentDB)
        }
        
        return commentDB
    }
    // MARK: - Checking Methode
    public class func isExist(commentId:Int)->Bool{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let searchQuery = NSPredicate(format: "commentId == %d", commentId)
        let commentData = realm.objects(QiscusCommentDB.self).filter(searchQuery)
        
        if commentData.count > 0{
            return true
        }else{
            return false
        }
    }
    public class func unsyncExist(topicId:Int)->Bool{ //
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let searchQuery = NSPredicate(format: "commentIsSynced == false AND commentTopicId == \(topicId)")
        let commentData = realm.objects(QiscusCommentDB.self).filter(searchQuery)
        
        if commentData.count > 0{
            return true
        }else{
            return false
        }
    }
    
    // MARK: - Comment in room / topic
    public class func lastComment(inTopicId topicId:Int? = nil)->QiscusComment?{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        var query = "(commentStatusRaw != \(QiscusCommentStatus.sending.rawValue) AND commentStatusRaw != \(QiscusCommentStatus.failed.rawValue))"
        if topicId != nil {
            query = "\(query) AND commentTopicId == \(topicId!)"
        }
        let searchQuery:NSPredicate = NSPredicate(format: query)
        let RetNext = realm.objects(QiscusCommentDB.self).filter(searchQuery).sorted(byKeyPath: "commentId")
        
        if RetNext.count > 0 {
            return RetNext.last!.comment()
        } else {
            return nil
        }
    }
    public class func unreadComments(inTopic topicId:Int)->[QiscusComment]{
        var comments = [QiscusComment]()
        if let room = QiscusRoom.room(withLastTopicId: topicId){
            if let participant = QiscusParticipant.getParticipant(withEmail: QiscusMe.sharedInstance.email, roomId: room.roomId){
                let lastReadId = participant.lastReadCommentId
                let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                
                let sortProperties = [SortDescriptor(keyPath: "commentCreatedAt"), SortDescriptor(keyPath: "commentId", ascending: true)]
                let searchQuery:NSPredicate = NSPredicate(format: "commentTopicId == \(topicId) AND commentId > \(lastReadId)")
                let commentData = realm.objects(QiscusCommentDB.self).filter(searchQuery).sorted(by: sortProperties)
                
                if(commentData.count > 0){
                    for commentDB in commentData{
                        comments.append(commentDB.comment())
                    }
                }
            }
        }
        return comments
    }
    
    // MARK : - Int
    public class func checkSync(inTopicId topicId: Int)->Int?{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let sortProperties = [SortDescriptor(keyPath: "commentId", ascending: true)]
        let searchQuery:NSPredicate = NSPredicate(format: "commentTopicId == \(topicId) AND commentId != 0")
        let commentData = realm.objects(QiscusCommentDB.self).filter(searchQuery).sorted(by: sortProperties)
        
        
        if(commentData.count > 0){
            let lastCommentId = commentData.first!.localId
            for comment in commentData{
                if !QiscusCommentDB.isExist(commentId: comment.commentBeforeId) && comment.localId != lastCommentId{
                    return comment.commentId
                }
            }
        }
        return nil
    }
    open class func lastSyncId(topicId:Int, unsyncCommentId:Int)->Int?{ //
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let searchQuery = NSPredicate(format: "commentTopicId == \(topicId) AND (commentStatusRaw != \(QiscusCommentStatus.sending.rawValue) AND commentStatusRaw != \(QiscusCommentStatus.failed.rawValue)) AND commentId < \(unsyncCommentId)")
        let commentData = realm.objects(QiscusCommentDB.self).filter(searchQuery).sorted(byKeyPath: "commentCreatedAt", ascending: true)
        
        if commentData.count > 0{
            let firstCommentId = commentData.first!.localId
            for comment in commentData.reversed(){
                if QiscusComment.isExist(commentId: comment.commentBeforeId) || comment.localId == firstCommentId{
                    return comment.commentId
                }
            }
        }
        return nil
    }
    
    // MARK: - [QiscusComment]
    public class func getComments(inTopicId topicId: Int, limit:Int = 0, fromCommentId:Int? = nil, after:Bool)->[QiscusComment]{ //
        
        var allComment = [QiscusComment]()
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let sortProperties = [SortDescriptor(keyPath: "commentCreatedAt", ascending: false)]
        var query = "commentTopicId == \(topicId)"
        if fromCommentId != nil{
            if after {
                query = "\(query) AND commentId > \(fromCommentId!)"
            }else{
                query = "\(query) AND commentId <= \(fromCommentId!)"
            }
        }
        let searchQuery:NSPredicate = NSPredicate(format: query)
        
        let commentData = realm.objects(QiscusCommentDB.self).filter(searchQuery).sorted(by: sortProperties)
        
        if(commentData.count > 0){
            var count = 0
            var previousUid = commentData.first!.commentUniqueId
            for commentDB in commentData{
                if (count <= limit || limit == 0){
                    if commentDB.commentUniqueId != previousUid || count == 0{
                        allComment.insert(commentDB.comment(), at: 0)
                        previousUid = commentDB.commentUniqueId
                        count += 1
                    }else{
                        try! realm.write {
                            realm.delete(commentDB)
                        }
                        break
                    }
                }else{
                    break
                }
            }
        }
        return allComment
    }
    open class func firstUnsyncComment(inTopicId topicId:Int)->QiscusComment?{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let searchQuery = NSPredicate(format: "commentIsSynced == false AND commentTopicId == %d AND (commentStatusRaw == %d OR commentStatusRaw == %d)",topicId,QiscusCommentStatus.sent.rawValue,QiscusCommentStatus.delivered.rawValue)
        
        let commentData = realm.objects(QiscusCommentDB.self).filter(searchQuery).sorted(byKeyPath: "commentCreatedAt")
        
        if commentData.count > 0{
            return commentData.first!.comment()
        }else{
            return nil
        }
    }
    
    // MARK: - Updater Methode
    open class func lastSent(inRoom roomId:Int)->QiscusComment?{
        if let room = QiscusRoomDB.roomDB(withId: roomId){
            let topicId = room.roomLastCommentTopicId
            
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            let searchQuery:NSPredicate = NSPredicate(format: "commentTopicId == %d", topicId)
            let commentData = realm.objects(QiscusCommentDB.self).filter(searchQuery).sorted(byKeyPath: "commentId", ascending: false)
            
            for commentDB in commentData {
                if commentDB.commentStatusRaw != QiscusCommentStatus.failed.rawValue &&
                   commentDB.commentStatusRaw != QiscusCommentStatus.sending.rawValue{
                    return commentDB.comment()
                }
            }
            return nil
        }else{
            return nil
        }
    }
    
    open func updateStatus(_ status: QiscusCommentStatus, email:String? = nil){
        
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        
        if(self.commentStatusRaw < status.rawValue) ||
           self.commentStatusRaw == QiscusCommentStatus.failed.rawValue{
            var changeStatus = false
            if status != QiscusCommentStatus.read && status != QiscusCommentStatus.delivered{
                try! realm.write {
                    self.commentStatusRaw = status.rawValue
                }
                changeStatus = true
            }else{
                if email != nil{
                    if let room = QiscusRoom.room(withLastTopicId: self.commentTopicId){
                        if let participant = QiscusParticipant.getParticipant(withEmail: email!, roomId: room.roomId){
                            if status == QiscusCommentStatus.read{
                                let oldMinReadId = QiscusParticipant.getMinReadCommentId(onRoom: room.roomId)
                                participant.updateLastReadCommentId(commentId: self.commentId)
                                if  QiscusParticipant.getMinReadCommentId(onRoom: room.roomId) != oldMinReadId{
                                    changeStatus = true
                                }
                            }else{
                                let oldMinDeliveredId = QiscusParticipant.getMinDeliveredCommentId(onRoom: room.roomId)
                                participant.updateLastDeliveredCommentId(commentId: self.commentId)
                                if  QiscusParticipant.getMinDeliveredCommentId(onRoom: room.roomId) != oldMinDeliveredId{
                                    changeStatus = true
                                }
                            }
                            
                        }
                    }
                }
            }
            if changeStatus {
                if let room = QiscusRoom.room(withLastTopicId: self.commentTopicId){
                    if let chatView = Qiscus.shared.chatViews[room.roomId] {
                        let copyComment = self.comment()
                        chatView.dataPresenter(didChangeStatusFrom: copyComment.commentId, toStatus: status, topicId: copyComment.commentTopicId)
                    }
                }
            }
        }
    }
    // MARK: - Delete
    public class func deleteAll(){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let comments = realm.objects(QiscusCommentDB.self)
        
        if comments.count > 0 {
            try! realm.write {
                realm.delete(comments)
            }
        }
    }
    public func deleteComment(){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        try! realm.write {
            realm.delete(self)
        }
    }
}
