//
//  QiscusAssetsConfiguration.swift
//  Example
//
//  Created by Ahmad Athaullah on 5/9/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

public class QiscusAssetsConfiguration: NSObject {
    static var shared = QiscusAssetsConfiguration()
    
    public var emptyChat:UIImage? = Qiscus.image(named: "empty_messages")?.withRenderingMode(.alwaysTemplate)
    
}
