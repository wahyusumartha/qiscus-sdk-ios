//
//  Qiscus.swift
//
//  Created by Ahmad Athaullah on 7/17/16.
//  Copyright © 2016 qiscus. All rights reserved.
//

import Foundation
import QiscusCore
import QiscusUI
import SwiftyJSON

@objc public protocol QiscusDiagnosticDelegate {
    @objc func qiscusDiagnostic(sendLog log:String)
}

public protocol QiscusConfigDelegate {
    func qiscusFailToConnect(_ withMessage:String)
    func qiscusConnected()
    
    func qiscus(gotSilentNotification comment:QComment, userInfo:[AnyHashable:Any])
    func qiscus(didConnect succes:Bool, error:String?)
    func qiscus(didRegisterPushNotification success:Bool, deviceToken:String, error:String?)
    func qiscus(didUnregisterPushNotification success:Bool, error:String?)
    func qiscus(didTapLocalNotification comment:QComment, userInfo:[AnyHashable : Any]?)
    
    func qiscusStartSyncing()
    func qiscus(finishSync success:Bool, error:String?)
}

public protocol QiscusRoomDelegate {
    func gotNewComment(_ comments:QComment)
    func didFinishLoadRoom(onRoom room: QRoom)
    func didFailLoadRoom(withError error:String)
    func didFinishUpdateRoom(onRoom room:QRoom)
    func didFailUpdateRoom(withError error:String)
}

var QiscusBackgroundThread = DispatchQueue(label: "com.qiscus.background", attributes: .concurrent)

public class Qiscus {
    
    public static let sharedInstance = Qiscus()
    static let qiscusVersionNumber:String = "2.9.1"
    var reachability:QReachability?
    var configDelegate : QiscusConfigDelegate? = nil
    static var qiscusDeviceToken: String = ""
    var notificationAction:((QiscusChatVC)->Void)? = nil
    var disableLocalization: Bool = false
    var isPushed:Bool = false
    /// cached qiscusChatVC : viewController that already opened will be chached here
    public var chatViews = [String:QiscusChatVC]()
    /**
     Active Qiscus Print log, by default is disable/false
     */
    public static var showDebugPrint = false
    
    /**
     Save qiscus log.
     */
    // TODO : when active save log, make sure file size under 1/3Mb.
    @available(*, deprecated, message: "no longer available for public ...")
    static var saveLog:Bool = false
    
