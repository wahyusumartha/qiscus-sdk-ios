//
//  QParticipant.swift
//  Example
//
//  Created by Ahmad Athaullah on 7/5/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import Foundation
import RealmSwift
@objc public protocol QParticipantDelegate {
    func participant(didChange participant:QParticipant)
}
public class QParticipant:Object {
    static var cache = [String : QParticipant]()
    public dynamic var localId:String = ""
    public dynamic var roomId:Int = 0
    public dynamic var email:String = ""
    public dynamic var lastReadCommentId:Int = 0
    public dynamic var lastDeliveredCommentId:Int = 0
    
    public var delegate:QParticipantDelegate? = nil
    
    // MARK: - Primary Key
    override public class func primaryKey() -> String {
        return "localId"
    }
    override public static func ignoredProperties() -> [String] {
        return ["delegate"]
    }
    
    // MARK: - Getter variable
    public var user:QUser? {
        get{
            if let cache = QUser.cache[self.email] {
                return cache
            }else{
                let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                if let result = realm.object(ofType: QUser.self, forPrimaryKey: self.email) {
                    QUser.cache[self.email] = result
                    return result
                }else{
                    return nil
                }
            }
        }
    }
    public class func participant(inRoomWithId roomId:Int, andEmail email: String)->QParticipant?{
        let id = "\(roomId)_\(email)"
        var participant:QParticipant? = nil
        if let cache = QParticipant.cache[id] {
            participant = cache
        }else{
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            if let data = realm.object(ofType: QParticipant.self, forPrimaryKey: id) {
                QParticipant.cache[id] = data
                participant = data
            }
        }
        return participant
    }
    public func updateLastDeliveredId(commentId:Int){
        if commentId > self.lastDeliveredCommentId {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            try! realm.write {
                self.lastDeliveredCommentId = commentId
            }
            if let room = QRoom.room(withId: self.roomId){
                room.updateCommentStatus()
            }
            if let cache = QParticipant.cache[self.localId] {
                cache.delegate?.participant(didChange: cache)
            }
        }
    }
    public func updateLastReadId(commentId:Int){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        if commentId > self.lastReadCommentId {
            try! realm.write {
                self.lastReadCommentId = commentId
            }
            if let room = QRoom.room(withId: self.roomId){
                room.updateCommentStatus()
            }
        }
        self.updateLastDeliveredId(commentId: commentId)
        if let cache = QParticipant.cache[self.localId] {
            cache.delegate?.participant(didChange: cache)
        }
    }
    public class func all(withEmail email:String)->[QParticipant]{
        var participants = [QParticipant]()
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let data =  realm.objects(QParticipant.self).filter("email == '\(email)'")
        for participant in data {
            participants.append(participant)
        }
        return participants
    }
    public class func updateLastDeliveredId(forUser email:String, commentId:Int){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let data =  realm.objects(QParticipant.self).filter("email == '\(email)'")
        
        for participant in data {
            participant.updateLastDeliveredId(commentId: commentId)
        }
    }
    public class func all() -> [QParticipant]{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let data = realm.objects(QParticipant.self)
        
        if data.count > 0 {
            return Array(data)
        }else{
            return [QParticipant]()
        }
    }
    internal class func cacheAll(){
        let participants = QParticipant.all()
        for participant in participants{
            if QParticipant.cache[participant.localId] == nil {
                QParticipant.cache[participant.localId] = participant
            }
        }
    }
}
