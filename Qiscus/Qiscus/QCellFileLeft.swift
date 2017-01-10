//
//  QCellFileLeft.swift
//  Example
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
        
        balloonView.image = QChatCellHelper.balloonImage(withPosition: CellPosition.left, cellVPos: cellPos)
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
            leftMargin.constant = 42
        }else{
            leftMargin.constant = 57
        }
        balloonView.tintColor = QiscusColorConfiguration.sharedInstance.leftBaloonColor
        dateLabel.textColor = QiscusColorConfiguration.sharedInstance.leftBaloonTextColor
        fileIcon.tintColor = QiscusColorConfiguration.sharedInstance.leftBaloonColor
        
        if file!.isUploading {
            let uploadProgres = Int(file!.uploadProgress * 100)
            let uploading = QiscusTextConfiguration.sharedInstance.uploadingText
            
            dateLabel.text = "\(uploading) \(QChatCellHelper.getFormattedStringFromInt(uploadProgres)) %"
        }
    }
}
