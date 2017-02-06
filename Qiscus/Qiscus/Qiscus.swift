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

open class Qiscus: NSObject, MQTTSessionDelegate, PKPushRegistryDelegate {

    open static let sharedInstance = Qiscus()
    
    open var config = QiscusConfig.sharedInstance
    open var commentService = QiscusCommentClient.sharedInstance
    open var styleConfiguration = QiscusUIConfiguration.sharedInstance
    
    let application = UIApplication.shared
    let appDelegate = UIApplication.shared.delegate
    
    open var isPushed:Bool = false
    open var iCloudUpload:Bool = false
    
    open var httpRealTime:Bool = false
    
    open var reachability:QReachability?
    open var connected:Bool = false
    open var mqtt:MQTTSession?
    open var mqttChannel = [String]()
    
    open var toastMessageAct:((_ roomId:Int, _ comment:QiscusComment)->Void)?
    
    static var realtimeThread = DispatchQueue(label: "qiscusRealtime")
    static var logThread = DispatchQueue(label: "qiscusLog", attributes: .concurrent)
    
    @objc open class var isLoggedIn:Bool{
        get{
            Qiscus.checkDatabaseMigration()
            if !Qiscus.sharedInstance.connected {
                Qiscus.setupReachability()
            }
            return QiscusMe.isLoggedIn
        }
    }
    
    @objc open class var style:QiscusUIConfiguration{
        get{
            return Qiscus.sharedInstance.styleConfiguration
        }
    }
    
    @objc open class var commentService:QiscusCommentClient{
        get{
            return QiscusCommentClient.sharedInstance
        }
    }
    
    fileprivate override init(){
        
    }
    
    @objc open class var bundle:Bundle{
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
    @objc open class func disableInAppNotif(){
        Qiscus.sharedInstance.config.showToasterMessage = false
    }
    /**
     Class function to enable notification when **In App**
     */
    @objc open class func enableInAppNotif(){
        Qiscus.sharedInstance.config.showToasterMessage = true
    }
    
    @objc open class func clear(){
        QiscusMe.clear()
        let realm = try! Realm()
        try! realm.write {
            realm.deleteAll()
        }
        Qiscus.deleteAllFiles()
        Qiscus.sharedInstance.mqtt?.disconnect()
    }
    
    // need Documentation
    open func RealtimeConnect(){
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidBecomeActive, object: nil)
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(Qiscus.applicationDidBecomeActife), name: .UIApplicationDidBecomeActive, object: nil)
        Qiscus.realtimeThread.sync {
            let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
            var deviceID = "000"
            if let vendorIdentifier = UIDevice.current.identifierForVendor {
                 deviceID = vendorIdentifier.uuidString
            }
            let clientID = "iosMQTT-\(appName)-\(deviceID)-\(QiscusMe.sharedInstance.id)"
            Qiscus.printLog(text: "Realtime client id: \(clientID)")
            Qiscus.sharedInstance.mqtt = MQTTSession(host: "mqtt.qiscus.com", port: 1885, clientID: clientID, cleanSession: false, keepAlive: 60, useSSL: true)
            Qiscus.sharedInstance.mqtt?.delegate = Qiscus.sharedInstance
            Qiscus.sharedInstance.mqtt?.connect(completion: { (succeeded, error) -> Void in
                if succeeded {
                    Qiscus.printLog(text: "Realtime socket connected")
                }else{
                    Qiscus.printLog(text: "Realtime socket connect error: \(error)")
                }
            })
            if !Qiscus.sharedInstance.mqttChannel.contains("\(QiscusMe.sharedInstance.token)/c"){
                Qiscus.sharedInstance.mqttChannel.append("\(QiscusMe.sharedInstance.token)/c")
            }
            var channels = [String: MQTTQoS]()
            for channel in Qiscus.sharedInstance.mqttChannel{
                channels[channel] = MQTTQoS.atLeastOnce
            }
            Qiscus.sharedInstance.mqtt?.subscribe(to: channels, completion: {(succeeded, error) -> Void in
                if succeeded {
                    Qiscus.printLog(text: "Realtime chat comment subscribed")
                }
            })
        }
        
