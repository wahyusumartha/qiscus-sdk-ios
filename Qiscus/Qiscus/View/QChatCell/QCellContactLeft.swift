//
//  QCellContactLeft.swift
//  Example
//
//  Created by Ahmad Athaullah on 8/23/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
import SwiftyJSON

class QCellContactLeft: QChatCell {

    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var contactIcon: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var contactNameLabel: UILabel!
    @IBOutlet weak var separator: UIView!
    @IBOutlet weak var balloonView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var topMargin: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.containerView.layer.cornerRadius = 10.0
        self.separator.backgroundColor = QiscusColorConfiguration.sharedInstance.leftBaloonColor
        self.balloonView.tintColor = QiscusColorConfiguration.sharedInstance.leftBaloonColor
    }
    override func commentChanged() {
        let data = self.comment!.data
        let payloadJSON = JSON(parseJSON: data)
        
        self.contactNameLabel.text = payloadJSON["name"].stringValue
        
        self.descriptionLabel.text = payloadJSON["value"].stringValue
        
        self.balloonView.image = self.getBallon()
        
        if self.comment?.cellPos == .first || self.comment?.cellPos == .single{
            if let sender = self.comment?.sender {
                self.userNameLabel.text = sender.fullname
            }else{
                self.userNameLabel.text = self.comment?.senderName
            }
            self.userNameLabel.isHidden = false
            self.topMargin.constant = 20
        }else{
            self.userNameLabel.text = ""
            self.userNameLabel.isHidden = true
            self.topMargin.constant = 0
        }
        self.dateLabel.textColor = QiscusColorConfiguration.sharedInstance.leftBaloonTextColor
        self.dateLabel.text = self.comment!.time.lowercased()
    }
    
    @IBAction func saveContact(_ sender: Any) {
        print("saving contact")
        self.delegate?.didTapSaveContact(withData: self.comment!)
    }
}
