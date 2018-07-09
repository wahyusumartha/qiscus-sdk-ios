//
//  QFilePublic.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 06/07/18.
//

import Foundation
import RealmSwift

extension QFile {
    public class func file(withURL url:String) -> QFile?{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        var file:QFile? = nil
        let data =  realm.objects(QFile.self).filter("url == '\(url)'")
        
        if data.count > 0{
            file = data.first!
        }
        return file
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
    public class func saveFile(_ fileData: Data, fileName: String) -> String {
        let path = QFileManager.saveFile(withData: fileData, fileName: fileName, type: .comment)
        QFileManager.clearTempDirectory()
        return path
    }
    public class func getURL(fromString text:String) -> String{
        let component1 = text.components(separatedBy: "[file]")
        let component2 = component1.last!.components(separatedBy: "[/file]")
        let mediaUrlString = component2.first?.trimmingCharacters(in: CharacterSet.whitespaces)
        return mediaUrlString!.replacingOccurrences(of: " ", with: "%20")
    }
    internal func updateLocalPath(path:String){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        try! realm.write {
            self.localPath = localPath
        }
    }
    public func saveFile(withData data:Data)->String{
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        let localPath = QFileManager.saveFile(withData: data, fileName: self.filename, type: .comment)
        try! realm.write {
            self.localPath = localPath
        }
        return localPath
    }
    public func updatePages(withTotalPage pages:Int){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        
        if self.pages != pages {
            try! realm.write {
                self.pages = pages
            }
        }
    }
    public func updateSize(withSize size:Double){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        
        if self.size != size {
            try! realm.write {
                self.size = size
            }
        }
    }
    public func saveThumbImage(withImage image:UIImage){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        var data = Data()
        var ext = "jpg"
        let imageSize = image.size
        var bigPart = CGFloat(0)
        if(imageSize.width > imageSize.height){
            bigPart = imageSize.width
        }else{
            bigPart = imageSize.height
        }
        
        var compressVal = CGFloat(1)
        
        if(bigPart > 2000){
            compressVal = 2000 / bigPart
        }
        if let imageData = UIImageJPEGRepresentation(image, compressVal) {
            data = imageData
        }else{
            data = UIImagePNGRepresentation(image)!
            ext = "png"
        }
        
        let localPath = QFileManager.saveFile(withData: data, fileName: "thumb-\(self.filename).\(ext)", type: .comment)
        try! realm.write {
            self.localThumbPath = localPath
        }
    }
    public func saveMiniThumbImage(withImage image:UIImage){
        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
        realm.refresh()
        var data = Data()
        if let imageData = UIImagePNGRepresentation(image){
            data = imageData
        }else{
            data = UIImageJPEGRepresentation(image, 1)!
        }
        let localPath = QFileManager.saveFile(withData: data, fileName: "minithumb-\(self.filename)", type: .comment)
        try! realm.write {
            self.localMiniThumbPath = localPath
        }
    }
}
