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
    @IBOutlet weak var ivBaloon: UIImageView!
    @IBOutlet weak var lbTime: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
        tvContent.sizeToFit()
        tvContent.isEditable = false
        tvContent.dataDetectorTypes = .link
        tvContent.isScrollEnabled = false;
    }
    
    override func bindDataToView() {
        self.tvContent.text = self.comment.text
        self.lbName.text = self.comment.senderName
        self.lbTime.text = self.comment.time
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
        
    }
    
}
