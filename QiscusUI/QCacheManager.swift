//
//  QCacheManager.swift
//  QiscusUI
//
//  Created by Rahardyan Bisma on 04/06/18.
//

import Foundation

class QCacheManager {
    private var pref = UserDefaults.standard
    static let shared = QCacheManager()
    private init(){
    }
    
    func cacheImage(image: UIImage, onCommentUniqueId id: String) {
        pref.set(image, forKey: id)
        
    }
    
    func getImage(onCommentUniqueId id: String) -> UIImage? {
        return pref.object(forKey: id) as? UIImage
    }
}
