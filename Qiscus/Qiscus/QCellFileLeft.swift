//
//  QCellFileLeft.swift
//  QiscusSDK
//
//  Created by Ahmad Athaullah on 1/6/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

class QCellFileLeft: QChatCell {

    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var balloonView: UIImageView!
    @IBOutlet weak var fileContainer: UIView!
    @IBOutlet weak var fileIcon: UIImageView!
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var fileTypeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var balloonWidth: NSLayoutConstraint!
    @IBOutlet weak var topMargin: NSLayoutConstraint!
    @IBOutlet weak var leftMargin: NSLayoutConstraint!
    @IBOutlet weak var cellHeight: NSLayoutConstraint!
        
    override func awakeFromNib() {
        super.awakeFromNib()
        fileContainer.layer.cornerRadius = 10
        fileIcon.image = Qiscus.image(named: "ic_file")?.withRenderingMode(.alwaysTemplate)
        fileIcon.contentMode = .scaleAspectFit
    }
    open override func setupCell(){
        userNameLabel.text = data.userFullName
        userNameLabel.isHidden = true
        topMargin.constant = 0
        cellHeight.constant = 0
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(QChatCell.showFile))
        fileContainer.addGestureRecognizer(tapRecognizer)
        
        if data.cellPos == .first || data.cellPos == .single{
            userNameLabel.isHidden = false
            topMargin.constant = 20
            cellHeight.constant = 20
        }
        
        balloonView.image = data.balloonImage
        if data.cellPos == .last || data.cellPos == .single{
            balloonWidth.constant = 215
        }else{
            balloonWidth.constant = 200
        }
        
        fileNameLabel.text = data.fileName
        if data.commentType == .document{
            fileTypeLabel.text = "\(data.fileType.uppercased()) File"
        }else{
            fileTypeLabel.text = "Unknown File"
        }
        dateLabel.text = data.commentTime.lowercased()

        if data.cellPos == .last || data.cellPos == .single {
            leftMargin.constant = 35
        }else{
            leftMargin.constant = 50
        }
        balloonView.tintColor = QiscusColorConfiguration.sharedInstance.leftBaloonColor
        dateLabel.textColor = QiscusColorConfiguration.sharedInstance.leftBaloonTextColor
        fileIcon.tintColor = QiscusColorConfiguration.sharedInstance.leftBaloonColor
        
        if data.isUploading {
            let uploadProgres = Int(data.uploadProgress * 100)
            let uploading = QiscusTextConfiguration.sharedInstance.uploadingText
            
            dateLabel.text = "\(uploading) \(QChatCellHelper.getFormattedStringFromInt(uploadProgres)) %"
        }
    }
}
