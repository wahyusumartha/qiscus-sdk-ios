//
//  SearchResultVC.swift
//  Example
//
//  Created by Ahmad Athaullah on 9/5/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
import Qiscus

class SearchResultVC: UITableViewController {
    var comments = [QComment](){
        didSet{
        
        }
    }
    var searchText:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Seach Result"
        self.tableView.dataSource = self
        self.tableView.register(UINib(nibName: "SearchCell", bundle: nil), forCellReuseIdentifier: "searchCell")
        self.tableView.estimatedRowHeight = 300
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.comments.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath)
        if let targetCell = cell as? SearchCell {
            targetCell.searchString = self.searchText
            targetCell.comment = self.comments[indexPath.row]
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let comment = self.comments[indexPath.row]
        let view = Qiscus.chatView(withRoomId: comment.roomId)
        view.chatTarget = comment
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
    }
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
}