        DispatchQueue.main.async {
            let rooms = QiscusRoom.getAllRoom()
            for room in rooms{
                let deliveryChannel = "r/\(room.roomId)/\(room.roomLastCommentTopicId)/+/d"
                let readChannel = "r/\(room.roomId)/\(room.roomLastCommentTopicId)/+/r"
                Qiscus.realtimeThread.sync {
                    Qiscus.addMqttChannel(channel: deliveryChannel)
                    Qiscus.addMqttChannel(channel: readChannel)
                }
            }
        }
    }
    @objc open class func setup(withAppId appId:String, userEmail:String, userKey:String, username:String, avatarURL:String? = nil, delegate:QiscusConfigDelegate? = nil, secureURl:Bool = true){
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
                QiscusCommentClient.sharedInstance.configDelegate!.qiscusConnected()
            }
        }
    }
    @objc open class func setup(withURL baseUrl:String, userEmail:String, id:Int, username:String, userKey:String, delegate:QiscusConfigDelegate? = nil, secureURl:Bool = true, realTimeKey:String){
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
            QiscusCommentClient.sharedInstance.configDelegate!.qiscusConnected()
        }
    }
    
    
    /**
     Class function to configure chat with user
     - parameter users: **String** users.
     - parameter readOnly: **Bool** to set read only or not (Optional), Default value : false.
     - parameter title: **String** text to show as chat title (Optional), Default value : "".
     - parameter subtitle: **String** text to show as chat subtitle (Optional), Default value : "" (empty string).
     */
    open class func chatVC(withUsers users:[String], readOnly:Bool = false, title:String = "", subtitle:String = "", distinctId:String? = nil, optionalData:String?=nil, withMessage:String? = nil)->QiscusChatVC{
        Qiscus.checkDatabaseMigration()
        if !Qiscus.sharedInstance.connected {
            Qiscus.setupReachability()
        }
        
        Qiscus.sharedInstance.isPushed = true
        QiscusUIConfiguration.sharedInstance.chatUsers = users
        QiscusUIConfiguration.sharedInstance.topicId = 0
        QiscusUIConfiguration.sharedInstance.readOnly = readOnly
        QiscusUIConfiguration.sharedInstance.copyright.chatSubtitle = subtitle
        QiscusUIConfiguration.sharedInstance.copyright.chatTitle = title
        
        let chatVC = QiscusChatVC.sharedInstance
        if distinctId != nil{
            chatVC.distincId = distinctId!
        }else{
            chatVC.distincId = ""
        }
        chatVC.optionalData = optionalData
        chatVC.message = withMessage
        chatVC.newChat = false
        
        if QiscusChatVC.sharedInstance.isPresence {
            QiscusChatVC.sharedInstance.goBack()
        }
        
        return chatVC
    }
    
    /**
     No Documentation
    */
    
    @objc open class func chat(withRoomId roomId:Int, target:UIViewController, readOnly:Bool = false, title:String = "", subtitle:String = "", distinctId:String? = nil, withMessage:String? = nil, optionalData:String?=nil){
        Qiscus.checkDatabaseMigration()
        if !Qiscus.sharedInstance.connected {
            Qiscus.setupReachability()
        }
        
        Qiscus.sharedInstance.isPushed = false
        QiscusUIConfiguration.sharedInstance.chatUsers = [String]()
        QiscusUIConfiguration.sharedInstance.topicId = 0
        QiscusUIConfiguration.sharedInstance.readOnly = readOnly
        QiscusUIConfiguration.sharedInstance.copyright.chatSubtitle = subtitle
        QiscusUIConfiguration.sharedInstance.copyright.chatTitle = title
        
        
        let chatVC = QiscusChatVC.sharedInstance
        if distinctId != nil{
            chatVC.distincId = distinctId!
        }else{
            chatVC.distincId = ""
        }
        chatVC.roomId = roomId
        chatVC.optionalData = optionalData
        chatVC.message = withMessage
        chatVC.newChat = false
        let navController = UINavigationController()
        navController.viewControllers = [chatVC]
        
        if QiscusChatVC.sharedInstance.isPresence {
            QiscusChatVC.sharedInstance.goBack()
        }
        
        target.navigationController?.present(navController, animated: true, completion: nil)
    }
    @objc open class func chat(withUsers users:[String], target:UIViewController, readOnly:Bool = false, title:String = "", subtitle:String = "", distinctId:String? = nil, withMessage:String? = nil, optionalData:String?=nil){
        Qiscus.checkDatabaseMigration()
        if !Qiscus.sharedInstance.connected {
            Qiscus.setupReachability()
        }
        
        Qiscus.sharedInstance.isPushed = false
        QiscusUIConfiguration.sharedInstance.chatUsers = users
        QiscusUIConfiguration.sharedInstance.topicId = 0
        QiscusUIConfiguration.sharedInstance.readOnly = readOnly
        QiscusUIConfiguration.sharedInstance.copyright.chatSubtitle = subtitle
        QiscusUIConfiguration.sharedInstance.copyright.chatTitle = title
        
        
        let chatVC = QiscusChatVC.sharedInstance
        if distinctId != nil{
            chatVC.distincId = distinctId!
        }else{
            chatVC.distincId = ""
        }
        chatVC.optionalData = optionalData
        chatVC.message = withMessage
        chatVC.newChat = false
        let navController = UINavigationController()
        navController.viewControllers = [chatVC]
        
        if QiscusChatVC.sharedInstance.isPresence {
            QiscusChatVC.sharedInstance.goBack()
        }
        
        target.navigationController?.present(navController, animated: true, completion: nil)
    }
    /** 
     No Documentation
    */
    @objc open class func chatView(withUsers users:[String], readOnly:Bool = false, title:String = "", subtitle:String = "", withMessage:String? = nil)->QiscusChatVC{
        Qiscus.checkDatabaseMigration()
        if !Qiscus.sharedInstance.connected {
            Qiscus.setupReachability()
        }
        Qiscus.sharedInstance.isPushed = true
        QiscusUIConfiguration.sharedInstance.chatUsers = users
        QiscusUIConfiguration.sharedInstance.topicId = 0
        QiscusUIConfiguration.sharedInstance.readOnly = readOnly
        QiscusUIConfiguration.sharedInstance.copyright.chatSubtitle = subtitle
        QiscusUIConfiguration.sharedInstance.copyright.chatTitle = title
        
        let chatVC = QiscusChatVC.sharedInstance
        chatVC.message = withMessage
        chatVC.newChat = false
        
        if QiscusChatVC.sharedInstance.isPresence {
            QiscusChatVC.sharedInstance.goBack()
        }
        
        return QiscusChatVC.sharedInstance
    }
    /**
     No Documentation
     */
    @objc open class func chatView(withRoomId roomId:Int, readOnly:Bool = false, title:String = "", subtitle:String = "", withMessage:String? = nil)->QiscusChatVC{
        Qiscus.checkDatabaseMigration()
        if !Qiscus.sharedInstance.connected {
            Qiscus.setupReachability()
        }
        Qiscus.sharedInstance.isPushed = true
        QiscusUIConfiguration.sharedInstance.chatUsers = [String]()
        QiscusUIConfiguration.sharedInstance.topicId = 0
        QiscusUIConfiguration.sharedInstance.readOnly = readOnly
        QiscusUIConfiguration.sharedInstance.copyright.chatSubtitle = subtitle
        QiscusUIConfiguration.sharedInstance.copyright.chatTitle = title
        
        let chatVC = QiscusChatVC.sharedInstance
        chatVC.roomId = roomId
        chatVC.message = withMessage
        chatVC.newChat = false
       
        if QiscusChatVC.sharedInstance.isPresence {
            QiscusChatVC.sharedInstance.goBack()
        }
        
        return QiscusChatVC.sharedInstance
    }
    @objc open class func image(named name:String)->UIImage?{
        return UIImage(named: name, in: Qiscus.bundle, compatibleWith: nil)?.localizedImage()
    }
    /**
     Class function to unlock action chat
     - parameter action: **()->Void** as unlock action for your chat
     */
    @objc open class func unlockAction(_ action:@escaping (()->Void)){
        QiscusChatVC.sharedInstance.unlockAction = action
    }
    /**
     Class function to show alert in chat with UIAlertController
     - parameter alert: The **UIAlertController** to show alert message in chat
     */
    @objc open class func showChatAlert(alertController alert:UIAlertController){
        QiscusChatVC.sharedInstance.showAlert(alert: alert)
    }
    /**
     Class function to unlock chat
     */
    @objc open class func unlockChat(){
        QiscusChatVC.sharedInstance.unlockChat()
    }
    /**
     Class function to lock chat
     */
    @objc open class func lockChat(){
        QiscusChatVC.sharedInstance.lockChat()
    }
    /**
     Class function to show loading message
     - parameter text: **String** text to show as loading text (Optional), Default value : "Loading ...".
     */
    @objc open class func showLoading(_ text: String = "Loading ..."){
        QiscusChatVC.sharedInstance.showLoading(text)
    }
    /**
     Class function to hide loading 
     */
    @objc open class func dismissLoading(){
        QiscusChatVC.sharedInstance.dismissLoading()
    }
    /**
     Class function to set color chat navigation with gradient
     - parameter topColor: The **UIColor** as your top gradient navigation color.
     - parameter bottomColor: The **UIColor** as your bottom gradient navigation color.
     - parameter tintColor: The **UIColor** as your tint gradient navigation color.
     */
    @objc open class func setGradientChatNavigation(_ topColor:UIColor, bottomColor:UIColor, tintColor:UIColor){
        QiscusChatVC.sharedInstance.setGradientChatNavigation(withTopColor: topColor, bottomColor: bottomColor, tintColor: tintColor)
        QPopUpView.sharedInstance.topColor = topColor
        QPopUpView.sharedInstance.bottomColor = bottomColor
    }
    /**
     Class function to set color chat navigation without gradient
     - parameter color: The **UIColor** as your navigation color.
     - parameter tintColor: The **UIColor** as your tint navigation color.
     */
    @objc open class func setNavigationColor(_ color:UIColor, tintColor: UIColor){
        QiscusChatVC.sharedInstance.setNavigationColor(color, tintColor: tintColor)
    }
    /**
     Class function to set upload from iCloud active or not
     - parameter active: **Bool** to set active or not.
     */
    @objc open class func iCloudUploadActive(_ active:Bool){
        Qiscus.sharedInstance.iCloudUpload = active
        //QiscusChatVC.sharedInstance.documentButton.hidden = !active
    }
    @objc open class func setHttpRealTime(_ rt:Bool = true){
        Qiscus.sharedInstance.httpRealTime = rt
    }
    
    @objc open class func setupReachability(){
        Qiscus.sharedInstance.reachability = QReachability()
        
        if let reachable = Qiscus.sharedInstance.reachability {
            if reachable.isReachable {
                Qiscus.sharedInstance.connected = true
                Qiscus.sharedInstance.RealtimeConnect()
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

                Qiscus.sharedInstance.RealtimeConnect()
                if QiscusChatVC.sharedInstance.isPresence {
                    Qiscus.printLog(text: "try to sync after connected")
                    QiscusChatVC.sharedInstance.syncData()
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
        if Qiscus.isLoggedIn{
            let channelArr = topic.characters.split(separator: "/")
            let lastChannelPart = String(channelArr.last!)
            Qiscus.printLog(text: "Realtime socket receive message in topic: \(topic)")
            switch lastChannelPart {
            case "c":
                let json = JSON(data: data)
                let notifTopicId = QiscusComment.getCommentTopicIdFromJSON(json)
                let commentBeforeId = QiscusComment.getCommentBeforeIdFromJSON(json)
                let commentId = QiscusComment.getCommentIdFromJSON(json)
                let qiscusService = QiscusCommentClient.sharedInstance
                let senderAvatarURL = json["user_avatar"].stringValue
                let senderName = json["username"].stringValue
                let isSaved = QiscusComment.getComment(fromRealtimeJSON: json)
                
                let roomId = json["room_id"].intValue
                let roomName = json["room_name"].stringValue
                let isPushed = Qiscus.sharedInstance.isPushed
                
                QiscusCommentClient.sharedInstance.publishMessageStatus(onComment: commentId, roomId: roomId, status: .delivered, withCompletion: {
                    if let thisComment = QiscusComment.getCommentById(commentId) {
                        thisComment.updateCommentStatus(.sent)
                        thisComment.updateCommentStatus(.read, email: thisComment.commentSenderEmail)
                    }
                })
                
                if isSaved{
                    let newMessage = QiscusComment.getCommentById(commentId)
                    if !QiscusComment.isValidCommentIdExist(commentBeforeId) {
                        qiscusService.syncMessage(notifTopicId)
                    }else{
                        newMessage?.updateCommentIsSync(true)
                    }
                    if qiscusService.commentDelegate != nil{
                        qiscusService.commentDelegate?.gotNewComment([newMessage!])
                    }
                    if qiscusService.roomDelegate != nil{
                        qiscusService.roomDelegate?.gotNewComment(newMessage!)
                    }
                    var showToast = true
                    let state = UIApplication.shared.applicationState
                    
                    if QiscusChatVC.sharedInstance.isPresence && QiscusChatVC.sharedInstance.topicId == notifTopicId  && state == .active{
                        showToast = false
                        if QiscusChatVC.sharedInstance.topicId != notifTopicId{
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
                                                Qiscus.chat(withRoomId: roomId, target: viewController)
                                            }
                                        }else{
                                            Qiscus.sharedInstance.toastMessageAct!(roomId, newMessage!)
                                        }
                                        
                                    }
                                    )
                                }
                            }
                        }
                    }else{
                        if !newMessage!.isOwnMessage{
                            if #available(iOS 10.0, *) {
                                let content = UNMutableNotificationContent()
                                content.title = roomName
                                content.body = "\(senderName): \(notificationMessage)"
                                content.sound = UNNotificationSound.default()
                                
                                let request = UNNotificationRequest.init(identifier: "QiscusComment-\(newMessage?.commentId)", content: content, trigger: nil)
                                let center = UNUserNotificationCenter.current()
                                center.add(request, withCompletionHandler: { (error) in
                                    if error == nil {
                                        if let window = UIApplication.shared.keyWindow{
                                            if let currenRootView = window.rootViewController as? UINavigationController{
                                                let viewController = currenRootView.viewControllers[currenRootView.viewControllers.count - 1]
                                                if Qiscus.sharedInstance.isPushed{
                                                    let chatVC = Qiscus.chatView(withRoomId: roomId, title: "")
                                                    currenRootView.pushViewController(chatVC, animated: true)
                                                }else{
                                                    Qiscus.chat(withRoomId: roomId, target: viewController)
                                                }
                                            }
                                        }
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
                let topicId:Int = Int(String(channelArr[2]))!
                let userEmail:String = String(channelArr[3])
                let message = String(data: data, encoding: .utf8)!
                if userEmail != QiscusMe.sharedInstance.email {
                    if QiscusChatVC.sharedInstance.isPresence && QiscusChatVC.sharedInstance.topicId == topicId {
                        switch message {
                        case "1":
                            if let user = QiscusUser.getUserWithEmail(userEmail) {
                                let userFullName = user.userFullName
                                if !QiscusChatVC.sharedInstance.isTypingOn || (QiscusChatVC.sharedInstance.typingIndicatorUser != userFullName){
                                    QiscusChatVC.sharedInstance.startTypingIndicator(withUser: user.userFullName)
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
                break
            case "d":
                let message = String(data: data, encoding: .utf8)!
                let messageArr = message.characters.split(separator: ":")
                let commentId = Int64(String(messageArr[0]))!
                let commentUniqueId:String = String(messageArr[1])
                let userEmail = String(channelArr[3])
                if let comment = QiscusComment.getCommentById(commentId){
                    comment.updateCommentStatus(.delivered, email: userEmail)
                }else if let comment = QiscusComment.getCommentByUniqueId(commentUniqueId){
                    comment.updateCommentStatus(.delivered, email: userEmail)
                }
                break
            case "r":
                let message = String(data: data, encoding: .utf8)!
                let messageArr = message.characters.split(separator: ":")
                let commentId = Int64(String(messageArr[0]))!
                let commentUniqueId:String = String(messageArr[1])
                let userEmail = String(channelArr[3])
                if let comment = QiscusComment.getCommentById(commentId){
                    comment.updateCommentStatus(.read, email: userEmail)
                }else if let comment = QiscusComment.getCommentByUniqueId(commentUniqueId){
                    comment.updateCommentStatus(.read, email: userEmail)
                }
                break
            default:
                Qiscus.printLog(text: "Realtime socket receive message in unknown topic: \(topic)")
                break
            }
        }
    }
    public func mqttDidDisconnect(session: MQTTSession){
        Qiscus.printLog(text: "Realtime server disconnected")
    }
    public func mqttSocketErrorOccurred(session: MQTTSession){
    
    }
    public class func deleteMqttChannel(channel: String) {
        Qiscus.realtimeThread.sync {
            if Qiscus.sharedInstance.mqttChannel.contains(channel){
                Qiscus.sharedInstance.mqtt?.unSubscribe(from: channel, completion: {(succeeded, error) -> Void in
                    if succeeded {
                        Qiscus.sharedInstance.mqttChannel = Qiscus.sharedInstance.mqttChannel.filter() { $0 != channel }
                        Qiscus.printLog(text: "Realtime channel \(channel) unsubscribed")
                    }
                })
            }
        }
    }
    public class func addMqttChannel(channel: String){
        //Qiscus.realtimeThread.sync {
            var isExist = false
            for channelName in Qiscus.sharedInstance.mqttChannel {
                if channelName == channel {
                    isExist = true
                }
            }
            if !isExist{
                Qiscus.sharedInstance.mqtt?.subscribe(to: channel, delivering: .atLeastOnce, completion: {(succeeded, error) -> Void in
                    if succeeded {
                        Qiscus.sharedInstance.mqttChannel.append(channel)
                        Qiscus.printLog(text: "Realtime channel \(channel) subscribed")
                    }
                })
            }
        //}
        
    }
    func applicationDidBecomeActife(){
        Qiscus.sharedInstance.RealtimeConnect()
    }
    class func printLog(text:String){
        Qiscus.logThread.async{
            print("[Qiscus]: \(text)")
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
    
    class func checkDatabaseMigration(){
        let currentSchema:UInt64 = 7
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
                        print("no realm files")
                    }
                }
                
            }
        }
        Realm.Configuration.defaultConfiguration = configuration
    }
    
    // MARK: - Create NEW Chat
    @objc open class func createChatView(withUsers users:[String], readOnly:Bool = false, title:String, subtitle:String = "", distinctId:String? = nil, optionalData:String?=nil, withMessage:String? = nil)->QiscusChatVC{
        Qiscus.checkDatabaseMigration()
        if !Qiscus.sharedInstance.connected {
            Qiscus.setupReachability()
        }
        
        Qiscus.sharedInstance.isPushed = true
        QiscusUIConfiguration.sharedInstance.chatUsers = users
        QiscusUIConfiguration.sharedInstance.topicId = 0
        QiscusUIConfiguration.sharedInstance.readOnly = readOnly
        QiscusUIConfiguration.sharedInstance.copyright.chatSubtitle = subtitle
        QiscusUIConfiguration.sharedInstance.copyright.chatTitle = title
        
        let chatVC = QiscusChatVC.sharedInstance
        if distinctId != nil{
            chatVC.distincId = distinctId!
        }else{
            chatVC.distincId = ""
        }
        chatVC.optionalData = optionalData
        chatVC.message = withMessage
        chatVC.newChat = true

        if QiscusChatVC.sharedInstance.isPresence {
            QiscusChatVC.sharedInstance.goBack()
        }
        
        return chatVC
    }
    @objc open class func createChat(withUsers users:[String], target:UIViewController, readOnly:Bool = false, title:String, subtitle:String = "", distinctId:String? = nil, optionalData:String?=nil, withMessage:String? = nil){
        Qiscus.checkDatabaseMigration()
        if !Qiscus.sharedInstance.connected {
            Qiscus.setupReachability()
        }
        
        Qiscus.sharedInstance.isPushed = false
        QiscusUIConfiguration.sharedInstance.chatUsers = users
        QiscusUIConfiguration.sharedInstance.topicId = 0
        QiscusUIConfiguration.sharedInstance.readOnly = readOnly
        QiscusUIConfiguration.sharedInstance.copyright.chatSubtitle = subtitle
        QiscusUIConfiguration.sharedInstance.copyright.chatTitle = title
        
        let chatVC = QiscusChatVC.sharedInstance
        if distinctId != nil{
            chatVC.distincId = distinctId!
        }else{
            chatVC.distincId = ""
        }
        chatVC.optionalData = optionalData
        chatVC.message = withMessage
        chatVC.newChat = true
        let navController = UINavigationController()
        navController.viewControllers = [chatVC]
        
        if QiscusChatVC.sharedInstance.isPresence {
            QiscusChatVC.sharedInstance.goBack()
        }
        target.navigationController?.present(navController, animated: true, completion: nil)
    }
    
    // MARK: - Update Room Methode
    @objc open class func updateRoom(withRoomId roomId:Int, roomName:String? = nil, roomAvatarURL:String? = nil, roomOptions:String? = nil){
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
            QiscusCommentClient.sharedInstance.registerDevice(withToken: token)
        }
    }
    public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, forType type: PKPushType) {
        print("got pushNotification with payload: \(JSON(payload.dictionaryPayload)) ")
        if Qiscus.isLoggedIn{
            let payloadData = JSON(payload.dictionaryPayload)
            if let pnData = payloadData["qiscus_sdk"].string {
                print("pn data: \(pnData)")
                Qiscus.sharedInstance.RealtimeConnect()
            }
        }
    }
    public func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenForType type: PKPushType) {
        print("token invalidated")
        Qiscus.registerNotification()
    }
    open class func registerNotification(){
        let notificationSettings = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
        Qiscus.sharedInstance.application.registerUserNotificationSettings(notificationSettings)
        Qiscus.sharedInstance.application.registerForRemoteNotifications()
    }
    open class func didRegisterUserNotification(){
        if Qiscus.isLoggedIn{
            let voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
            voipRegistry.desiredPushTypes = Set([PKPushType.voIP])
            voipRegistry.delegate = Qiscus.sharedInstance
        }
    }
}
