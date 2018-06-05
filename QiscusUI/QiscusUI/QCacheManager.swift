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
        let imageData = UIImageJPEGRepresentation(image, 0.8)
        pref.set(imageData, forKey: id)
        
    }
    
    func getImage(onCommentUniqueId id: String) -> UIImage? {
        if let imageData = pref.object(forKey: id) as? Data {
            return UIImage(data: imageData)
        }
        
        return nil
    }
}

