//
//  QUser.swift
//  Example
//
//  Created by Ahmad Athaullah on 7/5/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import Foundation
import RealmSwift

@objc public protocol QUserDelegate {
    @objc optional func user(didChangeName fullname:String)
    @objc optional func user(didChangeAvatarURL avatarURL:String)
    @objc optional func user(didChangeAvatar avatar:UIImage)
    @objc optional func user(didChangeLastSeen lastSeen:Double)
}
@objc public enum QUserPresence:Int {
    case offline,online
}
public class QUser:Object {
    static var cache = [String: QUser]()
    
    @objc public dynamic var email:String = ""
    @objc public dynamic var id:Int = 0
    @objc public dynamic var avatarURL:String = ""
    @objc public dynamic var storedName:String = ""
    @objc public dynamic var definedName:String = ""
    @objc public dynamic var lastSeen:Double = 0
    @objc internal dynamic var rawPresence:Int = 0
    @objc internal dynamic var avatarData:Data?
    
    public var cachedAvatar:UIImage?
    
    override public static func primaryKey() -> String? {
        return "email"
    }
    
    
    public var fullname:String{
        if self.definedName != "" {
            return self.definedName.capitalized
        }else{
            return self.storedName.capitalized
        }
    }
    public var presence:QUserPresence {
        get{
            return QUserPresence(rawValue: self.rawPresence)!
        }
    }
    public var avatar:UIImage?{
        get{
            if let data = self.avatarData {
                if let image = UIImage(data: data) {
                    return image
                }
            }
            return nil
        }
    }
    public var delegate:QUserDelegate?
    
    public var lastSeenString:String{
        get{
            if self.lastSeen == 0 {
                return ""
            }else{
                var result = ""
                let date = Date(timeIntervalSince1970: self.lastSeen)
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
                
                if secondDiff < 60 {
                    result = "FEW_SECOND_AGO".getLocalize()
                }
                else if minuteDiff == 1 {
                    result = "A_MINUTE_AGO".getLocalize()
                }
                else if minuteDiff < 60 {
                    result = "MINUTES_AGO".getLocalize(value: Int(secondDiff/60))
                }else if hourDiff == 1{
                    result = "AN_HOUR_AGO".getLocalize()
                }else if hourDiff < 6 {
                    result = "HOURS_AGO".getLocalize(value: hourDiff)
                }
                else if date.isToday{
                    result = "HOURS_AGO".getLocalize(value: timeString)
                }
                else if date.isYesterday{
                    result = "YESTERDAY_AT".getLocalize(value: timeString)
                }
                else{
                    result = "\(dateString) " + "AT".getLocalize() + " \(timeString)"
                }
                
                return result
            }
        }
    }
    
    // MARK: - Unstored properties
    override public static func ignoredProperties() -> [String] {
        return ["cachedAvatar","delegate"]
    }
    
    
    
    
    
    
}
