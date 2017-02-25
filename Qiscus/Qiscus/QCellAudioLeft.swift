//
//  QCellAudioLeft.swift
//  QiscusSDK
//
//  Created by Ahmad Athaullah on 1/5/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
import AVFoundation

class QCellAudioLeft: QCellAudio {

    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var balloonView: UIImageView!
    @IBOutlet weak var fileContainer: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var currentTimeSlider: UISlider!
    @IBOutlet weak var progressContainer: UIView!
    @IBOutlet weak var seekTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var progressImageView: UIImageView!
    
    @IBOutlet weak var cellHeight: NSLayoutConstraint!
    @IBOutlet weak var balloonTopMargin: NSLayoutConstraint!
    @IBOutlet weak var leftMargin: NSLayoutConstraint!
    @IBOutlet weak var balloonWidth: NSLayoutConstraint!
    @IBOutlet weak var progressHeight: NSLayoutConstraint!
    
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
                self.playButton.addTarget(self, action: #selector(downloadButtonTapped(_:)), for: .touchUpInside)
            }else{
                self.progressContainer.isHidden = true
                self.playButton.setImage(Qiscus.image(named: "play_audio"), for: UIControlState())
                self.playButton.addTarget(self, action: #selector(playButtonTapped(_:)), for: .touchUpInside)
            }
        }
    }
    var isPlaying = false {
        didSet {
            self.playButton.removeTarget(nil, action: nil, for: .allEvents)
            if isPlaying {
                self.playButton.setImage(Qiscus.image(named: "audio_pause"), for: UIControlState())
                self.playButton.addTarget(self, action: #selector(pauseButtonTapped(_:)), for: .touchUpInside)
            } else {
                self.playButton.setImage(Qiscus.image(named: "play_audio"), for: UIControlState())
                self.playButton.addTarget(self, action: #selector(playButtonTapped(_:)), for: .touchUpInside)
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
        self.currentTimeSlider.setValue(data.currentTimeSlider, animated: true)
        self.durationLabel.text = data.durationLabel
        
        userNameLabel.text = data.userFullName
        userNameLabel.isHidden = true
        balloonTopMargin.constant = 0
        cellHeight.constant = 0
        
        if data.cellPos == .first || data.cellPos == .single{
            userNameLabel.isHidden = false
            balloonTopMargin.constant = 20
            cellHeight.constant = 20
        }
        self.seekTimeLabel.text = data.seekTimeLabel
        if self.tapRecognizer != nil{
            self.fileContainer.removeGestureRecognizer(self.tapRecognizer!)
            self.tapRecognizer = nil
        }
        balloonView.image = data.balloonImage
        if data.cellPos == .single || data.cellPos == .last{
            balloonWidth.constant = 215
        }
        
        dateLabel.text = data.commentTime.lowercased()
        if data.cellPos == .single || data.cellPos == .last {
            leftMargin.constant = 42
        }else{
            leftMargin.constant = 57
        }
        
        balloonView.tintColor = QiscusColorConfiguration.sharedInstance.leftBaloonColor
        dateLabel.textColor = QiscusColorConfiguration.sharedInstance.leftBaloonTextColor
        
        if data.audioFileExist{
            self.filePath = data.localURL!
            self.isPlaying = data.audioIsPlaying
            let audioURL = URL(fileURLWithPath: data.localURL!)
            let audioAsset = AVURLAsset(url: audioURL)
            audioAsset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: {
                var error: NSError? = nil
                let status = audioAsset.statusOfValue(forKey: "duration", error: &error)
                switch status {
                case .loaded:
                    let duration = Double(CMTimeGetSeconds(audioAsset.duration))
                    self.currentTimeSlider.maximumValue = Float(duration)
                    if let durationString = self.timeFormatter?.string(from: duration) {
                        self.data.durationLabel = durationString
                        self.audioCellDelegate?.didChangeData(onCell: self, withData: self.data)
                        self.durationLabel.text = durationString
                    }
                    break
                default:
                    break
                }
            })
        }
        if data.isUploading{
            let uploadProgres = Int(data.uploadProgress * 100)
            let uploading = QiscusTextConfiguration.sharedInstance.uploadingText
            
            self.progressImageView.image = Qiscus.image(named: "audio_upload")
            self.progressContainer.isHidden = false
            self.progressHeight.constant = data.uploadProgress * 30
            dateLabel.text = "\(uploading) \(QChatCellHelper.getFormattedStringFromInt(uploadProgres)) %"
        }
    }
    @IBAction func playButtonTapped(_ sender: UIButton) {
        self.isPlaying = true
        self.data.audioIsPlaying = true
        self.audioCellDelegate?.didChangeData(onCell: self, withData: self.data)
        self.audioCellDelegate?.didTapPlayButton(sender, onCell: self)
    }
    
    @IBAction func pauseButtonTapped(_ sender: UIButton) {
        self.isPlaying = false
        self.data.audioIsPlaying = false
        self.audioCellDelegate?.didChangeData(onCell: self, withData: self.data)
        self.audioCellDelegate?.didTapPauseButton(sender, onCell: self)
    }
    
    @IBAction func downloadButtonTapped(_ sender: UIButton) {
        self.audioCellDelegate?.didTapDownloadButton(sender, onCell: self)
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        if let seekTimeString = timeFormatter?.string(from: Double(sender.value)){
            self.data.seekTimeLabel = seekTimeString
            self.data.currentTimeSlider = self.currentTimeSlider.value
            self.audioCellDelegate?.didChangeData(onCell: self, withData: self.data)
            self.seekTimeLabel.text = seekTimeString
        }
        
        self.audioCellDelegate?.didStartSeekTimeSlider(sender, onCell: self)
    }
    @IBAction func sliderTouchUpInside(_ sender: UISlider) {
        self.data.currentTimeSlider = self.currentTimeSlider.value
        self.audioCellDelegate?.didChangeData(onCell: self, withData: self.data)
        self.audioCellDelegate?.didEndSeekTimeSlider(sender, onCell: self)
    }
    open override func downloadingMedia(withPercentage percentage: Int) {
        if percentage > 0 {
            progressContainer.isHidden = false
            progressHeight.constant = CGFloat(percentage/100) * 30
            dateLabel.text = "Downloading \(QChatCellHelper.getFormattedStringFromInt(percentage)) %"
            progressContainer.layoutIfNeeded()
        }
    }
    open override func displayAudioDownloading() {
        self.isDownloading = true
        self.data.isDownloading = true
        self.audioCellDelegate?.didChangeData(onCell: self, withData: self.data)
        self.playButton.removeTarget(nil, action: nil, for: .allEvents)
    }
    open override func updateAudioDisplay(withTimeInterval timeInterval:TimeInterval) {
        self.isPlaying = data.audioIsPlaying
        self.data.currentTimeSlider = Float(timeInterval)
        self.audioCellDelegate?.didChangeData(onCell: self, withData: self.data)
        self.currentTimeSlider.setValue(Float(timeInterval), animated: true)
        self.seekTimeLabel.text = self.timeFormatter?.string(from: timeInterval)
    }
}
