//
//  QSystemCell.swift
//  QiscusUI
//
//  Created by Rahardyan Bisma on 05/06/18.
//

import UIKit

class QSystemCell: BaseChatCell {
    @IBOutlet weak var lbComment: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func bindDataToView() {
        self.lbComment.text = self.comment.text
    }
    
    override func menuResponderView() -> UIView {
        return self
    }
}
