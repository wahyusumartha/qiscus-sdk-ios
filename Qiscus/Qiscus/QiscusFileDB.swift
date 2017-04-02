//
//  QiscusFileDB.swift
//  Example
//
//  Created by Ahmad Athaullah on 4/1/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
import RealmSwift

class QiscusFileDB: Object {
    public dynamic var fileId:Int = 0
    public dynamic var fileURL:String = ""
    public dynamic var fileLocalPath:String = ""
    public dynamic var fileThumbPath:String = ""
    public dynamic var fileTopicId:Int = 0
    public dynamic var fileCommentId:Int = 0
    public dynamic var isDownloading:Bool = false
    public dynamic var isUploading:Bool = false
    public dynamic var downloadProgress:CGFloat = 0
    public dynamic var uploadProgress:CGFloat = 0
    public dynamic var uploaded = true
    public dynamic var fileMiniThumbPath:String = ""
    public dynamic var fileMimeType:String = ""

    // MARK: - Primary Key
    override public class func primaryKey() -> String {
        return "fileId"
    }
    
    public class func getLastId() -> Int{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let RetNext = realm.objects(QiscusFileDB.self).sorted(byKeyPath: "fileId")
        
        if RetNext.count > 0 {
            let last = RetNext.last!
            return last.fileId
        } else {
            return 0
        }
    }
    
    // MARK: - QiscusFileDB
    public class func fileDB(withId fileId:Int)->QiscusFileDB?{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let searchQuery:NSPredicate = NSPredicate(format: "fileId == \(fileId)")
        let RetNext = realm.objects(QiscusFileDB.self).filter(searchQuery)
        
        if RetNext.count > 0 {
            return RetNext.last!
        } else {
            return nil
        }
    }
    public class func fileDB(withCommentId commentId:Int)->QiscusFileDB?{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        
        let query = "fileCommentId == \(commentId)"
        let searchQuery = NSPredicate(format: query)
        let fileData = realm.objects(QiscusFileDB.self).filter(searchQuery)
        
        if fileData.count > 0 {
            return fileData.first!
        }else{
            return nil
        }
    }
    public class func file(withURL url: String)->QiscusFileDB?{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        
        let searchQuery:NSPredicate = NSPredicate(format: "fileURL == '\(url)'")
        let fileData = realm.objects(QiscusFileDB.self).filter(searchQuery)
        
        if(fileData.count == 0){
            return nil
        }else{
            return fileData.first!
        }
    }

    // MARK: - QiscusFile
    public func file()->QiscusFile{
        let newFile = QiscusFile()
        newFile.copyProcess = true
        newFile.fileId = self.fileId
        newFile.fileURL = self.fileURL
        newFile.fileLocalPath = self.fileLocalPath
        newFile.fileThumbPath = self.fileThumbPath
        newFile.fileTopicId = self.fileTopicId
        newFile.fileCommentId = self.fileCommentId
        newFile.isDownloading = self.isDownloading
        newFile.isUploading = self.isUploading
        newFile.downloadProgress = self.downloadProgress
        newFile.uploadProgress = self.uploadProgress
        newFile.uploaded = self.uploaded
        newFile.fileMiniThumbPath = self.fileMiniThumbPath
        newFile.copyProcess = false
        return newFile
    }
    
    // MARK: - addNewData
    public class func newFile()->QiscusFileDB{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        let newFile = QiscusFileDB()
        try! realm.write {
            newFile.fileId = QiscusFileDB.getLastId() + 1
            realm.add(newFile)
        }
        return newFile
    }
}
