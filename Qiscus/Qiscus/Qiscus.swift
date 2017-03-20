//
//  Qiscus.swift
//
//  Created by Ahmad Athaullah on 7/17/16.
//  Copyright © 2016 qiscus. All rights reserved.
//


import UIKit
import RealmSwift
import Foundation
import SwiftMQTT
import SwiftyJSON
import PushKit
import UserNotifications

@objc public class Qiscus: NSObject, MQTTSessionDelegate, PKPushRegistryDelegate, UNUserNotificationCenterDelegate {
    
    static let sharedInstance = Qiscus()
    static let qiscusVersionNumber:String = "2.2.8"
    static let showDebugPrint = true
    
    // MARK: - Thread
    static let realtimeThread = DispatchQueue(label: "com.qiscus.realtime")
    static let logThread = DispatchQueue(label: "com.qiscus.log")
    static let apiThread = DispatchQueue(label: "com.qiscus.httpRequest")
    static let dbThread = DispatchQueue(label: "com.qiscus.db")
    static let uiThread = DispatchQueue.main
    static let logicThread = DispatchQueue.global()
    
    static var qiscusDeviceToken: String = ""
    static var qiscusDownload:[String] = [String]()
    
    var config = QiscusConfig.sharedInstance
    var commentService = QiscusCommentClient.sharedInstance
    var iCloudUpload:Bool = false
    var isPushed:Bool = false
    var reachability:QReachability?
    var mqtt:MQTTSession?
    var mqttChannel = [String]()
    var notificationAction:((QiscusChatVC)->Void)? = nil
    var realtimeConnected = false
    
    @objc public var styleConfiguration = QiscusUIConfiguration.sharedInstance
    @objc public var connected:Bool = false
    @objc public var httpRealTime:Bool = false
    @objc public var toastMessageAct:((_ roomId:Int, _ comment:QiscusComment)->Void)?
    
    let application = UIApplication.shared
    let appDelegate = UIApplication.shared.delegate
    
    @objc public class var versionNumber:String{
        get{
            return Qiscus.qiscusVersionNumber
        }
    }
    @objc public class var shared:Qiscus{
        get{
            return Qiscus.sharedInstance
        }
    }
    @objc public class var isLoggedIn:Bool{
        get{
            Qiscus.checkDatabaseMigration()
            if !Qiscus.sharedInstance.connected {
                Qiscus.setupReachability()
            }
            return QiscusMe.isLoggedIn
        }
    }
    @objc public class var deviceToken:String{
        get{
            return Qiscus.qiscusDeviceToken
        }
    }
    @objc public class var style:QiscusUIConfiguration{
        get{
            return Qiscus.sharedInstance.styleConfiguration
        }
    }
    
    class var commentService:QiscusCommentClient{
        get{
            return QiscusCommentClient.sharedInstance
        }
    }
    
    fileprivate override init(){
        
    }
    
    class var bundle:Bundle{
        get{
            let podBundle = Bundle(for: Qiscus.self)
            
            if let bundleURL = podBundle.url(forResource: "Qiscus", withExtension: "bundle") {
                return Bundle(url: bundleURL)!
            }else{
                return podBundle
            }
        }
    }
    
    /**
     Class function to disable notification when **In App**
     */
    @objc public class func disableInAppNotif(){
        Qiscus.sharedInstance.config.showToasterMessage = false
    }
    /**
     Class function to enable notification when **In App**
     */
    @objc public class func enableInAppNotif(){
        Qiscus.sharedInstance.config.showToasterMessage = true
    }
    
    class func disconnectRealtime(){
        Qiscus.uiThread.async {
            Qiscus.sharedInstance.mqtt?.unSubscribe(from: Qiscus.sharedInstance.mqttChannel, completion: { (success, error) in
                Qiscus.sharedInstance.mqttChannel = [String]()
            })
            Qiscus.sharedInstance.mqtt?.disconnect()
        }
    }
    
    @objc public class func clear(){
        QiscusMe.clear()
        let realm = try! Realm()
        try! realm.write {
            realm.deleteAll()
        }
        Qiscus.deleteAllFiles()
        Qiscus.publishUserStatus(offline: true)
    }
    
