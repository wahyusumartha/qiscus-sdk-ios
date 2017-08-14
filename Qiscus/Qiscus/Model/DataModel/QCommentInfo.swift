//
//  QCommentInfo.swift
//  Example
//
//  Created by Ahmad Athaullah on 8/2/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import Foundation

public class QCommentInfo: NSObject {
    public var comment:QComment?
    public var deliveredUser = [QParticipant]()
    public var readUser = [QParticipant]()
    public var undeliveredUser = [QParticipant]()
}
