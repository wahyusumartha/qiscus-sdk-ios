//
//  QiscusComment.swift
//  LinkDokter
//
//  Created by Qiscus on 2/24/16.
//  Copyright © 2016 qiscus. All rights reserved.
//

import UIKit
import RealmSwift
import Alamofire
import SwiftyJSON

@objc public enum QiscusCommentType:Int {
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

@objc open class QiscusComment: Object {
    // MARK: - Dynamic Variable
    open dynamic var localId:Int64 = 0
    open dynamic var commentId:Int64 = 0
    open dynamic var commentText:String = ""
    open dynamic var commentCreatedAt: Double = 0
    open dynamic var commentUniqueId: String = ""
    open dynamic var commentTopicId:Int = 0
    open dynamic var commentSenderEmail:String = ""
    open dynamic var commentFileId:Int = 0
    open dynamic var commentStatusRaw:Int = QiscusCommentStatus.sending.rawValue
    open dynamic var commentIsDeleted:Bool = false
    open dynamic var commentIsSynced:Bool = false
    open dynamic var commentBeforeId:Int64 = 0
    open dynamic var commentCellHeight:CGFloat = 0
    open dynamic var commentTextWidth:CGFloat = 0
    open dynamic var commentRow:Int = 0
    open dynamic var commentSection:Int = 0
    open dynamic var showLink:Bool = false
    open dynamic var commentLinkPreviewed:String = ""
    
    open var commentLink:String? {
        get{
            if commentLinkPreviewed != "" {
                return commentLinkPreviewed
            }
            else if let url = QiscusHelper.getFirstLinkInString(text: commentText){
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
            print("message:\(commentText) | commentId:\(commentId) | read:\(minReadId) | delivered:\(minDeliveredId))")
            if commentId <= minReadId {
                print("status: read")
                return QiscusCommentStatus.read
            }else if commentId <= minDeliveredId{
                print("status: delivered")
                return QiscusCommentStatus.delivered
            }else{
                print("status: \(commentStatusRaw)")
                return QiscusCommentStatus(rawValue: commentStatusRaw)!
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
            let now = Date()
            
            let date = Date(timeIntervalSince1970: commentCreatedAt)
            let dayFormatter = DateFormatter()
            //dayFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
            dayFormatter.dateFormat = "EEEE"
            let dayString = dayFormatter.string(from: date)
            let dayNow = dayFormatter.string(from: now)
            if dayNow == dayString {
                return "Today"
            }else{
                return dayString
            }
        }
    }
    open var commentIsFile: Bool {
        get {
            return isFileMessage()
        }
    }
    

    // MARK: - Set Primary Key
    override open class func primaryKey() -> String {
        return "localId"
    }
    
    // MARK: - Getter Class Methode
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
    open class func deleteAllFailedMessage(){ // USED
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
    open class func deleteAllUnsendMessage(){
        let realm = try! Realm()
        let searchQuery:NSPredicate = NSPredicate(format: "commentStatusRaw == %d", QiscusCommentStatus.sending.rawValue)
        let RetNext = realm.objects(QiscusComment.self).filter(searchQuery)
        
        if RetNext.count > 0 {
            for sendingComment in RetNext{
                if let file = QiscusFile.getCommentFileWithComment(sendingComment){
                    if file.fileLocalPath != "" && file.isLocalFileExist(){
                        let manager = FileManager.default
                        try! manager.removeItem(atPath: "\(file.fileLocalPath as String)")
                        try! manager.removeItem(atPath: "\(file.fileThumbPath as String)")
                    }
                    try! realm.write {
                        realm.delete(file)
                    }
                }
                try! realm.write {
                    realm.delete(sendingComment)
                }
            }
        }
    }
    open class func lastCommentInTopic(_ topicId:Int)->QiscusComment?{
        let realm = try! Realm()
        let searchQuery:NSPredicate = NSPredicate(format: "commentTopicId == %d", topicId)
        let RetNext = realm.objects(QiscusComment.self).filter(searchQuery).sorted(byProperty: "commentId")
        
        if RetNext.count > 0 {
            let last = RetNext.last!
            return last
        } else {
            return nil
        }
    }
    open class func lastCommentIdInTopic(_ topicId:Int)->Int64{
        let realm = try! Realm()
        let searchQuery:NSPredicate = NSPredicate(format: "commentTopicId == %d", topicId)
        let RetNext = realm.objects(QiscusComment.self).filter(searchQuery).sorted(byProperty: "commentId")
        
        if RetNext.count > 0 {
            let last = RetNext.last!
            return last.commentId
        } else {
            return 0
        }
    }
    open func getMediaURL() -> String{
        let component1 = (self.commentText as String).components(separatedBy: "[file]")
        let component2 = component1.last!.components(separatedBy: "[/file]")
        let mediaUrlString = component2.first?.trimmingCharacters(in: CharacterSet.whitespaces)
        return mediaUrlString!
    }
    open class func getCommentByLocalId(_ localId: Int64)->QiscusComment?{
        let realm = try! Realm()
        
        let searchQuery:NSPredicate = NSPredicate(format: "localId == %d", localId)
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery)
        
        if(commentData.count == 0){
            return nil
        }else{
            return commentData.first
        }
    }
    open class func getCommentByUniqueId(_ uniqueId: String)->QiscusComment?{
        let realm = try! Realm()
        
        let searchQuery:NSPredicate = NSPredicate(format: "commentUniqueId == '\(uniqueId)'")
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery)
        
        if(commentData.count == 0){
            return nil
        }else{
            return commentData.first
        }
    }
    open class func getCommentById(_ commentId: Int64)->QiscusComment?{
        let realm = try! Realm()
        
        let searchQuery:NSPredicate = NSPredicate(format: "commentId == %d", commentId)
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery)
        
        if(commentData.count == 0){
            return nil
        }else{
            return commentData.first
        }
    }
    open class func getAllComment(_ topicId: Int, limit:Int = 0, fromComment:QiscusComment? = nil, firstLoad:Bool = false)->[QiscusComment]{ // USED
        if firstLoad {
            //QiscusComment.deleteAllFailedMessage()
        }
        var allComment = [QiscusComment]()
        let realm = try! Realm()
        
