//
//  QCellContactRight.swift
//  Example
//
//  Created by Ahmad Athaullah on 8/10/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

class QCellContactRight: QChatCell {
    @IBOutlet weak var topMargin: NSLayoutConstraint!

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var contactNameLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var balloonView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
