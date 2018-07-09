//
//  QParticipantFunction.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 06/07/18.
//

import Foundation
import RealmSwift

extension QParticipant {
    internal func updateLastDeliveredId(commentId:Int){
        if !self.isInvalidated {
            let roomId = self.roomId
            let email = self.email
            QiscusDBThread.async {
                if let room = QRoom.threadSaveRoom(withId: roomId){
                    if room.lastDeliveredCommentId >= commentId {return}
                    
                    if let participant = room.participant(withEmail: email){
                        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                        realm.refresh()
                        if room.isInvalidated {return}
                        if participant.lastDeliveredCommentId < commentId {
                            try! realm.write {
                                participant.lastDeliveredCommentId = commentId
                            }
                        }
                        var lastDeliveredId = 0
                        for p in room.participants {
                            if p.email != Qiscus.client.email {
                                if lastDeliveredId == 0 {
                                    lastDeliveredId = p.lastDeliveredCommentId
                                }
                                else if p.lastDeliveredCommentId < lastDeliveredId {
                                    lastDeliveredId = p.lastDeliveredCommentId
                                }
                            }
                        }
                        if room.lastDeliveredCommentId >= lastDeliveredId {return}
                        try! realm.write {
                            room.lastDeliveredCommentId = lastDeliveredId
                        }
                        
                        let data = room.rawComments.filter("id != 0 AND id <= \(lastDeliveredId) AND statusRaw < \(QCommentStatus.delivered.rawValue)")
                        for c in data {
                            c.updateStatus(status: .delivered)
                            if c.id == room.lastCommentId {
                                try! realm.write {
                                    room.lastCommentStatusRaw = QCommentStatus.delivered.rawValue
                                }
                                let rId = room.id
                                DispatchQueue.main.async {
                                    if let r = QRoom.room(withId: rId){
                                        QiscusNotification.publish(roomChange: r, onProperty: .lastComment)
                                    }
                                }
                            }
                            
                        }
                    }
                }
            }
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
