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
    public dynamic var id: String = ""
    public dynamic var createdAt: Double = 0
    public dynamic var senderEmail: String = ""
    public dynamic var senderName: String = ""
    public let comments = List<QComment>()
    
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
    
    public class func commentGroup(onRoomWithId roomId:Int, senderEmail:String, date:String)->QCommentGroup?{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        return realm.object(ofType: QCommentGroup.self, forPrimaryKey: "\(roomId):::\(date):::\(senderEmail)")
    }
}
