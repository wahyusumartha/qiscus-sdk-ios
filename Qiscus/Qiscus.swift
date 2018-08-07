//
//  Qiscus.swift
//
//  Created by Ahmad Athaullah on 7/17/16.
//  Copyright © 2016 qiscus. All rights reserved.
//

import Foundation
import QiscusCore
import QiscusUI

@objc public protocol QiscusConfigDelegate {
    @objc optional func qiscusFailToConnect(_ withMessage:String)
    @objc optional func qiscusConnected()
    
//    @objc optional func qiscus(gotSilentNotification comment:QComment, userInfo:[AnyHashable:Any])
    @objc optional func qiscus(didConnect succes:Bool, error:String?)
    @objc optional func qiscus(didRegisterPushNotification success:Bool, deviceToken:String, error:String?)
    @objc optional func qiscus(didUnregisterPushNotification success:Bool, error:String?)
//    @objc optional func qiscus(didTapLocalNotification comment:QComment, userInfo:[AnyHashable : Any]?)
    
    @objc optional func qiscusStartSyncing()
    @objc optional func qiscus(finishSync success:Bool, error:String?)
}

public protocol QiscusRoomDelegate {
    func gotNewComment(_ comments:QComment)
    func didFinishLoadRoom(onRoom room: QRoom)
    func didFailLoadRoom(withError error:String)
    func didFinishUpdateRoom(onRoom room:QRoom)
    func didFailUpdateRoom(withError error:String)
}

public class Qiscus {
    
    public static let sharedInstance = Qiscus()
    static let qiscusVersionNumber:String = "2.9.1"
    
    var configDelegate : QiscusConfigDelegate? = nil
    
    public func isLoggedIn() -> Bool {
        return false
    }
    
    public func connect(delegate del: QiscusConfigDelegate) {
        self.configDelegate = del
    }
    
    public func room(withId roomId:String, onSuccess:@escaping ((QRoom)->Void),onError:@escaping ((String)->Void)){
        
    }
    
    public func chatView(withRoomId: String) -> QiscusChatVC {
        return QiscusChatVC()
    }
    
    public func getNonce(onSuccess:@escaping ((String)->Void), onFailed:@escaping ((String)->Void), secureURL:Bool = true){
        
    }
    
    public func fetchAllRoom(onSuccess: @escaping (([QRoom]) -> Void), onError: @escaping ((String) -> Void)) {
    
    }
}
