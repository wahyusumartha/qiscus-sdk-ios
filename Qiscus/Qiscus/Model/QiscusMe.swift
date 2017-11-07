//
//  QiscusMe.swift
//  QiscusSDK
//
//  Created by Ahmad Athaullah on 9/8/16.
//  Copyright © 2016 Ahmad Athaullah. All rights reserved.
//

import UIKit
import SwiftyJSON

open class QiscusMe: NSObject {
    open static let sharedInstance = QiscusMe()
    
    let userData = UserDefaults.standard
    
    open class var isLoggedIn:Bool {
        get{
            return (QiscusMe.sharedInstance.token != "")
        }
    }
    open class var canReconnect:Bool{
        get{
            return (QiscusMe.sharedInstance.userKey != "" && QiscusMe.sharedInstance.email != "")
        }
    }
    public var id = 0
    public var email = ""
    public var userName = ""
    public var avatarUrl = ""
    public var rtKey = ""
    public var token = ""
    public var userKey = ""
    public var appId = ""
    public var baseUrl = ""
    
    public var realtimeServer:String = "mqtt.qiscus.com"
    public var realtimePort:Int = 1883
    public var realtimeSSL:Bool = false
    
    public var lastCommentId = Int(0)
    public var lastKnownCommentId = Int(0)
    
    public var paramEmail = ""
    public var paramPass = ""
    public var paramUsername = ""
    public var paramAvatar = ""
    
    open var deviceToken:String = ""{
        didSet{
            let userData = UserDefaults.standard
            userData.set(deviceToken, forKey: "qiscus_device_token")
        }
    }
    
    fileprivate override init(){
        
        if let userId = userData.value(forKey: "qiscus_id") as? Int {
            self.id = userId
        }
        if let userEmail = userData.value(forKey: "qiscus_email") as? String {
            self.email = userEmail
        }
        if let appId = userData.value(forKey: "qiscus_appId") as? String {
            self.appId = appId
        }
        if let realtimeServer = userData.value(forKey: "qiscus_realtimeServer") as? String{
            self.realtimeServer = realtimeServer
        }
        if let realtimePort = userData.value(forKey: "qiscus_realtimePort") as? Int{
            self.realtimePort = realtimePort
        }
        if let realtimeSSL = userData.value(forKey: "qiscus_realtimeSSL") as? Bool{
            self.realtimeSSL = realtimeSSL
        }
        if let name = userData.value(forKey: "qiscus_username") as? String {
            self.userName = name
        }
        if let avatar = userData.value(forKey: "qiscus_avatar_url") as? String {
            self.avatarUrl = avatar
        }
        if let key = userData.value(forKey: "qiscus_rt_key") as? String {
            self.rtKey = key
        }
        if let userToken = userData.value(forKey: "qiscus_token") as? String {
            self.token = userToken
        }
        if let key = userData.value(forKey: "qiscus_user_key") as? String{
            self.userKey = key
        }
        if let url = userData.value(forKey: "qiscus_base_url") as? String{
            self.baseUrl = url
        }
        if let lastComment = userData.value(forKey: "qiscus_lastComment_id") as? Int{
            self.lastCommentId = lastComment
        }
        if let lastComment = userData.value(forKey: "qiscus_lastKnownComment_id") as? Int{
            self.lastKnownCommentId = lastComment
        }
        if let dToken = userData.value(forKey: "qiscus_device_token") as? String{
            self.deviceToken = dToken
        }
        if let paramEmail = userData.value(forKey: "qiscus_param_email") as? String{
            self.paramEmail = paramEmail
        }
        if let paramPass = userData.value(forKey: "qiscus_param_pass") as? String{
            self.paramPass = paramPass
        }
        if let paramUsername = userData.value(forKey: "qiscus_param_username") as? String{
            self.paramUsername = paramUsername
        }
        if let paramAvatar = userData.value(forKey: "qiscus_param_avatar") as? String{
            self.paramAvatar = paramAvatar
        }
    }
    
    open class func saveData(fromJson json:JSON, reconnect:Bool = false)->QiscusMe{
        Qiscus.printLog(text: "jsonFron saveData: \(json)")
        QiscusMe.sharedInstance.id = json["id"].intValue
        QiscusMe.sharedInstance.email = json["email"].stringValue
        QiscusMe.sharedInstance.userName = json["username"].stringValue
        QiscusMe.sharedInstance.avatarUrl = json["avatar"].stringValue
        QiscusMe.sharedInstance.rtKey = json["rtKey"].stringValue
        QiscusMe.sharedInstance.token = json["token"].stringValue
        
