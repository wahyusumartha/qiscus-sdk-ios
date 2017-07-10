//
//  QComment.swift
//  Example
//
//  Created by Ahmad Athaullah on 7/5/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftyJSON

@objc public enum QCommentType:Int {
    case text
    case image
    case video
    case audio
    case file
    case postback
    case account
    case reply
    case system
}
@objc public enum QCommentStatus:Int{
    case sending
    case sent
    case delivered
    case read
    case failed
}
public class QComment:Object {
    public dynamic var uniqueId: String = ""
    public dynamic var id:Int = 0
    public dynamic var beforeId:Int = 0
    public dynamic var text:String = ""
    public dynamic var createdAt: Double = 0
    public dynamic var senderEmail:String = ""
    public dynamic var senderName:String = ""
    public dynamic var statusRaw:Int = QCommentStatus.sending.rawValue
    public dynamic var typeRaw:Int = QCommentType.text.rawValue
    public dynamic var data:String = ""
    
    
    //MARK : - Getter variable
    public var file:QFile? {
        get{
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            return realm.object(ofType: QFile.self, forPrimaryKey: self.uniqueId)
        }
    }
    public var sender:QUser? {
        get{
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            return realm.object(ofType: QUser.self, forPrimaryKey: self.senderEmail)
        }
    }
    public var type:QCommentType {
        get{
            return QCommentType(rawValue: self.typeRaw)!
        }
    }
    public var date: String {
        get {
            let date = Date(timeIntervalSince1970: self.createdAt)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d MMMM yyyy"
            let dateString = dateFormatter.string(from: date)
            
            return dateString
        }
    }
    public var cellIdentifier:String{
        get{
            var position = "Left"
            if self.senderEmail == QiscusMe.sharedInstance.email {
                position = "Right"
            }
            switch self.type {
            case .system:
                return "cellSystem"
            case .postback,.account:
                return "cellPostbackLeft"
            case .image, .video:
                return "cellMedia\(position)"
            case .audio:
                return "cellAudio\(position)"
            case .file:
                return "cellFile\(position)"
            default:
                return "cellText\(position)"
            }
        }
    }
    override open class func primaryKey() -> String {
        return "uniqueId"
    }
    public class func comment(withUniqueId uniqueId:String)->QComment?{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        return realm.object(ofType: QComment.self, forPrimaryKey: uniqueId)
    }
    
}
