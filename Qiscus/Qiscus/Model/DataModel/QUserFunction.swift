//
//  QUserFunction.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 06/07/18.
//

import Foundation
import RealmSwift
extension QUser {
    internal class func getUser(email:String) -> QUser? {
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        let data = realm.objects(QUser.self).filter("email == '\(email)'")
        if data.count > 0 {
            let user = data.first!
            return user
        }
        return nil
    }
    
    internal class func cacheAll(){
        let users = QUser.all()
        for user in users{
            if QUser.cache[user.email] == nil {
                QUser.cache[user.email] = user
            }
        }
    }
    
    internal func cacheObject(){
        if Thread.isMainThread {
            if QUser.cache[self.email] == nil {
                QUser.cache[self.email] = self
            }
        }
    }
}
