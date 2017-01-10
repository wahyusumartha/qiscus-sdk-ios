//
//  QCellFileRight.swift
//  Example
//
//  Created by Ahmad Athaullah on 1/6/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

class QCellFileRight: QChatCell {
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var balloonView: UIImageView!
    @IBOutlet weak var fileContainer: UIView!
    @IBOutlet weak var fileTypeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var statusImage: UIImageView!
    @IBOutlet weak var fileIcon: UIImageView!
    @IBOutlet weak var fileNameLabel: UILabel!

    @IBOutlet weak var balloonWidth: NSLayoutConstraint!
    @IBOutlet weak var cellHeight: NSLayoutConstraint!
    @IBOutlet weak var rightMargin: NSLayoutConstraint!
    @IBOutlet weak var topMargin: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        fileContainer.layer.cornerRadius = 10
        fileIcon.image = Qiscus.image(named: "ic_file")?.withRenderingMode(.alwaysTemplate)
        fileIcon.contentMode = .scaleAspectFit
    }
    open override func setupCell(){
        userNameLabel.text = ""
        userNameLabel.isHidden = true
        topMargin.constant = 0
        cellHeight.constant = 0
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(QChatCell.showFile))
        fileContainer.addGestureRecognizer(tapRecognizer)
        
        if cellPos == .first || cellPos == .single{
            userNameLabel.text = user?.userFullName
            userNameLabel.isHidden = false
            topMargin.constant = 20
            cellHeight.constant = 20
        }
        
        balloonView.image = QChatCellHelper.balloonImage(withPosition: CellPosition.right, cellVPos: cellPos)
        if cellPos == .last || cellPos == .single{
            balloonWidth.constant = 215
        }else{
            balloonView.image = QChatCellHelper.balloonImage(cellVPos: cellPos)
            balloonWidth.constant = 200
        }
        
        fileNameLabel.text = file?.fileName
        fileTypeLabel.text = "\(file!.fileExtension.uppercased()) File"
        dateLabel.text = comment.commentTime.lowercased()
        
        if cellPos == .last || cellPos == .single {
            rightMargin.constant = 8
        }else{
            rightMargin.constant = 23
        }
        balloonView.tintColor = QiscusColorConfiguration.sharedInstance.rightBaloonColor
        dateLabel.textColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
        fileIcon.tintColor = QiscusColorConfiguration.sharedInstance.rightBaloonColor
        
        if file!.isUploading {
            let uploadProgres = Int(file!.uploadProgress * 100)
            let uploading = QiscusTextConfiguration.sharedInstance.uploadingText
            
            dateLabel.text = "\(uploading) \(QChatCellHelper.getFormattedStringFromInt(uploadProgres)) %"
        }
        updateStatus(toStatus: comment.commentStatus)
    }
    open override func updateStatus(toStatus status:QiscusCommentStatus){
        dateLabel.textColor = UIColor.white
        statusImage.isHidden = false
        statusImage.tintColor = UIColor.white
        statusImage.isHidden = false
        statusImage.tintColor = UIColor.white
        
        if status == QiscusCommentStatus.sending {
            dateLabel.text = QiscusTextConfiguration.sharedInstance.sendingText
            statusImage.image = Qiscus.image(named: "ic_info_time")?.withRenderingMode(.alwaysTemplate)
        }else if status == .sent {
            statusImage.image = Qiscus.image(named: "ic_sending")?.withRenderingMode(.alwaysTemplate)
        }else if status == .delivered{
            statusImage.image = Qiscus.image(named: "ic_read")?.withRenderingMode(.alwaysTemplate)
        }else if status == .read{
            statusImage.tintColor = UIColor.green
            statusImage.image = Qiscus.image(named: "ic_read")?.withRenderingMode(.alwaysTemplate)
        }else if status == .failed {
            dateLabel.text = QiscusTextConfiguration.sharedInstance.failedText
            dateLabel.textColor = QiscusColorConfiguration.sharedInstance.failToSendColor
            statusImage.image = Qiscus.image(named: "ic_warning")?.withRenderingMode(.alwaysTemplate)
            statusImage.tintColor = QiscusColorConfiguration.sharedInstance.failToSendColor
        }
    }
}
