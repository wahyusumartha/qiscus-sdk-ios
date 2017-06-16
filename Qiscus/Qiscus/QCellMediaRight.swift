//
//  QCellMediaRight.swift
//  QiscusSDK
//
//  Created by Ahmad Athaullah on 1/5/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
import ImageViewer

class QCellMediaRight: QChatCell {

    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var balloonView: UIImageView!
    @IBOutlet weak var imageDisplay: UIImageView!
    @IBOutlet weak var videoFrame: UIImageView!
    @IBOutlet weak var downloadButton: ChatFileButton!
    @IBOutlet weak var videoPlay: UIImageView!
    @IBOutlet weak var progressContainer: UIView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var statusImage: UIImageView!
    @IBOutlet weak var progressView: UIView!
    
    @IBOutlet weak var cellHeight: NSLayoutConstraint!
    @IBOutlet weak var topMargin: NSLayoutConstraint!
    @IBOutlet weak var rightMargin: NSLayoutConstraint!
    @IBOutlet weak var balloonWidth: NSLayoutConstraint!
    @IBOutlet weak var progressHeight: NSLayoutConstraint!
    
    let defaultDateLeftMargin:CGFloat = -10
    var tapRecognizer: UITapGestureRecognizer?
    let maxProgressHeight:CGFloat = 40.0
    var isVideo = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        userNameLabel.textAlignment = .right
        progressContainer.layer.cornerRadius = 20
        progressContainer.clipsToBounds = true
        progressContainer.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.65).cgColor
        progressContainer.layer.borderWidth = 2
        downloadButton.setImage(Qiscus.image(named: "ic_download_chat")!.withRenderingMode(.alwaysOriginal), for: UIControlState())
        
        self.videoPlay.image = Qiscus.image(named: "play_button")
        self.videoFrame.image = Qiscus.image(named: "movie_frame")?.withRenderingMode(.alwaysTemplate)
        self.videoFrame.tintColor = UIColor.black
        self.videoFrame.layer.cornerRadius = 10
        self.videoPlay.contentMode = .scaleAspectFit
        self.imageDisplay.contentMode = .scaleAspectFill
        self.imageDisplay.clipsToBounds = true
        self.imageDisplay.backgroundColor = UIColor.black
        self.imageDisplay.isUserInteractionEnabled = true
        imageDisplay.layer.cornerRadius = 10
    }
    open override func setupCell(){
        progressContainer.isHidden = true
        progressView.isHidden = true
        
        if QiscusHelper.isFileExist(inLocalPath: data.localThumbURL!){
            imageDisplay.loadAsync(fromLocalPath: data.localThumbURL!, onLoaded: { (image, _) in
                self.imageDisplay.image = image
                self.data.displayImage = image
            })
        }else if QiscusHelper.isFileExist(inLocalPath: data.localMiniThumbURL!){
            imageDisplay.loadAsync(fromLocalPath: data.localMiniThumbURL!, onLoaded: { (image, _) in
                self.imageDisplay.image = image
                self.data.displayImage = image
            })
        }else{
            imageDisplay.loadAsync(data.remoteThumbURL!, onLoaded: { (image, _) in
                self.imageDisplay.image = image
                self.data.displayImage = image
            })
        }
        
        balloonView.image = data.balloonImage
        balloonView.tintColor = QiscusColorConfiguration.sharedInstance.rightBaloonColor
        
        // cleartap recognizer
        if self.tapRecognizer != nil{
            imageDisplay.removeGestureRecognizer(self.tapRecognizer!)
            tapRecognizer = nil
        }
        
        // if this is first cell
        if data.cellPos == .first || data.cellPos == .single{
            userNameLabel.text = data.userFullName
            userNameLabel.isHidden = false
            topMargin.constant = 20
            cellHeight.constant = 20
        }else{
            userNameLabel.text = ""
            userNameLabel.isHidden = true
            topMargin.constant = 0
            cellHeight.constant = 0
        }
        
        // if this is last cell
        if data.cellPos == .last || data.cellPos == .single{
            balloonWidth.constant = 200
            rightMargin.constant = 8
        }else{
            rightMargin.constant = 23
            balloonWidth.constant = 185
        }
        
        
        if data.commentType == .video || data.fileType == "gif"{
            if data.fileType == "gif" {
                self.videoPlay.image = Qiscus.image(named: "ic_gif")
                self.videoFrame.isHidden = true
            }else{
                self.videoPlay.image = Qiscus.image(named: "play_button")
                self.videoFrame.isHidden = false
            }
            self.videoPlay.isHidden = false
        }else{
            self.videoPlay.isHidden = true
            self.videoFrame.isHidden = true
        }
        
        dateLabel.text = data.commentTime
        progressLabel.isHidden = true
        dateLabel.textColor = UIColor.white
        
        self.downloadButton.removeTarget(nil, action: nil, for: .allEvents)
        
        if !data.localFileExist {
            self.videoPlay.isHidden = true
            if data.isDownloading{
                self.downloadButton.isHidden = true
                self.progressLabel.text = "\(Int(data.downloadProgress * 100)) %"
                self.progressLabel.isHidden = false
                self.progressContainer.isHidden = false
                self.progressView.isHidden = false
                let newHeight = data.downloadProgress * maxProgressHeight
                self.progressHeight.constant = newHeight
                self.progressView.layoutIfNeeded()
            }else{
                self.downloadButton.data = data
                self.downloadButton.addTarget(self, action: #selector(QCellMediaLeft.downloadMedia(_:)), for: .touchUpInside)
                self.downloadButton.isHidden = false
            }
        }else{
            self.downloadButton.isHidden = true
            tapRecognizer = UITapGestureRecognizer(target:self,action:#selector(QCellMediaLeft.didTapImage))
            imageDisplay.addGestureRecognizer(tapRecognizer!)
            if data.isUploading{
                self.progressContainer.isHidden = false
                self.progressView.isHidden = false
                let newHeight = data.uploadProgress * maxProgressHeight
                self.progressHeight.constant = newHeight
                self.progressView.layoutIfNeeded()
                if data.commentType == .video {
                    self.videoPlay.isHidden = true
                }
            }
        }
        updateStatus(toStatus: data.commentStatus)
        self.balloonView.layoutIfNeeded()
    }
    
    open func downloadMedia(_ sender: ChatFileButton){
        sender.isHidden = true
        DispatchQueue.global().async {
            let service = QiscusCommentClient.sharedInstance
            service.downloadMedia(data: self.data)
        }
    }
    
    open override func updateStatus(toStatus status:QiscusCommentStatus){
        dateLabel.textColor = UIColor.white
        statusImage.isHidden = false
        statusImage.tintColor = UIColor.white
        statusImage.isHidden = false
        statusImage.tintColor = UIColor.white
        
        if status == QiscusCommentStatus.sending {
            if self.data.isUploading{
                dateLabel.text = QiscusTextConfiguration.sharedInstance.uploadingText
            }else{
                dateLabel.text = QiscusTextConfiguration.sharedInstance.sendingText
            }
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

    open override func downloadingMedia(withPercentage percentage: Int) {
        if percentage > 0 {
            downloadButton.isHidden = true
            progressLabel.text = "\(percentage) %"
            progressLabel.isHidden = false
            progressContainer.isHidden = false
            progressView.isHidden = false
            
            let newHeight = CGFloat(percentage / 100) * maxProgressHeight
            progressHeight.constant = newHeight
            progressContainer.layoutIfNeeded()
        }
    }
    
    func didTapImage(){
        if data.localFileExist && !data.isUploading && !data.isDownloading{
            delegate?.didTapCell?(withData: data)
        }
    }
    
    func setupImageView(){
        
    }
}
