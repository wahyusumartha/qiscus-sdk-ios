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
    open dynamic var lastReadCommentId:Int64 = 0
    open dynamic var lastDeliveredCommentId:Int64 = 0
    
    open class var LastId:Int{
        get{
            let realm = try! Realm()
            let RetNext = realm.objects(QiscusParticipant.self).sorted(byProperty: "localId")
            
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
    open class func getParticipant(withEmail email:String, roomId:Int) -> QiscusParticipant?{
        let realm = try! Realm()
        let searchQuery = NSPredicate(format: "participantRoomId == %d AND participantEmail == '\(email)'", roomId)
        let participantData = realm.objects(QiscusParticipant.self).filter(searchQuery)
        
        if participantData.count > 0 {
            return participantData.first!
        }else{
            return nil
        }
    }
    open func updateLastReadCommentId(commentId:Int64){
        if self.lastReadCommentId < commentId {
            let realm = try! Realm()
            try! realm.write {
                self.lastReadCommentId = commentId
            }
        }
        updateLastDeliveredCommentId(commentId: commentId)
    }
    open func updateLastDeliveredCommentId(commentId:Int64){
        if self.lastDeliveredCommentId < commentId{
        let realm = try! Realm()
            try! realm.write {
                self.lastDeliveredCommentId = commentId
            }
        }
    }
    open class func getParticipant(onRoomId  roomId:Int)->[QiscusParticipant]{
        var participants = [QiscusParticipant]()
        let realm = try! Realm()
        let searchQuery = NSPredicate(format: "participantRoomId == %d", roomId)
        let participantData = realm.objects(QiscusParticipant.self).filter(searchQuery)
        
        if participantData.count > 0 {
            for participant in participantData {
                participants.append(participant)
            }
        }
        return participants
    }
    open class func addParticipant(_ userEmail:String, roomId:Int){ // USED
        let realm = try! Realm()
        var searchQuery = NSPredicate()
        
        searchQuery = NSPredicate(format: "participantRoomId == %d AND participantEmail == '\(userEmail)'", roomId)
        let participantData = realm.objects(QiscusParticipant.self).filter(searchQuery)
        
        if(participantData.count == 0){
            let participant = QiscusParticipant()
            participant.localId = QiscusParticipant.LastId + 1
            participant.participantRoomId = roomId
            participant.participantEmail = userEmail
            if let room = QiscusRoom.getRoomById(roomId){
                participant.lastReadCommentId = room.lastCommentIdInRoom
                participant.lastDeliveredCommentId = room.lastCommentIdInRoom
            }
            
            try! realm.write {
                realm.add(participant)
            }
        }
    }
    open class func removeAllParticipant(inRoom roomId:Int){
        let realm = try! Realm()
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
        let realm = try! Realm()
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
