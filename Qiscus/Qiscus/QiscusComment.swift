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
            if !self.copyProcess {
                let id : Int64 = self.localId
                let value = self.commentId
                if let savedComment = QiscusComment.comment(withLocalId: id){
                    let realm = try! Realm()
                    try! realm.write {
                        savedComment.commentId = value
                    }
                }
            }
        }
    }
    open dynamic var commentText:String = ""{
        didSet{
            if !self.copyProcess {
                let id : Int64 = self.localId
                let value = self.commentText
                if let savedComment = QiscusComment.comment(withLocalId: id){
                    let realm = try! Realm()
                    if self.commentIsFile{
                        let fileURL = self.getMediaURL()
                        var file = QiscusFile.getCommentFileWithURL(fileURL)
                        if(file == nil){
                            file = QiscusFile()
                            file?.updateURL(fileURL)
                            file?.updateCommentId(self.commentId)
                            file?.saveCommentFile()
                            file = QiscusFile.getCommentFileWithComment(self)
                        }
                        self.commentFileId = file!.fileId
                    }
                    try! realm.write {
                        savedComment.commentText = value
                    }
                }
            }
        }
    }
    open dynamic var commentCreatedAt: Double = 0 {
        didSet{
            if !self.copyProcess{
                let id : Int64 = self.localId
                let value = self.commentCreatedAt
                if let savedComment = QiscusComment.comment(withLocalId: id){
                    let realm = try! Realm()
                    try! realm.write {
                        savedComment.commentCreatedAt = value
                    }
                }
            }
        }
    }
    open dynamic var commentUniqueId: String = "" {
        didSet{
            if !self.copyProcess {
                let id : Int64 = self.localId
                let value = self.commentUniqueId
                if let savedComment = QiscusComment.comment(withLocalId: id){
                    let realm = try! Realm()
                    try! realm.write {
                        savedComment.commentUniqueId = value
                    }
                }
            }
        }
    }
    open dynamic var commentTopicId:Int = 0 {
        didSet{
            if !self.copyProcess {
                let id : Int64 = self.localId
                let value = self.commentTopicId
                if let savedComment = QiscusComment.comment(withLocalId: id){
                    let realm = try! Realm()
                    try! realm.write {
                        savedComment.commentTopicId = value
                    }
                }
            }
        }
    }
    open dynamic var commentSenderEmail:String = ""{
        didSet{
            if !self.copyProcess {
                let id : Int64 = self.localId
                let value = self.commentSenderEmail
                if let savedComment = QiscusComment.comment(withLocalId: id){
                    let realm = try! Realm()
                    try! realm.write {
                        savedComment.commentSenderEmail = value
                    }
                }
            }
        }
    }
    open dynamic var commentFileId:Int = 0 {
        didSet{
            if !self.copyProcess {
                let id : Int64 = self.localId
                let value = self.commentFileId
                if let savedComment = QiscusComment.comment(withLocalId: id){
                    let realm = try! Realm()
                    try! realm.write {
                        savedComment.commentFileId = value
                    }
                }
            }
        }
    }
    open dynamic var commentStatusRaw:Int = QiscusCommentStatus.sending.rawValue {
        didSet{
            if !self.copyProcess {
                let id : Int64 = self.localId
                let value = self.commentStatusRaw
                Qiscus.dbThread.async {
                    if value != QiscusCommentStatus.delivered.rawValue &&
                        value != QiscusCommentStatus.read.rawValue{
                        if let savedComment = QiscusComment.comment(withLocalId: id){
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
    }
    open dynamic var commentIsSynced:Bool = false {
        didSet{
            if !self.copyProcess {
                let id : Int64 = self.localId
                let value = self.commentIsSynced
                if let savedComment = QiscusComment.comment(withLocalId: id){
                    let realm = try! Realm()
                    try! realm.write {
                        savedComment.commentIsSynced = value
                    }
                }
            }
        }
    }
    open dynamic var commentBeforeId:Int64 = 0 {
        didSet{
            if !self.copyProcess {
                let id : Int64 = self.localId
                let value = self.commentBeforeId
                if let savedComment = QiscusComment.comment(withLocalId: id){
                    let realm = try! Realm()
                    try! realm.write {
                        savedComment.commentBeforeId = value
                    }
                }
            }
        }
    }
    open dynamic var commentCellHeight:CGFloat = 0{
        didSet{
            if !self.copyProcess {
                let id : Int64 = self.localId
                let value = self.commentCellHeight
                if let savedComment = QiscusComment.comment(withLocalId: id){
                    let realm = try! Realm()
                    try! realm.write {
                        savedComment.commentCellHeight = value
                    }
                }
            }
        }
    }
    open dynamic var commentCellWidth:CGFloat = 0 {
        didSet{
            if !self.copyProcess {
                let id : Int64 = self.localId
                let value = self.commentCellWidth
                Qiscus.dbThread.async {
                    if let savedComment = QiscusComment.comment(withLocalId: id){
                        let realm = try! Realm()
                        try! realm.write {
                            savedComment.commentCellWidth = value
                        }
                    }
                }
            }
        }
    }
    open dynamic var showLink:Bool = false {
        didSet{
            if !self.copyProcess {
                let id : Int64 = self.localId
                var value = self.showLink
                if let savedComment = QiscusComment.comment(withLocalId: id){
                    if value {
                        if self.commentLink == nil {
                            value = false
                        }
                    }
                    let realm = try! Realm()
                    
                    try! realm.write {
                        savedComment.showLink = value
                    }
                }
            }
        }
    }
    open dynamic var commentLinkPreviewed:String = "" {
        didSet{
            if !self.copyProcess {
                let id : Int64 = self.localId
                let value = self.commentLinkPreviewed
                if let savedComment = QiscusComment.comment(withLocalId: id){
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
    fileprivate var copyProcess:Bool = false
    
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
            if self.commentIsFile{
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
            var check:Bool = false
            if((self.commentText as String).hasPrefix("[file]")){
                check = true
            }
            return check
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
        newComment.copyProcess = true
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
        newComment.commentCellWidth = comment.commentCellWidth
        newComment.showLink = comment.showLink
        newComment.commentLinkPreviewed = comment.commentLinkPreviewed
        newComment.copyProcess = false
        return newComment
    }
    
    // MARK: - new comment
    public class func newComment(withId commentId:Int64, andUniqueId uniqueId:String)->QiscusComment{
        let comment = QiscusComment()
        comment.commentId = commentId
        comment.commentUniqueId = uniqueId
        
        let realm = try! Realm()
        
        try! realm.write {
            comment.localId = QiscusComment.LastId + 1
            realm.add(comment)
        }
        return QiscusComment.copyComment(comment: comment)
    }
    public class func newComment(withMessage message:String, inTopicId:Int, showLink:Bool = false)->QiscusComment{
        let comment = QiscusComment()
        let realm = try! Realm()
        
        let newComment = QiscusComment()
        
        try! realm.write {
            newComment.localId = QiscusComment.LastId + 1
            realm.add(newComment)
        }
        comment.localId = newComment.localId
        
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
    
    // MARK : - get comment
    public class func comment(withId commentId:Int64, andUniqueId uniqueId:String? = nil)->QiscusComment?{
        let realm = try! Realm()
        let searchQuery:NSPredicate?
        var query = "commentId == \(commentId)"
        if uniqueId != nil {
            query = "\(query) OR commentUniqueId == '\(uniqueId!)'"
        }
        searchQuery = NSPredicate(format: query)
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery!)
        
        if commentData.count == 0 {
            return nil
        }else{
            return QiscusComment.copyComment(comment: commentData.first!)
        }
    }
    public class func comment(withLocalId localId:Int64)->QiscusComment?{
        let realm = try! Realm()
        let searchQuery:NSPredicate = NSPredicate(format: "localId == \(localId)")
        let RetNext = realm.objects(QiscusComment.self).filter(searchQuery)
        
        if RetNext.count > 0 {
            return RetNext.last!
        } else {
            return nil
        }
    }
    public class func comment(withUniqueId uniqueId: String)->QiscusComment?{
        let realm = try! Realm()
        
        let searchQuery:NSPredicate = NSPredicate(format: "commentUniqueId == '\(uniqueId)'")
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery)
        
        if(commentData.count == 0){
            return nil
        }else{
            return QiscusComment.copyComment(comment: commentData.first!)
        }
    }
    public class func getLastComment(inTopicId topicId:Int? = nil)->QiscusComment?{
        let realm = try! Realm()
        var searchQuery:NSPredicate = NSPredicate(format: "(commentStatusRaw != \(QiscusCommentStatus.sending.rawValue) OR commentStatusRaw == \(QiscusCommentStatus.failed.rawValue))")
        if topicId != nil {
            searchQuery = NSPredicate(format: "commentTopicId == \(topicId!)")
        }
        let RetNext = realm.objects(QiscusComment.self).filter(searchQuery).sorted(byProperty: "commentId")
        
        if RetNext.count > 0 {
            let last = QiscusComment.copyComment(comment: RetNext.last!)
            return last
        } else {
            return nil
        }
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
        
        let sortProperties = [SortDescriptor(property: "commentId", ascending: true)]
        let searchQuery:NSPredicate = NSPredicate(format: "commentTopicId == \(topicId) AND commentId != 0")
        
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery).sorted(by: sortProperties)
        
        
        if(commentData.count > 0){
            let lastCommentId = commentData.first!.localId
            for comment in commentData{
                if !QiscusComment.isExist(commentId: comment.commentBeforeId) && comment.localId != lastCommentId{
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
            var count = 0
            var previousUid = commentData.first!.commentUniqueId
            for comment in commentData{
                if (count <= limit || limit == 0){
                    if comment.commentUniqueId != previousUid || count == 0{
                        allComment.insert(QiscusComment.copyComment(comment: comment), at: 0)
                        previousUid = comment.commentUniqueId
                        count += 1
                    }else{
                        try! realm.write {
                            realm.delete(comment)
                        }
                    }
                }else{
                    break
                }
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
    open class func grouppedComment(inTopicId topicId:Int, fromCommentId:Int64? = nil, limit:Int = 0)->[[QiscusComment]]{
        var allComment = [[QiscusComment]]()
        
        let commentData = QiscusComment.getComments(inTopicId: topicId, limit: limit,fromCommentId: fromCommentId)
        
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
    
    // MARK: Object Getter Method
    public func getMediaURL() -> String{
        let component1 = (self.commentText as String).components(separatedBy: "[file]")
        let component2 = component1.last!.components(separatedBy: "[/file]")
        let mediaUrlString = component2.first?.trimmingCharacters(in: CharacterSet.whitespaces)
        return mediaUrlString!
    }
    
    // MARK: - Object Setter Method

    open class func getLastSyncCommentId(_ topicId:Int, unsyncCommentId:Int64)->Int64?{ //
        
        let realm = try! Realm()
        let searchQuery = NSPredicate(format: "commentTopicId == \(topicId) AND (commentStatusRaw != \(QiscusCommentStatus.sending.rawValue) OR commentStatusRaw == \(QiscusCommentStatus.failed.rawValue)) AND commentId < \(unsyncCommentId)")
        let commentData = realm.objects(QiscusComment.self).filter(searchQuery).sorted(byProperty: "commentCreatedAt", ascending: true)
        
        if commentData.count > 0{
            let firstCommentId = commentData.first!.localId
            for comment in commentData.reversed(){
                print("comment: \(comment.commentId)  :  \(comment.commentText)")
                if QiscusComment.isExist(commentId: comment.commentBeforeId) || comment.localId == firstCommentId{
                    return comment.commentId
                }
            }
        }
        return nil
    }

    
    // MARK: - Updater Methode
    
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
    
    // MARK: - Checking Methode
    public class func isExist(commentId:Int64)->Bool{
        let realm = try! Realm()
        let searchQuery = NSPredicate(format: "commentId == %d", commentId)
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
    
    // MARK: - Delete
    open class func deleteAll(){
        let realm = try! Realm()
        let comments = realm.objects(QiscusComment.self)
        
        if comments.count > 0 {
            try! realm.write {
                realm.delete(comments)
            }
        }
    }
    public func deleteComment(){
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
}
