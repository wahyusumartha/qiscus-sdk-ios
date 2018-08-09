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
    
    func back() {
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
       self.tabBarController?.tabBar.isHidden = true
    }
   
}
