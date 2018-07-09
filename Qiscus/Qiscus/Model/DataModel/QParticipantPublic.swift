//
//  QParticipantPublic.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 06/07/18.
//

import Foundation
import RealmSwift

extension QParticipant {
    public func updateLastReadId(commentId:Int){
        if !self.isInvalidated {
            let roomId = self.roomId
            let email = self.email
            QiscusDBThread.async {
                guard let room = QRoom.threadSaveRoom(withId: roomId) else { return }
                if room.lastReadCommentId >= commentId {return}
                
                guard let participant = room.participant(withEmail: email) else { return }
                
                let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                realm.refresh()
                
                if participant.lastReadCommentId < commentId {
                    try! realm.write {
                        participant.lastReadCommentId = commentId
                    }
                }
                if participant.lastDeliveredCommentId < commentId {
                    try! realm.write {
                        participant.lastDeliveredCommentId = commentId
                    }
                }
                var lastDelivered = 0
                var lastRead = 0
                
                for p in room.participants {
                    if p.email != Qiscus.client.email {
                        if lastDelivered == 0 {
                            lastDelivered = p.lastDeliveredCommentId
                        }else if p.lastDeliveredCommentId < lastDelivered {
                            lastDelivered = p.lastDeliveredCommentId
                        }
                        if lastRead == 0 {
                            lastRead = p.lastReadCommentId
                        }else if p.lastReadCommentId < lastRead {
                            lastRead = p.lastReadCommentId
                        }
                    }
                }
                if room.lastDeliveredCommentId < lastDelivered {
                    try! realm.write {
                        room.lastDeliveredCommentId = lastDelivered
                    }
                }
                
                if room.lastReadCommentId < lastRead {
                    try! realm.write {
                        room.lastReadCommentId = lastRead
                    }
                    let data = room.rawComments.filter("id != 0 AND id <= \(lastRead) AND statusRaw < \(QCommentStatus.read.rawValue)")
                    for c in data {
                        c.updateStatus(status: .read)
                        if c.id == room.lastCommentId {
                            if room.lastCommentStatusRaw != QCommentStatus.read.rawValue {
                                try! realm.write {
                                    room.lastCommentStatusRaw = QCommentStatus.read.rawValue
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
    public class func all(withEmail email:String)->[QParticipant]{
        var participants = [QParticipant]()
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        let data =  realm.objects(QParticipant.self).filter("email == '\(email)'")
        for participant in data {
            participants.append(participant)
        }
        return participants
    }
    public class func updateLastDeliveredId(forUser email:String, commentId:Int){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        let data =  realm.objects(QParticipant.self).filter("email == '\(email)'")
        
        for participant in data {
            participant.updateLastDeliveredId(commentId: commentId)
        }
    }
    public class func all() -> [QParticipant]{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        let data = realm.objects(QParticipant.self)
        
        if data.count > 0 {
            return Array(data)
        }else{
            return [QParticipant]()
        }
    }
}
