//
//  String+Localization.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 03/05/18.
//

import Foundation

extension String {
    func getLocalize(value: Int) -> String {
        var bundle = QiscusUI.bundle
        
        if QiscusUI.disableLocalization {
            let path = bundle.path(forResource: "en", ofType: "lproj")
            bundle = Bundle(path: path!)!
        }
        
        return String(format: NSLocalizedString(self, bundle: bundle, comment: ""), value)
    }
    
    func getLocalize(value: String) -> String {
        var bundle = QiscusUI.bundle
        
        if QiscusUI.disableLocalization {
            let path = bundle.path(forResource: "en", ofType: "lproj")
            bundle = Bundle(path: path!)!
        }
        
        return String(format: NSLocalizedString(self, bundle: bundle, comment: ""), value)
    }
    
    func getLocalize() -> String {
        var bundle = QiscusUI.bundle
        
        if QiscusUI.disableLocalization {
            let path = bundle.path(forResource: "en", ofType: "lproj")
            bundle = Bundle(path: path!)!
        }
        
        return NSLocalizedString(self, bundle: bundle, comment: "")
    }
}

