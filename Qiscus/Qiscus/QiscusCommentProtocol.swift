//
//  QiscusCommentProtocol.swift
//  Example
//
//  Created by Ahmad Athaullah on 2/15/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import UIKit

@objc protocol QiscusCommentDelegate {
    func qiscusComment(didChange comment: QiscusComment, to newComment: QiscusComment)
}
