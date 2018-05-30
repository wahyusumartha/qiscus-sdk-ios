//
//  QImageCell.swift
//  QiscusUI
//
//  Created by Rahardyan Bisma on 25/05/18.
//

import UIKit

class QImageCell: BaseChatCell {
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var tvContent: UILabel!
    @IBOutlet weak var ivBaloonLeft: UIImageView!
    @IBOutlet weak var lbTime: UILabel!
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var lbNameHeight: NSLayoutConstraint!
    @IBOutlet weak var lbNameLeading: NSLayoutConstraint!
    @IBOutlet weak var lbNameTrailing: NSLayoutConstraint!
    @IBOutlet weak var btnButton: UIButton!
    @IBOutlet weak var ivComment: UIImageView!
    
    
    var leftConstrain: NSLayoutConstraint!
    var rightConstrain: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
        self.leftConstrain = NSLayoutConstraint(item: tvContent, attribute: .leading, relatedBy: .equal, toItem: lbName, attribute: .leading, multiplier: 1, constant: 7)
        self.rightConstrain = NSLayoutConstraint(item: lbName, attribute: .trailing, relatedBy: .equal, toItem: tvContent, attribute: .trailing, multiplier: 1, constant: 10)
        self.ivComment.contentMode = .scaleAspectFill
        self.ivComment.clipsToBounds = true
        self.ivComment.backgroundColor = UIColor.black
        self.ivComment.isUserInteractionEnabled = true
    }
    
    override func bindDataToView() {
        self.tvContent.text = ""
        self.lbName.text = self.comment.senderName
        self.lbTime.text = self.comment.time
        
        if let displayImage =  self.comment.displayImage {
            self.ivComment.image = displayImage
        } else {
            if let file = self.comment.file {
                self.ivComment.loadAsync(url: file.thumbURL, onLoaded: { (image, _) in
                    self.ivComment.image = image
                    self.comment.displayImage = image
                    file.saveThumbImage(withImage: image)
                })
            }
        }
        
        if self.comment.isMyComment {
            viewContainer.addConstraint(rightConstrain)
            viewContainer.removeConstraint(leftConstrain)
            lbNameTrailing.constant = 5
            lbNameLeading.constant = 20
            lbName.textAlignment = .right
        } else {
            viewContainer.removeConstraint(rightConstrain)
            viewContainer.addConstraint(leftConstrain)
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

