//
//  QRoomList.swift
//  Example
//
//  Created by Ahmad Athaullah on 9/15/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
public protocol QRoomListDelegate {
    func didSelect(room: QRoom)
    func didSelect(comment: QComment)
}

open class QRoomList: UITableView{
    public var listDelegate: QRoomListDelegate?
    
    public var rooms = [QRoom]() {
        didSet{
            let indexSet = IndexSet(integer: 0)
            self.reloadSections(indexSet, with: UITableViewRowAnimation.fade)
        }
    }
    
    public var comments = [QComment](){
        didSet{
            let indexSet = IndexSet(integer: 1)
            self.reloadSections(indexSet, with: UITableViewRowAnimation.fade)
        }
    }
    override open func draw(_ rect: CGRect) {
        // Drawing code
        self.delegate = self
        self.dataSource = self
        registerCell()
    }
 
    open func registerCell(){}
    internal func didSelectRoom(room: QRoom){
        self.listDelegate?.didSelect(room: room)
    }
    internal func didSelectComment(comment: QComment){
        self.listDelegate?.didSelect(comment: comment)
    }
    
    open func cell(at indexPath: IndexPath) -> QRoomListCell { return QRoomListCell()}
    
}

extension QRoomList: UITableViewDelegate,UITableViewDataSource {
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return self.rooms.count
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
        let cell = self.cell(at: indexPath)
        if indexPath.section == 0 {
            cell.room = self.rooms[indexPath.row]
        }else{
            cell.comment = self.comments[indexPath.row]
        }
        return self.cell(at: indexPath)
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            didSelectRoom(room: self.rooms[indexPath.row])
        }else{
            didSelectComment(comment: self.comments[indexPath.row])
        }
    }
}
