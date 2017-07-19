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
    public override func commentChanged() {
        balloonView.tintColor = QiscusColorConfiguration.sharedInstance.rightBaloonColor
        self.balloonView.image = self.getBallon()
        progressContainer.isHidden = true
        progressView.isHidden = true
        
        if let file = self.comment!.file {
            if let image = self.comment!.displayImage {
                self.imageDisplay.image = image
            }
            else if QiscusHelper.isFileExist(inLocalPath: file.localThumbPath){
                imageDisplay.loadAsync(fromLocalPath: file.localThumbPath, onLoaded: { (image, _) in
                    self.imageDisplay.image = image
                    self.comment!.displayImage = image
                })
            }else if QiscusHelper.isFileExist(inLocalPath: file.localMiniThumbPath){
                imageDisplay.loadAsync(fromLocalPath: data.localMiniThumbURL!, onLoaded: { (image, _) in
                    self.imageDisplay.image = image
                    self.comment!.displayImage = image
                })
            }else{
                imageDisplay.loadAsync(file.thumbURL, onLoaded: { (image, _) in
                    self.imageDisplay.image = image
                    self.comment!.displayImage = image
                })
            }
            if self.tapRecognizer != nil{
                imageDisplay.removeGestureRecognizer(self.tapRecognizer!)
                tapRecognizer = nil
            }
            if self.comment!.cellPos == .first || self.comment!.cellPos == .single{
                if let sender = self.comment?.sender {
                    self.userNameLabel.text = sender.fullname.capitalized
                }else{
                    self.userNameLabel.text = self.comment?.senderName.capitalized
                }
                self.userNameLabel.isHidden = false
                self.topMargin.constant = 20
                self.cellHeight.constant = 20
            }else{
                self.userNameLabel.text = ""
                self.userNameLabel.isHidden = true
                self.topMargin.constant = 0
                self.cellHeight.constant = 0
            }
            
            if self.comment!.type == .video {
                self.videoPlay.image = Qiscus.image(named: "play_button")
                self.videoFrame.isHidden = false
                self.videoPlay.isHidden = false
            }else if file.ext == "gif"{
                self.videoPlay.image = Qiscus.image(named: "ic_gif")
                self.videoFrame.isHidden = true
                self.videoPlay.isHidden = false
            }else{
                self.videoPlay.isHidden = true
                self.videoFrame.isHidden = true
            }
            
            dateLabel.text = self.comment!.time.lowercased()
            progressLabel.isHidden = true
            dateLabel.textColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
            
            self.downloadButton.removeTarget(nil, action: nil, for: .allEvents)
            
            updateStatus(toStatus: self.comment!.status)
        }
    }
    open override func setupCell(){
        
        
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
        //updateStatus(toStatus: data.commentStatus)
        self.balloonView.layoutIfNeeded()
    }
    
    open func downloadMedia(_ sender: ChatFileButton){
        sender.isHidden = true
        DispatchQueue.global().async {
            let service = QiscusCommentClient.sharedInstance
            service.downloadMedia(data: self.data)
        }
    }
    
    open override func updateStatus(toStatus status:QCommentStatus){
        dateLabel.textColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
        statusImage.isHidden = false
        statusImage.tintColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
        
        if status == .sending {
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
