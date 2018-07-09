//
//  QParticipant.swift
//  Example
//
//  Created by Ahmad Athaullah on 7/5/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import Foundation
import RealmSwift
@objc public protocol QParticipantDelegate {
    func participant(didChange participant:QParticipant)
}
public class QParticipant:Object {
    static var cache = [String : QParticipant]()
    @objc public dynamic var localId:String = ""
    @objc public dynamic var roomId:String = ""
    @objc public dynamic var email:String = ""
    @objc public dynamic var lastReadCommentId:Int = 0
    @objc public dynamic var lastDeliveredCommentId:Int = 0
    
    public var delegate:QParticipantDelegate? = nil
    
    override public static func ignoredProperties() -> [String] {
        return ["delegate"]
    }
    
    // MARK: - Getter variable
    public var user:QUser? {
        get{
            return QUser.user(withEmail: self.email)
        }
    }

}
