//
//  QiscusConfigDelegate.swift
//  Example
//
//  Created by Ahmad Athaullah on 9/8/16.
//  Copyright © 2016 Ahmad Athaullah. All rights reserved.
//

import UIKit

@objc public protocol QiscusConfigDelegate {
    func qiscusFailToConnect(_ withMessage:String)
    func qiscusConnected()
    @objc optional func failToRegisterQiscusPushNotification(withError error:String?, andDeviceToken token:String)
    @objc optional func didRegisterQiscusPushNotification(withDeviceToken token:String)
}
