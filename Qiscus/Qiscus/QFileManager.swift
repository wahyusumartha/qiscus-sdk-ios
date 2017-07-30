//
//  QFileManager.swift
//  Example
//
//  Created by Ahmad Athaullah on 7/30/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import Foundation
@objc public enum QDirectoryType:Int{
    case comment
    case user
    case room
}
internal class QFileManager:NSObject{
    private class func directoryPath(forDirectory directory:QDirectoryType)->String{
        var dir = ""
        switch directory {
        case .comment:
            dir = "comment"
            break
        case .room:
            dir = "room"
            break
        case .user:
            dir = "user"
            break
        default:
            break
        }
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let qiscusPath = "\(documentsPath)/Qiscus"
        if !FileManager.default.fileExists(atPath: qiscusPath){
            do {
                try FileManager.default.createDirectory(atPath: qiscusPath, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                Qiscus.printLog(text: error.localizedDescription);
            }
        }
        let directoryPath = "\(qiscusPath)/\(dir)"
        if !FileManager.default.fileExists(atPath: qiscusPath){
            do {
                try FileManager.default.createDirectory(atPath: qiscusPath, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                Qiscus.printLog(text: error.localizedDescription);
            }
        }
        return directoryPath
    }
    internal class func saveFile(withData fileData: Data, fileName: String, type:QDirectoryType)->String{
        let directoryPath = QFileManager.directoryPath(forDirectory: type)
        try? fileData.write(to: URL(fileURLWithPath: directoryPath), options: [.atomic])
    }
    public class func isFileExist(inLocalPath path:String)->Bool{
        var check:Bool = false
        
        let checkValidation = FileManager.default
        
        if (path != "" && checkValidation.fileExists(atPath:path))
        {
            check = true
        }
        return check
    }
}
