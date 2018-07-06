//
//  QFileFunction.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 06/07/18.
//

import Foundation

import RealmSwift
extension QFile {
    internal func update(fileURL:String){
        if self.url != fileURL {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            realm.refresh()
            try! realm.write {
                self.url = fileURL
            }
        }
    }
    internal func update(fileSize:Double){
        if self.size != fileSize {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            realm.refresh()
            try! realm.write {
                self.size = fileSize
            }
        }
    }
}