    // need Documentation
    func checkChat(){
        if Qiscus.isLoggedIn{
            Qiscus.mqttConnect(chatOnly: true)
        }
    }
    func RealtimeConnect(){
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidEnterBackground, object: nil)
        
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(Qiscus.applicationDidBecomeActife), name: .UIApplicationDidBecomeActive, object: nil)
        center.addObserver(self, selector: #selector(Qiscus.goToBackgroundMode), name: .UIApplicationDidEnterBackground, object: nil)
        if Qiscus.isLoggedIn {
            Qiscus.mqttConnect()
        }
    }
    @objc public class func setup(withAppId appId:String, userEmail:String, userKey:String, username:String, avatarURL:String? = nil, delegate:QiscusConfigDelegate? = nil, secureURl:Bool = true){
        Qiscus.checkDatabaseMigration()
        var requestProtocol = "https"
        if !secureURl {
            requestProtocol = "http"
        }
        let email = userEmail.lowercased()
        let baseUrl = "\(requestProtocol)://\(appId).qiscus.com/api/v2/mobile"
        
        QiscusMe.sharedInstance.baseUrl = baseUrl
        QiscusMe.sharedInstance.userData.set(baseUrl, forKey: "qiscus_base_url")
        if delegate != nil {
            QiscusCommentClient.sharedInstance.configDelegate = delegate
        }
        var needLogin = false
        
        if QiscusMe.isLoggedIn {
            if email != QiscusMe.sharedInstance.email{
                needLogin = true
            }
        }else{
            needLogin = true
        }
        
        if needLogin {
            Qiscus.clear()
            QiscusCommentClient.sharedInstance.loginOrRegister(userEmail, password: userKey, username: username, avatarURL: avatarURL)
        }else{
            if QiscusCommentClient.sharedInstance.configDelegate != nil {
                Qiscus.setupReachability()
                Qiscus.uiThread.async {
                    QiscusCommentClient.sharedInstance.configDelegate!.qiscusConnected()
                }
            }
        }
    }
    @objc public class func setup(withURL baseUrl:String, userEmail:String, id:Int, username:String, userKey:String, delegate:QiscusConfigDelegate? = nil, secureURl:Bool = true, realTimeKey:String){
        Qiscus.checkDatabaseMigration()
        let email = userEmail.lowercased()
        
        QiscusMe.sharedInstance.baseUrl = "\(baseUrl)/api/v2/mobile"
        QiscusMe.sharedInstance.id = id
        QiscusMe.sharedInstance.email = email
        QiscusMe.sharedInstance.userName = username
        QiscusMe.sharedInstance.token = userKey
        QiscusMe.sharedInstance.rtKey = realTimeKey
        
        QiscusMe.sharedInstance.userData.set(realTimeKey, forKey: "qiscus_rt_key")
        QiscusMe.sharedInstance.userData.set(id, forKey: "qiscus_id")
        QiscusMe.sharedInstance.userData.set(baseUrl, forKey: "qiscus_base_url")
        QiscusMe.sharedInstance.userData.set(email, forKey: "qiscus_email")
        QiscusMe.sharedInstance.userData.set(username, forKey: "qiscus_username")
        QiscusMe.sharedInstance.userData.set(userKey, forKey: "qiscus_token")
        Qiscus.setupReachability()
        
        Qiscus.sharedInstance.RealtimeConnect()
        
        if delegate != nil {
            QiscusCommentClient.sharedInstance.configDelegate = delegate
            Qiscus.uiThread.async {
                QiscusCommentClient.sharedInstance.configDelegate!.qiscusConnected()
            }
        }
    }
    
    
    /**
     Class function to configure chat with user
     - parameter users: **String** users.
     - parameter readOnly: **Bool** to set read only or not (Optional), Default value : false.
     - parameter title: **String** text to show as chat title (Optional), Default value : "".
     - parameter subtitle: **String** text to show as chat subtitle (Optional), Default value : "" (empty string).
     */
    @objc public class func chatVC(withUsers users:[String], readOnly:Bool = false, title:String = "", subtitle:String = "", distinctId:String? = nil, optionalData:String?=nil, withMessage:String? = nil)->QiscusChatVC{
        Qiscus.checkDatabaseMigration()
        if !Qiscus.sharedInstance.connected {
            Qiscus.setupReachability()
        }
        
        Qiscus.sharedInstance.isPushed = true
        QiscusUIConfiguration.sharedInstance.readOnly = readOnly
        QiscusUIConfiguration.sharedInstance.copyright.chatSubtitle = subtitle
        QiscusUIConfiguration.sharedInstance.copyright.chatTitle = title
        
        let chatVC = QiscusChatVC.sharedInstance
        chatVC.reset()
        if distinctId != nil{
            chatVC.distincId = distinctId!
        }else{
            chatVC.distincId = ""
        }
        chatVC.optionalData = optionalData
        chatVC.message = withMessage
        chatVC.users = users
        chatVC.optionalData = optionalData
        
        if chatVC.isPresence {
            chatVC.goBack()
        }
        chatVC.backAction = nil
        
        return chatVC
    }
    
    /**
     No Documentation
     */
    
    @objc public class func chat(withRoomId roomId:Int, target:UIViewController, readOnly:Bool = false, title:String = "", subtitle:String = "", distinctId:String? = nil, withMessage:String? = nil, optionalData:String?=nil){
        Qiscus.checkDatabaseMigration()
        if !Qiscus.sharedInstance.connected {
            Qiscus.setupReachability()
        }
        
        Qiscus.sharedInstance.isPushed = false
        QiscusUIConfiguration.sharedInstance.readOnly = readOnly
        QiscusUIConfiguration.sharedInstance.copyright.chatSubtitle = subtitle
        QiscusUIConfiguration.sharedInstance.copyright.chatTitle = title
        
        let chatVC = QiscusChatVC.sharedInstance
        chatVC.reset()
        if distinctId != nil{
            chatVC.distincId = distinctId!
        }else{
            chatVC.distincId = ""
        }
        chatVC.roomId = roomId
        chatVC.optionalData = optionalData
        chatVC.message = withMessage
        chatVC.newRoom = false
        
        if chatVC.isPresence {
            chatVC.goBack()
        }
        
        chatVC.backAction = nil
        
        let navController = UINavigationController()
        navController.viewControllers = [chatVC]
        
        target.navigationController?.present(navController, animated: true, completion: nil)
    }
    @objc public class func chat(withUsers users:[String], target:UIViewController, readOnly:Bool = false, title:String = "", subtitle:String = "", distinctId:String? = nil, withMessage:String? = nil, optionalData:String?=nil){
        Qiscus.checkDatabaseMigration()
        if !Qiscus.sharedInstance.connected {
            Qiscus.setupReachability()
        }
        
        Qiscus.sharedInstance.isPushed = false
        QiscusUIConfiguration.sharedInstance.readOnly = readOnly
        QiscusUIConfiguration.sharedInstance.copyright.chatSubtitle = subtitle
        QiscusUIConfiguration.sharedInstance.copyright.chatTitle = title
        
        
        let chatVC = QiscusChatVC.sharedInstance
        chatVC.reset()
        if distinctId != nil{
            chatVC.distincId = distinctId!
        }else{
            chatVC.distincId = ""
        }
        chatVC.optionalData = optionalData
        chatVC.message = withMessage
        chatVC.users = users
        
        if chatVC.isPresence {
            chatVC.goBack()
        }
        chatVC.backAction = nil
        
        let navController = UINavigationController()
        navController.viewControllers = [chatVC]
        
        target.navigationController?.present(navController, animated: true, completion: nil)
    }
    /**
     No Documentation
     */
    @objc public class func chatView(withUsers users:[String], readOnly:Bool = false, title:String = "", subtitle:String = "", withMessage:String? = nil)->QiscusChatVC{
        Qiscus.checkDatabaseMigration()
        if !Qiscus.sharedInstance.connected {
            Qiscus.setupReachability()
        }
        Qiscus.sharedInstance.isPushed = true
        QiscusUIConfiguration.sharedInstance.readOnly = readOnly
        QiscusUIConfiguration.sharedInstance.copyright.chatSubtitle = subtitle
        QiscusUIConfiguration.sharedInstance.copyright.chatTitle = title
        
        let chatVC = QiscusChatVC.sharedInstance
        chatVC.reset()
        chatVC.message = withMessage
        chatVC.users = users
        
        if chatVC.isPresence {
            chatVC.goBack()
        }
        chatVC.backAction = nil
        
        return chatVC
    }
    /**
     No Documentation
     */
    @objc public class func chatView(withRoomId roomId:Int, readOnly:Bool = false, title:String = "", subtitle:String = "", withMessage:String? = nil)->QiscusChatVC{
        Qiscus.checkDatabaseMigration()
        if !Qiscus.sharedInstance.connected {
            Qiscus.setupReachability()
        }
        Qiscus.sharedInstance.isPushed = true
        QiscusUIConfiguration.sharedInstance.readOnly = readOnly
        QiscusUIConfiguration.sharedInstance.copyright.chatSubtitle = subtitle
        QiscusUIConfiguration.sharedInstance.copyright.chatTitle = title
        
        let chatVC = QiscusChatVC.sharedInstance
        chatVC.reset()
        chatVC.roomId = roomId
        chatVC.message = withMessage
        
        if chatVC.isPresence {
            chatVC.goBack()
        }
        chatVC.backAction = nil
        
        return chatVC
    }
    @objc public class func image(named name:String)->UIImage?{
        return UIImage(named: name, in: Qiscus.bundle, compatibleWith: nil)?.localizedImage()
    }
    /**
     Class function to unlock action chat
     - parameter action: **()->Void** as unlock action for your chat
     */
    @objc public class func unlockAction(_ action:@escaping (()->Void)){
        QiscusChatVC.sharedInstance.unlockAction = action
    }
    /**
     Class function to show alert in chat with UIAlertController
     - parameter alert: The **UIAlertController** to show alert message in chat
     */
    @objc public class func showChatAlert(alertController alert:UIAlertController){
        QiscusChatVC.sharedInstance.showAlert(alert: alert)
    }
    /**
     Class function to unlock chat
     */
    @objc public class func unlockChat(){
        QiscusChatVC.sharedInstance.unlockChat()
    }
    /**
     Class function to lock chat
     */
    @objc public class func lockChat(){
        QiscusChatVC.sharedInstance.lockChat()
    }
    
    /**
     Class function to set color chat navigation with gradient
     - parameter topColor: The **UIColor** as your top gradient navigation color.
     - parameter bottomColor: The **UIColor** as your bottom gradient navigation color.
     - parameter tintColor: The **UIColor** as your tint gradient navigation color.
     */
    @objc public class func setGradientChatNavigation(_ topColor:UIColor, bottomColor:UIColor, tintColor:UIColor){
        QiscusChatVC.sharedInstance.setGradientChatNavigation(withTopColor: topColor, bottomColor: bottomColor, tintColor: tintColor)
        QPopUpView.sharedInstance.topColor = topColor
        QPopUpView.sharedInstance.bottomColor = bottomColor
    }
    /**
     Class function to set color chat navigation without gradient
     - parameter color: The **UIColor** as your navigation color.
     - parameter tintColor: The **UIColor** as your tint navigation color.
     */
    @objc public class func setNavigationColor(_ color:UIColor, tintColor: UIColor){
        QiscusChatVC.sharedInstance.setNavigationColor(color, tintColor: tintColor)
    }
    /**
     Class function to set upload from iCloud active or not
     - parameter active: **Bool** to set active or not.
     */
    @objc public class func iCloudUploadActive(_ active:Bool){
        Qiscus.sharedInstance.iCloudUpload = active
        //QiscusChatVC.sharedInstance.documentButton.hidden = !active
    }
    
    class func setupReachability(){
        Qiscus.sharedInstance.reachability = QReachability()
        
        if let reachable = Qiscus.sharedInstance.reachability {
            if reachable.isReachable {
                Qiscus.sharedInstance.connected = true
                if Qiscus.isLoggedIn {
                    Qiscus.sharedInstance.RealtimeConnect()
                }
            }
        }
        
        Qiscus.sharedInstance.reachability?.whenReachable = { reachability in
            
            DispatchQueue.main.async {
                
                if reachability.isReachableViaWiFi {
                    Qiscus.printLog(text: "connected via wifi")
                } else {
                    Qiscus.printLog(text: "connected via cellular data")
                }
                Qiscus.sharedInstance.connected = true
                if Qiscus.isLoggedIn {
                    Qiscus.sharedInstance.RealtimeConnect()
                }
                if QiscusChatVC.sharedInstance.isPresence {
                    Qiscus.printLog(text: "try to sync after connected")
                }
                
            }
        }
        Qiscus.sharedInstance.reachability?.whenUnreachable = { reachability in
            DispatchQueue.main.async {
                Qiscus.printLog(text: "disconnected")
                Qiscus.sharedInstance.connected = false
            }
        }
        do {
            try  Qiscus.sharedInstance.reachability?.startNotifier()
        } catch {
            Qiscus.printLog(text: "Unable to start network notifier")
        }
    }
    
    // MARK: - MQTT delegate
    public func mqttDidReceive(message data: Data, in topic: String, from session: MQTTSession){
        let state = UIApplication.shared.applicationState
        if state != .active {
            let channelArr = topic.characters.split(separator: "/")
            let lastChannelPart = String(channelArr.last!)
            Qiscus.printLog(text: "got new realtime message in topic: \(topic)")
            switch lastChannelPart {
            case "c":
                let json = JSON(data: data)
                let commentId = QiscusComment.getCommentIdFromJSON(json)
                let senderName = json["username"].stringValue
                let isSaved = QiscusComment.getComment(fromRealtimeJSON: json)
                let senderEmail = json["email"].stringValue
                let senderAvatar = json["user_avatar"].stringValue
                let roomId = json["room_id"].intValue
                let roomName = json["room_name"].stringValue
                let roomAvatar = json["room_avatar"].stringValue
                
                QiscusCommentClient.sharedInstance.publishMessageStatus(onComment: commentId, roomId: roomId, status: .delivered, withCompletion: {
                    if let thisComment = QiscusComment.getComment(withId: commentId) {
                        thisComment.updateCommentStatus(.read, email: thisComment.commentSenderEmail)
                    }
                })
                if let user = QiscusUser.getUserWithEmail(senderEmail){
                    if let room = QiscusRoom.getRoomById(roomId){
                        let newUser = QiscusUser()
                        newUser.userFullName = senderName
                        newUser.userEmail = senderEmail
                        newUser.userAvatarURL = senderAvatar
                        
                        let newRoom = QiscusRoom()
                        newRoom.roomId = roomId
                        newRoom.roomName = room.roomName
                        newRoom.roomAvatarURL = room.roomAvatarURL
                        
                        var userChanged = false
                        
                        if user.userFullName != senderName{
                            user.updateUserFullName(senderName)
                            userChanged = true
                            if room.roomType == .single && userChanged && senderEmail != QiscusMe.sharedInstance.email {
                                newRoom.roomName = senderName
                                room.updateRoomName(senderName)
                            }
                        }
                        if user.userAvatarURL != senderAvatar{
                            user.updateUserAvatarURL(senderAvatar)
                            userChanged = true
                            if room.roomType == .single && userChanged && senderEmail != QiscusMe.sharedInstance.email {
                                newRoom.roomAvatarURL = senderAvatar
                                room.updateRoomAvatar(senderAvatar)
                            }
                        }
                    }
                }else{
                    Qiscus.printLog(text: "New user detected")
                }
                
                if let room = QiscusRoom.getRoomById(roomId){
                    if room.roomType == .group{
                        let newRoom = QiscusRoom()
                        newRoom.roomId = roomId
                        newRoom.roomAvatarURL = room.roomAvatarURL
                        newRoom.roomName = room.roomName
                        
                        if room.roomName != roomName{
                            newRoom.roomName = roomName
                            room.updateRoomName(roomName)
                        }
                        if room.roomAvatarURL != roomAvatar{
                            newRoom.roomAvatarURL = roomAvatar
                            room.updateRoomAvatar(roomAvatar)
                        }
                    }
                }
                if isSaved{
                    let newMessage = QiscusComment.getComment(withId: commentId)
                    
                    var notificationMessage = ""
                    if newMessage!.commentIsFile {
                        if let file = QiscusFile.getCommentFileWithComment(newMessage!){
                            switch file.fileType {
                            case .media:
                                notificationMessage = "Send you picture"
                                break
                            case .document:
                                notificationMessage = "Send you document"
                                break
                            case .video:
                                notificationMessage = "Send you video"
                                break
                            case .audio:
                                notificationMessage = "Send you audio"
                                break
                            default:
                                notificationMessage = "Send you file"
                                break
                            }
                        }else{
                            notificationMessage = "Send you file"
                        }
                    }else{
                        notificationMessage = newMessage!.commentText
                    }
                    
                    if !newMessage!.isOwnMessage{
                        if #available(iOS 10.0, *) {
                            let content = UNMutableNotificationContent()
                            content.title = roomName
                            content.body = "\(senderName): \(notificationMessage)"
                            content.sound = UNNotificationSound.default()
                            content.userInfo = ["qiscus-room-id": roomId]
                            
                            let request = UNNotificationRequest.init(identifier: "QiscusComment-\(newMessage?.commentId)", content: content, trigger: nil)
                            let center = UNUserNotificationCenter.current()
                            center.add(request, withCompletionHandler: { (error) in
                                if error == nil {
                                    Qiscus.printLog(text: "Notification added")
                                }else{
                                    Qiscus.printLog(text: "Notificationerror: \(error)")
                                }
                            })
                        } else {
                            // Fallback on earlier versions
                        }
                    }
                }
                break
            default:
                Qiscus.printLog(text: "Realtime socket receive message in unknown topic: \(topic)")
                break
            }
        }else{
            Qiscus.realtimeThread.async {
                if Qiscus.isLoggedIn{
                    let channelArr = topic.characters.split(separator: "/")
                    let lastChannelPart = String(channelArr.last!)
                    Qiscus.printLog(text: "got new realtime message in topic: \(topic)")
                    switch lastChannelPart {
                    case "c":
                        let json = JSON(data: data)
                        let notifTopicId = QiscusComment.getCommentTopicIdFromJSON(json)
                        let commentId = QiscusComment.getCommentIdFromJSON(json)
                        let qiscusService = QiscusCommentClient.sharedInstance
                        let senderAvatarURL = json["user_avatar"].stringValue
                        let senderName = json["username"].stringValue
                        let isSaved = QiscusComment.getComment(fromRealtimeJSON: json)
                        let senderEmail = json["email"].stringValue
                        let senderAvatar = json["user_avatar"].stringValue
                        let roomId = json["room_id"].intValue
                        let roomName = json["room_name"].stringValue
                        let roomAvatar = json["room_avatar"].stringValue
                        let isPushed = Qiscus.sharedInstance.isPushed
                        
                        Qiscus.apiThread.async {
                            QiscusCommentClient.sharedInstance.publishMessageStatus(onComment: commentId, roomId: roomId, status: .delivered, withCompletion: {
                                if let thisComment = QiscusComment.getComment(withId: commentId) {
                                    thisComment.updateCommentStatus(.read, email: thisComment.commentSenderEmail)
                                }
                            })
                        }
                        if let user = QiscusUser.getUserWithEmail(senderEmail){
                            if let room = QiscusRoom.getRoomById(roomId){
                                let newUser = QiscusUser()
                                newUser.userFullName = senderName
                                newUser.userEmail = senderEmail
                                newUser.userAvatarURL = senderAvatar
                                
                                let newRoom = QiscusRoom()
                                newRoom.roomId = roomId
                                newRoom.roomName = room.roomName
                                newRoom.roomAvatarURL = room.roomAvatarURL
                                
                                var userChanged = false
                                var roomChanged = false
                                
                                if user.userFullName != senderName{
                                    user.updateUserFullName(senderName)
                                    userChanged = true
                                    if room.roomType == .single && userChanged && senderEmail != QiscusMe.sharedInstance.email {
                                        newRoom.roomName = senderName
                                        room.updateRoomName(senderName)
                                        roomChanged = true
                                    }
                                }
                                if user.userAvatarURL != senderAvatar{
                                    user.updateUserAvatarURL(senderAvatar)
                                    userChanged = true
                                    if room.roomType == .single && userChanged && senderEmail != QiscusMe.sharedInstance.email {
                                        newRoom.roomAvatarURL = senderAvatar
                                        room.updateRoomAvatar(senderAvatar)
                                        roomChanged = true
                                    }
                                }
                                if userChanged{
                                    qiscusService.delegate?.qiscusService(didChangeUser: newUser, onUserWithEmail: senderEmail)
                                }
                                if roomChanged{
                                    qiscusService.delegate?.qiscusService(didChangeRoom: newRoom, onRoomWithId: roomId)
                                }
                            }
                        }else{
                            Qiscus.printLog(text: "New user detected")
                        }
                        
                        if let room = QiscusRoom.getRoomById(roomId){
                            if room.roomType == .group{
                                var changed = false
                                let newRoom = QiscusRoom()
                                newRoom.roomId = roomId
                                newRoom.roomAvatarURL = room.roomAvatarURL
                                newRoom.roomName = room.roomName
                                
                                if room.roomName != roomName{
                                    changed = true
                                    newRoom.roomName = roomName
                                    room.updateRoomName(roomName)
                                }
                                if room.roomAvatarURL != roomAvatar{
                                    changed = true
                                    newRoom.roomAvatarURL = roomAvatar
                                    room.updateRoomAvatar(roomAvatar)
                                }
                                if changed{
                                    qiscusService.delegate?.qiscusService(didChangeRoom: newRoom, onRoomWithId: roomId)
                                }
                            }
                        }
                        if isSaved{
                            let newMessage = QiscusComment.getComment(withId: commentId)
                            
                            if qiscusService.commentDelegate != nil{
                                let copyComment = QiscusComment.copyComment(comment: newMessage!)
                                let presenter = QiscusCommentPresenter.getPresenter(forComment: copyComment)
                                presenter.userFullName = senderName
                                Qiscus.uiThread.async {
                                    qiscusService.delegate?.qiscusService(gotNewMessage: presenter)
                                }
                            }
                            if qiscusService.roomDelegate != nil{
                                let copyComment = QiscusComment.copyComment(comment: newMessage!)
                                Qiscus.uiThread.async {
                                    qiscusService.roomDelegate?.gotNewComment(copyComment)
                                    
                                }
                            }
                            var showToast = true
                            let state = UIApplication.shared.applicationState
                            
                            if QiscusChatVC.sharedInstance.isPresence && QiscusChatVC.sharedInstance.topicId == notifTopicId  && state == .active{
                                showToast = false
                                if QiscusChatVC.sharedInstance.room?.roomLastCommentTopicId != notifTopicId{
                                    if Qiscus.sharedInstance.config.showToasterMessageInsideChat{
                                        showToast = true
                                    }
                                }
                            }
                            var notificationMessage = ""
                            if newMessage!.commentIsFile {
                                if let file = QiscusFile.getCommentFileWithComment(newMessage!){
                                    switch file.fileType {
                                    case .media:
                                        notificationMessage = "Send you picture"
                                        break
                                    case .document:
                                        notificationMessage = "Send you document"
                                        break
                                    case .video:
                                        notificationMessage = "Send you video"
                                        break
                                    case .audio:
                                        notificationMessage = "Send you audio"
                                        break
                                    default:
                                        notificationMessage = "Send you file"
                                        break
                                    }
                                }else{
                                    notificationMessage = "Send you file"
                                }
                            }else{
                                notificationMessage = newMessage!.commentText
                            }
                            if Qiscus.sharedInstance.application.applicationState == UIApplicationState.active{
                                if showToast && Qiscus.sharedInstance.config.showToasterMessage{
                                    if let window = UIApplication.shared.keyWindow{
                                        if let currenRootView = window.rootViewController as? UINavigationController{
                                            let viewController = currenRootView.viewControllers[currenRootView.viewControllers.count - 1]
                                            QToasterSwift.toast(target: viewController, text: notificationMessage, title:senderName, iconURL:senderAvatarURL, iconPlaceHolder:Qiscus.image(named:"avatar"), onTouch: {
                                                if Qiscus.sharedInstance.toastMessageAct == nil{
                                                    if isPushed{
                                                        let chatVC = Qiscus.chatView(withRoomId: roomId, title: senderName)
                                                        currenRootView.pushViewController(chatVC, animated: true)
                                                    }else{
                                                        if QiscusChatVC.sharedInstance.isPresence{
                                                            QiscusChatVC.sharedInstance.goBack()
                                                        }
                                                        let activeViewController = currenRootView.viewControllers[currenRootView.viewControllers.count - 1]
                                                        Qiscus.chat(withRoomId: roomId, target: activeViewController)
                                                    }
                                                }else{
                                                    Qiscus.sharedInstance.toastMessageAct!(roomId, newMessage!)
                                                }
                                                
                                            }
                                            )
                                        }
                                    }
                                }
                            }
                            else{
                                if !newMessage!.isOwnMessage{
                                    if #available(iOS 10.0, *) {
                                        let content = UNMutableNotificationContent()
                                        content.title = roomName
                                        content.body = "\(senderName): \(notificationMessage)"
                                        content.sound = UNNotificationSound.default()
                                        content.userInfo = ["qiscus-room-id": roomId]
                                        
                                        let request = UNNotificationRequest.init(identifier: "QiscusComment-\(newMessage?.commentId)", content: content, trigger: nil)
                                        let center = UNUserNotificationCenter.current()
                                        center.add(request, withCompletionHandler: { (error) in
                                            if error == nil {
                                                Qiscus.printLog(text: "Notification added")
                                            }else{
                                                Qiscus.printLog(text: "Notificationerror: \(error)")
                                            }
                                        })
                                    } else {
                                        // Fallback on earlier versions
                                    }
                                    
                                }
                            }
                        }
                        break
                    case "t":
                        DispatchQueue.global().async {
                            let topicId:Int = Int(String(channelArr[2]))!
                            let userEmail:String = String(channelArr[3])
                            let message = String(data: data, encoding: .utf8)!
                            if userEmail != QiscusMe.sharedInstance.email {
                                if QiscusChatVC.sharedInstance.isPresence && QiscusChatVC.sharedInstance.topicId == topicId {
                                    switch message {
                                    case "1":
                                        if let user = QiscusUser.getUserWithEmail(userEmail) {
                                            user.updateLastSeen()
                                            user.updateStatus(isOnline: true)
                                            
                                            let userFullName = user.userFullName
                                            if !QiscusChatVC.sharedInstance.isTypingOn || (QiscusChatVC.sharedInstance.typingIndicatorUser != userFullName){
                                                QiscusChatVC.sharedInstance.startTypingIndicator(withUser: userFullName)
                                            }
                                        }else{
                                            if !QiscusChatVC.sharedInstance.isTypingOn || (QiscusChatVC.sharedInstance.typingIndicatorUser != userEmail){
                                                QiscusChatVC.sharedInstance.startTypingIndicator(withUser: userEmail)
                                            }
                                        }
                                        break
                                    default:
                                        if let user = QiscusUser.getUserWithEmail(userEmail) {
                                            let userFullName = user.userFullName
                                            if QiscusChatVC.sharedInstance.isTypingOn && (QiscusChatVC.sharedInstance.typingIndicatorUser == userFullName){
                                                QiscusChatVC.sharedInstance.stopTypingIndicator()
                                            }
                                        }else{
                                            if QiscusChatVC.sharedInstance.isTypingOn && (QiscusChatVC.sharedInstance.typingIndicatorUser == userEmail){
                                                QiscusChatVC.sharedInstance.stopTypingIndicator()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        break
                    case "d":
                        let message = String(data: data, encoding: .utf8)!
                        let messageArr = message.characters.split(separator: ":")
                        let commentId = Int64(String(messageArr[0]))!
                        let commentUniqueId:String = String(messageArr[1])
                        let userEmail = String(channelArr[3])
                        if let comment = QiscusComment.getComment(withId: commentId){
                            comment.updateCommentStatus(.delivered, email: userEmail)
                        }else if let comment = QiscusComment.getComment(withUniqueId: commentUniqueId){
                            comment.updateCommentStatus(.delivered, email: userEmail)
                        }
                        break
                    case "r":
                        let message = String(data: data, encoding: .utf8)!
                        let messageArr = message.characters.split(separator: ":")
                        let commentId = Int64(String(messageArr[0]))!
                        let commentUniqueId:String = String(messageArr[1])
                        let userEmail = String(channelArr[3])
                        if let comment = QiscusComment.getComment(withId: commentId){
                            comment.updateCommentStatus(.read, email: userEmail)
                        }else if let comment = QiscusComment.getComment(withUniqueId: commentUniqueId){
                            comment.updateCommentStatus(.read, email: userEmail)
                        }
                        break
                    case "s":
                        let message = String(data: data, encoding: .utf8)!
                        let messageArr = message.characters.split(separator: ":")
                        let online = Int(String(messageArr[0]))
                        let userEmail = String(channelArr[1])
                        if online == 1 {
                            if userEmail != QiscusMe.sharedInstance.email{
                                if let user = QiscusUser.getUserWithEmail(userEmail){
                                    if let timeToken = Double(String(messageArr[1])){
                                        user.updateStatus(isOnline: true)
                                        user.updateLastSeen(Double(timeToken)/1000)
                                    }
                                }
                            }
                        }else{
                            if userEmail != QiscusMe.sharedInstance.email{
                                if let user = QiscusUser.getUserWithEmail(userEmail){
                                    if let timeToken = Double(String(messageArr[1])){
                                        user.updateLastSeen(Double(timeToken)/1000)
                                        user.updateStatus(isOnline: false)
                                    }
                                }
                            }
                        }
                        break
                    default:
                        Qiscus.printLog(text: "Realtime socket receive message in unknown topic: \(topic)")
                        break
                    }
                }
            }
        }
    }
    public func mqttDidDisconnect(session: MQTTSession){
        Qiscus.printLog(text: "Realtime server disconnected")
    }
    public func mqttSocketErrorOccurred(session: MQTTSession){
        
    }
    public class func deleteMqttChannel(channel: String) {
        Qiscus.realtimeThread.async {
            if Qiscus.sharedInstance.mqttChannel.contains(channel){
                Qiscus.sharedInstance.mqtt?.unSubscribe(from: channel, completion: {(succeeded, error) -> Void in
                    if succeeded {
                        Qiscus.sharedInstance.mqttChannel = Qiscus.sharedInstance.mqttChannel.filter() { $0 != channel }
                    }
                })
            }
        }
    }
    public class func addMqttChannel(channel: String){
        var isExist = false
        for channelName in Qiscus.sharedInstance.mqttChannel {
            if channelName == channel {
                isExist = true
            }
        }
        if !isExist{
            Qiscus.uiThread.async {
                Qiscus.sharedInstance.mqtt?.subscribe(to: channel, delivering: .atLeastOnce, completion: {(succeeded, error) -> Void in
                    if succeeded {
                        Qiscus.sharedInstance.mqttChannel.append(channel)
                    }
                })
            }
        }
    }
    func applicationDidBecomeActife(){
        if Qiscus.isLoggedIn{
            Qiscus.sharedInstance.RealtimeConnect()
        }
    }
    class func printLog(text:String){
        if Qiscus.showDebugPrint{
            Qiscus.logThread.async{
                print("[Qiscus]: \(text)")
            }
        }
    }
    class func deleteAllFiles(){
        let fileManager = FileManager.default
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let qiscusDirPath = "\(dirPath)/Qiscus"
        
        do {
            let filePaths = try fileManager.contentsOfDirectory(atPath: qiscusDirPath)
            for filePath in filePaths {
                try fileManager.removeItem(atPath: NSTemporaryDirectory() + filePath)
            }
        } catch let error as NSError {
            Qiscus.printLog(text: "Could not clear temp folder: \(error.debugDescription)")
        }
    }
    
    // MARK: - local DB
    class func checkDatabaseMigration(){
        Qiscus.dbThread.async {
            let currentSchema:UInt64 = 14
            var configuration = Realm.Configuration()
            
            configuration.schemaVersion = currentSchema
            configuration.migrationBlock = { migration, oldSchemaVersion in
                Qiscus.printLog(text: "Need migration to QiscusDB schema: \(currentSchema) \nfrom schema: \(oldSchemaVersion)")
                
                if (oldSchemaVersion < currentSchema){
                    //Deleting Realm Files
                    let realmURL = Realm.Configuration.defaultConfiguration.fileURL!
                    let realmManagement = realmURL.appendingPathExtension("management")
                    
                    let realmURLs = [
                        realmURL,
                        realmURL.appendingPathExtension("lock"),
                        realmManagement.appendingPathComponent("access_control.control.mx"),
                        realmManagement.appendingPathComponent("access_control.write.mx")
                    ]
                    
                    for URL in realmURLs {
                        do {
                            try FileManager.default.removeItem(at: URL)
                        } catch {
                            // handle error
                            Qiscus.printLog(text: "no Database files")
                        }
                    }
                    
                }
            }
            Realm.Configuration.defaultConfiguration = configuration
        }
    }
    
    // MARK: - Create NEW Chat
    @objc public class func createChatView(withUsers users:[String], readOnly:Bool = false, title:String, subtitle:String = "", distinctId:String? = nil, optionalData:String?=nil, withMessage:String? = nil)->QiscusChatVC{
        Qiscus.checkDatabaseMigration()
        if !Qiscus.sharedInstance.connected {
            Qiscus.setupReachability()
        }
        
        Qiscus.sharedInstance.isPushed = true
        QiscusUIConfiguration.sharedInstance.readOnly = readOnly
        QiscusUIConfiguration.sharedInstance.copyright.chatSubtitle = subtitle
        QiscusUIConfiguration.sharedInstance.copyright.chatTitle = title
        
        let chatVC = QiscusChatVC.sharedInstance
        chatVC.reset()
        if distinctId != nil{
            chatVC.distincId = distinctId!
        }else{
            chatVC.distincId = ""
        }
        chatVC.optionalData = optionalData
        chatVC.message = withMessage
        chatVC.newRoom = true
        chatVC.users = users
        
        if QiscusChatVC.sharedInstance.isPresence {
            QiscusChatVC.sharedInstance.goBack()
        }
        
        return chatVC
    }
    @objc public class func createChat(withUsers users:[String], target:UIViewController, readOnly:Bool = false, title:String, subtitle:String = "", distinctId:String? = nil, optionalData:String?=nil, withMessage:String? = nil){
        Qiscus.checkDatabaseMigration()
        if !Qiscus.sharedInstance.connected {
            Qiscus.setupReachability()
        }
        
        Qiscus.sharedInstance.isPushed = false
        QiscusUIConfiguration.sharedInstance.readOnly = readOnly
        QiscusUIConfiguration.sharedInstance.copyright.chatSubtitle = subtitle
        QiscusUIConfiguration.sharedInstance.copyright.chatTitle = title
        
        let chatVC = QiscusChatVC.sharedInstance
        chatVC.reset()
        if distinctId != nil{
            chatVC.distincId = distinctId!
        }else{
            chatVC.distincId = ""
        }
        chatVC.optionalData = optionalData
        chatVC.message = withMessage
        chatVC.newRoom = true
        chatVC.users = users
        
        let navController = UINavigationController()
        navController.viewControllers = [chatVC]
        
        if QiscusChatVC.sharedInstance.isPresence {
            QiscusChatVC.sharedInstance.goBack()
        }
        target.navigationController?.present(navController, animated: true, completion: nil)
    }
    
    // MARK: - Update Room Methode
    @objc public class func updateRoom(withRoomId roomId:Int, roomName:String? = nil, roomAvatarURL:String? = nil, roomAvatar:UIImage? = nil, roomOptions:String? = nil){
        Qiscus.commentService.updateRoom(withRoomId: roomId, roomName: roomName, roomAvatarURL: roomAvatarURL, roomOptions: roomOptions)
    }
    
    // MARK: - Push Notification Setup
    public func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, forType type: PKPushType) {
        if Qiscus.isLoggedIn{
            var token: String = ""
            let deviceToken = credentials.token
            for i in 0..<credentials.token.count {
                token += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
            }
            Qiscus.qiscusDeviceToken = token
            Qiscus.printLog(text: "Device token: \(token)")
            QiscusCommentClient.sharedInstance.registerDevice(withToken: token)
        }
    }
    public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, forType type: PKPushType) {
        if Qiscus.isLoggedIn{
            let payloadData = JSON(payload.dictionaryPayload)
            if let _ = payloadData["qiscus_sdk"].string {
                Qiscus.sharedInstance.checkChat()
            }
        }
    }
    public func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenForType type: PKPushType) {
        Qiscus.registerNotification()
    }
    @objc public class func registerNotification(){
        let notificationSettings = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
        Qiscus.sharedInstance.application.registerUserNotificationSettings(notificationSettings)
        Qiscus.sharedInstance.application.registerForRemoteNotifications()
    }
    @objc public class func didRegisterUserNotification(withToken token: Data){
        if Qiscus.isLoggedIn{
            var tokenString: String = ""
            for i in 0..<token.count {
                tokenString += String(format: "%02.2hhx", token[i] as CVarArg)
            }
            Qiscus.qiscusDeviceToken = tokenString
            Qiscus.printLog(text: "Device token: \(tokenString)")
            QiscusCommentClient.sharedInstance.registerDevice(withToken: tokenString)
        }
    }
    @objc public class func didRegisterUserNotification(){
        if Qiscus.isLoggedIn{
            let voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
            voipRegistry.desiredPushTypes = Set([PKPushType.voIP])
            voipRegistry.delegate = Qiscus.sharedInstance
        }
    }
    @objc public class func didReceive(RemoteNotification userInfo:[AnyHashable : Any]){
        if Qiscus.isLoggedIn{
            if userInfo["qiscus_sdk"] != nil{
                Qiscus.sharedInstance.checkChat()
            }
        }
    }
    @objc public class func didReceive(LocalNotification notification:UILocalNotification){
        if let userInfo = notification.userInfo {
            if let roomData = userInfo["qiscus-room-id"]{
                let roomId = roomData as! Int
                UIApplication.shared.cancelAllLocalNotifications()
                if let window = UIApplication.shared.keyWindow{
                    if Qiscus.sharedInstance.notificationAction != nil{
                        let chatVC = Qiscus.chatView(withRoomId: roomId, title: "")
                        Qiscus.sharedInstance.notificationAction!(chatVC)
                    }else{
                        if let currenRootView = window.rootViewController as? UINavigationController{
                            if QiscusChatVC.sharedInstance.isPresence{
                                QiscusChatVC.sharedInstance.goBack()
                            }
                            
                            let viewController = currenRootView.viewControllers[currenRootView.viewControllers.count - 1]
                            if Qiscus.sharedInstance.isPushed{
                                let chatVC = Qiscus.chatView(withRoomId: roomId, title: "")
                                currenRootView.pushViewController(chatVC, animated: true)
                            }else{
                                Qiscus.chat(withRoomId: roomId, target: viewController)
                            }
                        }
                        else if let currentRootView = window.rootViewController as? UITabBarController{
                            if let navigation = currentRootView.selectedViewController as? UINavigationController{
                                if QiscusChatVC.sharedInstance.isPresence{
                                    QiscusChatVC.sharedInstance.goBack()
                                }
                                let viewController = navigation.viewControllers[navigation.viewControllers.count - 1]
                                if Qiscus.sharedInstance.isPushed{
                                    let chatVC = Qiscus.chatView(withRoomId: roomId, title: "")
                                    navigation.pushViewController(chatVC, animated: true)
                                }else{
                                    Qiscus.chat(withRoomId: roomId, target: viewController)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    class func mqttConnect(chatOnly:Bool = false){
        let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        var deviceID = "000"
        if let vendorIdentifier = UIDevice.current.identifierForVendor {
            deviceID = vendorIdentifier.uuidString
        }
        let clientID = "iosMQTT-\(appName)-\(deviceID)-\(QiscusMe.sharedInstance.id)"

        let mqtt = MQTTSession(host: "mqtt.qiscus.com", port: 1885, clientID: clientID, cleanSession: false, keepAlive: 60, useSSL: true)
        
        let message: String = "0";
        let data: Data = message.data(using: .utf8)!
        let channel = "u/\(QiscusMe.sharedInstance.email)/s"
        
        let lastWillMessage = MQTTPubMsg(topic: channel, payload: data, retain: true, QoS: .atLeastOnce)
        
        mqtt.lastWillMessage = lastWillMessage
        mqtt.delegate = Qiscus.shared
        
        mqtt.connect(completion: { (succeeded, error) -> Void in
            if succeeded {
                Qiscus.realtimeThread.async {
                    Qiscus.printLog(text: "Realtime socket connected")
                    let commentChannel = "\(QiscusMe.sharedInstance.token)/c"
                    
                    var channels = [String: MQTTQoS]()
                    channels[commentChannel] = MQTTQoS.atLeastOnce
                    if !chatOnly {
                        let rooms = QiscusRoom.getAllRoom()
                        for room in rooms{
                            let deliveryChannel = "r/\(room.roomId)/\(room.roomLastCommentTopicId)/+/d"
                            let readChannel = "r/\(room.roomId)/\(room.roomLastCommentTopicId)/+/r"
                            channels[deliveryChannel] = MQTTQoS.atLeastOnce
                            channels[readChannel] = MQTTQoS.atLeastOnce
                        }
                        if let allUser = QiscusUser.getAllUser() {
                            for user in allUser{
                                if !user.isSelf{
                                    let userChannel = "u/\(user.userEmail)/s"
                                    channels[userChannel] = MQTTQoS.atLeastOnce
                                }
                            }
                        }
                    }
                    mqtt.subscribe(to: channels, completion: { (succeeded, error) -> Void in
                        if succeeded {
                            Qiscus.printLog(text: "successfully subscribe to channel: \(channels)")
                            if !chatOnly{
                                Qiscus.shared.mqttChannel = [String]()
                                for (channel,_) in channels{
                                    Qiscus.shared.mqttChannel.append(channel)
                                }
                                Qiscus.shared.mqtt = mqtt
                                Qiscus.shared.mqtt?.delegate = Qiscus.shared
                            }
                        }else{
                            Qiscus.printLog(text: "fail subscribe to channel: \(channels) with error: \(error)")
                        }
                    })
                    
                    Qiscus.publishUserStatus()
                }
            }else{
                Qiscus.printLog(text: "Realtime socket connect error: \(error)")
            }
        })
    }
    class func publishUserStatus(offline:Bool = false){
        if Qiscus.isLoggedIn{
            Qiscus.realtimeThread.async {
                var message: String = "1";
                
                let channel = "u/\(QiscusMe.sharedInstance.email)/s"
                if offline {
                    message = "0"
                    let data: Data = message.data(using: .utf8)!
                    Qiscus.uiThread.async {
                        Qiscus.sharedInstance.mqtt?.publish(data, in: channel, delivering: .atLeastOnce, retain: true, completion: { (success, error) in
                            if success {
                                Qiscus.disconnectRealtime()
                            }else{
                                Qiscus.printLog(text: "fail to publish message on channel:\(channel) with message:\(message)")
                            }
                        })
                    }
                }else{
                    if Qiscus.sharedInstance.application.applicationState == UIApplicationState.active {
                        let data: Data = message.data(using: .utf8)!
                        Qiscus.uiThread.async {
                            Qiscus.sharedInstance.mqtt?.publish(data, in: channel, delivering: .atLeastOnce, retain: true, completion: nil)
                        }
                        
                        let when = DispatchTime.now() + 30
                        Qiscus.realtimeThread.asyncAfter(deadline: when) {
                            Qiscus.publishUserStatus()
                        }
                    }
                }
            }
        }
    }
    func goToBackgroundMode(){
        Qiscus.publishUserStatus(offline: true)
    }
    @objc public class func setNotificationAction(onClick action:@escaping ((QiscusChatVC)->Void)){
        Qiscus.sharedInstance.notificationAction = action
    }
    
    // MARK: - register PushNotification
    @objc public class func registerDevice(withToken deviceToken: String){
        QiscusCommentClient.sharedInstance.registerDevice(withToken: deviceToken)
    }
}
