//
//  QComment.swift
//  Alamofire
//
//  Created by asharijuang on 07/08/18.
//

import Foundation
import QiscusCore
import SwiftyJSON

public class QComment: CommentModel {
    
    public var senderName : String{
        get{
            return username
        }
    }
    
    public var text : String{
        get{
            return message
        }
    }
    
    public var createdAt : Int{
        get{
            return unixTimestamp
        }
    }
    
    public var senderEmail: String{
        get{
            return email
        }
    }
    
    //need room name from QComment
    public var roomName : String{
        get{
            return "room name harcode"
        }
    }
    
    //need payload string from QComment
    public var payloadData : String{
        get{
            return "need to be implement payloadData"
        }
    }
    
    //need extras string from QComment
    public var extrasData : String {
        get{
            return "need to be implement extra"
        }
    }
    
    //Todo search comment from local
    internal class func comments(searchQuery: String) -> [QComment] {
//        if Thread.isMainThread {
//            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
//            realm.refresh()
//            
//            let comments = realm.objects(QComment.self).filter({ (comment) -> Bool in
//                return comment.text.lowercased().contains(searchQuery.lowercased())
//            })
//            
//            return Array(comments)
//        }
//        
        return [QComment]()
    }
    
    //Todo call resendPendingMessage
    internal class func resendPendingMessage(){
        
    }
    
     //Todo get model comment
    internal class func tempComment(fromJSON json:JSON)->QComment?{
        return nil
    }
    
    public class func decodeDictionary(data:[AnyHashable : Any]) -> QComment? {
        if let isQiscusdata = data["qiscus_commentdata"] as? Bool{
            if isQiscusdata {
                let temp = QComment()
                if let uniqueId = data["qiscus_uniqueId"] as? String{
                    temp.uniqueTempId = uniqueId
                }
                if let id = data["qiscus_id"] as? String {
                    temp.id = id
                }
                if let roomId = data["qiscus_roomId"] as? Int {
                    temp.roomId = roomId
                }
                if let beforeId = data["qiscus_beforeId"] as? Int {
                    temp.commentBeforeId = beforeId
                }
                if let text = data["qiscus_text"] as? String {
                    temp.message = text
                }
                if let createdAt = data["qiscus_createdAt"] as? Int{
                    temp.unixTimestamp = createdAt
                }
                if let email = data["qiscus_senderEmail"] as? String{
                    temp.email = email
                }
                if let name = data["qiscus_senderName"] as? String{
                    temp.username = name
                }
                if let statusRaw = data["qiscus_statusRaw"] as? String {
                    temp.status = statusRaw
                }
                if let typeRaw = data["qiscus_typeRaw"] as? String {
                    temp.type = CommentType(rawValue: typeRaw)!
                }
                if let payload = data["qiscus_data"] as? String {
                    //temp.payloadData = payload
                }
                
                return temp
            }
        }
        return nil
    }
    
    public func encodeDictionary()->[AnyHashable : Any]{
        var data = [AnyHashable : Any]()
        
        data["qiscus_commentdata"] = true
        data["qiscus_uniqueId"] = self.uniqueTempId
        data["qiscus_id"] = self.id
        data["qiscus_roomId"] = self.roomId
        data["qiscus_beforeId"] = self.commentBeforeId
        data["qiscus_text"] = self.text
        data["qiscus_createdAt"] = self.createdAt
        data["qiscus_senderEmail"] = self.senderEmail
        data["qiscus_senderName"] = self.senderName
        data["qiscus_statusRaw"] = self.status
        data["qiscus_typeRaw"] = self.type
        data["qiscus_data"] = self.payloadData
        
        return data
    }
    
}
