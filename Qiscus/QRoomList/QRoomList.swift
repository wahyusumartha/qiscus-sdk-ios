//
//  ListChatViewController.swift
//  example
//
//  Created by Qiscus on 30/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import UIKit
import QiscusUI
import QiscusCore

open class QRoomList: UIChatListViewController {
    var roomData : [QRoom] = [QRoom]()
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Chat List"
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let room = self.rooms[indexPath.row]
        self.chat(withRoom: room as! QRoom)
    }
    
    private func chat(withRoom room: QRoom) {
        let target = QiscusChatVC()
        target.room = room
        self.navigationController?.pushViewController(target, animated: true)
    }
}
