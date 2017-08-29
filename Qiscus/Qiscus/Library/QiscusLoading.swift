//
//  QiscusLoading.swift
//  QiscusSDK
//
//  Created by Ahmad Athaullah on 12/20/16.
//  Copyright © 2016 Ahmad Athaullah. All rights reserved.
//

import UIKit

public extension UIViewController{
    @objc public func showQiscusLoading(withText text:String? = nil, andProgress progress:Float = 0, isBlocking:Bool = false){
        Qiscus.uiThread.async {autoreleasepool{
            let loadingView = QLoadingViewController.sharedInstance
            if !loadingView.isPresence{
                loadingView.modalTransitionStyle = .crossDissolve
                loadingView.modalPresentationStyle = .overCurrentContext
                loadingView.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
                
                if text == nil {
                    loadingView.loadingLabel.isHidden = true
                    loadingView.loadingLabel.text = ""
                }else{
                    loadingView.loadingLabel.isHidden = false
                    loadingView.loadingLabel.text = text
                }
                loadingView.isBlocking = isBlocking
                if progress == 0{
                    loadingView.percentageLabel.text = ""
                    loadingView.percentageLabel.isHidden = true
                }else{
                    let percentage:Int = Int(progress * 100)
                    loadingView.percentageLabel.text = "\(percentage)%"
                    loadingView.percentageLabel.isHidden = false
                }
                
                UIApplication.shared.keyWindow?.rootViewController?.present(loadingView, animated: false, completion: {
                        loadingView.isPresence = true
                })
            }
        }}
    }
    public func dismissQiscusLoading(){
        Qiscus.uiThread.async { autoreleasepool{
            let loadingView = QLoadingViewController.sharedInstance
            if loadingView.isPresence{
                loadingView.dismiss(animated: false, completion: {
                    loadingView.dismissImmediately = false
                    loadingView.isPresence = false
                })
            }
        }}
    }
}
