//
//  QUser.swift
//  Example
//
//  Created by Ahmad Athaullah on 7/5/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import Foundation
import RealmSwift

public class QUser:Object {
    public dynamic var email:String = ""
    public dynamic var id:Int = 0
    public dynamic var avatarURL:String = ""
    public dynamic var avatarLocalPath:String = ""
    public dynamic var fullname:String = ""
    public dynamic var lastSeen:Double = 0
    
    public dynamic var avatar:UIImage?
    
    public var lastSeenString:String{
        get{
            if self.lastSeen == 0 {
                return "offline"
            }else{
                var result = ""
                let date = Date(timeIntervalSince1970: self.lastSeen)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "d MMMM yyyy"
                let dateString = dateFormatter.string(from: date)
                
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "h:mm a"
                let timeString = timeFormatter.string(from: date)
                
                let now = Date()
                
                let secondDiff = now.offsetFromInSecond(date: date)
                let minuteDiff = Int(secondDiff/60)
                let hourDiff = Int(minuteDiff/60)
                
                if minuteDiff < 2 {
                    result = "online"
                }
                else if minuteDiff < 60 {
                    result = "\(Int(secondDiff/60)) minute ago"
                }else if hourDiff == 1{
                    result = "an hour ago"
                }else if hourDiff < 6 {
                    result = "\(hourDiff) hours ago"
                }
                else if date.isToday{
                    result = "today at \(timeString)"
                }
                else if date.isYesterday{
                    result = "yesterday at \(timeString)"
                }
                else{
                    result = "\(dateString) at \(timeString)"
                }
                
                return result
            }
        }
    }
    // MARK: - Primary Key
    override open class func primaryKey() -> String {
        return "email"
    }
    // MARK: - Unstored properties
    override public static func ignoredProperties() -> [String] {
        return ["avatar"]
    }
    public class func user(withEmail email:String) -> QUser? {
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        return realm.object(ofType: QUser.self, forPrimaryKey: email)
    }
    public class func all() -> [QUser]{
        var allUser = [QUser]()
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        
        let data = realm.objects(QUser.self)
        
        if data.count > 0 {
            for user in data{
                allUser.append(user)
            }
        }
        return allUser
    }
    public func updateLastSeen(lastSeen:Double){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        if lastSeen > self.lastSeen {
            try! realm.write {
                self.lastSeen = lastSeen
            }
            if let room = QRoom.room(withUser: self.email) {
                room.delegate?.room(didChangeUser: room, user: self)
            }
        }
    }
}
