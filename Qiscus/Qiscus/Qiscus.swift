//
//  Qiscus.swift
//  qonsultant
//
//  Created by Ahmad Athaullah on 7/17/16.
//  Copyright © 2016 qiscus. All rights reserved.
//

import UIKit
import RealmSwift
import Foundation
import SwiftMQTT
import SwiftyJSON

open class Qiscus: NSObject, MQTTSessionDelegate {

    open static let sharedInstance = Qiscus()
    
    open var config = QiscusConfig.sharedInstance
    open var commentService = QiscusCommentClient.sharedInstance
    open var styleConfiguration = QiscusUIConfiguration.sharedInstance
    
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
    
    open class var isLoggedIn:Bool{
        get{
            Qiscus.checkDatabaseMigration()
            if !Qiscus.sharedInstance.connected {
                Qiscus.setupReachability()
            }
            return QiscusMe.isLoggedIn
        }
    }
    
    open class var style:QiscusUIConfiguration{
        get{
            return Qiscus.sharedInstance.styleConfiguration
        }
    }
    
    open class var commentService:QiscusCommentClient{
        get{
            return QiscusCommentClient.sharedInstance
        }
    }
    
    fileprivate override init(){
        
    }
    
    open class var bundle:Bundle{
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
    open class func disableInAppNotif(){
        Qiscus.sharedInstance.config.showToasterMessage = false
    }
    /**
     Class function to enable notification when **In App**
     */
    open class func enableInAppNotif(){
        Qiscus.sharedInstance.config.showToasterMessage = true
    }
    
    open class func clear(){
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
    open class func setup(withAppId appId:String, userEmail:String, userKey:String, username:String, avatarURL:String? = nil, delegate:QiscusConfigDelegate? = nil, secureURl:Bool = true){
        Qiscus.checkDatabaseMigration()
        var requestProtocol = "https"
        if !secureURl {
            requestProtocol = "http"
        }
        let email = userEmail.lowercased()
        //QiscusConfig.sharedInstance.BASE_URL = "\(requestProtocol)://\(appId).qiscus.com/api/v2/mobile"
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
    open class func setup(withURL baseUrl:String, userEmail:String, id:Int, username:String, userKey:String, delegate:QiscusConfigDelegate? = nil, secureURl:Bool = true, realTimeKey:String){
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
     - parameter target: The **UIViewController** where chat will appear.
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
        chatVC.optionalDataCompletion = {_ in }
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
    
    open class func chat(withRoomId roomId:Int, target:UIViewController, readOnly:Bool = false, title:String = "", subtitle:String = "", distinctId:String? = nil, withMessage:String? = nil, optionalData:String?=nil,optionalDataCompletion: @escaping (String) -> Void){
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
        chatVC.optionalDataCompletion = optionalDataCompletion
        chatVC.message = withMessage
        chatVC.newChat = false
        let navController = UINavigationController()
        navController.viewControllers = [chatVC]
        
        if QiscusChatVC.sharedInstance.isPresence {
            QiscusChatVC.sharedInstance.goBack()
        }
        
        target.navigationController?.present(navController, animated: true, completion: nil)
    }
    open class func chat(withUsers users:[String], target:UIViewController, readOnly:Bool = false, title:String = "", subtitle:String = "", distinctId:String? = nil, withMessage:String? = nil, optionalData:String?=nil){
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
        chatVC.optionalDataCompletion = {_ in}
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
    open class func chatView(withUsers users:[String], readOnly:Bool = false, title:String = "", subtitle:String = "", withMessage:String? = nil)->QiscusChatVC{
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
    open class func chatView(withRoomId roomId:Int, readOnly:Bool = false, title:String = "", subtitle:String = "", withMessage:String? = nil)->QiscusChatVC{
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
    open class func image(named name:String)->UIImage?{
        return UIImage(named: name, in: Qiscus.bundle, compatibleWith: nil)?.localizedImage()
    }
    /**
     Class function to unlock action chat
     - parameter action: **()->Void** as unlock action for your chat
     */
    open class func unlockAction(_ action:@escaping (()->Void)){
        QiscusChatVC.sharedInstance.unlockAction = action
    }
    /**
     Class function to show alert in chat with UIAlertController
     - parameter alert: The **UIAlertController** to show alert message in chat
     */
    open class func showChatAlert(alertController alert:UIAlertController){
        QiscusChatVC.sharedInstance.showAlert(alert: alert)
    }
    /**
     Class function to unlock chat
     */
    open class func unlockChat(){
        QiscusChatVC.sharedInstance.unlockChat()
    }
    /**
     Class function to lock chat
     */
    open class func lockChat(){
        QiscusChatVC.sharedInstance.lockChat()
    }
    /**
     Class function to show loading message
     - parameter text: **String** text to show as loading text (Optional), Default value : "Loading ...".
     */
    open class func showLoading(_ text: String = "Loading ..."){
        QiscusChatVC.sharedInstance.showLoading(text)
    }
    /**
     Class function to hide loading 
     */
    open class func dismissLoading(){
        QiscusChatVC.sharedInstance.dismissLoading()
    }
    /**
     Class function to set color chat navigation with gradient
     - parameter topColor: The **UIColor** as your top gradient navigation color.
     - parameter bottomColor: The **UIColor** as your bottom gradient navigation color.
     - parameter tintColor: The **UIColor** as your tint gradient navigation color.
     */
    open class func setGradientChatNavigation(_ topColor:UIColor, bottomColor:UIColor, tintColor:UIColor){
        QiscusChatVC.sharedInstance.setGradientChatNavigation(withTopColor: topColor, bottomColor: bottomColor, tintColor: tintColor)
        QPopUpView.sharedInstance.topColor = topColor
        QPopUpView.sharedInstance.bottomColor = bottomColor
    }
    /**
     Class function to set color chat navigation without gradient
     - parameter color: The **UIColor** as your navigation color.
     - parameter tintColor: The **UIColor** as your tint navigation color.
     */
    open class func setNavigationColor(_ color:UIColor, tintColor: UIColor){
        QiscusChatVC.sharedInstance.setNavigationColor(color, tintColor: tintColor)
    }
    /**
     Class function to set upload from iCloud active or not
     - parameter active: **Bool** to set active or not.
     */
    open class func iCloudUploadActive(_ active:Bool){
        Qiscus.sharedInstance.iCloudUpload = active
        //QiscusChatVC.sharedInstance.documentButton.hidden = !active
    }
    open class func setHttpRealTime(_ rt:Bool = true){
        Qiscus.sharedInstance.httpRealTime = rt
    }
    
