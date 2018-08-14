//
//  QiscusChatVC.swift
//  Qiscus
//
//  Created by Qiscus on 07/08/18.
//

import UIKit
import QiscusUI

public protocol QiscusChatVCCellDelegate{
    func chatVC(viewController:QiscusChatVC, didTapLinkButtonWithURL url:URL )
    
    func chatVC(viewController:QiscusChatVC, hideCellWith comment:QComment)->Bool
}

public protocol QiscusChatVCConfigDelegate{
    func chatVCConfigDelegate(usingSoftDeleteOn viewController:QiscusChatVC)->Bool
    func chatVCConfigDelegate(deletedMessageTextFor viewController:QiscusChatVC, selfMessage isSelf:Bool)->String
    func chatVCConfigDelegate(enableReplyMenuItem viewController:QiscusChatVC, forComment comment: QComment)->Bool
    func chatVCConfigDelegate(enableForwardMenuItem viewController:QiscusChatVC, forComment comment: QComment)->Bool
    func chatVCConfigDelegate(enableResendMenuItem viewController:QiscusChatVC, forComment comment: QComment)->Bool
    func chatVCConfigDelegate(enableDeleteMenuItem viewController:QiscusChatVC, forComment comment: QComment)->Bool
    func chatVCConfigDelegate(enableDeleteForMeMenuItem viewController:QiscusChatVC, forComment comment: QComment)->Bool
    func chatVCConfigDelegate(enableShareMenuItem viewController:QiscusChatVC, forComment comment: QComment)->Bool
    func chatVCConfigDelegate(enableInfoMenuItem viewController:QiscusChatVC, forComment comment: QComment)->Bool
    
    func chatVCConfigDelegate(usingNavigationSubtitleTyping viewController:QiscusChatVC)->Bool
    func chatVCConfigDelegate(usingTypingCell viewController:QiscusChatVC)->Bool
    
}

public protocol QiscusChatVCDelegate{
    // MARK : Review this
    func chatVC(enableForwardAction viewController:QiscusChatVC)->Bool
    func chatVC(enableInfoAction viewController:QiscusChatVC)->Bool
    func chatVC(overrideBackAction viewController:QiscusChatVC)->Bool
    //
    func chatVC(backAction viewController:QiscusChatVC, room:QRoom?, data:Any?)
    func chatVC(titleAction viewController:QiscusChatVC, room:QRoom?, data:Any?)
    func chatVC(viewController:QiscusChatVC, onForwardComment comment:QComment, data:Any?)
    func chatVC(viewController:QiscusChatVC, infoActionComment comment:QComment,data:Any?)
    
    func chatVC(onViewDidLoad viewController:QiscusChatVC)
    func chatVC(viewController:QiscusChatVC, willAppear animated:Bool)
    func chatVC(viewController:QiscusChatVC, willDisappear animated:Bool)
    func chatVC(didTapAttachment actionSheet: UIAlertController, viewController: QiscusChatVC, onRoom: QRoom?)
    
    func chatVC(viewController:QiscusChatVC, willPostComment comment:QComment, room:QRoom?, data:Any?)->QComment?
    
    func chatVC(viewController:QiscusChatVC, didFailLoadRoom error:String)
}
public class QiscusChatVC: UIChatViewController {
    public var delegate:QiscusChatVCDelegate?
    public var configDelegate:QiscusChatVCConfigDelegate?
    public var cellDelegate:QiscusChatVCCellDelegate?
    public var isPresence:Bool = false
    public var chatDistinctId:String?
    public var chatData:String?
    public var chatMessage:String?
    public var archived:Bool = QiscusUIConfiguration.sharedInstance.readOnly
    public var chatNewRoomUsers:[String] = [String]()
    public var chatTitle:String?
    public var chatSubtitle:String?
    public var chatUser:String?
    public var data:Any?
    public var chatRoomId:String?
    public var chatTarget:QComment?
    
    @objc func back() {
        self.isPresence = false
        view.endEditing(true)
        if let delegate = self.delegate{
            if delegate.chatVC(overrideBackAction: self){
                delegate.chatVC(backAction: self, room: self.room as! QRoom, data: data)
            }else{
                let _ = self.navigationController?.popViewController(animated: true)
            }
        }else{
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(animated)
       self.tabBarController?.tabBar.isHidden = true
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    func setupUI(){
         self.setupNavigationTitle()
    }
    private func setupNavigationTitle(){
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = false
        }
        var totalButton = 1
        if let leftButtons = self.navigationItem.leftBarButtonItems {
            totalButton += leftButtons.count
        }
        if let rightButtons = self.navigationItem.rightBarButtonItems {
            totalButton += rightButtons.count
        }
        
        let backButton = self.backButton(self, action: #selector(self.back))
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.navigationItem.leftBarButtonItems = [backButton]
    }
    
    private func backButton(_ target: UIViewController, action: Selector) -> UIBarButtonItem{
        let backIcon = UIImageView()
        backIcon.contentMode = .scaleAspectFit
        
        let image = QiscusUI.image(named: "ic_back")?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        backIcon.image = image
        backIcon.tintColor = UINavigationBar.appearance().tintColor
        
        if UIApplication.shared.userInterfaceLayoutDirection == .leftToRight {
            backIcon.frame = CGRect(x: 0,y: 11,width: 13,height: 22)
        }else{
            backIcon.frame = CGRect(x: 22,y: 11,width: 13,height: 22)
        }
        
        let backButton = UIButton(frame:CGRect(x: 0,y: 0,width: 23,height: 44))
        backButton.addSubview(backIcon)
        backButton.addTarget(target, action: action, for: UIControlEvents.touchUpInside)
        return UIBarButtonItem(customView: backButton)
    }
    
}
