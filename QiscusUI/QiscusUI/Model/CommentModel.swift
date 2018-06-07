//
//  CommentModel.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 07/05/18.
//

import Foundation
import Qiscus

public struct CommentModel {
    var uniqueId: String = ""
    var id: Int = 0
    var roomId: String = ""
    var text: String = ""
    var time: String = ""
    var date: String = ""
    var senderEmail: String = ""
    var senderName: String = ""
    var senderAvatarURL: String = ""
    var roomName: String = ""
    var textFontName: String = ""
    var textFontSize: Float = 0
    var displayImage: UIImage?
    var additionalData: String = ""
//    var repliedText: String = "" 
    
    //audio variable
    var durationLabel: String = ""
    var currentTimeSlider: Float = 0
    var seekTimeLabel: String = "00:00"
    var audioIsPlaying: Bool = false
    
    //file variable
    var isDownloading: Bool = false
    var isUploading: Bool = false
    var progress: CGFloat = 0
    
    var isRead: Bool = false
    var extras: [String: Any]?
    
    var isMyComment: Bool = false
    var commentType: QCommentType = .text
    var commentStatus: QCommentStatus = .sending
    var file: QFile?
}
