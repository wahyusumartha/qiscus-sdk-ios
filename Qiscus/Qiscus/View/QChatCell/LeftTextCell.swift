//
//  LeftTextCell.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 08/05/18.
//

import UIKit

class LeftTextCell: UITableViewCell {
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var tvContent: UITextView!
    @IBOutlet weak var ivBaloon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
        tvContent.sizeToFit()
        tvContent.isEditable = false
        tvContent.dataDetectorTypes = .link
        tvContent.isScrollEnabled = false;
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
        
    }
    
}
