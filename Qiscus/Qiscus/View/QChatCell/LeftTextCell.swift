//
//  LeftTextCell.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 08/05/18.
//

import UIKit

class LeftTextCell: BaseChatCell {
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var tvContent: UITextView!
    @IBOutlet weak var ivBaloonLeft: UIImageView!
    @IBOutlet weak var lbTime: UILabel!
    @IBOutlet weak var lbNameHeight: NSLayoutConstraint!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
        tvContent.sizeToFit()
        tvContent.isEditable = false
        tvContent.dataDetectorTypes = .link
        tvContent.isScrollEnabled = false
    }
    
    override func bindDataToView() {
        self.tvContent.text = self.comment.text
        self.lbName.text = self.comment.senderName
        self.lbTime.text = self.comment.time
        
        if firstInSection {
            self.lbName.isHidden = false
            self.lbNameHeight.constant = CGFloat(21)
            self.layoutIfNeeded()
        } else {
            self.lbName.isHidden = true
            self.lbNameHeight.constant = CGFloat(0)
            self.layoutIfNeeded()
        }
    }
}