    open class func setupReachability(){
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
        let channelArr = topic.characters.split(separator: "/")
        let lastChannelPart = String(channelArr.last!)
        
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
                let isPushed = Qiscus.sharedInstance.isPushed
                
                QiscusCommentClient.sharedInstance.publishMessageStatus(onComment: commentId, roomId: roomId, status: .delivered, withCompletion: {
                    if let thisComment = QiscusComment.getCommentById(commentId) {
                        if !thisComment.isOwnMessage{
                            thisComment.updateCommentStatus(.delivered)
                        }
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
                    
                    if showToast && Qiscus.sharedInstance.config.showToasterMessage{
                        if let window = UIApplication.shared.keyWindow{
                            if let currenRootView = window.rootViewController as? UINavigationController{
                                let viewController = currenRootView.viewControllers[currenRootView.viewControllers.count - 1]
                                
                                QToasterSwift.toast(target: viewController, text: newMessage!.commentText, title:senderName, iconURL:senderAvatarURL, iconPlaceHolder:Qiscus.image(named:"avatar"), onTouch: {
                                    if Qiscus.sharedInstance.toastMessageAct == nil{
                                        if isPushed{
                                            let chatVC = Qiscus.chatView(withRoomId: roomId, title: senderName)
                                            currenRootView.pushViewController(chatVC, animated: true)
                                        }else{
                                            Qiscus.chat(withRoomId: roomId, target: viewController, optionalDataCompletion: { _ in})
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
                let commentId = Int(String(messageArr[0]))!
                let commentUniqueId:String = String(messageArr[1])
                let topicId:Int = Int(String(channelArr[2]))!
                if let comments = QiscusComment.updateCommentStatus(withId: commentId, orUniqueId: commentUniqueId, toStatus: .delivered){
                    if QiscusChatVC.sharedInstance.isPresence && (QiscusChatVC.sharedInstance.topicId == topicId){
                        QiscusCommentClient.sharedInstance.commentDelegate?.commentDidChangeStatus(Comments: comments, toStatus: .delivered)
                        Qiscus.printLog(text: "Change comment status to delivered")
                    }
                }
                break
            case "r":
                let message = String(data: data, encoding: .utf8)!
                let messageArr = message.characters.split(separator: ":")
                let commentId = Int(String(messageArr[0]))!
                let commentUniqueId:String = String(messageArr[1])
                let topicId:Int = Int(String(channelArr[2]))!
                if let comments = QiscusComment.updateCommentStatus(withId: commentId, orUniqueId: commentUniqueId, toStatus: .read){
                    if QiscusChatVC.sharedInstance.isPresence && (QiscusChatVC.sharedInstance.topicId == topicId){
                        QiscusCommentClient.sharedInstance.commentDelegate?.commentDidChangeStatus(Comments: comments, toStatus: .read)
                        Qiscus.printLog(text: "change comment status to read")
                    }
                }
                break
            default:
                Qiscus.printLog(text: "Realtime socket receive message in unknown topic: \(topic)")
                break
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
        let currentSchema:UInt64 = 5
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
    open class func createChatView(withUsers users:[String], readOnly:Bool = false, title:String, subtitle:String = "", distinctId:String? = nil, optionalData:String?=nil, withMessage:String? = nil)->QiscusChatVC{
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
        chatVC.optionalDataCompletion = {_ in }
        chatVC.message = withMessage
        chatVC.newChat = true

        if QiscusChatVC.sharedInstance.isPresence {
            QiscusChatVC.sharedInstance.goBack()
        }
        
        return chatVC
    }
    open class func createChat(withUsers users:[String], target:UIViewController, readOnly:Bool = false, title:String, subtitle:String = "", distinctId:String? = nil, optionalData:String?=nil, withMessage:String? = nil){
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
        chatVC.optionalDataCompletion = {_ in }
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
    open class func updateRoom(withRoomId roomId:Int, roomName:String? = nil, roomAvatarURL:String? = nil, roomOptions:String? = nil){
        Qiscus.commentService.updateRoom(withRoomId: roomId, roomName: roomName, roomAvatarURL: roomAvatarURL, roomOptions: roomOptions)
    }
}