    internal class func logFile()->String{
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask,true)[0] as NSString
        let logPath = documentsPath.appendingPathComponent("Qiscus.log")
        return logPath
    }
    
    /// Setup Qiscus Custom Configuration, default value is QiscusUIConfiguration.sharedInstance
    @available(*, deprecated, message: "no longer available for public ...")
    var styleConfiguration = QiscusUIConfiguration.sharedInstance
    @available(*, deprecated, message: "no longer available for public ...")
    var connected:Bool = false
    /// check qiscus is connected with server or not.
    @objc public var isConnected: Bool {
        get {
            return Qiscus.sharedInstance.connected
        }
    }
    
    /// shared instance of QiscusClient
    public static var client : QiscusClient {
        get { return QiscusClient.shared }
    }
    
    /**
     iCloud Config, by default is disable/false. You need to setup icloud capabilities then create container in your developer account.
     */
    public var iCloudUpload = false
    
    /**
     Receive all Qiscus Log, then handle logs\s by client.
     
     ```
     func qiscusDiagnostic(sendLog log:String)
     ```
     */
    public var diagnosticDelegate:QiscusDiagnosticDelegate?
    let application = UIApplication.shared
    
    /// Qiscus bundle
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
    
    ///check qiscus user login status
    @objc public class var isLoggedIn:Bool{
        get{
            return QiscusCore.isLogined
        }
    }
    
    public func connect(delegate del: QiscusConfigDelegate) {
        self.configDelegate = del
        if !QiscusCore.connect() {
            print("Qiscus Realtime Filed to connect, please try again or relogin")
        }
    }
    
    /**
     Set App ID, when you are using nonce auth you need to setup App ID before get nounce
     
     - parameter appId: Qiscus App ID, please register or login in http://qiscus.com to find your App ID
     */
    
    public func setAppId(appId:String){
        QiscusCore.setup(WithAppID: appId)
        QiscusCore.enableDebugPrint = true
    }
    
    /**
     Qiscus Setup with `identity token`, 2nd call method after you call getNounce. Response from you backend then putback in to Qiscus Server
     
     - parameter uidToken: token where you get from get nonce
     - parameter delegate: QiscusConfigDelegate
     
     */
    public func setup(withUserIdentityToken uidToken:String, delegate: QiscusConfigDelegate? = nil){
        if delegate != nil {
            Qiscus.sharedInstance.configDelegate = delegate
        }
        Qiscus.sharedInstance.setup(withuserIdentityToken: uidToken)
        Qiscus.setupReachability()
        Qiscus.sharedInstance.RealtimeConnect()
    }
    
    func setup(withuserIdentityToken: String){
        QiscusCore.connect(withIdentityToken: withuserIdentityToken) { (qUser, error) in
            if let user = qUser{
                 QiscusClient.shared.token = user.token
                 QiscusClient.shared.userData.set(user.token, forKey: "qiscus_token")
            }
           
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
    
    //Todo need to be fix
    @objc func goToBackgroundMode(){
//        for (_,chatView) in self.chatViews {
//            if chatView.isPresence {
//                chatView.goBack()
//                if let room = chatView.chatRoom {
//                    room.delegate = nil
//                }
//            }
//        }
//        Qiscus.shared.stopPublishOnlineStatus()
    }
    
    /// connect mqtt
    ///
    /// - Parameter chatOnly: -
    class func mqttConnect(chatOnly:Bool = false){
        QiscusBackgroundThread.asyncAfter(deadline: .now() + 1.0) {
            Qiscus.backgroundSync()
        }
    }
    
    /// QiscusUIConfiguration class
    public var style:QiscusUIConfiguration{
        get{
            return Qiscus.sharedInstance.styleConfiguration
        }
    }
    
    public func room(withId roomId:String, onSuccess:@escaping ((QRoom)->Void),onError:@escaping ((String)->Void)){
        return QiscusCore.shared.getRoom(withID: roomId, completion: { (qRoom, error) in
            onSuccess(qRoom as! QRoom)
        })
    }
    
    public func room(withUserId: String, onSuccess:@escaping ((QRoom)->Void),onError:@escaping ((String)->Void)){
        return QiscusCore.shared.getRoom(withUser: withUserId, completion: { (qRoom, error) in
            onSuccess(qRoom as! QRoom)
        })
    }
    
    public func chatView(withRoomId: String) -> QiscusChatVC {
        let chatRoom = QiscusChatVC()
        chatRoom.chatRoomId = withRoomId
        return chatRoom
    }
    
    public func getNonce(onSuccess:@escaping ((String)->Void), onFailed:@escaping ((String)->Void), secureURL:Bool = true){
        QiscusCore.getNonce { (nonceData, error) in
            onSuccess((nonceData?.nonce)!)
        }
    }
    
    public func fetchAllRoom(onSuccess:@escaping (([QRoom])->Void)){
        QRoom.getAllRoom { (qRoom, error) in
            onSuccess(qRoom!)
        }
    }
    
    /// get image assets on qiscus bundle
    ///
    /// - Parameter name: assets name
    /// - Returns: UIImage
    @objc public class func image(named name:String)->UIImage?{
        return UIImage(named: name, in: Qiscus.bundle, compatibleWith: nil)?.localizedImage()
    }
    
    /// subscribe room notification
    public func subscribeAllRoomNotification(){
//        QiscusBackgroundThread.async { autoreleasepool {
//            let rooms = QRoom.all()
//            for room in rooms {
//                room.subscribeRealtimeStatus()
//            }
//            }}
    }
    
    /// search local message comment
    ///
    /// - Parameter searchQuery: query to search
    /// - Returns: array of QComment obj
    public func searchComment(searchQuery: String) -> [QComment]? {
        return nil
    }
    
    /// search message comment from service
    ///
    /// - Parameter searchQuery: query to search
    /// - Returns: array of QComment obj
    public class func searchCommentService( withQuery text:String, room:QRoom? = nil, fromComment:QComment? = nil, onSuccess:@escaping (([QComment])->Void), onFailed: @escaping ((String)->Void)){
        
    }
    
    /// debug print
    ///
    /// - Parameter text: log message
    public class func printLog(text:String){
        if Qiscus.showDebugPrint{
            let logText = "[Qiscus]: \(text)"
            print(logText)
            DispatchQueue.global().sync{
                if Qiscus.saveLog {
                    let date = Date()
                    let df = DateFormatter()
                    df.dateFormat = "y-MM-dd H:m:ss"
                    let dateTime = df.string(from: date)
                    
                    let logFileText = "[Qiscus - \(dateTime)] : \(text)"
                    let logFilePath = Qiscus.logFile()
                    var dump = ""
                    if FileManager.default.fileExists(atPath: logFilePath) {
                        dump =  try! String(contentsOfFile: logFilePath, encoding: String.Encoding.utf8)
                    }
                    do {
                        // Write to the file
                        try  "\(dump)\n\(logFileText)".write(toFile: logFilePath, atomically: true, encoding: String.Encoding.utf8)
                    } catch let error as NSError {
                        Qiscus.printLog(text: "Failed writing to log file: \(logFilePath), Error: " + error.localizedDescription)
                    }
                }
            }
            Qiscus.sharedInstance.diagnosticDelegate?.qiscusDiagnostic(sendLog: logText)
        }
    }
    
    @objc public class func didReceive(RemoteNotification userInfo:[AnyHashable : Any], completionHandler: @escaping (UIBackgroundFetchResult) -> Void = {_ in}){
        completionHandler(.newData)
        
        if Qiscus.isLoggedIn{
            if userInfo["qiscus_sdk"] != nil {
                let state = Qiscus.sharedInstance.application.applicationState
                if state != .active {
                    Qiscus.sharedInstance.syncProcess()
                    if let payloadData = userInfo["payload"]{
                        let jsonPayload = JSON(arrayLiteral: payloadData)[0]
                        let tempComment = QComment.tempComment(fromJSON: jsonPayload)
                        Qiscus.sharedInstance.configDelegate?.qiscus(gotSilentNotification: tempComment!, userInfo: userInfo)
                    }
                }
            }
        }
    }
    
    //Todo call api SyncProses
    public func syncProcess(){
        
    }
    
    //Todo connect to mqtt
    public class func backgroundSync(){
        
    }
    
    /// register device token to sdk server
    ///
    /// - Parameter token: device token Data
    public func didRegisterUserNotification(withToken token: Data){
        if Qiscus.isLoggedIn{
            var tokenString: String = ""
            for i in 0..<token.count {
                tokenString += String(format: "%02.2hhx", token[i] as CVarArg)
            }
            
            //call service api to register notification
            QiscusCore.shared.register(deviceToken: tokenString) { (isRegister, erorr) in
                
            }
        }
    }
    
    
    /// this func to update room
    ///
    /// - Parameters:
    ///   - roomId: roomId
    ///   - roomName: roomName
    ///   - avatar: avatarUrl
    public func updateRoom(roomId: String, roomName: String? = nil, avatar: String? = nil){
        if(avatar != nil){
            QiscusCore.shared.updateRoom(withID: roomId, name: roomName, avatarURL: URL(string: avatar!), options: nil) { (qRoom, error) in
                
            }
        }else{
            QiscusCore.shared.updateRoom(withID: roomId, name: roomName, avatarURL: nil, options: nil) { (qRoom, error) in
                
            }
        }
        
    }
    
    /// didREceive localnotification
    ///
    /// - Parameter notification: UILocalNotification
    public func didReceiveNotification(notification:UILocalNotification){
        if notification.userInfo != nil {
            if let comment = QComment.decodeDictionary(data: notification.userInfo!) {
                var userData:[AnyHashable : Any]? = [AnyHashable : Any]()
                let qiscusKey:[AnyHashable] = ["qiscus_commentdata","qiscus_uniqueId","qiscus_id","qiscus_roomId","qiscus_beforeId","qiscus_text","qiscus_createdAt","qiscus_senderEmail","qiscus_senderName","qiscus_statusRaw","qiscus_typeRaw","qiscus_data"]
                for (key,value) in notification.userInfo! {
                    if !qiscusKey.contains(key) {
                        userData![key] = value
                    }
                }
                if userData!.count == 0 {
                    userData = nil
                }
                Qiscus.sharedInstance.configDelegate?.qiscus(didTapLocalNotification: comment, userInfo: userData)
            }
        }
    }
    
   public func didReceive(RemoteNotification userInfo:[AnyHashable : Any], completionHandler: @escaping (UIBackgroundFetchResult) -> Void = {_ in}){
        completionHandler(.newData)
        
        if Qiscus.isLoggedIn{
            if userInfo["qiscus_sdk"] != nil {
                let state = Qiscus.sharedInstance.application.applicationState
                if state != .active {
                    self.syncProcess()
                    if let payloadData = userInfo["payload"]{
                        let jsonPayload = JSON(arrayLiteral: payloadData)[0]
                        let tempComment = QComment.tempComment(fromJSON: jsonPayload)
                        Qiscus.sharedInstance.configDelegate?.qiscus(gotSilentNotification: tempComment!, userInfo: userInfo)
                    }
                }
            }
        }
    }
    
    @objc func applicationDidBecomeActife(){
        Qiscus.setupReachability()
        if Qiscus.isLoggedIn{
            Qiscus.sharedInstance.RealtimeConnect()
        }
        if !Qiscus.sharedInstance.styleConfiguration.rewriteChatFont {
            Qiscus.sharedInstance.styleConfiguration.chatFont = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        }
        if let chatView = QiscusHelper.topViewController() as? QiscusChatVC {
            chatView.isPresence = true
            
        }
        Qiscus.connect()
        Qiscus.sync(cloud: true)
    }
    
    /// do message synchronize
    ///
    /// - Parameter cloud: -
    public class func sync(cloud:Bool = false){
        if Qiscus.isLoggedIn{
            Qiscus.sharedInstance.syncProcess(cloud: cloud)
        }
    }
    
    //Todo need to be implement call api sync
   func syncProcess(first:Bool = true, cloud:Bool = false){
        
    }
    
    /// setup reachability for network connection detection
    class func setupReachability(){
        QiscusBackgroundThread.async {autoreleasepool{
            Qiscus.sharedInstance.reachability = QReachability()
            
            if let reachable = Qiscus.sharedInstance.reachability {
                if reachable.isReachable {
                    Qiscus.sharedInstance.connected = true
                    if Qiscus.isLoggedIn {
                        Qiscus.sharedInstance.RealtimeConnect()
                        DispatchQueue.main.async { autoreleasepool{
                            QComment.resendPendingMessage()
                            }}
                    }
                }
            }
            
            Qiscus.sharedInstance.reachability?.whenReachable = { reachability in
                if reachability.isReachableViaWiFi {
                    Qiscus.printLog(text: "connected via wifi")
                } else {
                    Qiscus.printLog(text: "connected via cellular data")
                }
                Qiscus.sharedInstance.connected = true
                if Qiscus.isLoggedIn {
                    Qiscus.sharedInstance.RealtimeConnect()
                    DispatchQueue.main.async { autoreleasepool{
                        QComment.resendPendingMessage()
                        }}
                }
            }
            Qiscus.sharedInstance.reachability?.whenUnreachable = { reachability in
                Qiscus.printLog(text: "disconnected")
                Qiscus.sharedInstance.connected = false
            }
            do {
                try  Qiscus.sharedInstance.reachability?.startNotifier()
            } catch {
                Qiscus.printLog(text: "Unable to start network notifier")
            }
            }}
    }
    
    
    /// connect to mqtt and setup reachability
    ///
    /// - Parameter delegate: QiscusConfigDelegate
    public class func connect(delegate:QiscusConfigDelegate? = nil){
        Qiscus.sharedInstance.RealtimeConnect()
        if delegate != nil {
            Qiscus.sharedInstance.configDelegate = delegate
        }
        Qiscus.setupReachability()
        Qiscus.sharedInstance.syncProcess()
    }
    
    /// set banner click action
    ///
    /// - Parameter action: do something on @escaping when banner notif did tap
    public func setNotificationAction(onClick action:@escaping ((QiscusChatVC)->Void)){
        Qiscus.sharedInstance.notificationAction = action
    }
    
    /// trigger register notif delegate on appDelegate
    public func registerNotification(){
        let notificationSettings = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
        Qiscus.sharedInstance.application.registerUserNotificationSettings(notificationSettings)
        Qiscus.sharedInstance.application.registerForRemoteNotifications()
    }
    
    /**
     Class function to set color chat navigation without gradient
     - parameter color: The **UIColor** as your navigation color.
     - parameter tintColor: The **UIColor** as your tint navigation color.
     */
    public func setNavigationColor(_ color:UIColor, tintColor: UIColor){
        Qiscus.sharedInstance.styleConfiguration.color.topColor = color
        Qiscus.sharedInstance.styleConfiguration.color.bottomColor = color
        Qiscus.sharedInstance.styleConfiguration.color.tintColor = tintColor
        //TODO Need to fix
//        for (_,chatView) in Qiscus.sharedInstance.chatViews {
//            chatView.topColor = color
//            chatView.bottomColor = color
//            chatView.tintColor = tintColor
//        }
    }
    
    /**
     Class function to set upload from iCloud active or not
     - parameter active: **Bool** to set active or not.
     */
    public func iCloudUploadActive(_ active:Bool){
        Qiscus.sharedInstance.iCloudUpload = active
    }
    
    //TODO Need to be implement,
    /// unregister device token from service
    public func unRegisterDevice(){
        QiscusCore.shared.remove(deviceToken: QiscusClient.shared.token) { (unRegister, error) in
            
        }
    }
    
    //Todo need to be fix
    /**
     Logout Qiscus and clear all data with this function
     @func clearData()
     */
    public func clear(){
        QiscusClient.clear()
        QiscusClient.hasRegisteredDeviceToken = false
    }
    
    //TODO Need TO Be Implement
    /// register device token to sdk service
    ///
    /// - Parameter deviceToken: device token in string
   public func registerDevice(withToken deviceToken: String){
        Qiscus.qiscusDeviceToken = deviceToken
        Qiscus.client.deviceToken = deviceToken
    
    }
    
    //Todo need to be implement to call api update profile
    /// update qiscus user profile
    ///
    /// - Parameters:
    ///   - username: String username
    ///   - avatarURL: String avatar url
    ///   - onSuccess: @escaping on success update user profile
    ///   - onFailed: @escaping on error update user profile with error message
    public func updateProfile(username:String? = nil, avatarURL:String? = nil, onSuccess:@escaping (()->Void), onFailed:@escaping ((String)->Void)) {
        
        var userName = ""
        if(userName != nil){
            userName = username!
        }
        if(avatarURL != nil){
            QiscusCore.shared.updateProfile(displayName: userName, avatarUrl: URL(string: avatarURL!)) { (qUser, error) in
                
            }
        }else{
            QiscusCore.shared.updateProfile(displayName: userName, avatarUrl: nil) { (qUser, error) in
                
            }
        }
        
        
    }
    
    /// create banner natification
    ///
    /// - Parameters:
    ///   - comment: QComment
    ///   - alertTitle: banner title
    ///   - alertBody: banner body
    ///   - userInfo: userInfo
    public func createLocalNotification(forComment comment:QComment, alertTitle:String? = nil, alertBody:String? = nil, userInfo:[AnyHashable : Any]? = nil){
        DispatchQueue.main.async {autoreleasepool{
            let localNotification = UILocalNotification()
            if let title = alertTitle {
                localNotification.alertTitle = title
            }else{
                localNotification.alertTitle = comment.senderName
            }
            if let body = alertBody {
                localNotification.alertBody = body
            }else{
                localNotification.alertBody = comment.text
            }
            
            localNotification.soundName = "default"
            var userData = [AnyHashable : Any]()
            
            if userInfo != nil {
                for (key,value) in userInfo! {
                    userData[key] = value
                }
            }
            
            let commentInfo = comment.encodeDictionary()
            for (key,value) in commentInfo {
                userData[key] = value
            }
            localNotification.userInfo = userData
            localNotification.fireDate = Date().addingTimeInterval(0.4)
            Qiscus.sharedInstance.application.scheduleLocalNotification(localNotification)
            }}
    }
    
    //Todo call QiscusUI
    /// get QiscusChatVC with array of username
    ///
    /// - Parameters:
    ///   - users: with array of client (username used on Qiscus.setup)
    ///   - readOnly: true => unable to access input view , false => able to access input view
    ///   - title: chat title
    ///   - subtitle: chat subtitle
    ///   - distinctId: -
    ///   - withMessage: predefined text message
    /// - Returns: QiscusChatVC to be presented or pushed
    public  func chatView(withUsers users:[String], readOnly:Bool = false, title:String = "", subtitle:String = "", distinctId:String = "", withMessage:String? = nil)->QiscusChatVC{
        
        let chatVC = QiscusChatVC()
        
        QiscusCore.shared.getRoom(withUser: users.first!) { (qRoom, error) in
            chatVC.room = qRoom
            chatVC.chatUser = users.first!
            chatVC.chatTitle = title
            chatVC.chatSubtitle = subtitle
            chatVC.archived = readOnly
            chatVC.chatMessage = withMessage
            if chatVC.isPresence {
                chatVC.back()
            }
    
        }
        return chatVC
    }
    
    /// get QiscusChatVC with room id
    ///
    /// - Parameters:
    ///   - users: array of user id
    ///   - readOnly: true => unable to access input view , false => able to access input view
    ///   - title: chat title
    ///   - subtitle: chat subtitle
    ///   - distinctId: -
    ///   - withMessage: predefined text message
    /// - Returns: QiscusChatVC to be presented or pushed
    public func createChatView(withUsers users:[String], readOnly:Bool = false, title:String, subtitle:String = "", distinctId:String? = nil, optionalData:String?=nil, withMessage:String? = nil)->QiscusChatVC{
        if !Qiscus.sharedInstance.connected {
            Qiscus.setupReachability()
        }
        
        Qiscus.sharedInstance.isPushed = true
        
        let chatVC = QiscusChatVC()
        QiscusCore.shared.createGroup(withName: title, participants: users, avatarUrl: nil) { (qRoom, error) in
            if distinctId != nil{
                chatVC.chatDistinctId = distinctId!
            }else{
                chatVC.chatDistinctId = ""
            }
            chatVC.chatData         = optionalData
            chatVC.chatMessage      = withMessage
            chatVC.archived         = readOnly
            chatVC.chatNewRoomUsers = users
            chatVC.chatTitle        = title
            chatVC.chatSubtitle     = subtitle
            chatVC.room             = qRoom
            if chatVC.isPresence {
                chatVC.back()
            }
        }
        
        return chatVC
        
    }
    
    /// get QiscusChatVC with room id
    ///
    /// - Parameters:
    ///   - roomId: room id
    ///   - readOnly: true => unable to access input view , false => able to access input view
    ///   - title: chat title
    ///   - subtitle: chat subtitle
    ///   - distinctId: -
    ///   - withMessage: predefined text message
    /// - Returns: QiscusChatVC to be presented or pushed
    public func chatView(withRoomId roomId:String, readOnly:Bool = false, title:String = "", subtitle:String = "", withMessage:String? = nil)->QiscusChatVC{
        if !Qiscus.sharedInstance.connected {
            Qiscus.setupReachability()
        }
        
        var chatVC = QiscusChatVC()
        
        if let chatView = Qiscus.sharedInstance.chatViews[roomId] {
            chatVC = chatView
        }else{
            chatVC.chatRoomId = roomId
        }
        chatVC.chatTitle = title
        chatVC.chatSubtitle = subtitle
        chatVC.archived = readOnly
        chatVC.chatMessage = withMessage
        
        return chatVC
    }
    
    
}
