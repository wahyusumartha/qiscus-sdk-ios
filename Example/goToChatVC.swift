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
        self.navigationController?.isNavigationBarHidden = true
        let dismissRecognizer = UITapGestureRecognizer(target: self, action: #selector(goToChatVC.hideKeyboard))
        self.view.addGestureRecognizer(dismissRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func goToChat(_ sender: UIButton) {
        Qiscus.chat(withUsers: [targetField.text!] , target: self, title: "SampleChat", optionalDataCompletion: { optionalData in
            print("optionalData from Example view: \(optionalData)")
        })
    }
    
    @IBAction func logOut(_ sender: UIButton) {
        Qiscus.clear()
        appDelegate.goToLoginView()
    }
    func hideKeyboard(){
        self.view.endEditing(true)
    }
}
