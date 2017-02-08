//
//  QDate.swift
//  Example
//
//  Created by Ahmad Athaullah on 2/7/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

extension Date {
//    extension NSDate {
//        
//        func offsetFrom(date:NSDate) -> String {
//            
//            let dayHourMinuteSecond: NSCalendarUnit = [.Day, .Hour, .Minute, .Second]
//            let difference = NSCalendar.currentCalendar().components(dayHourMinuteSecond, fromDate: date, toDate: self, options: [])
//            
//            let seconds = "\(difference.second)s"
//            let minutes = "\(difference.minute)m" + " " + seconds
//            let hours = "\(difference.hour)h" + " " + minutes
//            let days = "\(difference.day)d" + " " + hours
//            
//            if difference.day    > 0 { return days }
//            if difference.hour   > 0 { return hours }
//            if difference.minute > 0 { return minutes }
//            if difference.second > 0 { return seconds }
//            return ""
//        }
//        
//    }
    var isToday:Bool{
        get{
            if Calendar.current.isDateInToday(self){
                return true
            }
            return false
        }
    }
    var isYesterday:Bool{
        get{
            if Calendar.current.isDateInYesterday(self){
                return true
            }
            return false
        }
    }
    func offsetFromInSecond(date:Date) -> Int{
        let differerence = Calendar.current.dateComponents([.second], from: date, to: self)
        if let secondDiff = differerence.second{
            return secondDiff
        }else{
            return 0
        }
    }
    func offsetFromInMinutes(date:Date) -> Int{
        let differerence = Calendar.current.dateComponents([.minute], from: date, to: self)
        if let minuteDiff = differerence.minute{
            return minuteDiff
        }else{
            return 0
        }
    }
    
    func offsetFromInDay(date:Date)->Int{
        let differerence = Calendar.current.dateComponents([.day], from: self, to: date)
        if let dayDiff = differerence.day{
            return dayDiff
        }else{
            return 0
        }
    }
    
    
}

