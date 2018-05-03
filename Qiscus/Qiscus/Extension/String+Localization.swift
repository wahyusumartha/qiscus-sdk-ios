//
//  String+Localization.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 03/05/18.
//

import Foundation

extension String {
    static func getLocalize(key: String, value: Int) -> String{
        return String(format: NSLocalizedString(key, tableName: nil, bundle: Qiscus.bundle, value: "", comment: ""), value)
    }
    
    static func getLocalize(key: String, value: String) -> String{
        return String(format: NSLocalizedString(key, tableName: nil, bundle: Qiscus.bundle, value: "", comment: ""), value)
    }
    
    static func getLocalize(key: String) -> String{
        return NSLocalizedString(key, tableName: nil, bundle: Qiscus.bundle, value: "", comment: "")
    }
}
