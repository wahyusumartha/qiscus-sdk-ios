//
//  QDocumentCell.swift
//  Alamofire
//
//  Created by UziApel on 27/06/18.
//

import UIKit
import Qiscus
class QDocumentCell: BaseChatCell {
    
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var lbTime: UILabel!
    @IBOutlet weak var balloonView: UIImageView!
    @IBOutlet weak var fileContainer: UIView!
    @IBOutlet weak var fileIcon: UIImageView!
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var fileTypeLabel: UILabel!
    
    @IBOutlet weak var ivStatus: UIImageView!
    @IBOutlet weak var rightConstraint: NSLayoutConstraint!
    
    
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        fileIcon.image = Qiscus.image(named: "ic_file")?.withRenderingMode(.alwaysTemplate)
        fileIcon.contentMode = .scaleAspectFit
    }
    
    override func bindDataToView() {
        self.lbName.text = self.comment.senderName
        self.lbTime.text = self.comment.time
        if let file = self.comment!.file {
            fileNameLabel.text = file.filename
            if file.ext == "doc" || file.ext == "docx" || file.ext == "ppt" || file.ext == "pptx" || file.ext == "xls" || file.ext == "xlsx" || file.ext == "txt" {
                fileTypeLabel.text = "\(file.ext.uppercased()) File"
            }else{
                fileTypeLabel.text = "Unknown File"
            }
        }
        
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
    func updateStatus(){
        lbTime.text = self.comment!.time.lowercased()
    }
}
