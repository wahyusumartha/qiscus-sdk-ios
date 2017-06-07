//
//  QCellPostbackLeft.swift
//  Example
//
//  Created by Ahmad Athaullah on 5/18/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
import SwiftyJSON

protocol ChatCellPostbackDelegate {
    func didTapPostbackButton(withData data: JSON)
    func didTapAccountLinking(withData data: JSON)
}
class QCellPostbackLeft: QChatCell {
    let maxWidth:CGFloat = QiscusUIConfiguration.chatTextMaxWidth
    let minWidth:CGFloat = QiscusUIConfiguration.chatTextMaxWidth
    let buttonWidth:CGFloat = QiscusUIConfiguration.chatTextMaxWidth + 10
    
    var postbackDelegate:ChatCellPostbackDelegate?
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var balloonView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var buttonsView: UIStackView!
    
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    @IBOutlet weak var textViewWidth: NSLayoutConstraint!
    @IBOutlet weak var balloonTopMargin: NSLayoutConstraint!
    @IBOutlet weak var leftMargin: NSLayoutConstraint!
    @IBOutlet weak var balloonWidth: NSLayoutConstraint!
    @IBOutlet weak var cellHeight: NSLayoutConstraint!
    @IBOutlet weak var balloonHeight: NSLayoutConstraint!
    @IBOutlet weak var textLeading: NSLayoutConstraint!
    @IBOutlet weak var textTopMargin: NSLayoutConstraint!
    @IBOutlet weak var buttonsViewHeight: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textView.contentInset = UIEdgeInsets.zero
    }
    open override func setupCell() {
        textView.attributedText = data.commentAttributedText
        textView.linkTextAttributes = data.linkTextAttributes
        balloonView.image = data.balloonImage
        
        let textSize = data.cellSize
        var textWidth = data.cellSize.width
        
        if textWidth > minWidth {
            textWidth = textSize.width
        }else{
            textWidth = minWidth
        }
        
        for view in buttonsView.subviews{
            view.removeFromSuperview()
        }
        
        textViewWidth.constant = textWidth
        textViewHeight.constant = textSize.height
        
        userNameLabel.textAlignment = .left
        
        dateLabel.text = data.commentTime.lowercased()
        balloonView.tintColor = QiscusColorConfiguration.sharedInstance.leftBaloonColor
        dateLabel.textColor = QiscusColorConfiguration.sharedInstance.leftBaloonTextColor
        
        if data.cellPos == .first || data.cellPos == .single{
            userNameLabel.text = data.userFullName
            userNameLabel.isHidden = false
            balloonTopMargin.constant = 20
            cellHeight.constant = 20
        }else{
            userNameLabel.text = ""
            userNameLabel.isHidden = true
            balloonTopMargin.constant = 0
            cellHeight.constant = 0
        }
        
        // last cell
        if data.cellPos == .last || data.cellPos == .single{
            leftMargin.constant = 35
            textLeading.constant = 23
            balloonWidth.constant = 31
        }else{
            textLeading.constant = 8
            leftMargin.constant = 50
            balloonWidth.constant = 16
        }
        
        
        if data.commentType == .postback {
            var i = 0
            let buttonsPayload = JSON(parseJSON: data.comment!.commentButton).arrayValue
            //var yPos = CGFloat(5)
            self.buttonsViewHeight.constant = CGFloat(buttonsPayload.count * 35)
            self.layoutIfNeeded()
            for buttonsData in buttonsPayload{
                let button = UIButton(frame: CGRect(x: 0, y: 0, width: self.buttonWidth, height: 32))
                button.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.7)
                button.setTitle(buttonsData["label"].stringValue, for: .normal)
                button.setTitleColor(.black, for: .normal)
                button.tag = i
                button.addTarget(self, action:#selector(self.postback(sender:)), for: .touchUpInside)
                
                self.buttonsView.addArrangedSubview(button)
                
                i += 1
                //yPos += CGFloat(35)
            }
        }else{
            let dataPayload = JSON(parseJSON: data.comment!.commentButton)
            print("account linking data payload: \(dataPayload)")
            
            let paramData = dataPayload["params"]
            
            self.buttonsViewHeight.constant = CGFloat(35)
            self.layoutIfNeeded()
            
            let button = UIButton(frame: CGRect(x: 0, y: 0, width: self.buttonWidth, height: 32))
            button.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.7)
            button.setTitle(paramData["button_text"].stringValue, for: .normal)
            button.setTitleColor(.black, for: .normal)
            button.tag = 2222
            button.addTarget(self, action:#selector(self.accountLinking(sender:)), for: .touchUpInside)
            
            self.buttonsView.addArrangedSubview(button)
        }
    }
    
    func postback(sender:UIButton){
        let allData = JSON(parseJSON: self.data.comment!.commentButton).arrayValue
        if allData.count > sender.tag {
            let data = allData[sender.tag]
            self.postbackDelegate?.didTapPostbackButton(withData: data)
        }
    }
    
    func accountLinking(sender:UIButton){
        let data = JSON(parseJSON: self.data.comment!.commentButton)
        self.postbackDelegate?.didTapAccountLinking(withData: data)
    }
}
