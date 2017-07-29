//
//  QiscusHelper.swift
//  QiscusSDK
//
//  Created by Ahmad Athaullah on 7/22/16.
//  Copyright © 2016 Ahmad Athaullah. All rights reserved.
//

import UIKit

open class QiscusIndexPathData: NSObject{
    open var row = 0
    open var section = 0
    open var newGroup:Bool = false
}
open class QiscusSearchIndexPathData{
    open var row = 0
    open var section = 0
    open var found:Bool = false
}
open class QCommentIndexPath{
    open var row = 0
    open var section = 0
}
open class QiscusHelper: NSObject {
    class func screenWidth()->CGFloat{
        return UIScreen.main.bounds.size.width
    }
    class func screenHeight()->CGFloat{
        return UIScreen.main.bounds.size.height
    }
    class func statusBarSize()->CGRect{
        return UIApplication.shared.statusBarFrame
    }
    class var thisDateString:String{
        get{
            let date = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d MMMM yyyy"
            
            return dateFormatter.string(from: date)
        }
    }
    
    open class func isFileExist(inLocalPath path:String)->Bool{
        var check:Bool = false
        
        let checkValidation = FileManager.default
        
        if (path != "" && checkValidation.fileExists(atPath:path))
        {
            check = true
        }
        return check
    }
    open class func getFirstLinkInString(text:String)->String?{
        let pattern = "((?:http|https)://)?(?:www\\.)?([a-zA-Z0-9./]+[.][a-zA-Z0-9/]{2,3})+([a-zA-Z0-9./-]+)?((\\?)+[a-zA-Z0-9./-_&]*)*"
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options(rawValue: 0))
            let nsstr = text as NSString
            let all = NSRange(location: 0, length: nsstr.length)
            var matches = [String]()
            regex.enumerateMatches(in: text, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: all, using: { (result, flags, _) in
                matches.append(nsstr.substring(with: result!.range))
            })
            if matches.count > 0 {
                return matches[0]
            }else{
                return nil
            }
        } catch {
            return nil
        }
    }
}
