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
}
@objc public enum QiscusCommentStatus:Int{
    case sending
    case sent
    case delivered
    case read
    case failed
}

public class QiscusComment: Object {
    // MARK: - Variable
    // MARK: Dynamic Variable
    open dynamic var localId:Int64 = 0
    open dynamic var commentId:Int64 = 0 {
        didSet{
            let id : Int64 = self.localId
            let value = self.commentId
            Qiscus.dbThread.async {
                if let savedComment = QiscusComment.getSavedComment(localId: id){
                    if savedComment.commentId != value{
                        let realm = try! Realm()
                        try! realm.write {
                            savedComment.commentId = value
                        }
                    }
                }
            }
        }
    }
    open dynamic var commentText:String = ""{
        didSet{
            let id : Int64 = self.localId
            let value = self.commentText
            Qiscus.dbThread.async {
                if let savedComment = QiscusComment.getSavedComment(localId: id){
                    if savedComment.commentText != value{
                        let realm = try! Realm()
                        try! realm.write {
                            savedComment.commentText = value
                        }
                    }
                }
            }
        }
    }
    
    open dynamic var commentCreatedAt: Double = 0 {
        didSet{
            let id : Int64 = self.localId
            let value = self.commentCreatedAt
            Qiscus.dbThread.async {
                if let savedComment = QiscusComment.getSavedComment(localId: id){
                    if savedComment.commentCreatedAt != value{
                        let realm = try! Realm()
                        try! realm.write {
                            savedComment.commentCreatedAt = value
                        }
                    }
                }
            }
        }
    }
    open dynamic var commentUniqueId: String = "" {
        didSet{
            let id : Int64 = self.localId
            let value = self.commentUniqueId
            Qiscus.dbThread.async {
                if let savedComment = QiscusComment.getSavedComment(localId: id){
                    if savedComment.commentUniqueId != value{
                        let realm = try! Realm()
                        try! realm.write {
                            savedComment.commentUniqueId = value
                        }
                    }
                }
            }
        }
    }
    open dynamic var commentTopicId:Int = 0 {
        didSet{
            let id : Int64 = self.localId
            let value = self.commentTopicId
            Qiscus.dbThread.async {
                if let savedComment = QiscusComment.getSavedComment(localId: id){
                    if savedComment.commentTopicId != value{
                        let realm = try! Realm()
                        try! realm.write {
                            savedComment.commentTopicId = value
                        }
                    }
                }
            }
        }
    }
    open dynamic var commentSenderEmail:String = ""{
        didSet{
            let id : Int64 = self.localId
            let value = self.commentSenderEmail
            Qiscus.dbThread.async {
                if let savedComment = QiscusComment.getSavedComment(localId: id){
                    if savedComment.commentSenderEmail != value{
                        let realm = try! Realm()
                        try! realm.write {
                            savedComment.commentSenderEmail = value
                        }
                    }
                }
            }
        }
    }
    open dynamic var commentFileId:Int = 0 {
        didSet{
            let id : Int64 = self.localId
            let value = self.commentFileId
            Qiscus.dbThread.async {
                if let savedComment = QiscusComment.getSavedComment(localId: id){
                    if savedComment.commentFileId != value{
                        let realm = try! Realm()
                        try! realm.write {
                            savedComment.commentFileId = value
                        }
                    }
                }
            }
        }
    }
    open dynamic var commentStatusRaw:Int = QiscusCommentStatus.sending.rawValue {
        didSet{
            let id : Int64 = self.localId
            let value = self.commentStatusRaw
            Qiscus.dbThread.async {
                if value != QiscusCommentStatus.delivered.rawValue &&
                    value != QiscusCommentStatus.read.rawValue{
                    if let savedComment = QiscusComment.getSavedComment(localId: id){
                        if savedComment.commentStatusRaw != value{
                            if value > savedComment.commentStatusRaw || value == QiscusCommentStatus.failed.rawValue{
                                let realm = try! Realm()
                                try! realm.write {
                                    savedComment.commentStatusRaw = value
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    open dynamic var commentIsSynced:Bool = false {
        didSet{
            let id : Int64 = self.localId
            let value = self.commentIsSynced
            Qiscus.dbThread.async {
                if let savedComment = QiscusComment.getSavedComment(localId: id){
                    if savedComment.commentIsSynced != value{
                        let realm = try! Realm()
                        try! realm.write {
                            savedComment.commentIsSynced = value
                        }
                    }
                }
            }
        }
    }
    open dynamic var commentBeforeId:Int64 = 0 {
        didSet{
            let id : Int64 = self.localId
            let value = self.commentBeforeId
            
            Qiscus.dbThread.async {
                if let savedComment = QiscusComment.getSavedComment(localId: id){
                    if savedComment.commentBeforeId != value{
                        let realm = try! Realm()
                        try! realm.write {
                            savedComment.commentBeforeId = value
                        }
                    }
                }
            }
        }
    }
    open dynamic var commentCellHeight:CGFloat = 0{
        didSet{
            let id : Int64 = self.localId
            let value = self.commentCellHeight
            Qiscus.dbThread.async {
                if let savedComment = QiscusComment.getSavedComment(localId: id){
                    if savedComment.commentCellHeight != value{
                        let realm = try! Realm()
                        try! realm.write {
                            savedComment.commentCellHeight = value
                        }
                    }
                }
            }
        }
    }
    open dynamic var commentTextWidth:CGFloat = 0 {
        didSet{
            let id : Int64 = self.localId
            let value = self.commentTextWidth
            Qiscus.dbThread.async {
                if let savedComment = QiscusComment.getSavedComment(localId: id){
                    if savedComment.commentTextWidth != value{
                        let realm = try! Realm()
                        try! realm.write {
                            savedComment.commentTextWidth = value
                        }
                    }
                }
            }
        }
    }
    
    open dynamic var commentRow:Int = 0 {
        didSet{
            let id : Int64 = self.localId
            let value = self.commentRow
            Qiscus.dbThread.async {
                if let savedComment = QiscusComment.getSavedComment(localId: id){
                    if savedComment.commentRow != value{
                        let realm = try! Realm()
                        try! realm.write {
                            savedComment.commentRow = value
                        }
                    }
                }
            }
        }
    }
    open dynamic var commentSection:Int = 0 {
        didSet{
            let id : Int64 = self.localId
            let value = self.commentSection
            Qiscus.dbThread.async {
                if let savedComment = QiscusComment.getSavedComment(localId: id){
                    if savedComment.commentSection != value{
                        let realm = try! Realm()
                        try! realm.write {
                            savedComment.commentSection = value
                        }
                    }
                }
            }
        }
    }
    open dynamic var showLink:Bool = false {
        didSet{
            let id : Int64 = self.localId
            let value = self.showLink
            Qiscus.dbThread.async {
                if let savedComment = QiscusComment.getSavedComment(localId: id){
                    if savedComment.showLink != value{
                        let realm = try! Realm()
                        try! realm.write {
                            savedComment.showLink = value
                        }
                    }
                }
            }
        }
    }
    open dynamic var commentLinkPreviewed:String = "" {
        didSet{
            let id : Int64 = self.localId
            let value = self.commentLinkPreviewed
            Qiscus.dbThread.async {
                if let savedComment = QiscusComment.getSavedComment(localId: id){
                    if savedComment.commentLinkPreviewed != value{
                        let realm = try! Realm()
                        try! realm.write {
                            savedComment.commentLinkPreviewed = value
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Getter Variable
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
    open var commentIndexPath:IndexPath{
        get{
            return IndexPath(row: self.commentRow, section: self.commentSection)
        }
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
            if let thisRoom = QiscusRoom.getRoom(withLastTopicId: self.commentTopicId){
                room = thisRoom
            }
            return room
        }
    }
    open var commentStatus:QiscusCommentStatus {
        get {
            if commentStatusRaw == QiscusCommentStatus.failed.rawValue || commentStatusRaw == QiscusCommentStatus.sending.rawValue{
                return QiscusCommentStatus(rawValue: commentStatusRaw)!
            }else{
                var minReadId = Int64(0)
                var minDeliveredId = Int64(0)
                
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
    open var commentType: QiscusCommentType {
        get {
            var type = QiscusCommentType.text
            if isFileMessage(){
                type = QiscusCommentType.attachment
            }
            return type
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
            return isFileMessage()
        }
    }
    // MARK: Class Variable
    override open class func primaryKey() -> String {
        return "localId"
    }
    open class var LastId:Int64{
        get{
            let realm = try! Realm()
            let RetNext = realm.objects(QiscusComment.self).sorted(byProperty: "localId")
            
            if RetNext.count > 0 {
                let last = RetNext.last!
                return last.localId
            } else {
                return 0
            }
        }
    }
    open class var LastCommentId:Int64{
        get{
            let realm = try! Realm()
            let RetNext = realm.objects(QiscusComment.self).sorted(byProperty: "commentId")
            
            if RetNext.count > 0 {
                let last = RetNext.last!
                return last.commentId
            } else {
                return 0
            }
        }
    }
    
    // MARK: - Class Getter Method
    // MARK: QiscusComment
    class func copyComment(comment:QiscusComment)->QiscusComment{
        let newComment = QiscusComment()
        newComment.localId = comment.localId
        newComment.commentId = comment.commentId
        newComment.commentText = comment.commentText
        newComment.commentCreatedAt = comment.commentCreatedAt
        newComment.commentUniqueId = comment.commentUniqueId
        newComment.commentTopicId = comment.commentTopicId
        newComment.commentSenderEmail = comment.commentSenderEmail
        newComment.commentFileId = comment.commentFileId
        newComment.commentStatusRaw = comment.commentStatusRaw
        newComment.commentBeforeId = comment.commentBeforeId
        newComment.commentIsSynced = comment.commentIsSynced
        newComment.commentCellHeight = comment.commentCellHeight
        newComment.commentTextWidth = comment.commentTextWidth
        newComment.commentRow = comment.commentRow
        newComment.commentSection = comment.commentSection
        newComment.showLink = comment.showLink
        newComment.commentLinkPreviewed = comment.commentLinkPreviewed
        return newComment
    }
    open class func getLastComment()->QiscusComment?{
        let realm = try! Realm()
        let searchQuery = NSPredicate(format: "commentStatusRaw != %d && commentStatusRaw != %d",QiscusCommentStatus.sending.rawValue,QiscusCommentStatus.failed.rawValue)
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery).sorted(byProperty: "commentId")
        
        if commentData.count > 0 {
            return QiscusComment.copyComment(comment: commentData.last!)
        }
        return nil
    }
    open class func getFirstComment(inTopic topicId:Int)->QiscusComment?{
        let realm = try! Realm()
        let searchQuery = NSPredicate(format: "commentStatusRaw != \(QiscusCommentStatus.sending.rawValue) && commentStatusRaw != \(QiscusCommentStatus.failed.rawValue) && commentTopicId == \(topicId)")
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery).sorted(byProperty: "commentCreatedAt", ascending: true)
        
        if commentData.count > 0 {
            return QiscusComment.copyComment(comment: commentData.first!)
        }
        return nil
    }
    class func getSavedComment(localId:Int64)->QiscusComment?{
        let realm = try! Realm()
        let searchQuery:NSPredicate = NSPredicate(format: "localId == \(localId)")
        let RetNext = realm.objects(QiscusComment.self).filter(searchQuery)
        
        if RetNext.count > 0 {
            return RetNext.last!
        } else {
            return nil
        }
    }
    public class func getLastAllComment()->QiscusComment?{
        let realm = try! Realm()
        let searchQuery:NSPredicate = NSPredicate(format: "(commentStatusRaw != \(QiscusCommentStatus.sending.rawValue) OR commentStatusRaw == \(QiscusCommentStatus.failed.rawValue))")
        let RetNext = realm.objects(QiscusComment.self).filter(searchQuery).sorted(byProperty: "commentCreatedAt")
        
        if RetNext.count > 0 {
            let last = QiscusComment.copyComment(comment: RetNext.last!)
            return last
        } else {
            return nil
        }
    }
    public class func getLastComment(inTopicId topicId:Int)->QiscusComment?{
        let realm = try! Realm()
        let searchQuery:NSPredicate = NSPredicate(format: "commentTopicId == %d", topicId)
        let RetNext = realm.objects(QiscusComment.self).filter(searchQuery).sorted(byProperty: "commentId")
        
        if RetNext.count > 0 {
            let last = QiscusComment.copyComment(comment: RetNext.last!)
            return last
        } else {
            return nil
        }
    }
    public class func getComment(withLocalId localId: Int64)->QiscusComment?{
        let realm = try! Realm()
        
        let searchQuery:NSPredicate = NSPredicate(format: "localId == %d", localId)
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery)
        
        if(commentData.count == 0){
            return nil
        }else{
            return QiscusComment.copyComment(comment: commentData.first!)
        }
    }
    public class func getComment(withUniqueId uniqueId: String)->QiscusComment?{
        let realm = try! Realm()
        
        let searchQuery:NSPredicate = NSPredicate(format: "commentUniqueId == '\(uniqueId)'")
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery)
        
        if(commentData.count == 0){
            return nil
        }else{
            return QiscusComment.copyComment(comment: commentData.first!)
        }
    }
    public class func getComment(withId commentId: Int64)->QiscusComment?{
        let realm = try! Realm()
        
        let searchQuery:NSPredicate = NSPredicate(format: "commentId == \(commentId)")
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery)
        
        if(commentData.count == 0){
            return nil
        }else{
            return QiscusComment.copyComment(comment: commentData.first!)
        }
    }
    public class func newComment(withMessage message:String, inTopicId:Int, showLink:Bool = false)->QiscusComment{
        let comment = QiscusComment()
        comment.localId = QiscusComment.LastId + 1
        
        let realm = try! Realm()
        
        let newComment = QiscusComment()
        newComment.localId = comment.localId
        try! realm.write {
            realm.add(newComment)
        }
        
        
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
        
        return QiscusComment.copyComment(comment: comment)
    }
    private class func comment(withId commentId:Int64, uniqueId:String)->QiscusComment?{
        let realm = try! Realm()
        let searchQuery:NSPredicate?
        searchQuery = NSPredicate(format: "commentId == \(commentId) OR commentUniqueId == '\(uniqueId)'")
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery!)
        
        return commentData.first
    }
    
    //MARK: [QiscusComment]
    public class func getUnreadComments(inTopic topicId:Int)->[QiscusComment]{
        var comments = [QiscusComment]()
        if let room = QiscusRoom.getRoom(withLastTopicId: topicId){
            if let participant = QiscusParticipant.getParticipant(withEmail: QiscusMe.sharedInstance.email, roomId: room.roomId){
                let lastReadId = participant.lastReadCommentId
                let realm = try! Realm()
                
                let sortProperties = [SortDescriptor(property: "commentCreatedAt"), SortDescriptor(property: "commentId", ascending: true)]
                let searchQuery:NSPredicate = NSPredicate(format: "commentTopicId == \(topicId) AND commentId > \(lastReadId)")
                let commentData = realm.objects(QiscusComment.self).filter(searchQuery).sorted(by: sortProperties)
                
                if(commentData.count > 0){
                    for comment in commentData{
                        comments.append(QiscusComment.copyComment(comment: comment))
                    }
                }
            }
        }
        return comments
    }
    public class func checkSync(inTopicId topicId: Int)->Int64?{
        let realm = try! Realm()
        
        let sortProperties = [SortDescriptor(property: "commentCreatedAt", ascending: true)]
        let searchQuery:NSPredicate = NSPredicate(format: "commentTopicId == \(topicId)")
        
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery).sorted(by: sortProperties)
        
        
        if(commentData.count > 0){
            let lastCommentId = commentData.first!.localId
            for comment in commentData{
                print("comment check sync: \(comment.commentId) : \(comment.commentText)  || \(QiscusComment.isCommentExist(comment.commentBeforeId)) || \(lastCommentId) || \(comment.commentBeforeId)")
                if !QiscusComment.isCommentExist(comment.commentBeforeId) && comment.localId != lastCommentId{
                    return comment.commentId
                }
            }
        }
        return nil
    }
    public class func getComments(inTopicId topicId: Int, limit:Int = 0, fromCommentId:Int64? = nil)->[QiscusComment]{ //
        
        var allComment = [QiscusComment]()
        let realm = try! Realm()
        
        let sortProperties = [SortDescriptor(property: "commentCreatedAt", ascending: false)]
        
        var searchQuery:NSPredicate = NSPredicate(format: "commentTopicId == \(topicId)")
        
        if fromCommentId != nil{
            searchQuery = NSPredicate(format: "commentTopicId == \(topicId) AND commentId < \(fromCommentId!)")
        }
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery).sorted(by: sortProperties)
        
        
        if(commentData.count > 0){
            for comment in commentData{
                allComment.insert(QiscusComment.copyComment(comment: comment), at: 0)
            }
        }
        return allComment
    }
    open class func getFirstUnsyncComment(inTopicId topicId:Int)->QiscusComment?{
        let realm = try! Realm()
        let searchQuery = NSPredicate(format: "commentIsSynced == false AND commentTopicId == %d AND (commentStatusRaw == %d OR commentStatusRaw == %d)",topicId,QiscusCommentStatus.sent.rawValue,QiscusCommentStatus.delivered.rawValue)
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery).sorted(byProperty: "commentCreatedAt")
        
        if commentData.count > 0{
            let comment = QiscusComment.copyComment(comment: commentData.first!)
            return comment
        }else{
            return nil
        }
    }
    
    //MARK: [[QiscusComment]]
    open class func grouppedComment(inTopicId topicId:Int, fromCommentId:Int64? = nil)->[[QiscusComment]]{
        var allComment = [[QiscusComment]]()
        
        let commentData = QiscusComment.getComments(inTopicId: topicId, fromCommentId: fromCommentId)
        
        if(commentData.count > 0){
            var first = commentData.first!
            var grouppedMessage = [QiscusComment]()
            var i:Int = 1
            for comment in commentData{
                if(comment.commentDate == first.commentDate) && (comment.commentSenderEmail == first.commentSenderEmail){
                    grouppedMessage.append(QiscusComment.copyComment(comment: comment))
                }else{
                    allComment.append(grouppedMessage)
                    grouppedMessage = [QiscusComment]()
                    first = comment
                    grouppedMessage.append(QiscusComment.copyComment(comment: comment))
                }
                if( i == commentData.count){
                    allComment.append(grouppedMessage)
                }
                i += 1
            }
        }
        return allComment
    }
    
    open class func firstUnsyncCommentId(_ topicId:Int)->Int64{
        let realm = try! Realm()
        let searchQuery = NSPredicate(format: "commentIsSynced == false AND commentTopicId == %d AND (commentStatusRaw == %d OR commentStatusRaw == %d)",topicId,QiscusCommentStatus.sent.rawValue,QiscusCommentStatus.delivered.rawValue)
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery).sorted(byProperty: "commentCreatedAt")
        
        if commentData.count > 0{
            let firstData = commentData.first!
            return firstData.commentId
        }else{
            return 0
        }
    }
    
    // MARK: Object Getter Method
    public func getMediaURL() -> String{
        let component1 = (self.commentText as String).components(separatedBy: "[file]")
        let component2 = component1.last!.components(separatedBy: "[/file]")
        let mediaUrlString = component2.first?.trimmingCharacters(in: CharacterSet.whitespaces)
        return mediaUrlString!
    }
    
    // MARK: - Setter Method
    // MARK: Class Setter Method
    public class func deleteAllFailedMessage(){ //
        let realm = try! Realm()
        let searchQuery:NSPredicate = NSPredicate(format: "commentStatusRaw == %d", QiscusCommentStatus.failed.rawValue)
        let RetNext = realm.objects(QiscusComment.self).filter(searchQuery)
        
        if RetNext.count > 0 {
            for failedComment in RetNext{
                try! realm.write {
                    realm.delete(failedComment)
                }
            }
        }
    }
    // MARK: - Object Setter Method
    open func updateCommmentIndexPath(indexPath:IndexPath){
        self.commentRow = indexPath.row
        self.commentSection = indexPath.section
        Qiscus.dbThread.async {
            if let dbComment = QiscusComment.comment(withId: self.commentId, uniqueId: self.commentUniqueId){
                let realm = try! Realm()
                try! realm.write {
                    dbComment.commentRow = indexPath.row
                    dbComment.commentSection = indexPath.section
                }
            }
        }
    }
    open class func updateCommmentShowLink(show:Bool, commentId:Int64){
        if let comment = QiscusComment.getComment(withId: commentId){
            let realm = try! Realm()
            try! realm.write {
                comment.showLink = show
            }
            comment.updateCommentCellSize()
        }
    }
    open func updateCommmentShowLink(show:Bool){
        let realm = try! Realm()
        try! realm.write {
            self.showLink = show
        }
        self.updateCommentCellSize()
    }
    open func updateCommentCellWithLinkSize(linkURL:String, linkTitle: String){
        let newSize = calculateTextSizeForCommentLink(linkURL: linkURL, linkTitle: linkTitle)
        let realm = try! Realm()
        try! realm.write {
            self.commentCellHeight = newSize.height
            self.commentTextWidth = newSize.width
        }
    }
    open func updateCommentCellSize(size:CGSize? = nil){
        let id = self.commentId
        let uniqueId = self.commentUniqueId
        
        Qiscus.dbThread.async {
            let realm = try! Realm()
            let searchQuery:NSPredicate?
            searchQuery = NSPredicate(format: "commentId == \(id) OR commentUniqueId == '\(uniqueId)'")
            let commentData = realm.objects(QiscusComment.self).filter(searchQuery!)
            
            if let comment = commentData.first{
                if size == nil {
                    var newSize = CGSize()
                    switch comment.commentType {
                    case .text:
                        comment.calculateTextSizeForComment()
                        
                        break
                    case .attachment:
                        if let file = QiscusFile.getCommentFileWithComment(comment){
                            switch file.fileType {
                            case .audio:
                                newSize.height = 88
                                break
                            case .document:
                                newSize.height = 70
                                break
                            case .media:
                                newSize.height = 140
                                break
                            case .others:
                                newSize.height = 70
                                break
                            case .video:
                                newSize.height = 140
                                break
                            }
                        }
                        break
                    }
                    comment.updateCommentCellSize(size: newSize)
                }else{
                    if size!.height != comment.commentCellHeight || size!.width != comment.commentTextWidth{
                        try! realm.write {
                            comment.commentCellHeight = size!.height - 5
                            comment.commentTextWidth = size!.width
                        }
                        let copyComment = QiscusComment.copyComment(comment: comment)
                        if let commentDelegate = QiscusCommentClient.sharedInstance.commentDelegate {
                            Qiscus.uiThread.async {
                                commentDelegate.didChangeSize?(comment: copyComment)
                            }
                        }
                    }
                }
            }
        }
        
    }
    open class func getLastSyncCommentId(_ topicId:Int, unsyncCommentId:Int64)->Int64?{ //
        
        let realm = try! Realm()
        let searchQuery = NSPredicate(format: "commentTopicId == \(topicId) AND (commentStatusRaw != \(QiscusCommentStatus.sending.rawValue) OR commentStatusRaw == \(QiscusCommentStatus.failed.rawValue)) AND commentId < \(unsyncCommentId)")
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery).sorted(byProperty: "commentCreatedAt", ascending: true)
        
        if commentData.count > 0{
            let firstCommentId = commentData.first!.localId
            for comment in commentData.reversed(){
                print("comment: \(comment.commentId)  :  \(comment.commentText)")
                if QiscusComment.isCommentExist(comment.commentBeforeId) || comment.localId == firstCommentId{
                    return comment.commentId
                }
            }
        }
        return nil
    }
    open class func countCommentOntTopic(_ topicId:Int)->Int{ //
        let realm = try! Realm()
        
        let searchQuery:NSPredicate = NSPredicate(format: "commentTopicId == %d", topicId)
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery)
        
        return commentData.count
    }
    // MARK: - getComment from JSON
    open class func getCommentTopicIdFromJSON(_ data: JSON) -> Int{ //
        return data["topic_id"].intValue
    }
    open class func getCommentIdFromJSON(_ data: JSON) -> Int64{ //
        var commentId:Int64 = 0
        
        if let id = data["id"].int64{
            commentId = id
        }else if let id = data["comment_id"].int64{
            commentId = id
        }
        return commentId
    }
    open class func getComment(fromRealtimeJSON data:JSON)->Bool{
        
        let topicId = data["topic_id"].intValue
        let commentId = data["id"].int64Value
        let commentUniqueId = data["unique_temp_id"].stringValue
        var commentCreatedAt = Double(0)
        
        let createdAt = data["timestamp"].stringValue
        let dateTimeArr = createdAt.characters.split(separator: "T")
        let dateString = String(dateTimeArr.first!)
        let timeArr = String(dateTimeArr.last!).characters.split(separator: "Z")
        let timeString = String(timeArr.first!)
        let dateTimeString = "\(dateString) \(timeString) +0000"
        
        let rawDateFormatter = DateFormatter()
        rawDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        rawDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        
        let chatDate = rawDateFormatter.date(from: dateTimeString)
        
        if chatDate != nil{
            let timetoken = Double(chatDate!.timeIntervalSince1970)
            commentCreatedAt = timetoken
        }
        var link = false
        if let disableLink = data["disable_link_preview"].bool{
            link = !disableLink
        }
        
        let realm = try! Realm()
        let searchQuery:NSPredicate?
        searchQuery = NSPredicate(format: "commentId == \(commentId) OR commentUniqueId == '\(commentUniqueId)'")
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery!)
        
        var saved = false
        var newComment = QiscusComment()
        
        if(commentData.count == 0){
            saved = true
            newComment.localId = QiscusComment.LastId + 1
            newComment.commentId = commentId
            newComment.commentUniqueId = commentUniqueId
            newComment.commentTopicId = topicId
            newComment.commentCreatedAt = commentCreatedAt
            newComment.commentSenderEmail = data["email"].stringValue
            newComment.commentStatusRaw = QiscusCommentStatus.sent.rawValue
            newComment.commentText = data["message"].stringValue
            newComment.showLink = link
            try! realm.write {
                realm.add(newComment)
            }
        }else{
            newComment = QiscusComment.copyComment(comment: commentData.first!)
        }
        let comment = QiscusComment.copyComment(comment: newComment)
        if !saved{
            comment.commentId = commentId
            comment.commentUniqueId = commentUniqueId
            comment.commentTopicId = topicId
            comment.commentCreatedAt = commentCreatedAt
            comment.commentSenderEmail = data["email"].stringValue
            comment.commentStatusRaw = QiscusCommentStatus.sent.rawValue
            comment.commentText = data["message"].stringValue
            comment.showLink = link
        }
        comment.commentBeforeId = data["comment_before_id"].int64Value
        if let sender = QiscusUser.getUserWithEmail(comment.commentSenderEmail as String){
            if let userName = data["username"].string{
                if sender.userNameAs != userName {
                    sender.updateUserNameAs(userName)
                }
            }
        }
        
        if comment.commentType == QiscusCommentType.text && comment.commentLink != nil{
            if let disableLink = data["disable_link_preview"].bool{
                comment.showLink = !disableLink
            }else{
                comment.showLink = true
            }
        }else if comment.commentType == .attachment {
            var file = QiscusFile.getCommentFileWithComment(comment)
            if file == nil {
                file = QiscusFile()
            }
            file?.updateURL(comment.getMediaURL())
            file?.updateCommentId(comment.commentId)
            file?.saveCommentFile()
            
            file = QiscusFile.getCommentFileWithComment(comment)
            comment.commentFileId = file!.fileId
        }
        
        return saved
    }
    open class func getCommentBeforeIdFromJSON(_ data: JSON) -> Int64{//
        return data["comment_before_id"].int64Value
    }
    open class func getSenderFromJSON(_ data: JSON) -> String{
        return data["username_real"].stringValue
    }
    open class func getCommentFromJSON(_ data: JSON) -> Bool{
        let topicId = data["topic_id"].intValue
        let commentId = data["id"].int64Value
        var commentUniqueId = ""
        var commentText = ""
        var commentCreatedAt = Double(0)
        
        var created_at:String = ""
        if let created = data["created_at"].string{
            created_at = created
        }else if let created = data["created_at_ios"].string{
            created_at = created
        }
        let rawDateFormatter = DateFormatter()
        rawDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        rawDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        let chatDate = rawDateFormatter.date(from: "\(created_at as String) +0000")
        if chatDate != nil{
            let timetoken = Double(chatDate!.timeIntervalSince1970)
            commentCreatedAt = timetoken
        }
        if let uniqueId = data["unique_temp_id"].string {
            commentUniqueId = uniqueId
        }else if let randomme = data["randomme"].string {
            commentUniqueId = randomme
        }
        if let text = data["message"].string{
            commentText = text
        }else if let text = data["comment"].string{
            commentText = text
        }
        
        let realm = try! Realm()
        let searchQuery:NSPredicate?
        searchQuery = NSPredicate(format: "commentId == \(commentId) OR commentUniqueId == '\(commentUniqueId)'")
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery!)
        
        var saved = false
        var newComment = QiscusComment()
        
        if(commentData.count == 0){
            saved = true
            newComment.localId = QiscusComment.LastId + 1
            newComment.commentId = commentId
            newComment.commentUniqueId = commentUniqueId
            newComment.commentTopicId = topicId
            newComment.commentCreatedAt = commentCreatedAt
            newComment.commentText = commentText
            newComment.commentTopicId = data["topic_id"].intValue
            newComment.commentSenderEmail = data["username_real"].stringValue
            newComment.commentStatusRaw = QiscusCommentStatus.sent.rawValue
            try! realm.write {
                realm.add(newComment)
            }
        }else{
            newComment = QiscusComment.copyComment(comment: commentData.first!)
        }
        let comment = QiscusComment.copyComment(comment: newComment)
        if !saved{
            comment.commentId = commentId
            comment.commentUniqueId = commentUniqueId
            comment.commentTopicId = topicId
            comment.commentCreatedAt = commentCreatedAt
            comment.commentText = commentText
            comment.commentTopicId = data["topic_id"].intValue
            comment.commentSenderEmail = data["username_real"].stringValue
            comment.commentStatusRaw = QiscusCommentStatus.sent.rawValue
        }
        comment.commentBeforeId = data["comment_before_id"].int64Value
        var usernameAs:String = ""
        if(data["username_as"] != nil){
            usernameAs = data["username_as"].stringValue
        }else{
            usernameAs = data["username"].stringValue
        }
        if let sender = QiscusUser.getUserWithEmail(comment.commentSenderEmail as String){
            if usernameAs != ""{
                if sender.userNameAs != usernameAs {
                    sender.updateUserNameAs(usernameAs)
                }
            }
        }
        
        
        return saved
    }
    
    open class func getCommentFromJSON(_ data: JSON, topicId:Int, saved:Bool) -> Bool{ //
        let comment = QiscusComment()
        Qiscus.printLog(text: "getCommentFromJSON: \(data)")
        comment.commentTopicId = topicId
        comment.commentSenderEmail = data["email"].stringValue
        comment.commentStatusRaw = QiscusCommentStatus.sent.rawValue
        comment.commentBeforeId = data["comment_before_id"].int64Value
        
        var created_at:String = ""
        var usernameAs:String = ""
        if(data["message"] != nil){
            comment.commentText = data["message"].stringValue
            comment.commentId = data["id"].int64Value
            usernameAs = data["username"].stringValue
            created_at = data["timestamp"].stringValue
            if let uniqueId = data["unique_temp_id"].string {
                comment.commentUniqueId = uniqueId
            }else if let randomme = data["randomme"].string {
                comment.commentUniqueId = randomme
            }
        }else{
            comment.commentText = data["comment"].stringValue
            comment.commentId = data["id"].int64Value
            usernameAs = data["username"].stringValue
            if let uniqueId = data["unique_temp_id"].string {
                comment.commentUniqueId = uniqueId
            }else if let randomme = data["randomme"].string {
                comment.commentUniqueId = randomme
            }
            created_at = data["timestamp"].stringValue
        }
        if let sender = QiscusUser.getUserWithEmail(comment.commentSenderEmail as String){
            if usernameAs != ""{
                if sender.userNameAs != usernameAs {
                    sender.updateUserNameAs(usernameAs)
                }
            }
        }
        let dateTimeArr = created_at.characters.split(separator: "T")
        let dateString = String(dateTimeArr.first!)
        let timeArr = String(dateTimeArr.last!).characters.split(separator: "Z")
        let timeString = String(timeArr.first!)
        let dateTimeString = "\(dateString) \(timeString) +0000"
        Qiscus.printLog(text: "dateTimeString: \(dateTimeString)")
        Qiscus.printLog(text: "commentid: \(comment.commentId)")
        
        let rawDateFormatter = DateFormatter()
        rawDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        rawDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        
        let chatDate = rawDateFormatter.date(from: dateTimeString)
        
        if chatDate != nil{
            let timetoken = Double(chatDate!.timeIntervalSince1970)
            comment.commentCreatedAt = timetoken
        }
        
        if comment.commentType == QiscusCommentType.text && comment.commentLink != nil{
            if let disableLink = data["disable_link_preview"].bool{
                comment.showLink = !disableLink
            }else{
                comment.showLink = true
            }
        }
        
        if let participant = QiscusParticipant.getParticipant(withEmail: comment.commentSenderEmail, roomId: comment.roomId){
            participant.updateLastReadCommentId(commentId: comment.commentId)
        }
        
        let isSaved = comment.saveComment(true)
        return isSaved
    }
    
    // MARK: - Updater Methode
    open func updateCommentId(_ commentId:Int64){
        self.commentId = commentId
        Qiscus.dbThread.async {
            let realm = try! Realm()
            
            let searchQuery:NSPredicate = NSPredicate(format: "commentUniqueId == '\(self.commentUniqueId)' && commentUniqueId != ''")
            let commentData = realm.objects(QiscusComment.self).filter(searchQuery)
            
            if(commentData.count > 0){
                try! realm.write {
                    self.commentId = commentId
                }
            }
        }
        
    }
    open func updateCommentIsSync(_ sync: Bool){
        self.commentIsSynced = sync
        Qiscus.dbThread.async {
            let realm = try! Realm()
            
            let searchQuery:NSPredicate = NSPredicate(format: "commentId == %d", self.commentId)
            let commentData = realm.objects(QiscusComment.self).filter(searchQuery)
            
            if(commentData.count == 0){
                self.commentIsSynced = sync
            }else{
                try! realm.write {
                    self.commentIsSynced = sync
                }
            }
        }
    }
    open class func getLastSentComent(inRoom roomId:Int)->QiscusComment?{
        if let room = QiscusRoom.getRoomById(roomId){
            let topicId = room.roomLastCommentTopicId
            
            let realm = try! Realm()
            let searchQuery:NSPredicate = NSPredicate(format: "commentTopicId == %d", topicId)
            let commentData = realm.objects(QiscusComment.self).filter(searchQuery).sorted(byProperty: "commentId", ascending: false)
            
            for comment in commentData {
                if comment.commentStatus != QiscusCommentStatus.failed && comment.commentStatus != QiscusCommentStatus.sending{
                    return QiscusComment.copyComment(comment: comment)
                }
            }
            return nil
        }else{
            return nil
        }
    }
    
    open func updateCommentStatus(_ status: QiscusCommentStatus, email:String? = nil){
        let id = self.commentId
        let uniqueId = self.commentUniqueId
        self.commentStatusRaw = status.rawValue
        Qiscus.dbThread.async {
            let searchQuery:NSPredicate?
            let realm = try! Realm()
            
            searchQuery = NSPredicate(format: "commentId == \(id) OR commentUniqueId == '\(uniqueId)'")
            let commentData = realm.objects(QiscusComment.self).filter(searchQuery!)
            
            if let comment = commentData.first{
                if(comment.commentStatus.rawValue < status.rawValue) || comment.commentStatus == .failed{
                    var changeStatus = false
                    if status != QiscusCommentStatus.read && status != QiscusCommentStatus.delivered{
                        try! realm.write {
                            comment.commentStatusRaw = status.rawValue
                        }
                        changeStatus = true
                    }else{
                        if email != nil{
                            if let participant = QiscusParticipant.getParticipant(withEmail: email!, roomId: comment.roomId){
                                if status == QiscusCommentStatus.read{
                                    let oldMinReadId = QiscusParticipant.getMinReadCommentId(onRoom: comment.roomId)
                                    participant.updateLastReadCommentId(commentId: comment.commentId)
                                    if  QiscusParticipant.getMinReadCommentId(onRoom: comment.roomId) != oldMinReadId{
                                        changeStatus = true
                                    }
                                }else{
                                    let oldMinDeliveredId = QiscusParticipant.getMinDeliveredCommentId(onRoom: comment.roomId)
                                    participant.updateLastDeliveredCommentId(commentId: comment.commentId)
                                    if  QiscusParticipant.getMinDeliveredCommentId(onRoom: comment.roomId) != oldMinDeliveredId{
                                        changeStatus = true
                                    }
                                }
                            }
                        }
                    }
                    if changeStatus {
                        if let commentDelegate = QiscusCommentClient.sharedInstance.commentDelegate{
                            let copyComment = QiscusComment.copyComment(comment: comment)
                            Qiscus.uiThread.async {
                                commentDelegate.commentDidChangeStatus(fromComment: copyComment, toStatus: status)
                                QiscusDataPresenter.shared.delegate?.dataPresenter(didChangeStatusFrom: copyComment.commentId, toStatus: status, topicId: copyComment.commentTopicId)
                            }
                        }
                    }
                }
            }
        }
    }
    open func updateCommentFileId(_ fileId:Int){
        let realm = try! Realm()
        let searchQuery:NSPredicate?
        
        if(self.commentUniqueId != ""){
            searchQuery = NSPredicate(format: "commentUniqueId == '\(self.commentUniqueId)' && commentUniqueId != ''")
        }else{
            searchQuery = NSPredicate(format: "commentId == %d", self.commentId)
        }
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery!)
        
        if commentData.count == 0 {
            self.commentFileId = fileId
        }else{
            try! realm.write {
                self.commentFileId = fileId
            }
        }
    }
    
    open func updateCommentText(_ text:String){
        let realm = try! Realm()
        let searchQuery:NSPredicate?
        
        if(self.commentUniqueId != ""){
            searchQuery = NSPredicate(format: "commentUniqueId == '\(self.commentUniqueId)' && commentUniqueId != ''")
        }else{
            searchQuery = NSPredicate(format: "commentId == %d", self.commentId)
        }
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery!)
        
        if commentData.count == 0 {
            self.commentText = text
        }else{
            try! realm.write {
                self.commentText = text
            }
        }
    }
    // Create New Comment
    
    
    
