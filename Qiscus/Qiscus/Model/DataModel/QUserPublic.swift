//
//  QUserPublic.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 06/07/18.
//

import Foundation
import RealmSwift
extension QUser {
    public class func saveUser(withEmail email:String, id:Int? = nil ,fullname:String? = nil, avatarURL:String? = nil, lastSeen:Double? = nil)->QUser{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        var user = QUser()
        if let savedUser = QUser.getUser(email: email){
            user = savedUser
            if fullname != nil  && fullname! != user.storedName {
                try! realm.write {
                    user.storedName = fullname!
                }
                if user.definedName != "" {
                    DispatchQueue.main.async {
                        if let u = QUser.user(withEmail: email){
                            u.delegate?.user?(didChangeName: fullname!)
                            QiscusNotification.publish(userNameChange: u)
                        }
                    }
                }
            }
            if id != nil {
                try! realm.write {
                    user.id = id!
                }
            }
            if avatarURL != nil && avatarURL! != user.avatarURL{
                try! realm.write {
                    user.avatarURL = avatarURL!
                }
                user.downloadAvatar()
                
                DispatchQueue.main.async {
                    if let u = QUser.user(withEmail: email){
                        u.cachedAvatar = nil
                        u.delegate?.user?(didChangeAvatarURL: avatarURL!)
                        QiscusNotification.publish(userAvatarChange: u)
                    }
                }
            }
            if lastSeen != nil && lastSeen! > user.lastSeen{
                try! realm.write {
                    user.lastSeen = lastSeen!
                }
                DispatchQueue.main.async {
                    if let u = QUser.user(withEmail: email){
                        u.delegate?.user?(didChangeLastSeen: lastSeen!)
                    }
                }
            }
        }else{
            user.email = email
            if fullname != nil {
                user.storedName = fullname!
            }
            if avatarURL != nil {
                user.avatarURL = avatarURL!
            }
            if lastSeen != nil {
                user.lastSeen = lastSeen!
            }
            if id != nil {
                user.id = id!
            }
            try! realm.write {
                realm.add(user, update:true)
            }
            user.downloadAvatar()
        }
        
        return user
    }
    
    public class func user(withEmail email:String) -> QUser? {
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        if let cachedUser = QUser.cache[email] {
            if !cachedUser.isInvalidated {
                return cachedUser
            }
        }
        let data = realm.objects(QUser.self).filter("email == '\(email)'")
        if data.count > 0 {
            let user = data.first!
            user.cacheObject()
            return user
        }
        return nil
    }
    
    public func subscribeRealtimeStatus(){
        let channel = "u/\(self.email)/s"
        Qiscus.shared.mqtt?.subscribe(channel)
    }
    public func updatePresence(presence:QUserPresence){
        if self.isInvalidated { return }
        let email = self.email
        QiscusDBThread.async {
            if let user = QUser.getUser(email: email){
                let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                realm.refresh()
                if user.isInvalidated { return }
                if user.rawPresence != presence.rawValue {
                    try! realm.write {
                        user.rawPresence = presence.rawValue
                    }
                    DispatchQueue.main.sync {
                        if let updatedUser = QUser.user(withEmail: email){
                            QiscusNotification.publish(userPresence: updatedUser)
                        }
                    }
                }
            }
        }
    }
    public func updateLastSeen(lastSeen:Double){
        let email = self.email
        QiscusDBThread.async {
            if let user = QUser.getUser(email: email){
                let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                realm.refresh()
                if user.isInvalidated { return }
                if lastSeen > user.lastSeen {
                    try! realm.write {
                        user.lastSeen = lastSeen
                    }
                    DispatchQueue.main.async {
                        if let room = QRoom.room(withUser: email) {
                            if let mainUser = QUser.user(withEmail: email){
                                room.delegate?.room?(didChangeUser: room, user: mainUser)
                            }
                        }
                    }
                }
            }
        }
    }
    public func setName(name:String){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        let email = self.email
        if name != self.definedName {
            try! realm.write {
                self.definedName = name
            }
            DispatchQueue.main.async {
                if let user = QUser.user(withEmail: email) {
                    user.delegate?.user?(didChangeName: name)
                    QiscusNotification.publish(userNameChange: user)
                }
            }
        }
    }
    public class func all() -> [QUser]{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        let data = realm.objects(QUser.self)
        
        if data.count > 0 {
            return Array(data)
        }else{
            return [QUser]()
        }
    }
    
    public func clearAvatar(){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        try! realm.write {
            self.avatarData = nil
        }
    }
    
    public func downloadAvatar(){
        let email = self.email
        let url = self.avatarURL.replacingOccurrences(of: "/upload/", with: "/upload/c_thumb,g_center,h_100,w_100/")
        if !QChatService.downloadTasks.contains(url){
            QChatService.downloadImage(url: url, onSuccess: { (data) in
                QiscusDBThread.async {
                    if let user = QUser.getUser(email: email){
                        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                        realm.refresh()
                        try! realm.write {
                            user.avatarData = data
                        }
                        DispatchQueue.main.sync {
                            if let mainUser = QUser.user(withEmail: email){
                                QiscusNotification.publish(userAvatarChange: mainUser)
                            }
                        }
                    }
                }
            }, onFailed: { (error) in
                Qiscus.printLog(text: error)
            })
        }
    }
}
