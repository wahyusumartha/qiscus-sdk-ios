//
//  QiscusRoomDB.swift
//  Example
//
//  Created by Ahmad Athaullah on 4/1/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
import RealmSwift

class QiscusRoomDB: Object {
    
    public dynamic var localId:Int = 0
    public dynamic var roomId:Int = 0
    public dynamic var roomName:String = ""
    public dynamic var roomAvatarURL:String = ""
    public dynamic var roomAvatarLocalPath:String = ""
    public dynamic var roomLastCommentTopicId:Int = 0
    public dynamic var optionalData:String = ""
    public dynamic var distinctId:String = ""
    public dynamic var user:String = ""
    public dynamic var isGroup:Bool = false
    public dynamic var hasLoadMore:Bool = true
    
    // MARK: - Primary Key
    override public class func primaryKey() -> String {
        return "localId"
    }
    public class func lastId() -> Int{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let data = realm.objects(QiscusRoomDB.self).sorted(byKeyPath: "localId")
        
        if data.count > 0 {
            let last = data.last!
            return last.localId
        } else {
            return 0
        }
    }
    
    // MARK: - QiscusRoomDB
    public class func roomDB(withLocalId localId:Int)->QiscusRoomDB?{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let searchQuery:NSPredicate = NSPredicate(format: "localId == \(localId)")
        let data = realm.objects(QiscusRoomDB.self).filter(searchQuery)
        
        if data.count > 0 {
            return data.last!
        } else {
            return nil
        }
    }
    public class func roomDB(withId roomId:Int)->QiscusRoomDB?{ //
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        
        let searchQuery:NSPredicate = NSPredicate(format: "roomId == %d",roomId)
        let data = realm.objects(QiscusRoomDB.self).filter(searchQuery)
        
        if(data.count > 0){
            return data.first
        }else{
            return nil
        }
    }
    public class func roomDB(withDistinctId distinctId:String, andUserEmail email:String)->QiscusRoomDB?{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let searchQuery:NSPredicate = NSPredicate(format: "distinctId == '\(distinctId)' AND user == '\(email)' AND isGroup == false")
        let data = realm.objects(QiscusRoomDB.self).filter(searchQuery)
        
        if data.count > 0 {
            return data.first!
        }else{
            return nil
        }
    }
    public class func roomDB(withLastTopicId topicId:Int)->QiscusRoomDB?{ //
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        
        let searchQuery:NSPredicate = NSPredicate(format: "roomLastCommentTopicId == %d",topicId)
        let data = realm.objects(QiscusRoomDB.self).filter(searchQuery)
        
        if(data.count > 0){
            return data.first!
        }else{
            return nil
        }
    }
    
    // MARK: - QiscusRoom
    public func room()->QiscusRoom{
        let room = QiscusRoom()
        room.copyProcess = true
        room.localId = self.localId
        room.roomId = self.roomId
        room.roomName = self.roomName
        room.roomAvatarURL = self.roomAvatarURL
        room.roomAvatarLocalPath = self.roomAvatarLocalPath
        room.roomLastCommentTopicId = self.roomLastCommentTopicId
        room.optionalData = self.optionalData
        room.distinctId = self.distinctId
        room.user = self.user
        room.isGroup = self.isGroup
        room.copyProcess = false
        return room
    }
    
    // MARK: - [QiscusRoom]
    public class func all() -> [QiscusRoom]{
        var allRoom = [QiscusRoom]()
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        
        let data = realm.objects(QiscusRoomDB.self)
        
        if data.count > 0 {
            for roomDB in data{
                allRoom.append(roomDB.room())
            }
        }
        return allRoom
    }
    
    // MARK: - addNewData
    public class func newRoomDB()->QiscusRoomDB{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let newRoom = QiscusRoomDB()
        try! realm.write {
            newRoom.localId = QiscusRoomDB.lastId() + 1
            realm.add(newRoom)
        }
        return newRoom
    }
}
