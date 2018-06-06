//
//  QImageCell2.swift
//  QiscusUI
//
//  Created by Rahardyan Bisma on 31/05/18.
//

import UIKit
import SimpleImageViewer

class QImageCell: BaseChatCell {
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var tvContent: UILabel!
    @IBOutlet weak var ivBaloonLeft: UIImageView!
    @IBOutlet weak var lbTime: UILabel!
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var ivStatus: UIImageView!
    @IBOutlet weak var btnDownload: UIButton!
    @IBOutlet weak var ivComment: UIImageView!
    
    @IBOutlet weak var progressContainer: UIView!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var lbNameHeight: NSLayoutConstraint!
    @IBOutlet weak var lbNameLeading: NSLayoutConstraint!
    @IBOutlet weak var lbNameTrailing: NSLayoutConstraint!
    @IBOutlet weak var statusWidth: NSLayoutConstraint!
    @IBOutlet weak var rightConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    @IBOutlet weak var progressHeight: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.ivComment.contentMode = .scaleAspectFill
        self.ivComment.clipsToBounds = true
        self.ivComment.backgroundColor = UIColor.black
        self.ivComment.isUserInteractionEnabled = true
        self.progressContainer.layer.cornerRadius = 20
        self.progressContainer.clipsToBounds = true
        self.progressContainer.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.65).cgColor
        self.progressContainer.layer.borderWidth = 2
        self.progressView.backgroundColor = UIColor.green
        let imgTouchEvent = UITapGestureRecognizer(target: self, action: #selector(QImageCell.imageDidTap))
        self.ivComment.addGestureRecognizer(imgTouchEvent)
    }
    
    @objc func imageDidTap() {
        if let cellDelegate = self.delegate {
            let configuration = ImageViewerConfiguration { config in
                config.imageView = ivComment
            }
            
            let imageViewerController = ImageViewerController(configuration: configuration)
            cellDelegate.onImageCellDidTap(imageSlideShow: imageViewerController)
        }
    }
    
    override func menuResponderView() -> UIView {
        return self.ivBaloonLeft
    }
    
    func configureDisplayImage() {
        if let displayImage = self.comment.displayImage {
            self.ivComment.image = displayImage
            self.btnDownload.isHidden = true
            self.progressContainer.isHidden = true
        } else {
            self.btnDownload.isHidden = false
            self.progressContainer.isHidden = false
            if let file = self.comment.file {
                self.ivComment.loadAsync(url: file.thumbURL, onLoaded: { (image, _) in
                    self.ivComment.image = image
                    file.saveThumbImage(withImage: image)
                })
            }
        }
    }
    override func bindDataToView() {
        self.tvContent.text = "asdsad"
        self.lbName.text = self.comment.senderName
        self.lbTime.text = self.comment.time
        
        self.configureDisplayImage()
        
        if self.comment.isMyComment {
            DispatchQueue.main.async {
                self.rightConstraint.isActive = true
                self.leftConstraint.isActive = false
            }
            
            lbNameTrailing.constant = 5
            lbNameLeading.constant = 20
            lbName.textAlignment = .right
            self.statusWidth.constant = 15
            
            self.statusWidth.constant = 15
            
            switch self.comment.commentStatus {
            case .pending:
                let pendingIcon = QiscusUI.image(named: "ic_pending")?.withRenderingMode(.alwaysTemplate)
                self.ivStatus.tintColor = UIColor.lightGray
                self.ivStatus.image = pendingIcon
                break
            case .sending:
                let pendingIcon = QiscusUI.image(named: "ic_sending")?.withRenderingMode(.alwaysTemplate)
                self.ivStatus.tintColor = UIColor.lightGray
                self.ivStatus.image = pendingIcon
                break
            case .sent:
                let pendingIcon = QiscusUI.image(named: "ic_sending")?.withRenderingMode(.alwaysTemplate)
                self.ivStatus.tintColor = UIColor.lightGray
                self.ivStatus.image = pendingIcon
                break
            case .delivered:
                let pendingIcon = QiscusUI.image(named: "ic_read")?.withRenderingMode(.alwaysTemplate)
                self.ivStatus.tintColor = UIColor.lightGray
                self.ivStatus.image = pendingIcon
                break
            case .read:
                let pendingIcon = QiscusUI.image(named: "ic_read")?.withRenderingMode(.alwaysTemplate)
                self.ivStatus.tintColor = UIColor.green
                self.ivStatus.image = pendingIcon
                break
            case .deleting:
                let pendingIcon = QiscusUI.image(named: "ic_deleting")?.withRenderingMode(.alwaysTemplate)
                self.ivStatus.tintColor = UIColor.lightGray
                self.ivStatus.image = pendingIcon
                break
            case .deleted:
                let pendingIcon = QiscusUI.image(named: "ic_deleted")?.withRenderingMode(.alwaysTemplate)
                self.ivStatus.tintColor = UIColor.lightGray
                self.ivStatus.image = pendingIcon
                break
            case .deletePending:
                let pendingIcon = QiscusUI.image(named: "ic_deleting")?.withRenderingMode(.alwaysTemplate)
                self.ivStatus.tintColor = UIColor.lightGray
                self.ivStatus.image = pendingIcon
                break
            case .failed:
                let pendingIcon = QiscusUI.image(named: "ic_pending")?.withRenderingMode(.alwaysTemplate)
                self.ivStatus.tintColor = UIColor.lightGray
                self.ivStatus.image = pendingIcon
                break
            default:
                break
            }
            
        } else {
            DispatchQueue.main.async {
                self.rightConstraint.isActive = false
                self.leftConstraint.isActive = true
            }
            
            lbNameTrailing.constant = 20
            lbNameLeading.constant = 45
            lbName.textAlignment = .left
            self.statusWidth.constant = 0
        }
        
        if firstInSection {
            self.lbName.isHidden = false
            self.lbNameHeight.constant = CGFloat(21)
        } else {
            self.lbName.isHidden = true
            self.lbNameHeight.constant = CGFloat(0)
        }
    }
    
    override func updateDownloadProgress(progress: Double) {
        DispatchQueue.main.async {
            self.btnDownload.isHidden = true
            self.progressLabel.text = "\(Int(progress * 100)) %"
            self.progressLabel.isHidden = false
            self.progressContainer.isHidden = false
            self.progressView.isHidden = false
            
            let newHeight = CGFloat(progress) * self.maxProgressHeight
            self.progressHeight.constant = newHeight
            UIView.animate(withDuration: 0.65, animations: {
                self.progressView.layoutIfNeeded()
            })
        }
    }
    
    override func displayDownloadedImage(image: UIImage?) {
        if let displayImage = image {
            DispatchQueue.main.async {
                self.ivComment.image = displayImage
                self.progressContainer.isHidden = true
                self.btnDownload.isHidden = true
            }
        }
    }
    
    // MARK: button action
    @IBAction func btnDownloadDidTap(_ sender: UIButton) {
        self.downloadMedia()
    }
}


