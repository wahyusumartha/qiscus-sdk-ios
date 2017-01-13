//
//  MainView.swift
//  SampleSDK
//
//  Created by Ahmad Athaullah on 1/11/17.
//  Copyright © 2017 Evan Purnama. All rights reserved.
//

import UIKit
import Qiscus

class MainView: UIViewController, QiscusConfigDelegate {

    @IBOutlet weak var appIdField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var userKeyField: UITextField!
    @IBOutlet weak var userNameField: UITextField!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        let dismissRecognizer = UITapGestureRecognizer(target: self, action: #selector(MainView.hideKeyboard))
        self.view.addGestureRecognizer(dismissRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func login(_ sender: UIButton) {
        self.showQiscusLoading()
        Qiscus.setup(withAppId: appIdField.text!, userEmail: emailField.text!, userKey: userKeyField.text!, username: userNameField.text!,delegate: self)
    }
    func hideKeyboard(){
        self.view.endEditing(true)
    }
    
    // MARK: - QiscusConfigDelegate
    func qiscusFailToConnect(_ withMessage:String){
        print(withMessage)
        self.dismissQiscusLoading()
    }
    func qiscusConnected(){
        appDelegate.goToChatNavigationView()
        self.dismissQiscusLoading()
    }
}
