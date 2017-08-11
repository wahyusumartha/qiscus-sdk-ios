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
    
    public dynamic var id: String = ""
    public dynamic var createdAt: Double = 0
    public dynamic var senderEmail: String = ""
    public dynamic var senderName: String = ""
    private let comments = List<QComment>()
    
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
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            return realm.object(ofType: QUser.self, forPrimaryKey: self.senderEmail)
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
    override open class func primaryKey() -> String {
        return "id"
    }
    
    public class func commentGroup(withId id:String)->QCommentGroup?{
        if let cachedData = QCommentGroup.cache[id] {
            return cachedData
        }else{
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            if let cacheData = realm.object(ofType: QCommentGroup.self, forPrimaryKey: id) {
                QCommentGroup.cache[id] = cacheData
                return cacheData
            }
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
    }
}
