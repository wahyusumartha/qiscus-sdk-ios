//
//  String+Localization.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 03/05/18.
//

import Foundation

extension String {
    func getLocalize(value: Int) -> String{
        return String(format: NSLocalizedString(self, bundle: Qiscus.bundle, comment: ""), value)
    }
    
    func getLocalize(value: String) -> String{
        return String(format: NSLocalizedString(self, bundle: Qiscus.bundle, comment: ""), value)
    }
    
    func getLocalize() -> String{
        return NSLocalizedString(self, bundle: Qiscus.bundle, comment: "")
    }
}