    // MARK: - Save and Delete Comment
    open func deleteComment(){
        let commentId = self.commentId
        let commentUniqueId = self.commentUniqueId
        Qiscus.dbThread.async {
            let realm = try! Realm()
            let searchQuery:NSPredicate?
            searchQuery = NSPredicate(format: "commentId == \(commentId) OR commentUniqueId == '\(commentUniqueId)'")
            let commentData = realm.objects(QiscusComment.self).filter(searchQuery!)
            
            if commentData.count > 0 {
                let comment = commentData.first!
                try! realm.write {
                    realm.delete(comment)
                }
            }
        }
        
    }
    open class func deleteFailedComment(_ topicId:Int){
        let realm = try! Realm()
        let searchQuery = NSPredicate(format: "commentStatusRaw == %d AND commentTopicId == %d", QiscusCommentStatus.failed.rawValue,topicId)
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery)
        
        if commentData.count > 0 {
            for comment in commentData{
                try! realm.write {
                    realm.delete(comment)
                }
            }
        }
    }
    open class func deleteUnsendComment(_ topicId:Int){
        let realm = try! Realm()
        let searchQuery = NSPredicate(format: "(commentStatusRaw == %d || commentStatusRaw == %d) AND commentTopicId == %d", QiscusCommentStatus.sending.rawValue,QiscusCommentStatus.failed.rawValue,topicId)
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery)
        
        if commentData.count > 0 {
            for comment in commentData{
                try! realm.write {
                    realm.delete(comment)
                }
            }
        }
    }
    open func saveComment(_ saved:Bool)->Bool{ //
        let realm = try! Realm()
        let searchQuery:NSPredicate?
        searchQuery = NSPredicate(format: "commentId == %d OR commentUniqueId == '\(self.commentUniqueId)'", self.commentId)
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery!)
        
        if(commentData.count == 0){
            if self.commentIsFile{
                let fileURL = self.getMediaURL()
                var file = QiscusFile.getCommentFileWithURL(fileURL)
                
                if(file == nil){
                    file = QiscusFile()
                }
                file?.updateURL(fileURL)
                file?.updateCommentId(self.commentId)
                file?.saveCommentFile()
                
                file = QiscusFile.getCommentFileWithComment(self)
                self.commentFileId = file!.fileId
            }
            
            try? realm.write {
                self.localId = QiscusComment.LastId + 1
                realm.add(self)
            }

            if let user = QiscusUser.getUserWithEmail(self.commentSenderEmail){
                user.updateLastSeen(self.commentCreatedAt)
            }
            self.updateCommentCellSize()
            return true
        }else{
            let comment = commentData.first!
            try! realm.write {
                comment.commentId = self.commentId
                comment.commentText = self.commentText
                if(self.commentCreatedAt > 0){
                    comment.commentCreatedAt = self.commentCreatedAt
                }
                comment.commentBeforeId = self.commentBeforeId
                comment.commentTopicId = self.commentTopicId
                comment.commentSenderEmail = self.commentSenderEmail
                if self.commentFileId > 0 {
                    comment.commentFileId = self.commentFileId
                }
                if(comment.commentStatusRaw < self.commentStatusRaw){
                    comment.commentStatusRaw = self.commentStatusRaw
                }
                if self.commentIsSynced{
                    comment.commentIsSynced = true
                }
            }
            if let user = QiscusUser.getUserWithEmail(comment.commentSenderEmail){
                user.updateLastSeen(comment.commentCreatedAt)
            }
            return false
        }
    }
    open func saveComment()->QiscusComment{
        let realm = try! Realm()
        let searchQuery:NSPredicate?
        
        if(self.commentUniqueId != ""){
            searchQuery = NSPredicate(format: "commentUniqueId == '\(self.commentUniqueId)' && commentUniqueId != ''")
        }else{
            searchQuery = NSPredicate(format: "commentId == %d", self.commentId)
        }
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery!)
        
        if(self.localId == 0){
            self.localId = QiscusComment.LastId + 1
        }
        if(commentData.count == 0){
            if self.commentIsFile{
                let fileURL = self.getMediaURL()
                var file = QiscusFile.getCommentFileWithURL(fileURL)
                
                if(file == nil){
                    file = QiscusFile()
                }
                file?.updateURL(fileURL)
                file?.updateCommentId(self.commentId)
                file?.saveCommentFile()
                
                file = QiscusFile.getCommentFileWithComment(self)
                self.commentFileId = file!.fileId
            }
            try! realm.write {
                realm.add(self)
            }
            self.updateCommentCellSize()
            if let user = QiscusUser.getUserWithEmail(self.commentSenderEmail){
                user.updateLastSeen(self.commentCreatedAt)
            }
            return QiscusComment.copyComment(comment: self)
        }else{
            let comment = commentData.first!
            try! realm.write {
                comment.commentId = self.commentId
                comment.commentText = self.commentText
                if(self.commentCreatedAt > 0){
                    comment.commentCreatedAt = self.commentCreatedAt
                }
                
                comment.commentTopicId = self.commentTopicId
                comment.commentSenderEmail = self.commentSenderEmail
                if self.commentFileId > 0 {
                    comment.commentFileId = self.commentFileId
                }
                if(comment.commentStatusRaw < self.commentStatusRaw){
                    comment.commentStatusRaw = self.commentStatusRaw
                }
                if self.commentIsSynced{
                    comment.commentIsSynced = true
                }
            }
            comment.updateCommentCellSize()
            if let user = QiscusUser.getUserWithEmail(comment.commentSenderEmail){
                user.updateLastSeen(comment.commentCreatedAt)
            }
            return QiscusComment.copyComment(comment: comment)
        }
    }
    
    // MARK: - Checking Methode
    open func isFileMessage() -> Bool{
        var check:Bool = false
        if((self.commentText as String).hasPrefix("[file]")){
            check = true
        }
        return check
    }
    open class func isCommentIdExist(_ commentId:Int64)->Bool{
        let realm = try! Realm()
        let searchQuery = NSPredicate(format: "commentId == %d", commentId)
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery)
        
        if commentData.count > 0{
            return true
        }else{
            return false
        }
    }
    open class func isCommentExist(_ commentId:Int64)->Bool{
        let realm = try! Realm()
        let searchQuery = NSPredicate(format: "commentId ==\(commentId)")
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery)
        
        if commentData.count > 0{
            return true
        }else{
            return false
        }
    }
    open class func isUnsyncMessageExist(_ topicId:Int)->Bool{ //
        let realm = try! Realm()
        let searchQuery = NSPredicate(format: "commentIsSynced == false AND commentTopicId == %d",topicId)
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery)
        
        if commentData.count > 0{
            return true
        }else{
            return false
        }
    }
    
    // MARK: - Load More
    open class func loadMoreComment(fromCommentId commentId:Int64, topicId:Int, limit:Int = 10)->[QiscusComment]{
        var comments = [QiscusComment]()
        let realm = try! Realm()
        let searchQuery = NSPredicate(format: "commentId < %d AND commentTopicId == %d", commentId, topicId)
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery).sorted(byProperty: "commentId")
        
        if commentData.count > 0{
            var i = 0
            for comment in commentData {
                if i < limit {
                    comments.append(comment)
                }else{
                    break
                }
                i += 1
            }
        }
        
        return comments
    }
    
    open class func deleteAll(){
        let realm = try! Realm()
        let comments = realm.objects(QiscusComment.self)
        
        if comments.count > 0 {
            try! realm.write {
                realm.delete(comments)
            }
        }
    }
    
    open func calculateTextSizeForComment(){
        var size = CGSize()
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.dataDetectorTypes = .all
        textView.linkTextAttributes = [
            NSForegroundColorAttributeName: QiscusColorConfiguration.sharedInstance.rightBaloonLinkColor,
            NSUnderlineColorAttributeName: QiscusColorConfiguration.sharedInstance.rightBaloonLinkColor,
            NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue,
            NSFontAttributeName: UIFont.systemFont(ofSize: 14)
        ]
        
        let maxWidth:CGFloat = 190
        let comment = QiscusComment.copyComment(comment: self)
        Qiscus.uiThread.async {
            textView.text = comment.commentText
            let textSize = textView.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
            
            size.height = textSize.height + 18
            size.width = textSize.width
            
            if comment.showLink {
                size.height += 73
            }
            Qiscus.dbThread.async {
                comment.updateCommentCellSize(size: size)
            }
        }
    }
    open func calculateTextSizeForCommentLink(linkURL:String, linkTitle:String) -> CGSize {
        var size = CGSize()
        let textView = UITextView()
        textView.font = Qiscus.style.chatFont
        textView.dataDetectorTypes = .all
        textView.linkTextAttributes = [
            NSForegroundColorAttributeName: QiscusColorConfiguration.sharedInstance.rightBaloonLinkColor,
            NSUnderlineColorAttributeName: QiscusColorConfiguration.sharedInstance.rightBaloonLinkColor,
            NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue,
            NSFontAttributeName: Qiscus.style.chatFont
        ]
        
        let maxWidth:CGFloat = 190
        let text = self.commentText.replacingOccurrences(of: linkURL, with: linkTitle)
        let titleRange = (text as NSString).range(of: linkTitle)
        let attributedText = NSMutableAttributedString(string: text)
        attributedText.addAttributes(textView.linkTextAttributes, range: titleRange)
        let allRange = (text as NSString).range(of: text)
        attributedText.addAttribute(NSFontAttributeName, value: Qiscus.style.chatFont, range: allRange)
        textView.attributedText = attributedText
        let textSize = textView.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        
        size.height = textSize.height + 86
        size.width = textSize.width
        
        return size
    }
}
