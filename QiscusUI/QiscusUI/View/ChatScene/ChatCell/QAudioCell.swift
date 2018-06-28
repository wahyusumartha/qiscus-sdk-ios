//
//  QAudioCell.swift
//  Alamofire
//
//  Created by UziApel on 26/06/18.
//

import UIKit
import Qiscus
import AVFoundation

class QAudioCell: BaseChatCell {

    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var balloonView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var fileContainer: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var currentTImeSlider: UISlider!
    @IBOutlet weak var progressContainer: UIView!
    @IBOutlet weak var seekTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var progressImageView: UIImageView!
    
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightConstraint: NSLayoutConstraint!
   
    
    var isDownloading = false{
        didSet {
            self.playButton.removeTarget(nil, action: nil, for: .allEvents)
            if isDownloading {
                self.progressImageView.image = Qiscus.image(named: "audio_download")
                self.progressContainer.isHidden = false
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
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    override func bindDataToView() {
        self.userNameLabel.text = self.comment.senderName
        self.dateLabel.text = self.comment.time
        print("cekk com \(self.comment!.durationLabel)")
        self.durationLabel.text = self.comment!.durationLabel // duration label belum ada datanya
        self.isPlaying = self.comment!.audioIsPlaying

        if self.comment.isMyComment {
            DispatchQueue.main.async {
                self.rightConstraint.isActive = true
                self.leftConstraint.isActive = false
            }
            userNameLabel.textAlignment = .right
        }else {
            DispatchQueue.main.async {
                self.leftConstraint.isActive = true
                self.rightConstraint.isActive = false
            }
            userNameLabel.textAlignment = .left
        }
        self.filePath = ""
        if let file = self.comment!.file{
            if file.localPath != "" {
                if QFileManager.isFileExist(inLocalPath: file.localPath){
                    self.filePath = file.localPath
                    self.isPlaying = self.comment!.audioIsPlaying
                    let audioURL = URL(fileURLWithPath: file.localPath)
                    let audioAsset = AVURLAsset(url: audioURL)
                    audioAsset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: {
                        var error: NSError? = nil
                        let status = audioAsset.statusOfValue(forKey: "duration", error: &error)
                        switch status {
                        case .loaded:
                            let duration = Double(CMTimeGetSeconds(audioAsset.duration))
                            DispatchQueue.main.async {
                                autoreleasepool{
                                    self.currentTImeSlider.maximumValue = Float(duration)
                                    if let durationString = self.timeFormatter?.string(from: duration) {
//                                        self.comment!.updateDurationLabel(label: durationString) update qcomment
                                        self.durationLabel.text = durationString
                                    }
                                }
                            }
                            break
                        default:
                            break
                        }
                    })
                }else{
                    file.updateLocalPath(path: "")
                }
            }
        }
        
        if self.comment!.isUploading || self.comment!.isDownloading{
            let uploadProgres = Int(self.comment!.progress * 100)
            let uploading = QiscusTextConfiguration.sharedInstance.uploadingText
            let downloading = QiscusTextConfiguration.sharedInstance.downloadingText
            
            self.progressContainer.isHidden = false
//            self.progressHeight.constant = self.comment!.progress * 30
            
            if self.comment!.isDownloading{
                self.progressImageView.image = Qiscus.image(named: "audio_download")
                dateLabel.text = "\(downloading) \(QChatCellHelper.getFormattedStringFromInt(uploadProgres)) %"
            }else{
                self.progressImageView.image = Qiscus.image(named: "audio_upload")
                dateLabel.text = "\(uploading) \(QChatCellHelper.getFormattedStringFromInt(uploadProgres)) %"
            }
        }
    }
}

extension QAudioCell {
   
    @IBAction func downloadButtonTapped(_ sender: UIButton) {
        self.audioCellDelegate?.didTapDownloadButton(sender, onCell: self)
    }
    
    @IBAction func playButtonTapped(_ sender: UIButton) {
        self.isPlaying = true
        DispatchQueue.main.async {
            autoreleasepool{
//                self.comment?.updatePlaying(playing: true) data ada di dalam Qcomment
                self.audioCellDelegate?.didTapPlayButton(sender, onCell: self)
            }
        }
    }
    @IBAction func pauseButtonTapped(_ sender: UIButton) {
        self.isPlaying = false
        DispatchQueue.main.async {
            autoreleasepool{
//                self.comment?.updatePlaying(playing: false) sama kayak diatas
                self.audioCellDelegate?.didTapPauseButton(sender, onCell: self)
            }
        }
    }
}
