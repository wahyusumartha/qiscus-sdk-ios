//
//  QCommentDelegate.swift
//  Qiscus
//
//  Created by Qiscus on 05/07/18.
//

import UIKit

@objc public protocol QCommentDelegate {
    func comment(didChangeStatus comment:QComment, status:QCommentStatus)
    func comment(didChangePosition comment:QComment, position:QCellPosition)
    
    // Audio comment delegate
    @objc optional func comment(didChangeDurationLabel comment:QComment, label:String)
    @objc optional func comment(didChangeCurrentTimeSlider comment:QComment, value:Float)
    @objc optional func comment(didChangeSeekTimeLabel comment:QComment, label:String)
    @objc optional func comment(didChangeAudioPlaying comment:QComment, playing:Bool)
    
    // File comment delegate
    @objc optional func comment(didDownload comment:QComment, downloading:Bool)
    @objc optional func comment(didUpload comment:QComment, uploading:Bool)
    @objc optional func comment(didChangeProgress comment:QComment, progress:CGFloat)
}
