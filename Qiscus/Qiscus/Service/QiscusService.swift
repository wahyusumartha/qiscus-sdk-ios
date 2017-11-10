//
//  QiscusService.swift
//  Qiscus
//
//  Created by Ahmad Athaullah on 10/11/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import Alamofire

internal class QiscusService: NSObject {
    static let shared = QiscusService()
    static var manager: SessionManager {
        get{
            return QiscusService.shared.request()
        }
    }
    fileprivate override init(){}
    
    func request()->SessionManager{
        let configuration = URLSessionConfiguration.default
        let manager = Alamofire.SessionManager(configuration: configuration)
        return manager
    }
}
