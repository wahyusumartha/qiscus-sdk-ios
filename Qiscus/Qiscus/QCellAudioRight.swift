//
//  QCellAudioRight.swift
//  Example
//
//  Created by Ahmad Athaullah on 1/5/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
import AVFoundation

class QCellAudioRight: QCellAudio {

    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var balloonView: UIImageView!
    @IBOutlet weak var fileContainer: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var currentTimeSlider: UISlider!
    @IBOutlet weak var progressContainer: UIView!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var progressImageView: UIImageView!
    @IBOutlet weak var seekTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var statusImage: UIImageView!
    
    @IBOutlet weak var balloonWidth: NSLayoutConstraint!
    @IBOutlet weak var progressHeight: NSLayoutConstraint!
    @IBOutlet weak var rightMargin: NSLayoutConstraint!
    @IBOutlet weak var cellHeight: NSLayoutConstraint!
    @IBOutlet weak var balloonTopMargin: NSLayoutConstraint!
    
    let defaultDateLeftMargin:CGFloat = -10
    var tapRecognizer: ChatTapRecognizer?
    
    var isDownloading = false{
        didSet {
            self.playButton.removeTarget(nil, action: nil, for: .allEvents)
            if isDownloading {
                self.progressImageView.image = Qiscus.image(named: "audio_download")
                self.progressContainer.isHidden = false
            }
        }
    }
    var filePath = "" {
        didSet {
            self.playButton.removeTarget(nil, action: nil, for: .allEvents)
            if filePath == "" {
                self.progressContainer.isHidden = true
                self.playButton.setImage(Qiscus.image(named: "audio_download"), for: UIControlState())
                self.playButton.addTarget(self, action: #selector(QCellAudioRight.downloadButtonTapped(_:)), for: .touchUpInside)
            }else{
                self.progressContainer.isHidden = true
                self.playButton.setImage(Qiscus.image(named: "play_audio"), for: UIControlState())
                self.playButton.addTarget(self, action: #selector(QCellAudioRight.playButtonTapped(_:)), for: .touchUpInside)
            }
        }
    }
    var isPlaying = false {
        didSet {
            self.playButton.removeTarget(nil, action: nil, for: .allEvents)
            if isPlaying {
                self.playButton.setImage(Qiscus.image(named: "audio_pause"), for: UIControlState())
                self.playButton.addTarget(self, action: #selector(QCellAudioRight.pauseButtonTapped(_:)), for: .touchUpInside)
            } else {
                self.playButton.setImage(Qiscus.image(named: "play_audio"), for: UIControlState())
                self.playButton.addTarget(self, action: #selector(QCellAudioRight.playButtonTapped(_:)), for: .touchUpInside)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        progressContainer.layer.cornerRadius = 15
        progressContainer.clipsToBounds = true
        fileContainer.layer.cornerRadius = 10
    }
    open override func setupCell(){
        self.progressHeight.constant = 0
        self.progressContainer.isHidden = true
        self.currentTimeSlider.value = 0
        self.durationLabel.text = ""
        
        let user = comment.sender
        userNameLabel.text = ""
        userNameLabel.isHidden = true
        balloonTopMargin.constant = 0
        cellHeight.constant = 0
        
        if cellPos == .first || cellPos == .single{
            userNameLabel.text = user?.userFullName
            userNameLabel.isHidden = false
            balloonTopMargin.constant = 20
            cellHeight.constant = 20
        }
        
        var path = ""
        var file = QiscusFile()
        if let audioFile = QiscusFile.getCommentFileWithComment(comment){
            file = audioFile
            if file.isOnlyLocalFileExist{
                path = file.fileLocalPath
            }
        }
        filePath = path
        if self.tapRecognizer != nil{
            self.fileContainer.removeGestureRecognizer(self.tapRecognizer!)
            self.tapRecognizer = nil
        }
        balloonView.image = QChatCellHelper.balloonImage(withPosition: .right, cellVPos: cellPos)
        if cellPos == .single || cellPos == .last{
            balloonWidth.constant = 215
        }else{
            balloonView.image = QChatCellHelper.balloonImage(cellVPos: cellPos)
            balloonWidth.constant = 200
        }
        
        dateLabel.text = comment.commentTime.lowercased()
        if cellPos == .single || cellPos == .last {
            rightMargin.constant = 8
        }else{
            rightMargin.constant = 23
        }
        balloonView.tintColor = QiscusColorConfiguration.sharedInstance.rightBaloonColor
        dateLabel.textColor = QiscusColorConfiguration.sharedInstance.rightBaloonTextColor
        
        if file.isOnlyLocalFileExist{
            let audioURL = URL(fileURLWithPath: file.fileLocalPath)
            let audioAsset = AVURLAsset(url: audioURL)
            audioAsset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: {
                var error: NSError? = nil
                let status = audioAsset.statusOfValue(forKey: "duration", error: &error)
                switch status {
                case .loaded:
                    let duration = Double(CMTimeGetSeconds(audioAsset.duration))
                    self.currentTimeSlider.maximumValue = Float(duration)
                    self.durationLabel.text = self.timeFormatter?.string(from: duration)
                    break
                default:
                    break
                }
            })
        }
        if file.isUploading {
            let uploadProgres = Int(file.uploadProgress * 100)
            let uploading = QiscusTextConfiguration.sharedInstance.uploadingText
            
            self.progressImageView.image = Qiscus.image(named: "audio_upload")
            self.progressContainer.isHidden = false
            self.progressHeight.constant = file.uploadProgress * 30
            dateLabel.text = "\(uploading) \(QChatCellHelper.getFormattedStringFromInt(uploadProgres)) %"
        }
        updateStatus(toStatus: comment.commentStatus)
    }
    func playButtonTapped(_ sender: UIButton) {
        self.isPlaying = true
        self.delegate?.didTapPlayButton(sender, onCell: self)
    }
    
    func pauseButtonTapped(_ sender: UIButton) {
        self.isPlaying = false
        self.delegate?.didTapPauseButton(sender, onCell: self)
    }
    
    func downloadButtonTapped(_ sender: UIButton) {
        self.delegate?.didTapDownloadButton(sender, onCell: self)
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        self.seekTimeLabel.text = timeFormatter?.string(from: Double(sender.value))
        self.delegate?.didStartSeekTimeSlider(sender, onCell: self)
    }
    @IBAction func sliderTouchUpInside(_ sender: UISlider) {
        self.delegate?.didEndSeekTimeSlider(sender, onCell: self)
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
    open override func downloadingMedia(withPercentage percentage: Int) {
        if percentage > 0 {
            progressContainer.isHidden = false
            progressHeight.constant = (file?.downloadProgress)! * 30
            dateLabel.text = "Downloading \(QChatCellHelper.getFormattedStringFromInt(percentage)) %"
            progressContainer.layoutIfNeeded()
        }
    }
}