        QiscusMe.sharedInstance.userData.set(json["id"].intValue, forKey: "qiscus_id")
        QiscusMe.sharedInstance.userData.set(json["email"].stringValue, forKey: "qiscus_email")
        QiscusMe.sharedInstance.userData.set(json["username"].stringValue, forKey: "qiscus_username")
        QiscusMe.sharedInstance.userData.set(json["avatar"].stringValue, forKey: "qiscus_avatar_url")
        QiscusMe.sharedInstance.userData.set(json["rtKey"].stringValue, forKey: "qiscus_rt_key")
        QiscusMe.sharedInstance.userData.set(json["token"].stringValue, forKey: "qiscus_token")
        
        if !reconnect {
            QiscusMe.sharedInstance.userData.set(json["last_comment_id"].intValue, forKey: "qiscus_lastComment_id")
            QiscusMe.sharedInstance.userData.set(json["last_comment_id"].intValue, forKey: "qiscus_lastKnownComment_id")
        }else{
            if json["last_comment_id"].intValue > QiscusMe.sharedInstance.lastCommentId {
                Qiscus.sync()
            }
        }
        if let lastComment = QiscusMe.sharedInstance.userData.value(forKey: "qiscus_lastComment_id") as? Int{
            QiscusMe.sharedInstance.lastCommentId = lastComment
        }
        if let lastComment = QiscusMe.sharedInstance.userData.value(forKey: "qiscus_lastKnownComment_id") as? Int{
            QiscusMe.sharedInstance.lastKnownCommentId = lastComment
        }
        return QiscusMe.sharedInstance
    }
    public class func updateLastCommentId(commentId:Int){
        if QiscusMe.sharedInstance.lastCommentId < commentId {
            QiscusMe.sharedInstance.lastCommentId = commentId
            QiscusMe.sharedInstance.userData.set(commentId, forKey: "qiscus_lastComment_id")
        }
        if QiscusMe.sharedInstance.lastKnownCommentId < commentId {
            QiscusMe.sharedInstance.lastKnownCommentId = commentId
            QiscusMe.sharedInstance.userData.set(commentId, forKey: "qiscus_lastKnownComment_id")
        }
    }
    public class func updateLastKnownCommentId(commentId:Int){
        if QiscusMe.sharedInstance.lastKnownCommentId < commentId {
            QiscusMe.sharedInstance.lastKnownCommentId = commentId
            QiscusMe.sharedInstance.userData.set(commentId, forKey: "qiscus_lastKnownComment_id")
        }
    }
    open class func clear(){
        QiscusMe.sharedInstance.id = 0
        QiscusMe.sharedInstance.email = ""
        QiscusMe.sharedInstance.userName = ""
        QiscusMe.sharedInstance.avatarUrl = ""
        QiscusMe.sharedInstance.rtKey = ""
        QiscusMe.sharedInstance.token = ""
        QiscusMe.sharedInstance.lastCommentId = 0
        QiscusMe.sharedInstance.appId = ""
        QiscusMe.sharedInstance.baseUrl = ""
        QiscusMe.sharedInstance.realtimeSSL = false
        QiscusMe.sharedInstance.realtimePort = 1883
        QiscusMe.sharedInstance.realtimeServer = "mqtt.qiscus.com"
        
        QiscusMe.sharedInstance.userData.removeObject(forKey: "qiscus_id")
        QiscusMe.sharedInstance.userData.removeObject(forKey: "qiscus_email")
        QiscusMe.sharedInstance.userData.removeObject(forKey: "qiscus_username")
        QiscusMe.sharedInstance.userData.removeObject(forKey: "qiscus_avatar_url")
        QiscusMe.sharedInstance.userData.removeObject(forKey: "qiscus_rt_key")
        QiscusMe.sharedInstance.userData.removeObject(forKey: "qiscus_token")
        QiscusMe.sharedInstance.userData.removeObject(forKey: "qiscus_lastComment_id")
        QiscusMe.sharedInstance.userData.removeObject(forKey: "qiscus_lastKnownComment_id")
        QiscusMe.sharedInstance.userData.removeObject(forKey: "qiscus_base_url")
        QiscusMe.sharedInstance.userData.removeObject(forKey: "qiscus_appId")
        QiscusMe.sharedInstance.userData.removeObject(forKey: "qiscus_realtimeServer")
        QiscusMe.sharedInstance.userData.removeObject(forKey: "qiscus_realtimePort")
        QiscusMe.sharedInstance.userData.removeObject(forKey: "qiscus_realtimeSSL")
        
    }
    
}
