//
//  ChatInputText.swift
//  qonsultant
//
//  Created by Ahmad Athaullah on 7/20/16.
//  Copyright © 2016 qiscus. All rights reserved.
//

import UIKit

@objc public protocol ChatInputTextDelegate {
    func chatInputTextDidChange(chatInput input:ChatInputText, height: CGFloat)
    func chatInputDidEndEditing(chatInput input:ChatInputText)
    func valueChanged(value:String)
}

open class ChatInputText: UITextView, UITextViewDelegate {
    
    var chatInputDelegate: ChatInputTextDelegate?
    
    var value: String = "" 
    var placeHolderColor = UIColor(red: 153/255.0, green: 153/255.0, blue: 153/255.0, alpha: 1.0)
    var activeTextColor = UIColor(red: 77/255.0, green: 77/255.0, blue: 77/255.0, alpha: 1.0)
    
    var placeholder: String = ""{
        didSet{
            if placeholder != oldValue && self.value == ""{
                self.text = placeholder
                self.textColor = placeHolderColor
            }
        }
    }
    
    
    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        //self.commonInit()
    }
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    fileprivate func commonInit(){
        self.delegate = self
        self.placeholder = ""
        if self.value == "" {
            self.textColor = placeHolderColor
            self.text = placeholder
        }
        self.layer.cornerRadius = 14.0
        self.backgroundColor = UIColor.white
        self.isScrollEnabled = true
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor(red: 199/255.0, green: 199/255.0, blue: 204/255.0, alpha: 1.0).cgColor
        self.textContainerInset = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
    }

    // MARK: - UITextViewDelegate
    open func textViewDidChange(_ textView: UITextView) {
        let maxHeight:CGFloat = 85
        let minHeight:CGFloat = 28
        let fixedWidth = textView.frame.width
        
        self.value = textView.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        self.chatInputDelegate?.valueChanged(value: self.value)
        var newHeight = textView.sizeThatFits(CGSize(width: fixedWidth, height: maxHeight)).height
        
        if newHeight <= 28 {
            newHeight = minHeight
        }
        if newHeight > maxHeight {
            newHeight = maxHeight
        }
        if self.value == "" {
            QiscusChatVC.sharedInstance.sendButton.isEnabled = false
        }else{
            QiscusChatVC.sharedInstance.sendButton.isEnabled = true
        }
        self.chatInputDelegate?.chatInputTextDidChange(chatInput: self, height: newHeight)
        
    }
    
    open func textViewDidBeginEditing(_ textView: UITextView) {
        textView.text = self.value
        textView.textColor = self.activeTextColor
        textView.becomeFirstResponder()
    }
    open func textViewDidEndEditing(_ textView: UITextView) {
        if value == "" {
            textView.text = self.placeholder
            textView.textColor = self.placeHolderColor
            QiscusChatVC.sharedInstance.sendButton.isEnabled = false
        }
        textView.resignFirstResponder()
        self.chatInputDelegate?.chatInputDidEndEditing(chatInput: self)
    }
    open func clearValue(){
        self.value = ""
        Qiscus.uiThread.async {
            self.text = self.placeholder
            self.textColor = self.placeHolderColor
        }
    }
    
}
