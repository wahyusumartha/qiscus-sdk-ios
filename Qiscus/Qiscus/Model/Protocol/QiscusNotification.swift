//
//  QiscusNotification.swift
//  Example
//
//  Created by Ahmad Athaullah on 9/12/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

public class QiscusNotification: NSObject {
    static let nc = NotificationCenter.default
    static let GOT_NEW_COMMENT = NSNotification.Name("qiscus_gotNewComment")
    static let USER_TYPING = NSNotification.Name("qiscus_userTyping")

    public class func publish(gotNewComment comment:QComment){
        let userInfo = ["comment" : comment]
        QiscusNotification.nc.post(name: GOT_NEW_COMMENT, object: nil, userInfo: userInfo)
    }
    
    public class func publish(userTyping user:QUser?){
        var userInfo: [AnyHashable: Any]?
        if user != nil {
         userInfo = ["user" : user!]
        }
        QiscusNotification.nc.post(name: USER_TYPING, object: nil, userInfo: userInfo)
    }
}
