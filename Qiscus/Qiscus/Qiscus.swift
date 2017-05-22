//
//  Qiscus.swift
//
//  Created by Ahmad Athaullah on 7/17/16.
//  Copyright © 2016 qiscus. All rights reserved.
//


import UIKit
import RealmSwift
import Foundation
import SwiftyJSON
import PushKit
import UserNotifications
import CocoaMQTT

@objc public class Qiscus: NSObject, PKPushRegistryDelegate, UNUserNotificationCenterDelegate {
    
    static let sharedInstance = Qiscus()
    static let qiscusVersionNumber:String = "2.2.8"
    static let showDebugPrint = false
    
    // MARK: - Thread
    static let realtimeThread = DispatchQueue.global()
    static let logThread = DispatchQueue.global()
    static let apiThread = DispatchQueue.global()
    static let uiThread = DispatchQueue.main
    static let logicThread = DispatchQueue.global()
    
    static var qiscusDeviceToken: String = ""
    static var dbConfiguration = Realm.Configuration.defaultConfiguration
    
    static var qiscusDownload:[String] = [String]()
    
    var config = QiscusConfig.sharedInstance
    var commentService = QiscusCommentClient.sharedInstance
    var iCloudUpload:Bool = false
    var isPushed:Bool = false
    var reachability:QReachability?
    var mqtt:CocoaMQTT?
    var mqttChannel = [String]()
    var notificationAction:((QiscusChatVC)->Void)? = nil
    var realtimeConnected = false
    var syncing = false
    
    @objc public var styleConfiguration = QiscusUIConfiguration.sharedInstance
    @objc public var connected:Bool = false
    @objc public var httpRealTime:Bool = false
    @objc public var toastMessageAct:((_ roomId:Int, _ comment:QiscusComment)->Void)?
    
    let application = UIApplication.shared
    let appDelegate = UIApplication.shared.delegate
    
