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
    open var id = 0
    open var email = ""
    open var userName = ""
    open var avatarUrl = ""
    open var rtKey = ""
    open var token = ""
    open var userKey = ""
    open var baseUrl = ""
    open var lastCommentId = Int(0)
    
    open var paramEmail = ""
    open var paramPass = ""
    open var paramUsername = ""
    open var paramAvatar = ""
    
    open var deviceToken:String = ""{
        didSet{
            let userData = UserDefaults.standard
            userData.set(deviceToken, forKey: "qiscus_device_token")
        }
    }
    
    fileprivate override init(){
        let userData = UserDefaults.standard
        if let userId = userData.value(forKey: "qiscus_id") as? Int {
            self.id = userId
        }
        if let userEmail = userData.value(forKey: "qiscus_email") as? String {
            self.email = userEmail
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
    
    open class func saveData(fromJson json:JSON)->QiscusMe{
        Qiscus.printLog(text: "jsonFron saveData: \(json)")
        QiscusMe.sharedInstance.id = json["id"].intValue
        QiscusMe.sharedInstance.email = json["email"].stringValue
        QiscusMe.sharedInstance.userName = json["username"].stringValue
        QiscusMe.sharedInstance.avatarUrl = json["avatar"].stringValue
        QiscusMe.sharedInstance.rtKey = json["rtKey"].stringValue
        QiscusMe.sharedInstance.token = json["token"].stringValue
        QiscusMe.sharedInstance.lastCommentId = json["last_comment_id"].intValue
                
        QiscusMe.sharedInstance.userData.set(json["id"].intValue, forKey: "qiscus_id")
        QiscusMe.sharedInstance.userData.set(json["email"].stringValue, forKey: "qiscus_email")
        QiscusMe.sharedInstance.userData.set(json["username"].stringValue, forKey: "qiscus_username")
        QiscusMe.sharedInstance.userData.set(json["avatar"].stringValue, forKey: "qiscus_avatar_url")
        QiscusMe.sharedInstance.userData.set(json["rtKey"].stringValue, forKey: "qiscus_rt_key")
        QiscusMe.sharedInstance.userData.set(json["token"].stringValue, forKey: "qiscus_token")
        QiscusMe.sharedInstance.userData.set(json["last_comment_id"].intValue, forKey: "qiscus_lastComment_id")
        return QiscusMe.sharedInstance
    }
    public class func updateLastCommentId(commentId:Int){
        if QiscusMe.sharedInstance.lastCommentId < commentId {
            QiscusMe.sharedInstance.lastCommentId = commentId
            QiscusMe.sharedInstance.userData.set(commentId, forKey: "qiscus_lastComment_id")
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
        
        QiscusMe.sharedInstance.userData.removeObject(forKey: "qiscus_id")
        QiscusMe.sharedInstance.userData.removeObject(forKey: "qiscus_email")
        QiscusMe.sharedInstance.userData.removeObject(forKey: "qiscus_username")
        QiscusMe.sharedInstance.userData.removeObject(forKey: "qiscus_avatar_url")
        QiscusMe.sharedInstance.userData.removeObject(forKey: "qiscus_rt_key")
        QiscusMe.sharedInstance.userData.removeObject(forKey: "qiscus_token")
        QiscusMe.sharedInstance.userData.removeObject(forKey: "qiscus_lastComment_id")
    }
    
}
