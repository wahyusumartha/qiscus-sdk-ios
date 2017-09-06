//
//  goToChatVC.swift
//  SampleSDK
//
//  Created by Ahmad Athaullah on 1/11/17.
//  Copyright © 2017 Evan Purnama. All rights reserved.
//

import UIKit
import Qiscus

class goToChatVC: UIViewController {

    @IBOutlet weak var targetField: UITextField!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Home"
        Qiscus.cacheData()
        let dismissRecognizer = UITapGestureRecognizer(target: self, action: #selector(goToChatVC.hideKeyboard))
        self.view.addGestureRecognizer(dismissRecognizer)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func goToChat(_ sender: UIButton) {
        if targetField.text! != "" {
            if targetField.text!.contains("@") {
                let emailData = targetField.text!.characters.split(separator: ",")
                if emailData.count > 1 {
                    var emails = [String]()
                    for email in emailData{
                        emails.append(String(email).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
                    }
                    Qiscus.createChat(withUsers:emails, target:self, title:"New Group Chat", subtitle: "Always new chat")
                }else{
                    let email = targetField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                    let view = Qiscus.chatView(withUsers: [email])
                    self.navigationController?.pushViewController(view, animated: true)
                    view.titleAction = {
                        print("title clicked")
                    }
                }
            }else{
                if let roomId = Int(targetField.text!){
                    let view = Qiscus.chatView(withRoomId: roomId)
                    self.navigationController?.pushViewController(view, animated: true)
                    view.titleAction = {
                        print("title clicked")
                    }
                    view.forwardAction = {(comment) in
                        view.navigationController?.popViewController(animated: true)
                        comment.forward(toRoomWithId: 13006)
                        let newView = Qiscus.chatView(withRoomId: 13006)
                        self.navigationController?.pushViewController(newView, animated: true)
                    }
                    view.infoAction = {(comment) in
                        let statusInfo = comment.statusInfo!
                        print("commentInfo: \(statusInfo)")
                        print("delivered to: \(statusInfo.deliveredUser)")
                        print("read by: \(statusInfo.readUser)")
                    }
                }else{
                    let uniqueId = targetField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                    let view = Qiscus.chatView(withRoomUniqueId: uniqueId)
                    self.navigationController?.pushViewController(view, animated: true)
                    view.titleAction = {
                        print("title clicked")
                    }
                }
            }
        }

    }
    @IBAction func ClearData(_ sender: Any) {
        Qiscus.clearData()
    }
    @IBAction func search(_ sender: Any) {
        if targetField.text! != "" {
            QChatService.searchComment(withQuery: targetField.text!, onSuccess: { (comments) in
                print("success search comment with result:\n\(comments)")
                DispatchQueue.main.async {
                    let searchView = SearchResultVC()
                    searchView.comments = comments
                    searchView.searchText = self.targetField.text!
                    self.navigationController?.pushViewController(searchView, animated: true)
                }
                
            }, onFailed: { (error) in
                print("fail to get search result")
            })
        }
    }
    
    @IBAction func logOut(_ sender: UIButton) {
        Qiscus.clear()
        appDelegate.goToLoginView()
    }
    func hideKeyboard(){
        self.view.endEditing(true)
    }
}
