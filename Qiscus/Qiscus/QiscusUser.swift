//
//  QiscusUser.swift
//  LinkDokter
//
//  Created by Qiscus on 2/24/16.
//  Copyright © 2016 qiscus. All rights reserved.
//

import UIKit
import RealmSwift
import Alamofire
import AlamofireImage
import SwiftyJSON

open class QiscusUser: Object {
    // MARK: - Class Attribute
    open dynamic var localId:Int = 0
    open dynamic var userId:Int = 0
    open dynamic var userAvatarURL:String = ""
    open dynamic var userAvatarLocalPath:String = ""
    open dynamic var userNameAs:String = ""
    open dynamic var userEmail:String = ""
    open dynamic var userFullName:String = ""
    open dynamic var userAvailability:Bool = true
    open dynamic var userLastSeen:Double = 0
    open dynamic var isOffline:Bool = true

    // MARK: - Primary Key
    override open class func primaryKey() -> String {
        return "localId"
    }
//    var avatar:UIImage?{
//        get{
//            if QiscusHelper.isFileExist(inLocalPath: self.userAvatarLocalPath){
//                if let image =  UIImage(contentsOfFile: self.userAvatarLocalPath){
//                    return image
//                }else{
//                    self.downloadAvatar()
//                    return nil
//                }
//            }else{
//                self.downloadAvatar()
//                return nil
//            }
//        }
//    }
    var isSelf:Bool{
        get{
            if self.userEmail == QiscusConfig.sharedInstance.USER_EMAIL{
                return true
            }
            return false
        }
    }
    var isOnline:Bool{
        get{
            return !isOffline
        }
    }
    
    var lastSeenString:String{
        get{
            var result = ""
            
            let date = Date(timeIntervalSince1970: userLastSeen)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d MMMM yyyy"
            let dateString = dateFormatter.string(from: date)
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            let timeString = timeFormatter.string(from: date)
            
            let now = Date()
            
            let secondDiff = now.offsetFromInSecond(date: date)
            let minuteDiff = Int(secondDiff/60)
            let hourDiff = Int(minuteDiff/60)
            
            if minuteDiff < 2 {
                result = "a minute ago"
            }
            else if minuteDiff < 60 {
                result = "\(Int(secondDiff/60)) minute ago"
            }else if hourDiff == 1{
                result = "an hour ago"
            }else if hourDiff < 6 {
                result = "\(hourDiff) hours ago"
            }
            else if date.isToday{
                result = "today at \(timeString)"
            }
            else if date.isYesterday{
                result = "yesterday at \(timeString)"
            }
            else{
                result = "\(dateString) at \(timeString)"
            }
            
            return result
        }
    }
    // MARK: - UpdaterMethode
    open func userId(_ value:Int){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        try! realm.write {
            self.userId = value
        }
    }
    open func userAvatarURL(_ value:String){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        try! realm.write {
            self.userAvatarURL = value
        }
    }
    open func userAvatarLocalPath(_ value:String){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let searchQuery:NSPredicate = NSPredicate(format: "userEmail == '\(self.userEmail)'")
        let userData = realm.objects(QiscusUser.self).filter(searchQuery)
        
        if let user = userData.first{
            if user.userAvatarLocalPath != value{
                try! realm.write {
                    user.userAvatarLocalPath = value
                }
                
                if let presenterDelegate = QiscusDataPresenter.shared.delegate {
                    let copyUser = QiscusUser.copyUser(user: user)
                    presenterDelegate.dataPresenter(didChangeUser: copyUser, onUserWithEmail: copyUser.userEmail)
                }
            }
        }
    }
    public func updateUserNameAs(_ value:String){
        if userNameAs != value {
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            let searchQuery:NSPredicate = NSPredicate(format: "userEmail == '\(self.userEmail)'")
            let userData = realm.objects(QiscusUser.self).filter(searchQuery)
            
            if let user = userData.first{
                try! realm.write {
                    user.userNameAs = value
                }
            }
        }
    }
    open func userEmail(_ value:String){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        try! realm.write {
            self.userEmail = value
        }
    }
    open func userFullName(_ value:String){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        try! realm.write {
            self.userFullName = value
        }
    }

