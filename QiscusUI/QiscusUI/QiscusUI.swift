//
//  QiscusUI.swift
//  QiscusUI
//
//  Created by Rahardyan Bisma on 25/05/18.
//

import Foundation

var QiscusRequestThread = DispatchQueue(label: "com.qiscus.request", attributes: .concurrent)
public class QiscusUI {
    static var cachedVC: [String: QChatVC] = [:]
    class var bundle:Bundle{
        get{
            let podBundle = Bundle(for: QiscusUI.self)
            
            if let bundleURL = podBundle.url(forResource: "QiscusUI", withExtension: "bundle") {
                return Bundle(url: bundleURL)!
            }else{
                return podBundle
            }
        }
    }
    
    static var disableLocalization: Bool = false
    
    @objc public class func chatView(roomId: String) -> QChatVC {
        if let cachedVC = self.cachedVC[roomId] {
            return cachedVC
        } else {
            let chatView = QChatVC()
            chatView.roomId = roomId
            chatView.hidesBottomBarWhenPushed = true
            
            self.cachedVC[roomId] = chatView
            return chatView
        }
    }
    
    @objc public class func image(named name:String)->UIImage?{
        return UIImage(named: name, in: QiscusUI.bundle, compatibleWith: nil)?.localizedImage()
    }
}
