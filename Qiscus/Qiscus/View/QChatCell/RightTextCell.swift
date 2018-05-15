//
//  RightTextCell.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 08/05/18.
//

import UIKit

class RightTextCell: BaseChatCell {
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
        tvContent.isScrollEnabled = false
    }

    override func bindDataToView() {
        self.tvContent.text = self.comment.text
        self.lbTime.text = self.comment.time
    }
}
