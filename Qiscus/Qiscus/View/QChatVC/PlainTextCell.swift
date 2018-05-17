//
//  PlainTextCell.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 16/05/18.
//

import UIKit

class PlainTextCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
//        self.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
//        label.sizeToFit()
//        label.isEditable = false
//        label.isScrollEnabled = false
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
