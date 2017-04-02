//
//  QiscusFile.swift
//  LinkDokter
//
//  Created by Qiscus on 2/24/16.
//  Copyright © 2016 qiscus. All rights reserved.
//

import UIKit
import RealmSwift
import Alamofire
import AlamofireImage
import AVFoundation
import SwiftyJSON

public enum QFileType:Int {
    case media
    case document
    case video
    case audio
    case others
}

public class QiscusFile: NSObject {
    public var fileId:Int = 0
    public var fileURL:String = ""{
        didSet{
            if !self.copyProcess {
                if let fileDB = QiscusFileDB.fileDB(withId: self.fileId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        fileDB.fileURL = self.fileURL
                    }
                    if self.isUploaded && (self.fileType == .video || self.fileType == .media) && self.fileMiniThumbPath == ""{
                        DispatchQueue.main.async {
                            self.downloadMiniImage()
                        }
                    }
                }
            }
        }
    }
    public var fileLocalPath:String = ""{
        didSet{
            if !self.copyProcess {
                if let fileDB = QiscusFileDB.fileDB(withId: self.fileId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        fileDB.fileLocalPath = self.fileLocalPath
                    }
                }
            }
        }
    }
    public var fileThumbPath:String = ""{
        didSet{
            if !self.copyProcess {
                if let fileDB = QiscusFileDB.fileDB(withId: self.fileId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        fileDB.fileThumbPath = self.fileThumbPath
                    }
                }
            }
        }
    }
    public var fileTopicId:Int = 0{
        didSet{
            if !self.copyProcess {
                if let fileDB = QiscusFileDB.fileDB(withId: self.fileId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        fileDB.fileTopicId = self.fileTopicId
                    }
                }
            }
        }
    }
    public var fileCommentId:Int = 0{
        didSet{
            if !self.copyProcess {
                if let fileDB = QiscusFileDB.fileDB(withId: self.fileId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        fileDB.fileCommentId = self.fileCommentId
                    }
                }
            }
        }
    }
    public var isDownloading:Bool = false{
        didSet{
            if !self.copyProcess {
                if let fileDB = QiscusFileDB.fileDB(withId: self.fileId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        fileDB.isDownloading = self.isDownloading
                    }
                }
            }
        }
    }
    public var isUploading:Bool = false {
        didSet{
            if !self.copyProcess {
                if let fileDB = QiscusFileDB.fileDB(withId: self.fileId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        fileDB.isUploading = self.isUploading
                    }
                }
            }
        }
    }
    public var downloadProgress:CGFloat = 0{
        didSet{
            if !self.copyProcess {
                if let fileDB = QiscusFileDB.fileDB(withId: self.fileId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        fileDB.downloadProgress = self.downloadProgress
                    }
                }
            }
        }
    }
    public var uploadProgress:CGFloat = 0{
        didSet{
            if !self.copyProcess {
                if let fileDB = QiscusFileDB.fileDB(withId: self.fileId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        fileDB.uploadProgress = self.uploadProgress
                    }
                }
            }
        }
    }
    public var uploaded = true{
        didSet{
            if !self.copyProcess {
                if let fileDB = QiscusFileDB.fileDB(withId: self.fileId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        fileDB.uploaded = self.uploaded
                    }
                }
            }
        }
    }
    public var fileMiniThumbPath:String = ""{
        didSet{
            if !self.copyProcess {
                if let fileDB = QiscusFileDB.fileDB(withId: self.fileId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        fileDB.fileMiniThumbPath = self.fileMiniThumbPath
                    }
                }
            }
        }
    }
    public var fileMimeType:String = ""{
        didSet{
            if !self.copyProcess {
                if let fileDB = QiscusFileDB.fileDB(withId: self.fileId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        fileDB.fileMimeType = self.fileMimeType
                    }
                }
            }
        }
    }
    
    public var copyProcess = false
    
    var isUploaded:Bool{
        get{
            var check = false
            let regex = "^(http|https)://"
            let url = self.fileURL
            if let range = url.range(of:regex, options: .regularExpression) {
                let result = url.substring(with:range)
                if result != "" {
                    check = true
                }
            }
            return check
        }
    }
    var thumbExist:Bool{
        get{
            var check:Bool = false
            let checkValidation = FileManager.default
            if (self.fileThumbPath != "" && checkValidation.fileExists(atPath: self.fileThumbPath as String))
            {
                check = true
            }else if (self.fileMiniThumbPath != "" && checkValidation.fileExists(atPath: self.fileMiniThumbPath as String)){
                check = true
            }
            return check
        }
    }
    var localFileExist:Bool{
        get{
            var check:Bool = false
            let checkValidation = FileManager.default
            if (self.fileLocalPath != "" && checkValidation.fileExists(atPath: self.fileLocalPath as String))
            {
                check = true
            }
            return check
        }
    }
    var isOnlyLocalFileExist:Bool{
        get{
            var check:Bool = false
            let checkValidation = FileManager.default
            if (self.fileLocalPath != "" && checkValidation.fileExists(atPath: self.fileLocalPath as String))
            {
                check = true
            }
            return check
        }
    }
    var screenWidth:CGFloat{
        get{
            return UIScreen.main.bounds.size.width
        }
    }
    var screenHeight:CGFloat{
        get{
            return UIScreen.main.bounds.size.height
        }
    }
    
    public var fileExtension:String{
        get{
            return getExtension()
        }
    }
    public var fileName:String{
        get{
            return getFileName()
        }
    }
    public var fileType:QFileType{
        get {
            var type:QFileType = QFileType.others
            if(isMediaFile()){
                type = QFileType.media
            }else if(isDocFile()){
                type = QFileType.document
            }else if(isVideoFile()){
                type = QFileType.video
            }else if isAudioFile() {
                type = QFileType.audio
            }
            return type
        }
    }
    public var qiscus:Qiscus{
        get{
            return Qiscus.sharedInstance
        }
    }
    public func thumbImage()->UIImage?{
        if thumbExist{
            let checkValidation = FileManager.default
            if (self.fileThumbPath != "" && checkValidation.fileExists(atPath: self.fileThumbPath as String))
            {
                if let image = UIImage(contentsOfFile: fileThumbPath){
                    return image
                }
            }else if (self.fileMiniThumbPath != "" && checkValidation.fileExists(atPath: self.fileMiniThumbPath as String)){
                if let image = UIImage(contentsOfFile: fileMiniThumbPath){
                    return image
                }
            }
        }
        return nil
    }
    public func thumbPath()->String{
        if self.fileThumbPath != ""{
            return fileThumbPath
        }else if self.fileMiniThumbPath != ""{
            return self.fileMiniThumbPath
        }
        
        return ""
    }
    
    public class func file(forComment comment: QiscusComment)->QiscusFile?{
        if let fileDB = QiscusFileDB.fileDB(withId: comment.commentFileId){
            return fileDB.file()
        }else if let fileDB = QiscusFileDB.fileDB(withCommentId: comment.commentId){
            return fileDB.file()
        }else{
            return nil
        }
    }
    public class func file(withURL url: String)->QiscusFile?{
        if let fileDB = QiscusFileDB.file(withURL: url){
            return fileDB.file()
        }else{
            return nil
        }
    }
    public class func newFile()->QiscusFile{
        let newDBFile = QiscusFileDB.newFile()
        return newDBFile.file()
    }
    
    // MARK: Additional Methode
    fileprivate func getExtension() -> String{
        var ext = ""
        
        if (self.fileName as String).range(of: ".") != nil{
            let fileNameArr = (self.fileName as String).characters.split(separator: ".")
            ext = String(fileNameArr.last!).lowercased()
        }
        return ext
    }
    public class func getExtension(fromURL url:String) -> String{
        var ext = ""
        if url.range(of: ".") != nil{
            let fileNameArr = url.characters.split(separator: ".")
            ext = String(fileNameArr.last!).lowercased()
            if ext.contains("?"){
                let newArr = ext.characters.split(separator: "?")
                ext = String(newArr.first!).lowercased()
            }
        }
        return ext
    }
    fileprivate func getFileName() ->String{
        var mediaURL:URL?
        var fileName:String? = ""
        if(self.fileLocalPath == ""){
            let remoteURL = self.fileURL.replacingOccurrences(of: " ", with: "%20")
            mediaURL = URL(string: remoteURL)!
            fileName = mediaURL!.lastPathComponent.replacingOccurrences(of: "%20", with: "_")
        }else if(self.fileLocalPath as String).range(of: "/") == nil{
            fileName = self.fileLocalPath as String
        }else{
            let fileLastPath = String(self.fileLocalPath.characters.split(separator: "/").last!)
            fileName = fileLastPath.replacingOccurrences(of: " ", with: "_")
        }
        return fileName!
    }
    fileprivate func isDocFile() -> Bool{
        var check:Bool = false
        let ext = self.getExtension()
        
        if(ext == "pdf" || ext == "pdf_" || ext == "doc" || ext == "docx" || ext == "ppt" || ext == "pptx" || ext == "xls" || ext == "xlsx" || ext == "txt"){
            check = true
        }
        
        return check
    }
    fileprivate func isPdfFile() -> Bool{
        var check:Bool = false
        let ext = self.getExtension()
        
        if(ext == "pdf" || ext == "pdf_"){
            check = true
        }

        return check
    }
    fileprivate func isVideoFile() -> Bool{
        var check:Bool = false
        let ext = self.getExtension()
        
        if(ext == "mov" || ext == "mov_" || ext == "mp4" || ext == "mp4_"){
            check = true
        }
        
        return check
    }
    fileprivate func isAudioFile() -> Bool {
        var check:Bool = false
        let ext = self.getExtension()
        
        if(ext == "m4a" || ext == "m4a_" || ext == "aac" || ext == "aac_" || ext == "mp3" || ext == "mp3_"){
            check = true
        }
        
        return check
    }
    fileprivate func isMediaFile() -> Bool{
        var check:Bool = false
        let ext = self.getExtension()
        
        if(ext == "jpg" || ext == "jpg_" || ext == "png" || ext == "png_" || ext == "gif" || ext == "gif_"){
            check = true
        }
        
        return check
    }
    
    // MARK: - image manipulation
    public func getLocalThumbImage() -> UIImage{
        if let image = UIImage(contentsOfFile: (self.fileThumbPath as String)) {
            return image
        }else{
            return UIImage()
        }
    }
    public func getLocalImage() -> UIImage{
        if let image = UIImage(contentsOfFile: (self.fileLocalPath as String)) {
            return image
        }else{
            return UIImage()
        }
    }
    public class func createThumbImage(_ image:UIImage, fillImageSize:UIImage? = nil)->UIImage{
        let inputImage = image

        if fillImageSize == nil{
            var smallPart:CGFloat = inputImage.size.height
            
            if(inputImage.size.width > inputImage.size.height){
                smallPart = inputImage.size.width
            }
            let ratio:CGFloat = CGFloat(396.0/smallPart)
            let newSize = CGSize(width: (inputImage.size.width * ratio),height: (inputImage.size.height * ratio))
            
            UIGraphicsBeginImageContext(newSize)
            inputImage.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return newImage!
        }else{
            let newImage = UIImage.resizeImage(inputImage, toFillOnImage: fillImageSize!)
            
            return newImage
        }
    }
    public class func resizeImage(_ image:UIImage, toFillSize:CGSize)->UIImage{

        var ratio:CGFloat = 1
        let widthRatio:CGFloat = CGFloat(toFillSize.width/image.size.width)
        let heightRatio:CGFloat = CGFloat(toFillSize.height/image.size.height)
        
        if widthRatio > heightRatio {
            ratio = widthRatio
        }else{
            ratio = heightRatio
        }
        
        let newSize = CGSize(width: (image.size.width * ratio),height: (image.size.height * ratio))
        
        UIGraphicsBeginImageContext(newSize)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
        
    }
    public class func saveFile(_ fileData: Data, fileName: String) -> String {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let directoryPath = "\(documentsPath)/Qiscus"
        if !FileManager.default.fileExists(atPath: directoryPath){
            do {
                try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                Qiscus.printLog(text: error.localizedDescription);
            }
        }
        let path = "\(documentsPath)/Qiscus/\(fileName)"
        
        try? fileData.write(to: URL(fileURLWithPath: path), options: [.atomic])
        
        return path
    }
    public func isLocalFileExist()->Bool{
        var check:Bool = false
        
        let checkValidation = FileManager.default
        
        if (self.fileLocalPath != "" && checkValidation.fileExists(atPath: self.fileLocalPath as String) && checkValidation.fileExists(atPath: self.fileThumbPath as String))
        {
            check = true
        }
        return check
    }
    private func downloadMiniImage(){
        Qiscus.printLog(text: "Downloading miniImage for url \(self.fileURL)")
        
        var thumbMiniPath = self.fileURL.replacingOccurrences(of: "/upload/", with: "/upload/w_30,c_scale/").replacingOccurrences(of: " ", with: "%20")
        let fileExtension = QiscusFile.getExtension(fromURL: thumbMiniPath)
        
        if self.fileType == .video || fileExtension == "gif"{
            let thumbUrlArr = thumbMiniPath.characters.split(separator: ".")
            var newThumbURL = ""
            var i = 0
            for thumbComponent in thumbUrlArr{
                if i == 0{
                    newThumbURL += String(thumbComponent)
                }else if i < (thumbUrlArr.count - 1){
                    newThumbURL += ".\(String(thumbComponent))"
                }else{
                    newThumbURL += ".png"
                }
                i += 1
            }
            thumbMiniPath = newThumbURL
        }
        
        
        Alamofire.request(thumbMiniPath, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil)
            .responseData(completionHandler: { response in
                Qiscus.printLog(text: "download miniImage result: \(response)")
                if let data = response.data {
                    if let image = UIImage(data: data) {
                        var thumbImage = UIImage()
                        let fileName = "ios-miniThumb-\(self.fileId).\(fileExtension)"
                        
                        thumbImage = QiscusFile.resizeImage(image, toFillSize: CGSize(width: 441, height: 396))
                        
                        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
                        let directoryPath = "\(documentsPath)/Qiscus"
                        if !FileManager.default.fileExists(atPath: directoryPath){
                            do {
                                try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: false, attributes: nil)
                            } catch let error as NSError {
                                Qiscus.printLog(text: error.localizedDescription);
                            }
                        }
                        let thumbPath = "\(documentsPath)/Qiscus/\(fileName)"
                        if fileExtension == "jpg" {
                            try? UIImageJPEGRepresentation(thumbImage, 1)!.write(to: URL(fileURLWithPath: thumbPath), options: [.atomic])
                        }else{
                            try? UIImagePNGRepresentation(thumbImage)!.write(to: URL(fileURLWithPath: thumbPath), options: [.atomic])
                        }
                        
                        
                        self.fileMiniThumbPath = thumbPath
                    }
                }
            }).downloadProgress(closure: { progressData in
                let progress = CGFloat(progressData.fractionCompleted)
                DispatchQueue.main.async(execute: {
                    Qiscus.printLog(text: "Download miniImage progress: \(progress)")
                })
            })
    }
}
