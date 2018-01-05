//
//  QiscusErrorCode.swift
//  Qiscus
//
//  Created by qiscus on 05/01/18.
//  Copyright © 2018 Ashari Juang. All rights reserved.
//

import UIKit

public enum QiscusErrorCode: Int {
    case ErrorNonAuthorized = 400301
    case ErrorTokenExpired  = 400302
    
    case ErrorUnexpected    = 500100
}