    public var chatViews = [Int:QiscusChatVC]()
    
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
            Qiscus.sharedInstance.mqtt?.disconnect()
        }
    }
    
    @objc public class func clear(){
        Qiscus.publishUserStatus(offline: true)
        Qiscus.shared.mqtt?.disconnect()
        Qiscus.unRegisterPN()
        QiscusMe.clear()
        Qiscus.dbConfiguration.schemaVersion = Qiscus.shared.config.dbSchemaVersion
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        try! realm.write {
            realm.deleteAll()
        }
        Qiscus.deleteAllFiles()
        Qiscus.shared.chatViews = [Int:QiscusChatVC]()
    }
    
    @objc public class func unRegisterPN(){
        if Qiscus.isLoggedIn {
            QiscusCommentClient.sharedInstance.unRegisterDevice()
        }
    }
    // need Documentation
    func backgroundCheck(){
        if Qiscus.isLoggedIn{
            if let lastComment = QiscusComment.getLastComment(){
                QiscusCommentClient.shared.syncChat(fromComment: lastComment.commentId, backgroundFetch: true)
            }else{
                let lastId = QiscusMe.sharedInstance.lastCommentId
                QiscusCommentClient.shared.syncChat(fromComment: lastId, backgroundFetch: true)
            }
        }
    }
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
        QiscusChatVC.sharedInstance.archived = readOnly
        QiscusUIConfiguration.sharedInstance.copyright.chatSubtitle = subtitle
        QiscusUIConfiguration.sharedInstance.copyright.chatTitle = title
        
        let chatVC = QiscusChatVC.sharedInstance
        //chatVC.reset()
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
        QiscusChatVC.sharedInstance.archived = readOnly
        QiscusUIConfiguration.sharedInstance.copyright.chatSubtitle = subtitle
        QiscusUIConfiguration.sharedInstance.copyright.chatTitle = title
        
        let chatVC = QiscusChatVC.sharedInstance
        //chatVC.reset()
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
        
        UIApplication.shared.keyWindow?.rootViewController?.present(navController, animated: true, completion: nil)
    }
    @objc public class func chat(withUsers users:[String], target:UIViewController, readOnly:Bool = false, title:String = "", subtitle:String = "", distinctId:String? = nil, withMessage:String? = nil, optionalData:String?=nil){
        Qiscus.checkDatabaseMigration()
        if !Qiscus.sharedInstance.connected {
            Qiscus.setupReachability()
        }
        
        Qiscus.sharedInstance.isPushed = false
        QiscusChatVC.sharedInstance.archived = readOnly
        QiscusUIConfiguration.sharedInstance.copyright.chatSubtitle = subtitle
        QiscusUIConfiguration.sharedInstance.copyright.chatTitle = title
        
        
        let chatVC = QiscusChatVC.sharedInstance
        //chatVC.reset()
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
        
        UIApplication.shared.keyWindow?.rootViewController?.present(navController, animated: true, completion: nil)
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
        QiscusChatVC.sharedInstance.archived = readOnly
        QiscusUIConfiguration.sharedInstance.copyright.chatSubtitle = subtitle
        QiscusUIConfiguration.sharedInstance.copyright.chatTitle = title
        
        let chatVC = QiscusChatVC.sharedInstance
        //chatVC.reset()
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
        
        var chatVC = QiscusChatVC()
        if let chatView = Qiscus.shared.chatViews[roomId] {
            chatVC = chatView
        }else{
            chatVC.navTitle = title
            chatVC.navSubtitle = subtitle
            chatVC.archived = readOnly
            chatVC.roomId = roomId
            chatVC.message = withMessage
            chatVC.backAction = nil
            Qiscus.shared.chatViews[roomId] = chatVC
        }
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
        Qiscus.shared.styleConfiguration.color.topColor = topColor
        Qiscus.shared.styleConfiguration.color.bottomColor = bottomColor
        Qiscus.shared.styleConfiguration.color.tintColor = tintColor
        
        for (_,chatView) in Qiscus.shared.chatViews {
            chatView.topColor = topColor
            chatView.bottomColor = bottomColor
            chatView.tintColor = tintColor
        }
        //        Qiscus.uiThread.async {
        //            QiscusChatVC.sharedInstance.setGradientChatNavigation(withTopColor: topColor, bottomColor: bottomColor, tintColor: tintColor)
        //            let popUpView = QPopUpView.sharedInstance
        //            popUpView.topColor = topColor
        //            popUpView.bottomColor = bottomColor
        //        }
    }
    /**
     Class function to set color chat navigation without gradient
     - parameter color: The **UIColor** as your navigation color.
     - parameter tintColor: The **UIColor** as your tint navigation color.
     */
    @objc public class func setNavigationColor(_ color:UIColor, tintColor: UIColor){
        Qiscus.shared.styleConfiguration.color.topColor = color
        Qiscus.shared.styleConfiguration.color.bottomColor = color
        Qiscus.shared.styleConfiguration.color.tintColor = tintColor
        for (_,chatView) in Qiscus.shared.chatViews {
            chatView.topColor = color
            chatView.bottomColor = color
            chatView.tintColor = tintColor
        }
        //        QiscusChatVC.sharedInstance.setNavigationColor(color, tintColor: tintColor)
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
                    if let lastComment = QiscusComment.getLastComment() {
                        QiscusCommentClient.shared.syncChat(fromComment: lastComment.commentId)
                    }
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
    
    
    
    func applicationDidBecomeActife(){
        if Qiscus.isLoggedIn{
            Qiscus.sharedInstance.RealtimeConnect()
        }
        if !Qiscus.sharedInstance.styleConfiguration.rewriteChatFont {
            Qiscus.sharedInstance.styleConfiguration.chatFont = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
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
        if Qiscus.dbConfiguration.fileURL?.lastPathComponent != "Qiscus.realm" {
            Qiscus.dbConfiguration = Realm.Configuration.defaultConfiguration
            var realmURL = Qiscus.dbConfiguration.fileURL!
            realmURL.deleteLastPathComponent()
            realmURL.appendPathComponent("Qiscus.realm")
            Qiscus.dbConfiguration.fileURL = realmURL
            Qiscus.dbConfiguration.deleteRealmIfMigrationNeeded = true
        }
        Qiscus.dbConfiguration.schemaVersion = Qiscus.shared.config.dbSchemaVersion
        
        let _ = try! Realm(configuration: Qiscus.dbConfiguration)
        Qiscus.printLog(text:"realmURL \(Qiscus.dbConfiguration.fileURL!)")
        print("realmURL \(Qiscus.dbConfiguration.fileURL!)")
    }
    
    // MARK: - Create NEW Chat
    @objc public class func createChatView(withUsers users:[String], readOnly:Bool = false, title:String, subtitle:String = "", distinctId:String? = nil, optionalData:String?=nil, withMessage:String? = nil)->QiscusChatVC{
        Qiscus.checkDatabaseMigration()
        if !Qiscus.sharedInstance.connected {
            Qiscus.setupReachability()
        }
        
        Qiscus.sharedInstance.isPushed = true
        QiscusChatVC.sharedInstance.archived = readOnly
        QiscusUIConfiguration.sharedInstance.copyright.chatSubtitle = subtitle
        QiscusUIConfiguration.sharedInstance.copyright.chatTitle = title
        
        let chatVC = QiscusChatVC.sharedInstance
        //chatVC.reset()
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
        QiscusChatVC.sharedInstance.archived = readOnly
        QiscusUIConfiguration.sharedInstance.copyright.chatSubtitle = subtitle
        QiscusUIConfiguration.sharedInstance.copyright.chatTitle = title
        
        let chatVC = QiscusChatVC.sharedInstance
        //chatVC.reset()
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
        UIApplication.shared.keyWindow?.rootViewController?.present(navController, animated: true, completion: nil)
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
            QiscusMe.sharedInstance.deviceToken = token
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
            QiscusMe.sharedInstance.deviceToken = tokenString
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
    
    @objc public class func didReceive(RemoteNotification userInfo:[AnyHashable : Any], completionHandler: @escaping (UIBackgroundFetchResult) -> Void = {_ in}){
        completionHandler(.newData)
        let state = UIApplication.shared.applicationState
        if Qiscus.isLoggedIn && state != .active{
            if userInfo["qiscus_room_id"] != nil{
                let roomId = userInfo["qiscus_room_id"] as! Int
                Qiscus.notificationAction(roomId: roomId)
            }
        }
    }
    @objc public class func notificationAction(roomId: Int){
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
    @objc public class func didReceive(LocalNotification notification:UILocalNotification){
        UIApplication.shared.cancelAllLocalNotifications()
        if let userInfo = notification.userInfo {
            if let roomData = userInfo["qiscus-room-id"]{
                let roomId = roomData as! Int
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
        if let lastComment = QiscusComment.getLastComment(){
            QiscusCommentClient.shared.syncChat(fromComment: lastComment.commentId)
        }else{
            let lastId = QiscusMe.sharedInstance.lastCommentId
            QiscusCommentClient.shared.syncChat(fromComment: lastId)
        }
        let clientID = "iosMQTT-\(appName)-\(deviceID)-\(QiscusMe.sharedInstance.id)"
        let mqtt = CocoaMQTT(clientID: clientID, host: "mqtt.qiscus.com", port: 1883)
        mqtt.username = ""
        mqtt.password = ""
        mqtt.cleanSession = false
        mqtt.willMessage = CocoaMQTTWill(topic: "u/\(QiscusMe.sharedInstance.email)/s", message: "0")
        mqtt.keepAlive = 60
        mqtt.delegate = Qiscus.shared
        mqtt.connect()
        
    }
    class func publishUserStatus(offline:Bool = false){
        if Qiscus.isLoggedIn{
            Qiscus.realtimeThread.async {
                var message: String = "1";
                
                let channel = "u/\(QiscusMe.sharedInstance.email)/s"
                if offline {
                    message = "0"
                    Qiscus.uiThread.async {
                        Qiscus.shared.mqtt?.publish(channel, withString: message, qos: .qos1, retained: true)
                    }
                }else{
                    if Qiscus.sharedInstance.application.applicationState == UIApplicationState.active {
                        Qiscus.uiThread.async {
                            Qiscus.shared.mqtt?.publish(channel, withString: message, qos: .qos1, retained: true)
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
        if QiscusChatVC.sharedInstance.isPresence {
            QiscusChatVC.sharedInstance.goBack()
            QiscusChatVC.sharedInstance.room = nil
            QiscusChatVC.sharedInstance.comments = [[QiscusCommentPresenter]]()
        }
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
extension Qiscus:CocoaMQTTDelegate{
    public func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int){
        let state = UIApplication.shared.applicationState
        
        let commentChannel = "\(QiscusMe.sharedInstance.token)/c"
        mqtt.subscribe(commentChannel, qos: .qos2)
        if state == .active {
            let rooms = QiscusRoom.all()
            for room in rooms{
                let deliveryChannel = "r/\(room.roomId)/\(room.roomLastCommentTopicId)/+/d"
                let readChannel = "r/\(room.roomId)/\(room.roomLastCommentTopicId)/+/r"
                mqtt.subscribe(deliveryChannel, qos: .qos1)
                mqtt.subscribe(readChannel, qos: .qos1)
            }
            if let allUser = QiscusUser.getAllUser() {
                for user in allUser{
                    if !user.isSelf{
                        let userChannel = "u/\(user.userEmail)/s"
                        mqtt.subscribe(userChannel, qos: .qos1)
                    }
                }
            }
            Qiscus.shared.mqtt = mqtt
        }
    }
    public func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck){
        
    }
    public func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16){
        
    }
    public func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16){
        
    }
    public func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ){
        Qiscus.logicThread.async {
            if let messageData = message.string {
                let channelArr = message.topic.characters.split(separator: "/")
                let lastChannelPart = String(channelArr.last!)
                switch lastChannelPart {
                case "c":
                    
                    let json = JSON.parse(messageData)
                    let notifTopicId = json["topic_id"].intValue
                    let commentBeforeId = json["comment_before_id"].intValue
                    let roomId = json["room_id"].intValue
                    let commentId = json["id"].intValue
                    let email = json["email"].stringValue
                    
                    var comment = QiscusComment()
                    var saved = false
                    let uniqueId = json["unique_temp_id"].stringValue
                    if let dbComment = QiscusComment.comment(withId: commentId, andUniqueId: uniqueId){
                        comment = dbComment
                    }else{
                        comment = QiscusComment.newComment(withId: commentId, andUniqueId: uniqueId)
                        saved = true
                    }
                    comment.commentText = json["message"].stringValue
                    comment.commentSenderEmail = email
                    comment.showLink = !(json["disable_link_preview"].boolValue)
                    comment.commentCreatedAt = Double(json["unix_timestamp"].doubleValue)
                    comment.commentBeforeId = commentBeforeId
                    comment.commentTopicId = notifTopicId
                    comment.commentStatusRaw = QiscusCommentStatus.sent.rawValue
                    print("mqtt payload: \(json)")
                    
                    if json["type"].string == "buttons" {
                        comment.commentText = json["payload"]["text"].stringValue
                        comment.commentButton = "\(json["payload"]["buttons"])"
                        print("postback payload: \(json["payload"])")
                        print("buttons payload: \(json["payload"]["buttons"])")
                    }
                    
                    if let room = QiscusRoom.room(withLastTopicId: notifTopicId){
                        let dataCount = QiscusComment.getComments(inTopicId: notifTopicId).count
                        if  dataCount > 0 && QiscusComment.comment(withId: commentBeforeId) == nil {
                            if let syncId = QiscusComment.getLastSyncCommentId(notifTopicId, unsyncCommentId: commentId){
                                QiscusCommentClient.shared.syncMessage(inRoom: room, fromComment: syncId, silent: true, triggerDelegate: true)
                            }
                        }else{
                            var roomChanged = false
                            var userChanged = false
                            if let user = QiscusUser.getUserWithEmail(email){
                                if let room = QiscusRoom.room(withId: roomId){
                                    if room.roomType == .group{
                                        if room.roomName != json["room_name"].stringValue{
                                            roomChanged = true
                                            room.roomName = json["room_name"].stringValue
                                        }
                                    }
                                    if user.userEmail != QiscusMe.sharedInstance.email{
                                        if user.userFullName != json["username"].stringValue{
                                            if room.roomType == .single{
                                                roomChanged = true
                                            }
                                            userChanged = true
                                            user.updateUserFullName(json["username"].stringValue)
                                        }
                                        
                                        if user.userAvatarURL != json["user_avatar"].stringValue{
                                            if room.roomType == .single{
                                                roomChanged = true
                                            }
                                            userChanged = true
                                            user.updateUserAvatarURL(json["user_avatar"].stringValue)
                                        }
                                    }
                                    if let presenterDelegate = QiscusDataPresenter.shared.delegate {
                                        if userChanged {
                                            let copyUser = QiscusUser.copyUser(user: user)
                                            presenterDelegate.dataPresenter(didChangeUser: copyUser, onUserWithEmail: copyUser.userEmail)
                                        }
                                        if roomChanged {
                                            presenterDelegate.dataPresenter(didChangeRoom: room, onRoomWithId: roomId)
                                        }
                                    }
                                }
                            }else if let room = QiscusRoom.room(withId: roomId){
                                let user = QiscusUser()
                                user.userEmail = email
                                user.userFullName = json["username"].stringValue
                                user.userAvatarURL = json["user_avatar"].stringValue
                                let newUser = QiscusUser.copyUser(user: user.saveUser())
                                QiscusParticipant.addParticipant(newUser.userEmail, roomId: room.roomId)
                                if let presenterDelegate = QiscusDataPresenter.shared.delegate {
                                    presenterDelegate.dataPresenter(didChangeUser: newUser, onUserWithEmail: newUser.userEmail)
                                    presenterDelegate.dataPresenter(didChangeRoom: room, onRoomWithId: roomId)
                                }
                            }
                            if let participant = QiscusParticipant.getParticipant(withEmail: email, roomId: room.roomId){
                                participant.updateLastReadCommentId(commentId: comment.commentId)
                            }
                            if saved {
                                let service = QiscusCommentClient.sharedInstance
                                if QiscusChatVC.sharedInstance.isPresence && QiscusChatVC.sharedInstance.room?.roomId == roomId && !Qiscus.shared.syncing{
                                    if let delegate = service.delegate {
                                        let presenter = QiscusCommentPresenter.getPresenter(forComment: comment)
                                        delegate.qiscusService(gotNewMessage: presenter,realtime:true)
                                    }
                                }
                            }
                        }
                    }
                    QiscusCommentClient.sharedInstance.publishMessageStatus(onComment: commentId, roomId: roomId, status: .delivered, withCompletion: {
                        if let thisComment = QiscusComment.comment(withId: commentId) {
                            thisComment.updateCommentStatus(.read, email: thisComment.commentSenderEmail)
                        }
                    })
                    if let roomDelegate = QiscusCommentClient.sharedInstance.roomDelegate {
                        roomDelegate.gotNewComment(comment)
                    }
                    break
                case "t":
                    let topicId:Int = Int(String(channelArr[2]))!
                    let userEmail:String = String(channelArr[3])
                    if userEmail != QiscusMe.sharedInstance.email {
                        if QiscusChatVC.sharedInstance.isPresence && QiscusChatVC.sharedInstance.room?.roomLastCommentTopicId == topicId {
                            switch messageData {
                            case "1":
                                if let user = QiscusUser.getUserWithEmail(userEmail) {
                                    user.updateLastSeen()
                                    user.updateStatus(isOnline: true)
                                    
                                    let userFullName = user.userFullName
                                    
                                    QiscusChatVC.sharedInstance.startTypingIndicator(withUser: userFullName)
                                }
                                
                                break
                            default:
                                if let user = QiscusUser.getUserWithEmail(userEmail) {
                                    let userFullName = user.userFullName
                                    if QiscusChatVC.sharedInstance.isTypingOn && (QiscusChatVC.sharedInstance.typingIndicatorUser == userFullName){
                                        QiscusChatVC.sharedInstance.stopTypingIndicator()
                                    }
                                }
                            }
                        }
                    }
                    break
                case "d":
                    let messageArr = messageData.characters.split(separator: ":")
                    let commentId = Int(String(messageArr[0]))!
                    let commentUniqueId:String = String(messageArr[1])
                    let userEmail = String(channelArr[3])
                    print("mqtt d : \(commentUniqueId)")
                    if let comment = QiscusComment.comment(withId: commentId){
                        comment.updateCommentStatus(.delivered, email: userEmail)
                    }
                    else if let comment = QiscusComment.comment(withUniqueId: commentUniqueId){
                        comment.updateCommentStatus(.delivered, email: userEmail)
                    }
                    break
                case "r":
                    let messageArr = messageData.characters.split(separator: ":")
                    let commentId = Int(String(messageArr[0]))!
                    let commentUniqueId:String = String(messageArr[1])
                    let userEmail = String(channelArr[3])
                    print("mqtt r : \(commentUniqueId)")
                    if let comment = QiscusComment.comment(withId: commentId){
                        comment.updateCommentStatus(.read, email: userEmail)
                    }
                    else if let comment = QiscusComment.comment(withUniqueId: commentUniqueId){
                        comment.updateCommentStatus(.read, email: userEmail)
                    }
                    break
                case "s":
                    let messageArr = messageData.characters.split(separator: ":")
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
                    Qiscus.printLog(text: "Realtime socket receive message in unknown topic: \(message.topic)")
                    break
                }
            }
        }
        
    }
    public func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String){
        Qiscus.printLog(text: "topic : \(topic) subscribed")
    }
    public func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String){
        
    }
    public func mqttDidPing(_ mqtt: CocoaMQTT){
    }
    public func mqttDidReceivePong(_ mqtt: CocoaMQTT){
        
    }
    public func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?){
        
    }
}
