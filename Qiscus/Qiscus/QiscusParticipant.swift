//
//  QiscusParticipant.swift
//  LinkDokter
//
//  Created by Qiscus on 2/24/16.
//  Copyright © 2016 qiscus. All rights reserved.
//

import UIKit
import RealmSwift

open class QiscusParticipant: Object {
    open dynamic var localId:Int = 0
    open dynamic var participantRoomId:Int = 0
    open dynamic var participantEmail:String = ""
    open dynamic var lastReadCommentId:Int = 0
    open dynamic var lastDeliveredCommentId:Int = 0
    
    open class var LastId:Int{
        get{
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            let RetNext = realm.objects(QiscusParticipant.self).sorted(byKeyPath: "localId")
            
            if RetNext.count > 0 {
                let last = RetNext.last!
                return last.localId
            } else {
                return 0
            }
        }
    }
    
    override open class func primaryKey() -> String {
        return "localId"
    }
    open class func getMinReadCommentId(onRoom roomId:Int)->Int{
        var minRead = Int(0)
        let participants = QiscusParticipant.getParticipant(onRoomId: roomId)
        if participants.count > 0{
            minRead = participants.first!.lastReadCommentId
            for participant in participants{
                if participant.lastReadCommentId < minRead{
                    minRead = participant.lastReadCommentId
                }
            }
        }
        return minRead
    }
    open class func getMinDeliveredCommentId(onRoom roomId:Int)->Int{
        var minDelivered = Int(0)
        let participants = QiscusParticipant.getParticipant(onRoomId: roomId)
        if participants.count > 0{
            minDelivered = participants.first!.lastDeliveredCommentId
            for participant in participants{
                if participant.lastDeliveredCommentId < minDelivered{
                    minDelivered = participant.lastDeliveredCommentId
                }
            }
        }
        return minDelivered
    }
    open class func getParticipant(withEmail email:String, roomId:Int) -> QiscusParticipant?{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let searchQuery = NSPredicate(format: "participantRoomId == %d AND participantEmail == '\(email)'", roomId)
        let participantData = realm.objects(QiscusParticipant.self).filter(searchQuery)
        
        if participantData.count > 0 {
            return participantData.first!
        }else{
            return nil
        }
    }
    open func updateLastReadCommentId(commentId:Int){
        if self.lastReadCommentId < commentId {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            try! realm.write {
                self.lastReadCommentId = commentId
            }
        }
        updateLastDeliveredCommentId(commentId: commentId)
    }
    open func updateLastDeliveredCommentId(commentId:Int){
        if self.lastDeliveredCommentId < commentId{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            try! realm.write {
                self.lastDeliveredCommentId = commentId
            }
        }
    }
    open class func getParticipant(onRoomId  roomId:Int)->[QiscusParticipant]{
        var participants = [QiscusParticipant]()
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let searchQuery = NSPredicate(format: "participantRoomId == %d", roomId)
        let participantData = realm.objects(QiscusParticipant.self).filter(searchQuery)
        
        if participantData.count > 0 {
            for participant in participantData {
                participants.append(participant)
            }
        }
        return participants
    }
    open class func addParticipant(_ userEmail:String, roomId:Int){ //  
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        var searchQuery = NSPredicate()
        
        searchQuery = NSPredicate(format: "participantRoomId == %d AND participantEmail == '\(userEmail)'", roomId)
        let participantData = realm.objects(QiscusParticipant.self).filter(searchQuery)
        
        if(participantData.count == 0){
            let participant = QiscusParticipant()
            participant.participantRoomId = roomId
            participant.participantEmail = userEmail
            if let room = QiscusRoom.room(withId: roomId){
                if let lastComment = room.roomLastComment{
                    participant.lastReadCommentId = lastComment.commentId
                    participant.lastDeliveredCommentId = lastComment.commentId
                }
            }
            
            try! realm.write {
                participant.localId = QiscusParticipant.LastId + 1
                realm.add(participant)
            }
        }
    }
    public func remove(){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        var searchQuery = NSPredicate()
        
        searchQuery = NSPredicate(format: "localId == %d", self.localId)
        let participantData = realm.objects(QiscusParticipant.self).filter(searchQuery)
        
        if participantData.count > 0 {
            try! realm.write {
                realm.delete(participantData)
            }
        }
        
    }
    open class func removeAllParticipant(inRoom roomId:Int){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        var searchQuery = NSPredicate()
        
        searchQuery = NSPredicate(format: "participantRoomId == %d", roomId)
        let participantData = realm.objects(QiscusParticipant.self).filter(searchQuery)
        
        if participantData.count > 0 {
            try! realm.write {
                realm.delete(participantData)
            }
        }
    }
    open class func CommitParticipantChange(_ roomId:Int){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let searchQuery =  NSPredicate(format: "participantRoomId == %d AND participantIsDeleted == true", roomId)
        let participantData = realm.objects(QiscusParticipant.self).filter(searchQuery)
        
        if(participantData.count > 0){
            for participant in participantData{
                try! realm.write {
                    realm.delete(participant)
                }
            }
        }
    }
}