    open func updateLastSeen(_ timeToken:Double = 0){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        
        let searchQuery:NSPredicate = NSPredicate(format: "userEmail == '\(self.userEmail)'")
        let userData = realm.objects(QiscusUser.self).filter(searchQuery)
        
        if let user = userData.first{
            if timeToken == 0 {
                try! realm.write {
                    user.userLastSeen = Double(Date().timeIntervalSince1970)
                }
                user.updateStatus(isOnline: true)
            }else{
                if timeToken > userLastSeen{
                    try! realm.write {
                        user.userLastSeen = timeToken
                    }
                }
            }
        }
    }
    class func copyUser(user: QiscusUser)->QiscusUser{
        let newUser = QiscusUser()
        newUser.localId = user.localId
        newUser.userId = user.userId
        newUser.userAvatarURL = user.userAvatarURL
        newUser.userAvatarLocalPath = user.userAvatarLocalPath
        newUser.userNameAs = user.userNameAs
        newUser.userEmail = user.userEmail
        newUser.userFullName = user.userFullName
        newUser.userAvailability = user.userAvailability
        newUser.userLastSeen = user.userLastSeen
        newUser.isOffline = user.isOffline
        return newUser
    }
    open func updateStatus(isOnline online:Bool){
        let changed = (isOnline != online)
        if changed{
            let realm = try! Realm(configuration: Qiscus.dbConfiguration)
            let searchQuery:NSPredicate = NSPredicate(format: "userEmail == '\(self.userEmail)'")
            let userData = realm.objects(QiscusUser.self).filter(searchQuery)
            
            if let user = userData.first {
                try! realm.write {
                    user.isOffline = !online
                }
//                if let commentDelegate = QiscusCommentClient.sharedInstance.commentDelegate{
//                    if QiscusMe.sharedInstance.email != user.userEmail{
//                        let copyUser = QiscusUser.copyUser(user: user)
//                        DispatchQueue.main.async {
//                            commentDelegate.didChangeUserStatus?(withUser: copyUser)
//                        }
//                    }
//                }
            }
        }
    }
    // MARK: - Getter Methode
    open func getLastId() -> Int{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let RetNext = realm.objects(QiscusUser.self).sorted(byKeyPath: "localId")
        
        if RetNext.count > 0 {
            let last = RetNext.last!
            return last.localId
        } else {
            return 0
        }
    }
    
    open class func getAllUser()->[QiscusUser]?{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let userData = realm.objects(QiscusUser.self)
        var users = [QiscusUser]()
        if(userData.count == 0){
            return nil
        }else{
            for user in userData{
                users.append(user)
            }
            return users
        }
    }
    open class func getUserWithEmail(_ email:String)->QiscusUser?{ //  
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        
        let searchQuery:NSPredicate = NSPredicate(format: "userEmail == '\(email)'")
        let userData = realm.objects(QiscusUser.self).filter(searchQuery)
        
        if(userData.count == 0){
            return nil
        }else{
            return QiscusUser.copyUser(user: userData.first!)
        }
    }

    open func updateUserFullName(_ fullName: String){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        
        let searchQuery:NSPredicate = NSPredicate(format: "userEmail == '\(self.userEmail)'")
        let userData = realm.objects(QiscusUser.self).filter(searchQuery)
        
        if(userData.count == 0){
            self.userFullName = fullName
        }else{
            let user = userData.first!
            try! realm.write {
                user.userFullName = fullName
            }
        }
    }
    open func updateUserAvatarURL(_ avatarURL: String){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        
        let searchQuery:NSPredicate = NSPredicate(format: "userEmail == '\(self.userEmail)'")
        let userData = realm.objects(QiscusUser.self).filter(searchQuery)
        
        if(userData.count > 0){
            let user = userData.first!
            if user.userAvatarURL != avatarURL{
                try! realm.write {
                    user.userAvatarURL = avatarURL
                    user.userAvatarLocalPath = ""
                }
                user.downloadAvatar()
            }
        }
    }
    open func getUserFromRoomJSON(_ json:JSON)->QiscusUser{
        var user = QiscusUser()
        user.userId = json["id"].intValue
        user.userAvatarURL = json["image"].stringValue
        user.userAvatarLocalPath = ""
        user.userEmail = json["email"].stringValue
        user.userFullName = json["fullname"].stringValue
        
        user = user.saveUser()

        return user
    }
    open func saveUser()->QiscusUser{ // 
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        
        let searchQuery:NSPredicate = NSPredicate(format: "userEmail == '\(self.userEmail)'")
        let userData = realm.objects(QiscusUser.self).filter(searchQuery)

        if(userData.count == 0){
            try! realm.write {
                self.localId = getLastId() + 1
                realm.add(self)
            }
            let thisUser = QiscusUser.copyUser(user: self)
            DispatchQueue.global().async {
                thisUser.downloadAvatar()
            }
            let userEmail = self.userEmail
            
            Qiscus.shared.mqtt?.subscribe("u/\(userEmail)/s", qos: .qos1)

            return self
        }else{
            let user = userData.first!
            if(user.userAvatarURL != self.userAvatarURL){
                try! realm.write {
                    user.userAvatarURL = self.userAvatarURL
                }
                DispatchQueue.global().async {
                    self.downloadAvatar()
                }
            }
            try! realm.write {
                user.userId = self.userId
                user.userFullName = self.userFullName
            }
            return user
        }
    }
    fileprivate func getFileName() ->String{
        let mediaURL:URL = URL(string: self.userAvatarURL as String)!
        let fileName = mediaURL.lastPathComponent.replacingOccurrences(of: "%20", with: "_")
        return fileName
    }
    
