//
//  NavigationBar.swift
//  qonsultant
//
//  Created by Ahmad Athaullah on 7/20/16.
//  Copyright © 2016 qiscus. All rights reserved.
//

import UIKit

extension UINavigationItem {

    public func setTitleWithSubtitle(title:String, subtitle : String){
        
        let titleWidth = QiscusHelper.screenWidth() - 160
        
        let titleLabel = UILabel(frame:CGRect(x: 0, y: 0, width: 0, height: 0))
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.text = title
        titleLabel.textAlignment = .left
        titleLabel.tag = 502
        titleLabel.sizeToFit()
        
        let subTitleLabel = UILabel(frame:CGRect(x: 0, y: 18, width: 0, height: 0))
        subTitleLabel.backgroundColor = UIColor.clear
        subTitleLabel.textColor = UIColor.white
        subTitleLabel.font = UIFont.systemFont(ofSize: 11)
        subTitleLabel.text = subtitle
        subTitleLabel.tag = 402
        subTitleLabel.textAlignment = .left
        subTitleLabel.sizeToFit()

        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: titleWidth, height: 30))
        
        if titleLabel.frame.width > titleWidth {
            var adjustment = titleLabel.frame
            adjustment.size.width = titleWidth
            titleLabel.frame = adjustment
        }
        if subTitleLabel.frame.width > titleWidth {
            var adjustment = subTitleLabel.frame
            adjustment.size.width = titleWidth
            subTitleLabel.frame = adjustment
        }
        
        titleView.addSubview(titleLabel)
        titleView.addSubview(subTitleLabel)
        
        let tapRecognizer = UITapGestureRecognizer(target: QiscusChatVC.sharedInstance, action: #selector(QiscusChatVC.goToTitleAction))
        titleView.addGestureRecognizer(tapRecognizer)
        
        self.titleView = titleView
        
    }

}
