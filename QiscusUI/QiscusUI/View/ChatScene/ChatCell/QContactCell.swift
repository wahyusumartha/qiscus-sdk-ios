//
//  QContactCell.swift
//  Alamofire
//
//  Created by UziApel on 25/06/18.
//

import UIKit
import SwiftyJSON

class QContactCell: BaseChatCell {
    @IBOutlet weak var nameContact: UILabel!
    @IBOutlet weak var noTelp: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var ivBaloon: UIImageView!
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var lbTime: UILabel!
    @IBOutlet weak var ivStatus: UIImageView!
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func menuResponderView() -> UIView {
        return self.ivBaloon
    }
    override func bindDataToView() {
        self.lbName.text = self.comment.senderName
        self.lbTime.text = self.comment.time
        let data = self.comment.additionalData
        let payloadJSON = JSON(parseJSON: data)
        self.nameContact.text = payloadJSON["name"].stringValue
        self.noTelp.text = payloadJSON["value"].stringValue
        
        if self.comment.isMyComment {
            DispatchQueue.main.async {
                self.rightConstraint.isActive = true
                self.leftConstraint.isActive = false
            }
            lbName.textAlignment = .right
        }else {
            DispatchQueue.main.async {
                self.leftConstraint.isActive = true
                self.rightConstraint.isActive = false
            }
            lbName.textAlignment = .left
        }
    }
    
    @IBAction func saveContact(_ sender: Any) {
     self.delegate?.onSaveContactCellDidTap(comment: self.comment)
    }
    
}
