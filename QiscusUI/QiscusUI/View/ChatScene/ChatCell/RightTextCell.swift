//
//  LeftTextCell.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 08/05/18.
//

import UIKit

class RightTextCell: BaseChatCell {
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var tvContent: UILabel!
    @IBOutlet weak var ivBaloonLeft: UIImageView!
    @IBOutlet weak var lbTime: UILabel!
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var lbNameHeight: NSLayoutConstraint!
    @IBOutlet weak var lbNameLeading: NSLayoutConstraint!
    @IBOutlet weak var lbNameTrailing: NSLayoutConstraint!
    var leftConstrain: NSLayoutConstraint!
    var rightConstrain: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
        self.leftConstrain = NSLayoutConstraint(item: tvContent, attribute: .leading, relatedBy: .equal, toItem: lbName, attribute: .leading, multiplier: 1, constant: 7)
        self.rightConstrain = NSLayoutConstraint(item: lbName, attribute: .trailing, relatedBy: .equal, toItem: tvContent, attribute: .trailing, multiplier: 1, constant: 10)
    }
    
    override func bindDataToView() {
        self.tvContent.text = self.comment.text
        self.lbName.text = self.comment.senderName
        self.lbTime.text = self.comment.time
        
        if self.comment.isMyComment {
            //            viewContainer.addConstraint(rightConstrain)
            //            viewContainer.removeConstraint(leftConstrain)
            lbNameTrailing.constant = 5
            lbNameLeading.constant = 20
            lbName.textAlignment = .right
        } else {
            //            viewContainer.removeConstraint(rightConstrain)
            //            viewContainer.addConstraint(leftConstrain)
            lbNameTrailing.constant = 20
            lbNameLeading.constant = 45
            lbName.textAlignment = .left
        }
        
        if firstInSection {
            self.lbName.isHidden = false
            self.lbNameHeight.constant = CGFloat(21)
        } else {
            self.lbName.isHidden = true
            self.lbNameHeight.constant = CGFloat(0)
        }
    }
}

