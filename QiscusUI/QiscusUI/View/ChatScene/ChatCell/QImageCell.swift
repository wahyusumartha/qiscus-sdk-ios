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
    @IBOutlet weak var ivStatus: UIImageView!
    @IBOutlet weak var lbNameHeight: NSLayoutConstraint!
    @IBOutlet weak var lbNameLeading: NSLayoutConstraint!
    @IBOutlet weak var lbNameTrailing: NSLayoutConstraint!
    @IBOutlet weak var btnButton: UIButton!
    @IBOutlet weak var ivComment: UIImageView!
    @IBOutlet weak var statusWidth: NSLayoutConstraint!
    @IBOutlet weak var rightConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
        self.ivComment.contentMode = .scaleAspectFill
        self.ivComment.clipsToBounds = true
        self.ivComment.backgroundColor = UIColor.black
        self.ivComment.isUserInteractionEnabled = true
    }
    
    override func menuResponderView() -> UIView {
        return self.ivBaloonLeft
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
            self.rightConstraint.isActive = true
            self.leftConstraint.isActive = false
            lbNameTrailing.constant = 5
            lbNameLeading.constant = 20
            lbName.textAlignment = .right
            self.statusWidth.constant = 15
            
            self.statusWidth.constant = 15
            
            switch self.comment.commentStatus {
            case .pending:
                let pendingIcon = QiscusUI.image(named: "ic_pending")?.withRenderingMode(.alwaysTemplate)
                self.ivStatus.tintColor = UIColor.lightGray
                self.ivStatus.image = pendingIcon
                break
            case .sending:
                let pendingIcon = QiscusUI.image(named: "ic_sending")?.withRenderingMode(.alwaysTemplate)
                self.ivStatus.tintColor = UIColor.lightGray
                self.ivStatus.image = pendingIcon
                break
            case .sent:
                let pendingIcon = QiscusUI.image(named: "ic_sending")?.withRenderingMode(.alwaysTemplate)
                self.ivStatus.tintColor = UIColor.lightGray
                self.ivStatus.image = pendingIcon
                break
            case .delivered:
                let pendingIcon = QiscusUI.image(named: "ic_read")?.withRenderingMode(.alwaysTemplate)
                self.ivStatus.tintColor = UIColor.lightGray
                self.ivStatus.image = pendingIcon
                break
            case .read:
                let pendingIcon = QiscusUI.image(named: "ic_read")?.withRenderingMode(.alwaysTemplate)
                self.ivStatus.tintColor = UIColor.green
                self.ivStatus.image = pendingIcon
                break
            case .deleting:
                let pendingIcon = QiscusUI.image(named: "ic_deleting")?.withRenderingMode(.alwaysTemplate)
                self.ivStatus.tintColor = UIColor.lightGray
                self.ivStatus.image = pendingIcon
                break
            case .deleted:
                let pendingIcon = QiscusUI.image(named: "ic_deleted")?.withRenderingMode(.alwaysTemplate)
                self.ivStatus.tintColor = UIColor.lightGray
                self.ivStatus.image = pendingIcon
                break
            case .deletePending:
                let pendingIcon = QiscusUI.image(named: "ic_deleting")?.withRenderingMode(.alwaysTemplate)
                self.ivStatus.tintColor = UIColor.lightGray
                self.ivStatus.image = pendingIcon
                break
            case .failed:
                let pendingIcon = QiscusUI.image(named: "ic_pending")?.withRenderingMode(.alwaysTemplate)
                self.ivStatus.tintColor = UIColor.lightGray
                self.ivStatus.image = pendingIcon
                break
            default:
                break
            }
            
        } else {
            self.rightConstraint.isActive = false
            self.leftConstraint.isActive = true
            lbNameTrailing.constant = 20
            lbNameLeading.constant = 45
            lbName.textAlignment = .left
            self.statusWidth.constant = 0
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

