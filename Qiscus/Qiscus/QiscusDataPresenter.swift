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
        commentClient.commentDelegate = self
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
extension QiscusDataPresenter: QCommentDelegate{
    func didSuccesPostComment(_ comment:QiscusComment){
        
    }
    func didFailedPostComment(_ comment:QiscusComment){
    
    }
    func downloadingMedia(_ comment:QiscusComment){
    
    }
    func didDownloadMedia(_ comment: QiscusComment){
    
    }
    func didUploadFile(_ comment:QiscusComment){
    
    }
    func uploadingFile(_ comment:QiscusComment){
    
    }
    func didFailedUploadFile(_ comment:QiscusComment){
    
    }
    func didSuccessPostFile(_ comment:QiscusComment){
    
    }
    func didFailedPostFile(_ comment:QiscusComment){
    
    }
    func finishedLoadFromAPI(_ topicId: Int){
    
    }
    func gotNewComment(_ comments:[QiscusComment]){
    
    }
    func didFailedLoadDataFromAPI(_ error: String){
    
    }
    func didFinishLoadMore(){
    
    }
    func commentDidChangeStatus(fromComment comment:QiscusComment, toStatus: QiscusCommentStatus){
    
    }
    func performResendMessage(onIndexPath: IndexPath){
    
    }
    func performDeleteMessage(onIndexPath:IndexPath){
    
    }
    func didChangeUserStatus(withUser user:QiscusUser){
    
    }
    func didChangeUserName(withUser user:QiscusUser){
    
    }
    func didChangeSize(comment: QiscusComment){
    
    }
}
