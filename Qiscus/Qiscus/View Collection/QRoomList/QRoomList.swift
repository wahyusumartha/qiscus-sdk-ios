//
//  QRoomList.swift
//  Example
//
//  Created by Ahmad Athaullah on 9/15/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
@objc public protocol QRoomListDelegate {
    @objc optional func didSelect(room: QRoom)
    @objc optional func didDeselect(room:QRoom)
    @objc optional func didSelect(comment: QComment)
    @objc optional func didDeselect(comment:QComment)
}

open class QRoomList: UITableView{
    public var listDelegate: QRoomListDelegate?
    
    public var rooms = [QRoom]()
    
    public var filteredRooms: [QRoom] {
        get{
            let text = searchText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if text == "" {
                return self.rooms
            }else{
                return self.rooms.filter({ (room) in
                    return room.name.lowercased().contains(text)
                })
            }
        }
    }
    
    public var comments = [QComment](){
        didSet{
            let indexSet = IndexSet(integer: 1)
            self.reloadSections(indexSet, with: UITableViewRowAnimation.fade)
        }
    }
    
    public var searchText:String = "" {
        didSet{
            let indexSet = IndexSet(integer: 0)
            self.reloadSections(indexSet, with: .none)
        }
    }
    
    override open func draw(_ rect: CGRect) {
        // Drawing code
        self.delegate = self
        self.dataSource = self
        self.estimatedRowHeight = 60
        self.rowHeight = UITableViewAutomaticDimension
        self.tableFooterView = UIView()
        NotificationCenter.default.addObserver(self, selector: #selector(QRoomList.newCommentNotif(_:)), name: QiscusNotification.GOT_NEW_COMMENT, object: nil)
        registerCell()
    }
 
    open func registerCell(){
        self.register(UINib(nibName: "QRoomListDefaultCell", bundle: Qiscus.bundle), forCellReuseIdentifier: "roomDefaultCell")
        self.register(UINib(nibName: "QSearchListDefaultCell", bundle: Qiscus.bundle), forCellReuseIdentifier: "searchDefaultCell")
    }
    internal func didSelectRoom(room: QRoom){
        self.listDelegate?.didSelect?(room: room)
    }
    internal func didSelectComment(comment: QComment){
        self.listDelegate?.didSelect?(comment: comment)
    }
    
    open func roomCell(at row: Int) -> QRoomListCell {
        let indexPath = IndexPath(row: row, section: 0)
        let cell = self.dequeueReusableCell(withIdentifier: "roomDefaultCell", for: indexPath) as! QRoomListDefaultCell
        return cell
    }
    
    open func commentCell(at row: Int) -> QSearchListCell{
        let indexPath = IndexPath(row: row, section: 1)
        let cell = self.dequeueReusableCell(withIdentifier: "searchDefaultCell", for: indexPath) as! QSearchListDefaultCell
        return cell
    }
    open func gotNewComment(inRoom room:QRoom?, comment:QComment){
        self.rooms = QRoom.all()
        let indexSet = IndexSet(integer: 0)
        self.reloadSections(indexSet, with: .none)
    }
    
    public func search(text:String){
        self.searchText = text
        QChatService.searchComment(withQuery: text, onSuccess: { (comments) in
            if text == self.searchText {
                self.comments = comments
            }
        }) { (error) in
            print("test")
        }
    }
    
    @objc private func newCommentNotif(_ notification: Notification){
        if let userInfo = notification.userInfo {
            let comment = userInfo["comment"] as! QComment
            self.gotNewComment(inRoom: comment.room, comment: comment)
        }
    }
    
    open func roomSectionHeight()->CGFloat{
        if self.searchText != ""{
            return 25.0
        } else {
            return 0
        }
    }
    
    open func commentSectionHeight()->CGFloat{
        if self.searchText != ""{
            return 25.0
        } else {
            return 0
        }
    }
    
    open func roomHeader()->UIView? {
        if self.searchText != "" {
            let screenWidth: CGFloat    = QiscusHelper.screenWidth()
            
            let container           = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 25))
            let title               = UILabel(frame: CGRect(x: 8, y: 0, width: screenWidth - 16, height: 25))
            title.textAlignment     = NSTextAlignment.left
            title.textColor         = UIColor.black
            title.font              = UIFont.boldSystemFont(ofSize: 12)
            
            title.text = "Conversations"
            
            container.backgroundColor = UIColor.lightGray
            container.addSubview(title)
            return container
        } else {
            return nil
        }
    }
    
    open func commentHeader()->UIView?{
        if self.searchText != "" {
            let screenWidth: CGFloat    = QiscusHelper.screenWidth()
            let container           = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 25))
            let title               = UILabel(frame: CGRect(x: 8, y: 0, width: screenWidth - 16, height: 25))
            title.textAlignment     = NSTextAlignment.left
            title.textColor         = UIColor.black
            title.font              = UIFont.boldSystemFont(ofSize: 12)
            
            title.text = "Messages"
            container.backgroundColor = UIColor.lightGray
            container.addSubview(title)
            return container
        } else {
            return nil
        }
    }
}

extension QRoomList: UITableViewDelegate,UITableViewDataSource {
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return self.filteredRooms.count
        case 1:
            return self.comments.count
        default:
            return 0
        }
    }
    
    open func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = self.roomCell(at: indexPath.row)
            cell.room = self.filteredRooms[indexPath.row]
            cell.searchText = searchText
            return cell
        }else{
            let cell = self.commentCell(at: indexPath.row)
            cell.comment = self.comments[indexPath.row]
            cell.searchText = self.searchText
            return cell
        }
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            didSelectRoom(room: self.filteredRooms[indexPath.row])
        }else{
            didSelectComment(comment: self.comments[indexPath.row])
        }
    }

    open func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            self.listDelegate?.didDeselect?(room: self.filteredRooms[indexPath.row])
        }else{
            self.listDelegate?.didDeselect?(comment: self.comments[indexPath.row])
        }
    }
    
    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return self.roomSectionHeight()
        }else{
            return self.commentSectionHeight()
        }
    }
    
    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return roomHeader()
        }else{
            return commentHeader()
        }
    }
}
