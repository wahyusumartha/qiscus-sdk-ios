//
//  QiscusConfigDelegate.swift
//  QiscusSDK
//
//  Created by Ahmad Athaullah on 9/8/16.
//  Copyright © 2016 Ahmad Athaullah. All rights reserved.
//

import UIKit

@objc public protocol QiscusDiagnosticDelegate {
    @objc func qiscusDiagnostic(sendLog log:String)
}
@objc public protocol QiscusChatDelegate {
    @objc optional func qiscusChat(gotNewComment comment:QComment)
    @objc optional func qiscusChat(userDidTyping users:QUser)
    @objc optional func qiscusChat(gotNewRoom room:QRoom)
}
@objc public protocol QiscusConfigDelegate {
    @objc optional func qiscusFailToConnect(_ withMessage:String)
    @objc optional func qiscusConnected()
    
    @objc optional func qiscus(gotSilentNotification comment:QComment, userInfo:[AnyHashable:Any])
    @objc optional func qiscus(didConnect succes:Bool, error:String?)
    @objc optional func qiscus(didRegisterPushNotification success:Bool, deviceToken:String, error:String?)
    @objc optional func qiscus(didUnregisterPushNotification success:Bool, error:String?)
    @objc optional func qiscus(didTapLocalNotification comment:QComment, userInfo:[AnyHashable : Any]?)
    
    @objc optional func qiscusStartSyncing()
    @objc optional func qiscus(finishSync success:Bool, error:String?)
    //@objc optional func failToRegisterQiscusPushNotification(withError error:String?, andDeviceToken token:String)
    
    //@objc optional func didRegisterQiscusPushNotification(withDeviceToken token:String)
    //@objc optional func didUnregisterQiscusPushNotification(success:Bool, error:String?, deviceToken:String)
}
