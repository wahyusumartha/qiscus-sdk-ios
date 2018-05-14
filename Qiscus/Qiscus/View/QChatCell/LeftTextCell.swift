//
//  LeftTextCell.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 08/05/18.
//

import UIKit

class LeftTextCell: BaseChatCell {
    @IBOutlet weak var lbNameLeft: UILabel!
    @IBOutlet weak var tvContentLeft: UITextView!
    @IBOutlet weak var ivBaloonLeft: UIImageView!
    @IBOutlet weak var lbTimeLeft: UILabel!
    
    @IBOutlet weak var lbNameRight: UILabel!
    @IBOutlet weak var tvContentRight: UITextView!
    @IBOutlet weak var ivBaloonRight: UIImageView!
    @IBOutlet weak var lbTimeRight: UILabel!
    
    @IBOutlet weak var viewRight: UIView!
    @IBOutlet weak var viewLeft: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
        tvContentLeft.sizeToFit()
        tvContentLeft.isEditable = false
        tvContentLeft.dataDetectorTypes = .link
        tvContentLeft.isScrollEnabled = false
        
        tvContentRight.sizeToFit()
        tvContentRight.isEditable = false
        tvContentRight.dataDetectorTypes = .link
        tvContentRight.isScrollEnabled = false
        
        if !firstInSection {
            self.lbNameLeft.isHidden = true
        } else {
            self.lbNameLeft.isHidden = false
        }
    }
    
    override func bindDataToView() {
        if self.comment.isMyComment {
            self.viewLeft.isHidden = true
            self.viewRight.isHidden = false
            self.tvContentRight.text = self.comment.text
            self.lbNameRight.text = self.comment.senderName
            self.lbTimeRight.text = self.comment.time
        } else {
            self.viewLeft.isHidden = false
            self.viewRight.isHidden = true
            self.tvContentLeft.text = self.comment.text
            self.lbNameLeft.text = self.comment.senderName
            self.lbTimeLeft.text = self.comment.time
            
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
        
    }
    
}
