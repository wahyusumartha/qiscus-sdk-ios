//
//  QiscusDataPresenter.swift
//  QiscusSDK
//
//  Created by Ahmad Athaullah on 2/15/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit
import Photos

@objc public protocol QiscusDataPresenterDelegate {
    func dataPresenter(didFinishLoad comments:[[QiscusCommentPresenter]], inRoom:QiscusRoom)
    func dataPresenter(gotNewData presenter:QiscusCommentPresenter, inRoom:QiscusRoom, realtime:Bool)
    func dataPresenter(didChangeStatusFrom commentId: Int, toStatus: QiscusCommentStatus, topicId: Int)
    func dataPresenter(didChangeContent data:QiscusCommentPresenter, inRoom:QiscusRoom)
    func dataPresenter(didChangeCellSize presenter:QiscusCommentPresenter, inRoom:QiscusRoom)
    func dataPresenter(didFinishLoadMore comments:[[QiscusCommentPresenter]], inRoom:QiscusRoom)
    func dataPresenter(didFailLoadMore inRoom:QiscusRoom)
    func dataPresenter(didChangeUser user: QiscusUser, onUserWithEmail email: String)
    func dataPresenter(didChangeRoom room: QiscusRoom, onRoomWithId roomId:Int)
    func dataPresenter(didFailLoad error:String)
    func dataPresenter(willResendData data:QiscusCommentPresenter)
    func dataPresenter(dataDeleted data:QiscusCommentPresenter)
}
@objc class QiscusDataPresenter: NSObject {
    open static let shared = QiscusDataPresenter()
    
    var commentClient = QiscusCommentClient.sharedInstance
    var delegate:QiscusDataPresenterDelegate?
    
    fileprivate override init(){
        super.init()
//        commentClient.commentDelegate = self
        commentClient.delegate = self
    }
    
    
}
// MARK: QiscusServiceDelegate
extension QiscusDataPresenter: QiscusServiceDelegate{
    func qiscusService(didFinishLoadRoom inRoom: QiscusRoom, withMessage message: String?) {
        
    }
    func qiscusService(didFailLoadRoom withError: String) {
    }
    func qiscusService(didFinishLoadMore inRoom: QiscusRoom, dataCount: Int, from commentId:Int) {
        
    }
    func qiscusService(didChangeContent data:QiscusCommentPresenter){
    }
    func qiscusService(didFailLoadMore inRoom: QiscusRoom) {
        
    }
    func qiscusService(didChangeUser user: QiscusUser, onUserWithEmail email: String) {
    }
    func qiscusService(didChangeRoom room: QiscusRoom, onRoomWithId roomId: Int) {
        
    }
}
