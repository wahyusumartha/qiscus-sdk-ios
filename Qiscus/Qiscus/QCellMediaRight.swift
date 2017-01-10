//
//  QCellMediaRight.swift
//  Example
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
    let maxProgressHeight:CGFloat = 36.0
    var isVideo = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        progressContainer.layer.cornerRadius = 20
        progressContainer.clipsToBounds = true
        progressContainer.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.65).cgColor
        progressContainer.layer.borderWidth = 2
        downloadButton.setImage(Qiscus.image(named: "ic_download_chat")!.withRenderingMode(.alwaysTemplate), for: UIControlState())
        downloadButton.tintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.7)
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
        imageDisplay.image = nil
        
        switch self.cellPos {
        case .first:
            let balloonEdgeInset = UIEdgeInsetsMake(13, 13, 13, 13)
            balloonView.image = Qiscus.image(named:"text_balloon_first")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
            break
        case .middle:
            let balloonEdgeInset = UIEdgeInsetsMake(13, 13, 13, 13)
            balloonView.image = Qiscus.image(named:"text_balloon_mid")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
            break
        case .last:
            let balloonEdgeInset = UIEdgeInsetsMake(13, 13, 13, 28)
            balloonView.image = Qiscus.image(named:"text_balloon_last_r")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
            break
        case .single:
            let balloonEdgeInset = UIEdgeInsetsMake(13, 13, 13, 28)
            balloonView.image = Qiscus.image(named:"text_balloon_right")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
            break
        }
        balloonView.tintColor = QiscusColorConfiguration.sharedInstance.leftBaloonColor
        
        // cleartap recognizer
        if self.tapRecognizer != nil{
            imageDisplay.removeGestureRecognizer(self.tapRecognizer!)
            tapRecognizer = nil
        }
        
        // if this is first cell
        if cellPos == .first || cellPos == .single{
            userNameLabel.text = user?.userFullName
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
        let imagePlaceholder = Qiscus.image(named: "media_balloon")
        
        if cellPos == .last || cellPos == .single{
            balloonWidth.constant = 147
            rightMargin.constant = 8
        }else{
            rightMargin.constant = 23
            balloonWidth.constant = 132
        }
        
        
        if file?.fileType == .video{
            self.videoPlay.isHidden = false
            self.videoFrame.isHidden = false
        }else{
            self.videoPlay.isHidden = true
            self.videoFrame.isHidden = true
        }
        
        self.imageDisplay.image = imagePlaceholder
        
        dateLabel.text = comment.commentTime.lowercased()
        progressLabel.isHidden = true
        dateLabel.textColor = UIColor.white
        
        self.downloadButton.removeTarget(nil, action: nil, for: .allEvents)
        
        if file != nil {
            if !file!.isLocalFileExist() {
                if QiscusHelper.isFileExist(inLocalPath: file!.fileMiniThumbPath){
                    if let image = UIImage.init(contentsOfFile: file!.fileMiniThumbPath){
                        self.imageDisplay.image = image
                    }
                }else{
                    var thumbLocalPath = file?.fileURL.replacingOccurrences(of: "/upload/", with: "/upload/w_30,c_scale/")
                    if file?.fileType == .video{
                        if let thumbUrlArr = thumbLocalPath?.characters.split(separator: "."){
                            var newThumbURL = ""
                            var i = 0
                            for thumbComponent in thumbUrlArr{
                                if i == 0{
                                    newThumbURL += String(thumbComponent)
                                }else if i < (thumbUrlArr.count - 1){
                                    newThumbURL += ".\(String(thumbComponent))"
                                }else{
                                    newThumbURL += ".png"
                                }
                                i += 1
                            }
                            thumbLocalPath = newThumbURL
                        }
                    }
                    
                    self.imageDisplay.loadAsync(thumbLocalPath!)
                }
                
                self.videoPlay.isHidden = true
                if file!.isDownloading {
                    self.downloadButton.isHidden = true
                    self.progressLabel.text = "\(Int(file!.downloadProgress * 100)) %"
                    self.progressLabel.isHidden = false
                    self.progressContainer.isHidden = false
                    self.progressView.isHidden = false
                    let newHeight = file!.downloadProgress * maxProgressHeight
                    self.progressHeight.constant = newHeight
                    self.progressView.layoutIfNeeded()
                    
                }else{
                    self.downloadButton.comment = comment
                    //self.fileNameLabel.hidden = false
                    //self.fileIcon.hidden = false
                    self.downloadButton.addTarget(self, action: #selector(QCellMediaRight.downloadMedia(_:)), for: .touchUpInside)
                    self.downloadButton.isHidden = false
                }
            }else{
                self.downloadButton.isHidden = true
                self.imageDisplay.image = UIImage.init(contentsOfFile: file!.fileThumbPath)
                tapRecognizer = UITapGestureRecognizer(target:self, action:#selector(QCellMediaLeft.didTapImage))
                imageDisplay.addGestureRecognizer(tapRecognizer!)
                if file!.isUploading{
                    self.progressContainer.isHidden = false
                    self.progressView.isHidden = false
                    let newHeight = file!.uploadProgress * maxProgressHeight
                    self.progressHeight.constant = newHeight
                    self.progressView.layoutIfNeeded()
                    if file?.fileType == .video {
                        self.videoPlay.isHidden = true
                    }
                }
            }
        }
        updateStatus(toStatus: comment.commentStatus)
        self.balloonView.layoutIfNeeded()
    }
    
    open func downloadMedia(_ sender: ChatFileButton){
        sender.isHidden = true
        let service = QiscusCommentClient.sharedInstance
        service.downloadMedia(sender.comment!)
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
            downloadButton.isHidden = true
            progressLabel.text = "\(percentage) %"
            progressLabel.isHidden = false
            progressContainer.isHidden = false
            progressView.isHidden = false
            
            let newHeight = (file?.downloadProgress)! * maxProgressHeight
            progressHeight.constant = newHeight
            progressView.layoutIfNeeded()
        }
    }
    
    func didTapImage(){
        if file != nil && !file!.isUploading && !file!.isDownloading{
            if let delegate = QiscusChatVC.sharedInstance.cellDelegate{
                delegate.didTapMediaCell(URL(string: "file://\(file!.fileLocalPath)")!, mediaName: file!.fileName)
            }else{
                QiscusChatVC.sharedInstance.galleryItems = [QiscusGalleryItem]()
                let comments = QiscusChatVC.sharedInstance.comments
                var i = 0
                var currentIndex = 0
                for commentGroup in comments{
                    for comment in commentGroup{
                        if let targetFile = QiscusFile.getCommentFile(comment.commentFileId){
                            if targetFile.fileType == QFileType.media || targetFile.fileType == QFileType.video{
                                if targetFile.isLocalFileExist(){
                                    if file!.fileLocalPath == targetFile.fileLocalPath{
                                        currentIndex = i
                                    }
                                    if targetFile.fileType == .media{
                                        let urlString = "file://\(targetFile.fileLocalPath)"
                                        if let url = URL(string: urlString) {
                                            if let data = try? Data(contentsOf: url) {
                                                let image = UIImage(data: data)!
                                                let item = QiscusGalleryItem()
                                                item.image = image
                                                item.isVideo = false
                                                QiscusChatVC.sharedInstance.galleryItems.append(item)
                                            }
                                        }
                                    }else{
                                        let urlString = "file://\(targetFile.fileLocalPath)"
                                        let urlThumb = "file://\(targetFile.fileThumbPath)"
                                        if let url = URL(string: urlThumb) {
                                            if let data = try? Data(contentsOf: url) {
                                                let image = UIImage(data: data)!
                                                let item = QiscusGalleryItem()
                                                item.image = image
                                                item.isVideo = true
                                                item.url = urlString
                                                QiscusChatVC.sharedInstance.galleryItems.append(item)
                                            }
                                        }
                                    }
                                    i += 1
                                }
                            }
                        }
                    }
                }
                let closeButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 20, height: 20)))
                closeButton.setImage(Qiscus.image(named: "close")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
                closeButton.tintColor = UIColor.white
                closeButton.imageView?.contentMode = .scaleAspectFit
                
                let seeAllButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 20, height: 20)))
                seeAllButton.setTitle("", for: UIControlState())
                seeAllButton.setImage(Qiscus.image(named: "viewmode")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
                seeAllButton.tintColor = UIColor.white
                seeAllButton.imageView?.contentMode = .scaleAspectFit
                
                let gallery = GalleryViewController(startIndex: currentIndex, itemsDatasource: QiscusChatVC.sharedInstance, displacedViewsDatasource: nil, configuration: QiscusChatVC.sharedInstance.galleryConfiguration())
                QiscusChatVC.sharedInstance.presentImageGallery(gallery)
            }
        }
    }
    
    func setupImageView(){
        if file != nil && !file!.isDownloading && !file!.isUploading{
            downloadButton.isHidden = true
            progressLabel.isHidden = true
            imageDisplay.loadAsync("file://\(file!.fileThumbPath)")
            if tapRecognizer != nil {
                imageDisplay.removeGestureRecognizer(tapRecognizer!)
            }
            tapRecognizer = UITapGestureRecognizer(target:self, action:#selector(QCellMediaRight.didTapImage))
            imageDisplay.addGestureRecognizer(tapRecognizer!)
            progressContainer.isHidden = true
            progressView.isHidden = true
            
            if file!.fileType == .video{
                videoPlay.isHidden = false
            }
        }
    }
}
