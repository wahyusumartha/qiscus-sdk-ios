//
//  QiscusComment.swift
//
//  Created by Qiscus on 2/24/16.
//  Copyright © 2016 qiscus. All rights reserved.
//

import UIKit
import RealmSwift
import Alamofire
import SwiftyJSON

public enum QiscusCommentType:Int {
    case text
    case attachment
    case postback
    case account
    case reply
    case system
}
@objc public enum QiscusCommentStatus:Int{
    case sending
    case sent
    case delivered
    case read
    case failed
}

public class QiscusComment: NSObject {
    // MARK: - Variable
    public var localId:Int = 0
    public var commentId:Int = 0 {
        didSet{
            if !self.copyProcess {
                if let savedComment = QiscusCommentDB.commentDB(withLocalId: self.localId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        savedComment.commentId = self.commentId
                    }
                }
            }
        }
    }
    public var commentButton:String = "" {
        didSet{
            if !self.copyProcess && self.commentButton != ""{
                if let savedComment = QiscusCommentDB.commentDB(withLocalId: self.localId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        savedComment.commentButton = self.commentButton
                    }
                }
            }
        }
    }
    public var commentText:String = ""{
        didSet{
            if !self.copyProcess {
                if let savedComment = QiscusCommentDB.commentDB(withLocalId: self.localId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    if self.commentIsFile{
                        let fileURL = self.getMediaURL()
                        //let oldURL = self.getURL(fromMessage: oldValue)
                        var file = QiscusFile()
                        if let savedFile = QiscusFile.file(forComment: self) {
                            file = savedFile
                        }else{
                            if fileURL.contains("http"){
                                file = QiscusFile.newFile()
                                file.fileURL = fileURL
                                file.fileCommentId = self.commentId
                            }else{
                                file = QiscusFile.newFile()
                                file.fileURL = fileURL
                                file.fileLocalPath = fileURL
                                file.fileCommentId = self.commentId
                            }
                        }
                        self.commentFileId = file.fileId
                    }
                    try! realm.write {
                        savedComment.commentText = self.commentText
                    }
                }
            }
        }
    }
    public var commentCreatedAt: Double = 0 {
        didSet{
            if !self.copyProcess{
                if let savedComment = QiscusCommentDB.commentDB(withLocalId: self.localId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        savedComment.commentCreatedAt = self.commentCreatedAt
                    }
                }
            }
        }
    }
    public var commentUniqueId: String = "" {
        didSet{
            if !self.copyProcess {
                if let savedComment = QiscusCommentDB.commentDB(withLocalId: self.localId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        savedComment.commentUniqueId = self.commentUniqueId
                    }
                }
            }
        }
    }
    public var commentTopicId:Int = 0 {
        didSet{
            if !self.copyProcess {
                if let savedComment = QiscusCommentDB.commentDB(withLocalId: self.localId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        savedComment.commentTopicId = self.commentTopicId
                    }
                }
            }
        }
    }
    public var commentSenderEmail:String = ""{
        didSet{
            if !self.copyProcess {
                if let savedComment = QiscusCommentDB.commentDB(withLocalId: self.localId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        savedComment.commentSenderEmail = self.commentSenderEmail
                    }
                }
            }
        }
    }
    public var commentFileId:Int = 0 {
        didSet{
            if !self.copyProcess {
                if let savedComment = QiscusCommentDB.commentDB(withLocalId: self.localId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        savedComment.commentFileId = self.commentFileId
                    }
                }
            }
        }
    }
    public var commentStatusRaw:Int = QiscusCommentStatus.sending.rawValue {
        didSet{
            if !self.copyProcess {
                if self.commentStatusRaw != QiscusCommentStatus.delivered.rawValue &&
                    self.commentStatusRaw != QiscusCommentStatus.read.rawValue{
                    if let savedComment = QiscusCommentDB.commentDB(withLocalId: self.localId){
                        if savedComment.commentStatusRaw != self.commentStatusRaw{
                            if self.commentStatusRaw > savedComment.commentStatusRaw || savedComment.commentStatusRaw == QiscusCommentStatus.failed.rawValue{
                                let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                                try! realm.write {
                                    savedComment.commentStatusRaw = self.commentStatusRaw
                                }
                            }
                        }
                    }
                }
                
            }
        }
    }
    public var commentIsSynced:Bool = false {
        didSet{
            if !self.copyProcess {
                if let savedComment = QiscusCommentDB.commentDB(withLocalId: self.localId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        savedComment.commentIsSynced = self.commentIsSynced
                    }
                }
            }
        }
    }
    public var commentBeforeId:Int = 0 {
        didSet{
            if !self.copyProcess {
                if let savedComment = QiscusCommentDB.commentDB(withLocalId: self.localId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        savedComment.commentBeforeId = self.commentBeforeId
                    }
                }
            }
        }
    }
    public var commentCellHeight:CGFloat = 0{
        didSet{
            if !self.copyProcess {
                if let savedComment = QiscusCommentDB.commentDB(withLocalId: self.localId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        savedComment.commentCellHeight = self.commentCellHeight
                    }
                }
            }
        }
    }
    public var commentCellWidth:CGFloat = 0 {
        didSet{
            if !self.copyProcess {
                if let savedComment = QiscusCommentDB.commentDB(withLocalId: self.localId){
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        savedComment.commentCellWidth = self.commentCellWidth
                    }
                }
            }
        }
    }
    public var showLink:Bool = false {
        didSet{
            if !self.copyProcess {
                if let savedComment = QiscusCommentDB.commentDB(withLocalId: self.localId){
                    if self.showLink {
                        if self.commentLink == nil {
                            self.showLink = false
                        }
                    }
                    let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                    try! realm.write {
                        savedComment.showLink = self.showLink
                    }
                }
            }
        }
    }
    public var commentLinkPreviewed:String = "" {
        didSet{
            if !self.copyProcess {
                if let savedComment = QiscusCommentDB.commentDB(withLocalId: self.localId){
                    if savedComment.commentLinkPreviewed != self.commentLinkPreviewed{
                        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                        try! realm.write {
                            savedComment.commentLinkPreviewed = self.commentLinkPreviewed
                        }
                    }
                }
            }
        }
    }
    public var commentFontSize:CGFloat = 0 {
        didSet{
            if !self.copyProcess {
                if let savedComment = QiscusCommentDB.commentDB(withLocalId: self.localId){
                    if savedComment.commentFontSize != self.commentFontSize{
                        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                        try! realm.write {
                            savedComment.commentFontSize = self.commentFontSize
                        }
                    }
                }
            }
        }
    }
    public var commentFontName:String = "" {
        didSet{
            if !self.copyProcess {
                if let savedComment = QiscusCommentDB.commentDB(withLocalId: self.localId){
                    if savedComment.commentFontName != self.commentFontName{
                        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                        try! realm.write {
                            savedComment.commentFontName = self.commentFontName
                        }
                    }
                }
            }
        }
    }
    public var commentType: QiscusCommentType = QiscusCommentType.text {
        didSet{
            if !self.copyProcess {
                if let savedComment = QiscusCommentDB.commentDB(withLocalId: self.localId){
                    if savedComment.commentTypeRaw != self.commentType.rawValue{
                        let realm = try! Realm(configuration: Qiscus.dbConfiguration)
                        try! realm.write {
                            savedComment.commentTypeRaw = self.commentType.rawValue
                        }
                    }
                }
            }
        }
    }
    // MARK: - Process Flag
    public var copyProcess:Bool = false
    
    // MARK: Getter Variable
    open var cellSize:CGSize? {
        get{
            if commentCellHeight > 0 && commentCellWidth > 0 {
                return CGSize(width: commentCellWidth, height: commentCellHeight)
            }else{
                return nil
            }
        }
    }
    open var commentLink:String? {
        get{
            if commentLinkPreviewed != "" {
                return commentLinkPreviewed
            }else if let url = QiscusHelper.getFirstLinkInString(text: commentText){
                return url
            }else{
                return nil
            }
        }
    }
    open var sender : QiscusUser? {
        let user = QiscusUser.getUserWithEmail(self.commentSenderEmail)
        return user
    }
    open var isOwnMessage:Bool{
        if self.commentSenderEmail == QiscusConfig.sharedInstance.USER_EMAIL{
            return true
        }else{
            return false
        }
    }
    open var roomId:Int{
        get{
            return commentRoom.roomId
        }
    }
    open var commentRoom:QiscusRoom{
        get{
            var room = QiscusRoom()
            if let thisRoom = QiscusRoom.room(withLastTopicId: self.commentTopicId){
                room = thisRoom
            }
            return room
        }
    }
    open var commentStatus:QiscusCommentStatus {
        get {
            if commentStatusRaw == QiscusCommentStatus.failed.rawValue || commentStatusRaw == QiscusCommentStatus.sending.rawValue{
                return QiscusCommentStatus(rawValue: commentStatusRaw)!
            }
            else{
                var minReadId = Int(0)
                var minDeliveredId = Int(0)
                
                if commentRoom.participants.count > 0 {
                    minReadId = commentRoom.participants.first!.lastReadCommentId
                    minDeliveredId = commentRoom.participants.first!.lastDeliveredCommentId
                    for participant in commentRoom.participants {
                        if participant.lastReadCommentId < minReadId {
                            minReadId = participant.lastReadCommentId
                        }
                        if participant.lastDeliveredCommentId < minReadId {
                            minDeliveredId = participant.lastDeliveredCommentId
                        }
                    }
                }
                if commentId <= minReadId {
                    return QiscusCommentStatus.read
                }else if commentId <= minDeliveredId{
                    return QiscusCommentStatus.delivered
                }else{
                    return QiscusCommentStatus(rawValue: commentStatusRaw)!
                }
            }
        }
    }
    
    open var commentDate: String {
        get {
            let date = Date(timeIntervalSince1970: commentCreatedAt)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d MMMM yyyy"
            let dateString = dateFormatter.string(from: date)
            
            return dateString
        }
    }
    open var commentTime: String {
        get {
            let date = Date(timeIntervalSince1970: commentCreatedAt)
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            let timeString = timeFormatter.string(from: date)
            
            return timeString
        }
    }
    open var commentTime24: String {
        get {
            let date = Date(timeIntervalSince1970: commentCreatedAt)
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            let timeString = timeFormatter.string(from: date)
            
            return timeString
        }
    }
    open var commentDay: String {
        get {
            
            let date = Date(timeIntervalSince1970: commentCreatedAt)
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            let dayString = dayFormatter.string(from: date)
            if date.isToday {
                return "Today"
            }else if date.isYesterday{
                return "Yesterday"
            }else{
                return "\(dayString), \(self.commentDate)"
            }
        }
    }
    open var isToday:Bool{
        get{
            return Date(timeIntervalSince1970: commentCreatedAt).isToday
        }
    }
    open var commentIsFile: Bool {
        get {
            var check:Bool = false
            if((self.commentText as String).hasPrefix("[file]")){
                check = true
            }
            return check
        }
    }
    
    
    // MARK: - new comment
    public class func newComment(withId commentId:Int, andUniqueId uniqueId:String)->QiscusComment{
        let commentDB = QiscusCommentDB.new(commentWithId: commentId, andUniqueId: uniqueId)
        return commentDB.comment()
    }
    public class func newComment(withMessage message:String, inTopicId:Int, showLink:Bool = false)->QiscusComment{
        let commentDB = QiscusCommentDB.newComment()
        let comment = commentDB.comment()
        
        let time = Double(Date().timeIntervalSince1970)
        let timeToken = UInt64(time * 10000)
        let uniqueID = "ios-\(timeToken)"
        let config = QiscusConfig.sharedInstance
        
        comment.commentId = 0
        comment.commentText = message
        comment.commentCreatedAt = Double(Date().timeIntervalSince1970)
        comment.commentUniqueId = uniqueID
        comment.commentTopicId = inTopicId
        comment.commentSenderEmail = config.USER_EMAIL
        comment.commentStatusRaw = QiscusCommentStatus.sending.rawValue
        comment.commentIsSynced = false
        comment.showLink = showLink
        
        if comment.commentIsFile{
            comment.commentType = QiscusCommentType.attachment
        }else {
            comment.commentType = QiscusCommentType.text
        }
        
        return comment
    }
    
    // MARK : - get comment
    public class func comment(withId commentId:Int, andUniqueId uniqueId:String? = nil)->QiscusComment?{
        return QiscusCommentDB.comment(withId: commentId, andUniqueId: uniqueId)
    }
    public class func comment(withLocalId localId:Int)->QiscusComment?{
        return QiscusCommentDB.comment(withLocalId:localId)
    }
    public class func comment(withUniqueId uniqueId: String)->QiscusComment?{
        return QiscusCommentDB.comment(withUniqueId:uniqueId)
    }
    public class func getLastComment(inTopicId topicId:Int? = nil)->QiscusComment?{
        return QiscusCommentDB.lastComment(inTopicId:topicId)
    }

    
    
    //MARK: [QiscusComment]
    public class func unreadComments(inTopic topicId:Int)->[QiscusComment]{
        return QiscusCommentDB.unreadComments(inTopic:topicId)
    }
    
    public class func checkSync(inTopicId topicId: Int)->Int?{
        return QiscusCommentDB.checkSync(inTopicId:topicId)
    }
    public class func getComments(inTopicId topicId: Int, limit:Int = 0, fromCommentId:Int? = nil, after:Bool = false)->[QiscusComment]{
        return QiscusCommentDB.getComments(inTopicId:topicId,limit:limit,fromCommentId:fromCommentId, after: after)
    }
    open class func getFirstUnsyncComment(inTopicId topicId:Int)->QiscusComment?{
        return QiscusCommentDB.firstUnsyncComment(inTopicId:topicId)
    }
    open class func getLastSyncCommentId(_ topicId:Int, unsyncCommentId:Int)->Int?{ //
        return QiscusCommentDB.lastSyncId(topicId:topicId, unsyncCommentId:unsyncCommentId)
    }
    
    //MARK: [[QiscusComment]]
    open class func grouppedComment(inTopicId topicId:Int, fromCommentId:Int? = nil, limit:Int = 0, after:Bool = false)->[[QiscusComment]]{
        var allComment = [[QiscusComment]]()
        
        let commentData = QiscusComment.getComments(inTopicId: topicId, limit: limit,fromCommentId: fromCommentId, after: after)
        
        if(commentData.count > 0){
            var first = commentData.first!
            var grouppedMessage = [QiscusComment]()
            var i:Int = 1
            for comment in commentData{
                if(comment.commentDate == first.commentDate) && (comment.commentSenderEmail == first.commentSenderEmail){
                    grouppedMessage.append(comment)
                }else{
                    allComment.append(grouppedMessage)
                    grouppedMessage = [QiscusComment]()
                    first = comment
                    grouppedMessage.append(comment)
                }
                if( i == commentData.count){
                    allComment.append(grouppedMessage)
                }
                i += 1
            }
        }
        return allComment
    }
    
    // MARK: Object Getter Method
    public func getMediaURL() -> String{
        let component1 = (self.commentText as String).components(separatedBy: "[file]")
        let component2 = component1.last!.components(separatedBy: "[/file]")
        let mediaUrlString = component2.first?.trimmingCharacters(in: CharacterSet.whitespaces)
        return mediaUrlString!
    }
    func getURL(fromMessage message:String) -> String{
        let component1 = message.components(separatedBy: "[file]")
        let component2 = component1.last!.components(separatedBy: "[/file]")
        let mediaUrlString = component2.first?.trimmingCharacters(in: CharacterSet.whitespaces)
        return mediaUrlString!
    }
    
    // MARK: - Updater Methode
    open class func getLastSentComent(inRoom roomId:Int)->QiscusComment?{
        return QiscusCommentDB.lastSent(inRoom:roomId)
    }
    
    open func updateCommentStatus(_ status: QiscusCommentStatus, email:String? = nil){
        self.commentStatusRaw = status.rawValue
        if let commentDB = QiscusCommentDB.commentDB(withLocalId: self.localId){
            commentDB.updateStatus(status, email: email)
        }
    }
    
    // MARK: - Checking Methode
    public class func isExist(commentId:Int)->Bool{
        return QiscusCommentDB.isExist(commentId:commentId)
    }
    
    open class func isUnsyncMessageExist(topicId:Int)->Bool{ //
        return QiscusCommentDB.unsyncExist(topicId:topicId)
    }
    
    // MARK: - Delete
    open class func deleteAll(){
        QiscusCommentDB.deleteAll()
    }
    public func deleteComment(){
        if let commentDB = QiscusCommentDB.commentDB(withLocalId: self.localId){
            commentDB.deleteComment()
        }
    }
}
