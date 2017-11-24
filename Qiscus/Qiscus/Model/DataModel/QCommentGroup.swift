//
//  QCommentGroup.swift
//  Example
//
//  Created by Ahmad Athaullah on 7/5/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import Foundation
import RealmSwift

public class QCommentGroup: Object{
    static var cache = [String: QCommentGroup]()
    
    @objc public dynamic var id: String = ""
    @objc public dynamic var createdAt: Double = 0
    @objc public dynamic var senderEmail: String = ""
    @objc public dynamic var senderName: String = ""
    internal let comments = List<QComment>()
    
    public var commentsCount:Int{
        return self.comments.count
    }
    public var lastComment:QComment?{
        get{
            if let comment = self.comments.last {
                return QComment.comment(withUniqueId: comment.uniqueId)
            }else{
                return nil
            }
        }
    }
    public var sender:QUser? {
        get{
            return QUser.user(withEmail: self.senderEmail)
        }
    }
    public var date:String{
        get{
            let date = Date(timeIntervalSince1970: self.createdAt)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d MMMM yyyy"
            let dateString = dateFormatter.string(from: date)
            
            return dateString
        }
    }
    
    public class func commentGroup(withId id:String)->QCommentGroup?{
        if let cachedData = QCommentGroup.cache[id] {
            if !cachedData.isInvalidated{
                return cachedData
            }
        }
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let groups = realm.objects(QCommentGroup.self).filter("id == '\(id)'")
        if groups.count > 0 {
            let cacheData = groups.first!
            QCommentGroup.cache[id] = cacheData
            return cacheData
        }
        
        return nil
    }
    public func comment(index:Int)->QComment?{
        if self.comments.count > index {
            let comment = self.comments[index]
            return QComment.comment(withUniqueId: comment.uniqueId)
        }else{
            return nil
        }
    }
    public func append(comment:QComment){
        if let group = QCommentGroup.commentGroup(withId: self.id){
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            try! realm.write {
                group.comments.append(comment)
            }
        }else{
            self.comments.append(comment)
        }
        if QComment.cache[comment.uniqueId] == nil {
            QComment.cache[comment.uniqueId] = comment
        }
    }
    public func insert(comment:QComment, at:Int){
        if let group = QCommentGroup.commentGroup(withId: self.id){
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            try! realm.write {
                group.comments.insert(comment, at: at)
            }
        }else{
            self.comments.insert(comment, at: at)
        }
        if QComment.cache[comment.uniqueId] == nil {
            QComment.cache[comment.uniqueId] = comment
        }
    }
    public class func all() -> [QCommentGroup]{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let data = realm.objects(QCommentGroup.self)
        
        if data.count > 0 {
            return Array(data)
        }else{
            return [QCommentGroup]()
        }
    }
    internal class func cacheAll(){
        let groups = QCommentGroup.all()
        for group in groups{
            group.cacheObject()
        }
    }
    internal func cacheObject(){
        if Thread.isMainThread {
            QCommentGroup.cache[self.id] = self
        }
    }
    internal class func clearAllMessage(onFinish: (()->Void)? = nil){
        //let all = QCommentGroup.all()
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let groups = realm.objects(QCommentGroup.self)
        let comments = realm.objects(QComment.self)
        let files = realm.objects(QFile.self)
        for file in files {
            if QFileManager.isFileExist(inLocalPath: file.localPath) {
                let fileURL = URL(fileURLWithPath: file.localPath)
                do {
                    try FileManager.default.removeItem(at: fileURL)
                } catch let error as NSError {
                    Qiscus.printLog(text: error.domain)
                }
            }
        }
        try! realm.write {
            realm.delete(groups)
            realm.delete(comments)
            realm.delete(files)
        }
        
        
        Qiscus.chatRooms = [String : QRoom]()
        QParticipant.cache = [String : QParticipant]()
        QCommentGroup.cache = [String : QCommentGroup]()
        QComment.cache = [String : QComment]()
        QUser.cache = [String: QUser]()
        Qiscus.shared.chatViews = [String:QiscusChatVC]()
        QiscusNotification.publish(finishedClearMessage: true)
        onFinish?()
    }
}
