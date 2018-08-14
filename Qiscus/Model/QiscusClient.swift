//
//  QiscusMe.swift
//  QiscusSDK
//
//  Created by Ahmad Athaullah on 9/8/16.
//  Copyright © 2016 Ahmad Athaullah. All rights reserved.
//

import UIKit
import SwiftyJSON


/// contain sdk user information
open class QiscusClient: NSObject {
    
    
    
    public static var hasRegisteredDeviceToken: Bool {
        set {
            let userData = UserDefaults.standard
            userData.set(hasRegisteredDeviceToken, forKey: "has_register_device_token")
        }
        
        get {
            let userData = UserDefaults.standard
            if let hasRegisteredDeviceToken = userData.value(forKey: "has_register_device_token") as? Bool {
                return hasRegisteredDeviceToken
            }
            return false
        }
    }
    
    
    
    open static let shared = QiscusClient()
    
    let userData = UserDefaults.standard
    
    open class var isLoggedIn:Bool {
        get{
            return (Qiscus.client.token != "")
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
    public var lastEventId = ""
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
        if let lastEvent = userData.value(forKey: "qiscus_lastEvent_id") as? String{
            self.lastEventId = lastEvent
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
    
    public class func clear(){
        Qiscus.client.id = 0
        Qiscus.client.email = ""
        Qiscus.client.userName = ""
        Qiscus.client.avatarUrl = ""
        Qiscus.client.rtKey = ""
        Qiscus.client.token = ""
        Qiscus.client.lastCommentId = 0
        Qiscus.client.lastEventId = ""
        
        Qiscus.client.userData.removeObject(forKey: "qiscus_id")
        Qiscus.client.userData.removeObject(forKey: "qiscus_email")
        Qiscus.client.userData.removeObject(forKey: "qiscus_username")
        Qiscus.client.userData.removeObject(forKey: "qiscus_avatar_url")
        Qiscus.client.userData.removeObject(forKey: "qiscus_rt_key")
        Qiscus.client.userData.removeObject(forKey: "qiscus_token")
        Qiscus.client.userData.removeObject(forKey: "qiscus_lastComment_id")
        Qiscus.client.userData.removeObject(forKey: "qiscus_lastKnownComment_id")
        Qiscus.client.userData.removeObject(forKey: "qiscus_lastEvent_id")
    }
    

}

