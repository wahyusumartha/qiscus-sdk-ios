//
//  QRoomService.swift
//  Example
//
//  Created by Ahmad Athaullah on 7/8/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import AlamofireImage


public class QRoomService:NSObject{    
    public func sync(onRoom room:QRoom){
        let loadURL = QiscusConfig.ROOM_REQUEST_ID_URL
        let parameters:[String : AnyObject] =  [
            "id" : room.id as AnyObject,
            "token"  : Qiscus.shared.config.USER_TOKEN as AnyObject
        ]
        Alamofire.request(loadURL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
            if let response = responseData.result.value {
                let json = JSON(response)
                let results = json["results"]
                let error = json["error"]
                
                if results != JSON.null{
                    let roomData = results["room"]
                    room.syncRoomData(withJSON: roomData)
                }else if error != JSON.null{
                    Qiscus.printLog(text: "error getRoom")
                    
                }else{
                    Qiscus.printLog(text: "error getRoom: ")
                }
            }else{
                Qiscus.printLog(text: "error getRoom")
            }
        })
    }
    public func loadMore(onRoom room:QRoom){
        let loadURL = QiscusConfig.LOAD_URL
        var parameters =  [
            "topic_id" : room.id as AnyObject,
            "token" : Qiscus.shared.config.USER_TOKEN as AnyObject
        ]
        if room.comments.count > 0 {
            parameters["last_comment_id"] = room.comments.first!.comments.first!.id as AnyObject
        }
        Qiscus.printLog(text: "request loadMore parameters: \(parameters)")
        Qiscus.printLog(text: "request loadMore url \(loadURL)")
        
        Alamofire.request(loadURL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON(completionHandler: {responseData in
            Qiscus.printLog(text: "loadMore result: \(responseData)")
            if let response = responseData.result.value{
                let json = JSON(response)
                let results = json["results"]
                let error = json["error"]
                if results != JSON.null{
                    let comments = json["results"]["comments"].arrayValue
                    if comments.count > 0 {
                        for newComment in comments {
                            room.saveOldComment(fromJSON: newComment)
                        }
                    }
                }else if error != JSON.null{
                    Qiscus.printLog(text: "error loadMore: \(error)")
                }
            }else{
                Qiscus.printLog(text: "fail to LoadMore Data")
            }
        })
    }
    
}