        let sortProperties = [SortDescriptor(property: "commentCreatedAt", ascending: false), SortDescriptor(property: "commentId", ascending: true)]
        
        var searchQuery:NSPredicate = NSPredicate(format: "commentTopicId == %d",topicId)
        
        if fromComment != nil{
            searchQuery = NSPredicate(format: "commentTopicId == %d AND commentId < %d",topicId, fromComment!.commentId)
        }
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery).sorted(by: sortProperties)
        
        
        if(commentData.count > 0){
            dataLoop: for comment in commentData{
                allComment.insert(comment, at: 0)
            }
        }
        
        Qiscus.printLog(text: "OK from getAllComment")
        return allComment
    }
    open class func getAllComment(_ topicId: Int)->[QiscusComment]{
        var allComment = [QiscusComment]()
        let realm = try! Realm()
        
        let sortProperties = [SortDescriptor(property: "commentCreatedAt"), SortDescriptor(property: "commentId", ascending: true)]
        let searchQuery:NSPredicate = NSPredicate(format: "commentTopicId == %d",topicId)
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery).sorted(by: sortProperties)
        
        if(commentData.count > 0){
            for comment in commentData{
                allComment.append(comment)
            }
        }
        return allComment
    }
    open class func groupAllCommentByDate(_ topicId: Int,limit:Int, firstLoad:Bool = false)->[[QiscusComment]]{ //USED
        var allComment = [[QiscusComment]]()
        let commentData = QiscusComment.getAllComment(topicId, limit: limit, firstLoad: firstLoad)
        
        if(commentData.count > 0){
            var firstCommentInGroup = commentData.first!
            var grouppedMessage = [QiscusComment]()
            var i:Int = 1
            for comment in commentData{
                if(comment.commentDate == firstCommentInGroup.commentDate){
                    grouppedMessage.append(comment)
                }else{
                    allComment.append(grouppedMessage)
                    grouppedMessage = [QiscusComment]()
                    firstCommentInGroup = comment
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
    open class func grouppedComment(inTopicId topicId:Int, fromComment:QiscusComment? = nil ,firstLoad:Bool = true)->[[QiscusComment]]{
        var allComment = [[QiscusComment]]()
        
        let commentData = QiscusComment.getAllComment(topicId, fromComment: fromComment, firstLoad: firstLoad)

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
    open class func groupAllCommentByDateInRoom(_ roomId: Int,limit:Int, firstLoad:Bool = false)->[[QiscusComment]]{ //USED
        var allComment = [[QiscusComment]]()
        var topicId = 0
        if let room = QiscusRoom.getRoomById(roomId){
            if room.roomLastCommentTopicId > 0 {
                topicId = room.roomLastCommentTopicId
            }
        }
        if topicId > 0 {
            
            let commentData = QiscusComment.getAllComment(topicId, limit: limit, firstLoad: firstLoad)
            
            if(commentData.count > 0){
                var firstCommentInGroup = commentData.first!
                var grouppedMessage = [QiscusComment]()
                var i:Int = 1
                for comment in commentData{
                    if(comment.commentDate == firstCommentInGroup.commentDate){
                        grouppedMessage.append(comment)
                    }else{
                        allComment.append(grouppedMessage)
                        grouppedMessage = [QiscusComment]()
                        firstCommentInGroup = comment
                        grouppedMessage.append(comment)
                    }
                    if( i == commentData.count){
                        allComment.append(grouppedMessage)
                    }
                    i += 1
                }
            }
        }
        return allComment
    }
    open class func groupAllCommentByDate(_ topicId: Int)->[[QiscusComment]]{
        var allComment = [[QiscusComment]]()
        let realm = try! Realm()
        
        let sortProperties = [SortDescriptor(property: "commentCreatedAt"), SortDescriptor(property: "commentId", ascending: true)]
        let searchQuery:NSPredicate = NSPredicate(format: "commentTopicId == %d",topicId)
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery).sorted(by: sortProperties)
        
        if(commentData.count > 0){
            var firstCommentInGroup = commentData.first!
            var grouppedMessage = [QiscusComment]()
            var i:Int = 1
            for comment in commentData{
                if(comment.commentDate == firstCommentInGroup.commentDate){
                    grouppedMessage.append(comment)
                }else{
                    allComment.append(grouppedMessage)
                    grouppedMessage = [QiscusComment]()
                    firstCommentInGroup = comment
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
    open func updateCommmentIndexPath(indexPath:IndexPath){
        let realm = try! Realm()
        try! realm.write {
            self.commentRow = indexPath.row
            self.commentSection = indexPath.section
        }
    }
    open class func updateCommmentShowLink(show:Bool, commentId:Int64){
        if let comment = QiscusComment.getCommentById(commentId){
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
    open func updateCommentCellSize(){
        var newSize = CGSize()
        switch self.commentType {
        case .text:
            newSize = self.calculateTextSizeForComment()
            if self.showLink{
                newSize.height += 73
            }
            break
        case .attachment:
            if let file = QiscusFile.getCommentFileWithComment(self){
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

        let realm = try! Realm()
        try! realm.write {
            self.commentCellHeight = newSize.height - 5
            self.commentTextWidth = newSize.width
        }
    }
    open class func getLastSyncCommentId(_ topicId:Int)->Int64?{ //USED
        if QiscusComment.isUnsyncMessageExist(topicId) {
            var lastSyncCommentId:Int64?
            
            let realm = try! Realm()
            let searchQuery = NSPredicate(format: "commentIsSynced == true AND commentTopicId == %d AND (commentStatusRaw == %d OR commentStatusRaw == %d) AND commentId < %d",topicId,QiscusCommentStatus.sent.rawValue,QiscusCommentStatus.delivered.rawValue,QiscusComment.firstUnsyncCommentId(topicId))
            let commentData = realm.objects(QiscusComment.self).filter(searchQuery).sorted(byProperty: "commentCreatedAt")
            
            if commentData.count > 0{
                lastSyncCommentId = commentData.last!.commentId
            }else{
                lastSyncCommentId = QiscusComment.lastCommentIdInTopic(topicId)
            }
            return lastSyncCommentId
        }else{
            return QiscusComment.lastCommentIdInTopic(topicId)
        }
    }
    open class func countCommentOntTopic(_ topicId:Int)->Int{ // USED
        let realm = try! Realm()
        
        let searchQuery:NSPredicate = NSPredicate(format: "commentTopicId == %d", topicId)
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery)
        
        return commentData.count
    }
    // MARK: - getComment from JSON
    open class func getCommentTopicIdFromJSON(_ data: JSON) -> Int{ //USED
        return data["topic_id"].intValue
    }
    open class func getCommentIdFromJSON(_ data: JSON) -> Int64{ // USED
        var commentId:Int64 = 0

        if let id = data["id"].int64{
            commentId = id
        }else if let id = data["comment_id"].int64{
            commentId = id
        }
        return commentId
    }
    open class func getComment(fromRealtimeJSON data:JSON)->Bool{
        /*
        {
            "user_avatar" : "https:\/\/qiscuss3.s3.amazonaws.com\/uploads\/2843d09883c80473ff84a5cc4922f561\/qiscus-dp.png",
            "unique_temp_id" : "ios-14805592733157",
            "topic_id" : 407,
            "created_at" : "2016-12-01T02:27:54.930Z",
            "room_name" : "ee",
            "username" : "ee",
            "message" : "dddd",
            "email" : "e3@qiscus.com",
            "comment_before_id" : 13764,
            "room_id" : 427,
            "timestamp" : "2016-12-01T02:27:54Z",
            "id" : 13765,
            "chat_type" : "single"
        }
        */
        let topicId = data["topic_id"].intValue
        let comment = QiscusComment()
        
        comment.commentTopicId = topicId
        comment.commentSenderEmail = data["email"].stringValue
        comment.commentStatusRaw = QiscusCommentStatus.sent.rawValue
        comment.commentBeforeId = data["comment_before_id"].int64Value
        comment.commentText = data["message"].stringValue
        comment.commentId = data["id"].int64Value
        comment.commentUniqueId = data["unique_temp_id"].stringValue
        let createdAt = data["timestamp"].stringValue
        let dateTimeArr = createdAt.characters.split(separator: "T")
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
        if let sender = QiscusUser.getUserWithEmail(comment.commentSenderEmail as String){
            sender.usernameAs(data["username"].stringValue)
        }
        if QiscusComment.isValidCommentIdExist(comment.commentBeforeId) || QiscusComment.countCommentOntTopic(topicId) == 0{
            comment.commentIsSynced = true
        }
        if comment.commentType == QiscusCommentType.text && comment.commentLink != nil{
            if let disableLink = data["disable_link_preview"].bool{
                comment.showLink = !disableLink
            }else{
                comment.showLink = true
            }
        }
        let isSaved = comment.saveComment(true)
        if isSaved{
            Qiscus.printLog(text: "New comment saved")
        }
        
        return isSaved
    }
    open class func getCommentBeforeIdFromJSON(_ data: JSON) -> Int64{//USED
        return data["comment_before_id"].int64Value
    }
    open class func getSenderFromJSON(_ data: JSON) -> String{
        return data["username_real"].stringValue
    }
    open class func getCommentFromJSON(_ data: JSON) -> Bool{
        let comment = QiscusComment()
        comment.commentTopicId = data["topic_id"].intValue
        comment.commentSenderEmail = data["username_real"].stringValue
        comment.commentStatusRaw = QiscusCommentStatus.sent.rawValue
        comment.commentBeforeId = data["comment_before_id"].int64Value
        var created_at:String = ""
        var usernameAs:String = ""
        if(data["username_as"] != nil){
            comment.commentText = data["message"].stringValue
            comment.commentId = data["id"].int64Value
            usernameAs = data["username_as"].stringValue
            comment.commentIsDeleted = data["deleted"].boolValue
            created_at = data["created_at"].stringValue
        }else{
            comment.commentText = data["comment"].stringValue
            comment.commentId = data["id"].int64Value
            usernameAs = data["username"].stringValue
            if let uniqueId = data["unique_temp_id"].string {
                comment.commentUniqueId = uniqueId
            }else if let randomme = data["randomme"].string {
                comment.commentUniqueId = randomme
            }
            created_at = data["created_at_ios"].stringValue
        }
        if let sender = QiscusUser.getUserWithEmail(comment.commentSenderEmail as String){
            sender.usernameAs(usernameAs)
        }
        let rawDateFormatter = DateFormatter()
        rawDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        rawDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        
        let chatDate = rawDateFormatter.date(from: "\(created_at as String) +0000")
        
        if chatDate != nil{
            let timetoken = Double(chatDate!.timeIntervalSince1970)
            comment.commentCreatedAt = timetoken
        }
        comment.commentStatusRaw = QiscusCommentStatus.sent.rawValue
        let saved = comment.saveComment(true)
        return saved
    }
    
    
    open class func getCommentFromJSON(_ data: JSON, topicId:Int, saved:Bool) -> Bool{ // USED
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
            comment.commentIsDeleted = data["deleted"].boolValue
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
            sender.usernameAs(usernameAs)
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
        if QiscusComment.isValidCommentIdExist(comment.commentBeforeId) || QiscusComment.countCommentOntTopic(topicId) == 0{
            comment.commentIsSynced = true
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
        let realm = try! Realm()
        
        let searchQuery:NSPredicate = NSPredicate(format: "commentUniqueId == '\(self.commentUniqueId)' && commentUniqueId != ''")
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery)
        
        if(commentData.count > 0){
            try! realm.write {
                self.commentId = commentId
            }
        }
    }
    open func updateCommentIsSync(_ sync: Bool){
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
    open class func getLastSentComent(inRoom roomId:Int)->QiscusComment?{
        if let room = QiscusRoom.getRoomById(roomId){
            let topicId = room.roomLastCommentTopicId
            
            let realm = try! Realm()
            let searchQuery:NSPredicate = NSPredicate(format: "commentTopicId == %d", topicId)
            let commentData = realm.objects(QiscusComment.self).filter(searchQuery).sorted(byProperty: "commentId", ascending: false)
            
            for comment in commentData {
                if comment.commentStatus != QiscusCommentStatus.failed && comment.commentStatus != QiscusCommentStatus.sending{
                    return comment
                }
            }
            return nil
        }else{
            return nil
        }
    }

    open func updateCommentStatus(_ status: QiscusCommentStatus, email:String? = nil){
        if(self.commentStatus.rawValue < status.rawValue) || self.commentStatus == .failed{
            var changeStatus = false
            if status != QiscusCommentStatus.read && status != QiscusCommentStatus.delivered{
                let realm = try! Realm()
                try! realm.write {
                    self.commentStatusRaw = status.rawValue
                }
                changeStatus = true
            }else{
                if email != nil{
                    if let participant = QiscusParticipant.getParticipant(withEmail: email!, roomId: self.roomId){
                        if status == QiscusCommentStatus.read{
                            let oldMinReadId = QiscusParticipant.getMinReadCommentId(onRoom: self.roomId)
                            participant.updateLastReadCommentId(commentId: self.commentId)
                            if  QiscusParticipant.getMinReadCommentId(onRoom: self.roomId) != oldMinReadId{
                                changeStatus = true
                            }
                        }else{
                            let oldMinDeliveredId = QiscusParticipant.getMinDeliveredCommentId(onRoom: self.roomId)
                            participant.updateLastDeliveredCommentId(commentId: self.commentId)
                            if  QiscusParticipant.getMinDeliveredCommentId(onRoom: self.roomId) != oldMinDeliveredId{
                                changeStatus = true
                            }
                        }
                    }
                }
            }
            if changeStatus {
                if let commentDelegate = QiscusCommentClient.sharedInstance.commentDelegate{
                    commentDelegate.commentDidChangeStatus(fromComment: self, toStatus: status)
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
    open class func newCommentWithMessage(message:String, inTopicId:Int, showLink:Bool = false)->QiscusComment{
        let realm = try! Realm()
        let searchQuery = NSPredicate(format: "commentTopicId == %d", inTopicId)
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery).sorted(byProperty: "commentId")
        
        var lastComentInTopic:QiscusComment = QiscusComment()
        if commentData.count > 0 {
            lastComentInTopic = commentData.last!
        }
        
        let comment = QiscusComment()
        let time = Double(Date().timeIntervalSince1970)
        let timeToken = UInt64(time * 10000)
        let uniqueID = "ios-\(timeToken)"
        let config = QiscusConfig.sharedInstance
        comment.localId = QiscusComment.LastId + 1
        comment.commentId = (lastComentInTopic.commentId + 1)
        comment.commentText = message
        comment.commentCreatedAt = Double(Date().timeIntervalSince1970)
        comment.commentUniqueId = uniqueID
        comment.commentTopicId = inTopicId
        comment.commentSenderEmail = config.USER_EMAIL
        comment.commentStatusRaw = QiscusCommentStatus.sending.rawValue
        comment.commentIsSynced = false
        comment.commentBeforeId = lastComentInTopic.commentId
        comment.showLink = showLink
        return comment.saveComment()
    }
    
    // MARK: - Save and Delete Comment
    open func deleteComment(){
        let realm = try! Realm()
        try! realm.write {
            realm.delete(self)
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
    open func saveComment(_ saved:Bool)->Bool{ // USED
        let realm = try! Realm()
        let searchQuery:NSPredicate?
        print("commentId: \(self.commentId)")
        print("commentUniqueId: \(self.commentUniqueId)")
        searchQuery = NSPredicate(format: "commentId == %d OR commentUniqueId == '\(self.commentUniqueId)'", self.commentId)
        print("searchQuery: \(searchQuery)")
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
            return true
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
                comment.commentIsDeleted = self.commentIsDeleted
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
            return self
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
                comment.commentIsDeleted = self.commentIsDeleted
            }
            comment.updateCommentCellSize()
            return comment
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
    open class func isCommentExist(_ comment:QiscusComment)->Bool{
        let realm = try! Realm()
        let searchQuery = NSPredicate(format: "commentId == %d", comment.commentId)
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery)
        
        if commentData.count > 0{
            return true
        }else{
            return false
        }
    }
    open class func isCommentIdExist(_ commentId:Int)->Bool{
        let realm = try! Realm()
        let searchQuery = NSPredicate(format: "commentId == %d", commentId)
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery)
        
        if commentData.count > 0{
            return true
        }else{
            return false
        }
    }
    open class func isValidCommentIdExist(_ commentId:Int64)->Bool{
        let realm = try! Realm()
        let searchQuery = NSPredicate(format: "commentId == %d AND commentIsSynced == true AND commentStatusRaw == %d", commentId,QiscusCommentStatus.delivered.rawValue)
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery)
        
        if commentData.count > 0{
            return true
        }else{
            return false
        }
    }
    open class func isUnsyncMessageExist(_ topicId:Int)->Bool{ // USED
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
    
    open func calculateTextSizeForComment() -> CGSize {
        var size = CGSize()
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 13)
        textView.dataDetectorTypes = .all
        textView.linkTextAttributes = [
            NSForegroundColorAttributeName: QiscusColorConfiguration.sharedInstance.rightBaloonLinkColor,
            NSUnderlineColorAttributeName: QiscusColorConfiguration.sharedInstance.rightBaloonLinkColor,
            NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue,
            NSFontAttributeName: UIFont.systemFont(ofSize: 13)
        ]
        
        let maxWidth:CGFloat = 190
        
        textView.text = self.commentText
        let textSize = textView.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        
        size.height = textSize.height + 18
        size.width = textSize.width
        
        return size
    }
    open func calculateTextSizeForCommentLink(linkURL:String, linkTitle:String) -> CGSize {
        var size = CGSize()
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 13)
        textView.dataDetectorTypes = .all
        textView.linkTextAttributes = [
            NSForegroundColorAttributeName: QiscusColorConfiguration.sharedInstance.rightBaloonLinkColor,
            NSUnderlineColorAttributeName: QiscusColorConfiguration.sharedInstance.rightBaloonLinkColor,
            NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue,
            NSFontAttributeName: UIFont.systemFont(ofSize: 13)
        ]
        
        let maxWidth:CGFloat = 190
        let text = self.commentText.replacingOccurrences(of: linkURL, with: linkTitle)
        let titleRange = (text as NSString).range(of: linkTitle)
        let attributedText = NSMutableAttributedString(string: text)
        attributedText.addAttributes(textView.linkTextAttributes, range: titleRange)
        let allRange = (text as NSString).range(of: text)
        attributedText.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 13), range: allRange)
        textView.attributedText = attributedText
        let textSize = textView.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        
        size.height = textSize.height + 86
        size.width = textSize.width
        
        return size
    }
}
