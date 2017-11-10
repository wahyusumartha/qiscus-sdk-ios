//
//  QiscusService.swift
//  Qiscus
//
//  Created by Ahmad Athaullah on 10/11/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import Alamofire

internal class QiscusService: NSObject {
    static let session: SessionManager = {
        // work
        let configuration = URLSessionConfiguration.default
        return SessionManager(configuration: configuration)
    }()

    fileprivate override init(){}
    
}