    open class func setUnavailableAll(){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        
        let searchQuery:NSPredicate = NSPredicate(format: "userAvailability == true")
        let userData = realm.objects(QiscusUser.self).filter(searchQuery)
        
        if userData.count > 0{
            for user in userData{
                user.userAvailability = false
            }
        }
    }
    public func downloadAvatar(){
        let user = QiscusUser.copyUser(user: self)
        if user.userAvatarURL != ""{
            if !Qiscus.qiscusDownload.contains("\(user.userAvatarURL):user:\(user.userId)"){
                let checkURL = "\(user.userAvatarURL):user:\(user.userId)"
                Qiscus.qiscusDownload.append(checkURL)
                
                Alamofire.request(user.userAvatarURL, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil)
                    .responseData(completionHandler: { response in
                        if let data = response.data {
                            if let image = UIImage(data: data) {
                                var thumbImage = UIImage()
                                
                                let fileExt = QiscusFile.getExtension(fromURL: user.userAvatarURL)
                                let fileName = "ios-avatar-\(user.localId).\(fileExt)"
                                
                                if fileExt == "gif" || fileExt == "gif_"{
                                    thumbImage = image
                                }else if fileExt == "jpg" || fileExt == "jpg_" || fileExt == "png" || fileExt == "png_" {
                                    thumbImage = user.createThumbAvatar(image)
                                }
                                
                                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
                                let directoryPath = "\(documentsPath)/Qiscus"
                                if !FileManager.default.fileExists(atPath: directoryPath){
                                    do {
                                        try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: false, attributes: nil)
                                    } catch let error as NSError {
                                        Qiscus.printLog(text: error.localizedDescription);
                                    }
                                }
                                let thumbPath = "\(directoryPath)/\(fileName)"
                                
                                if fileExt == "png" || fileExt == "png_" {
                                    try? UIImagePNGRepresentation(thumbImage)!.write(to: URL(fileURLWithPath: thumbPath), options: [.atomic])
                                } else if fileExt == "jpg" || fileExt == "jpg_"{
                                    try? UIImageJPEGRepresentation(thumbImage, 1.0)!.write(to: URL(fileURLWithPath: thumbPath), options: [.atomic])
                                } else if fileExt == "gif" || fileExt == "gif_"{
                                    try? data.write(to: URL(fileURLWithPath: thumbPath), options: [.atomic])
                                }
                                DispatchQueue.main.async(execute: {
                                    user.userAvatarLocalPath(thumbPath)
                                })
                                var i = 0
                                var index:Int?
                                for downloadURL in Qiscus.qiscusDownload{
                                    if downloadURL == checkURL{
                                        index = i
                                        break
                                    }
                                    i += 1
                                }
                                if index != nil{
                                    Qiscus.qiscusDownload.remove(at: index!)
                                }
                            }else{
                                var i = 0
                                var index:Int?
                                for downloadURL in Qiscus.qiscusDownload{
                                    if downloadURL == checkURL{
                                        index = i
                                        break
                                    }
                                    i += 1
                                }
                                if index != nil{
                                    Qiscus.qiscusDownload.remove(at: index!)
                                }
                            }
                        }else{
                            var i = 0
                            var index:Int?
                            for downloadURL in Qiscus.qiscusDownload{
                                if downloadURL == checkURL{
                                    index = i
                                    break
                                }
                                i += 1
                            }
                            if index != nil{
                                Qiscus.qiscusDownload.remove(at: index!)
                            }
                        }
                    }).downloadProgress(closure: { progressData in
                        let _ = CGFloat(progressData.fractionCompleted)
                    })
                
            }
        }
    }
    fileprivate func createThumbAvatar(_ image:UIImage)->UIImage{
        var smallPart:CGFloat = image.size.height
        
        if(image.size.width > image.size.height){
            smallPart = image.size.width
        }
        let ratio:CGFloat = CGFloat(100.0/smallPart)
        let newSize = CGSize(width: (image.size.width * ratio),height: (image.size.height * ratio))
        
        UIGraphicsBeginImageContext(newSize)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
