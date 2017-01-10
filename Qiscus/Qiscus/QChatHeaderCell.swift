//
//  QChatHeaderCell.swift
//  Example
//
//  Created by Ahmad Athaullah on 1/3/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

class QChatHeaderCell: UICollectionReusableView {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var cellWidth: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
    }
    
    func setupHeader(withText text:String){
        label.text = text
        let textSize = label.sizeThatFits(CGSize(width: QiscusHelper.screenWidth(), height: 20))
        cellWidth.constant = textSize.width + 30
    }
    
}
