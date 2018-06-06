//
//  LeftTextCell.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 08/05/18.
//

import UIKit

class LeftTextCell: BaseChatCell {
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var tvContent: UILabel!
    @IBOutlet weak var ivBaloonLeft: UIImageView!
    @IBOutlet weak var lbTime: UILabel!
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var ivStatus: UIImageView!
    @IBOutlet weak var lbNameHeight: NSLayoutConstraint!
    @IBOutlet weak var lbNameLeading: NSLayoutConstraint!
    @IBOutlet weak var lbNameTrailing: NSLayoutConstraint!
    @IBOutlet weak var statusWidth: NSLayoutConstraint!
    @IBOutlet weak var rightConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func menuResponderView() -> UIView {
        return self.ivBaloonLeft
    }
    
    override func bindDataToView() {
        self.tvContent.text = self.comment.text
        self.lbName.text = self.comment.senderName
        self.lbTime.text = self.comment.time

        if self.comment.isMyComment {
            DispatchQueue.main.async {
                self.rightConstraint.isActive = true
                self.leftConstraint.isActive = false
            }
            
            lbNameTrailing.constant = 5
            lbNameLeading.constant = 20
            lbName.textAlignment = .right
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
            DispatchQueue.main.async {
                self.leftConstraint.isActive = true
                self.rightConstraint.isActive = false
            }
            
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
        
        self.layoutIfNeeded()
    }
}
