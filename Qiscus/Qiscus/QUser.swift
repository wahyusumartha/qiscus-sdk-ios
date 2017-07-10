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
    public dynamic var avatarURL:String = ""
    public dynamic var avatarLocalPath:String = ""
    public dynamic var fullname:String = ""
    public dynamic var lastSeen:Double = 0
    
    // MARK: - Primary Key
    override open class func primaryKey() -> String {
        return "email"
    }
    public class func user(withEmail email:String) -> QUser? {
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        return realm.object(ofType: QUser.self, forPrimaryKey: email)
    }
}
