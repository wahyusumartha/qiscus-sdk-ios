//
//  RoomListVC2.swift
//  Example
//
//  Created by Ahmad Athaullah on 9/15/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
import Qiscus

class RoomListVC2: UIViewController {

    @IBOutlet weak var roomListView: QRoomList!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var rooms = [QRoom](){
        didSet{
            roomListView.rooms = self.rooms
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Chat List"
        
        self.roomListView.listDelegate = self
        
        let logoutButton = UIBarButtonItem(image: UIImage(named: "ic_exit_to_app"), style: .plain, target: self, action: #selector(logOut))
        self.navigationItem.leftBarButtonItems = [logoutButton]
        let addButton = UIBarButtonItem(title: "+", style: .plain, target: self, action: #selector(addChat))
        let searchButton = UIBarButtonItem(title: "s", style: .plain, target: self, action: #selector(searchText))

        let rightBarButtons = [ addButton, searchButton]
        self.navigationItem.rightBarButtonItems = rightBarButtons
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.showQiscusLoading()
        self.rooms = QRoom.all()
        
        if self.rooms.count == 0 {
            self.loadRoomList()
        }else{
            Qiscus.subscribeAllRoomNotification()
            self.dismissQiscusLoading()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func searchText(){
        self.roomListView.search(text: "kiwari")
    }
    func loadRoomList(page:Int? = 1){
        QChatService.roomList(withLimit: 100, page: page, onSuccess: { (rooms, totalRoom, currentPage, limit) in
            if totalRoom > (limit * (currentPage - 1)) + rooms.count{
                self.loadRoomList(page: currentPage + 1)
            }else{
                DispatchQueue.main.async {
                    self.rooms = QRoom.all()
                    Qiscus.subscribeAllRoomNotification()
                    self.roomListView.reloadData()
                    self.dismissQiscusLoading()
                }
            }
        }) { (error) in
            print("\(error)")
        }
    }
    
    func logOut(){
        Qiscus.clear()
        self.appDelegate.goToLoginView()
    }
    func addChat(){
        let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cancelActionButton = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)
        
        let singleChat = UIAlertAction(title: "Add Single Chat", style: .default) { action -> Void in
            self.createChat(type: .single)
        }
        actionSheetController.addAction(singleChat)
        
        let groupChat = UIAlertAction(title: "Add Group Chat", style: .default) { action -> Void in
            self.createChat(type: .group)
        }
        actionSheetController.addAction(groupChat)
        
        let channelChat = UIAlertAction(title: "Add Channel", style: .default) { action -> Void in
            self.createChat(type: .channel)
        }
        actionSheetController.addAction(channelChat)
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
    func createChat(type:AddChatType){
        let view = goToChatVC()
        view.type = type
        self.navigationController?.pushViewController(view, animated: true)
    }
    
}
extension RoomListVC2: QRoomListDelegate {
    func didSelect(room: QRoom) {
        let chatView = Qiscus.chatView(withRoomId: room.id)
        self.navigationController?.pushViewController(chatView, animated: true)
    }
    func didSelect(comment: QComment) {
        
    }
}
extension QRoomList {
    func commentCell(at indexPath: IndexPath) -> UITableViewCell{
    return UITableViewCell()
    }

}

