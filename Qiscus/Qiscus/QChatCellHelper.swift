//
//  QChatCellHelper.swift
//  QiscusSDK
//
//  Created by Ahmad Athaullah on 12/30/16.
//  Copyright © 2016 Ahmad Athaullah. All rights reserved.
//

import UIKit

public enum CellTypePosition {
    case single,first,middle,last
}
public enum CellPosition {
    case left, right
}

open class QChatCellHelper: NSObject {
    open class func maskImage(image: UIImage, withMaskImage maskImage:UIImage)->UIImage{
        let imageReference = image.cgImage!
        let maskReference = maskImage.cgImage!
        
        let imageMask = CGImage(maskWidth: maskReference.width, height: maskReference.width, bitsPerComponent: maskReference.bitsPerComponent, bitsPerPixel: maskReference.bitsPerPixel, bytesPerRow: maskReference.bytesPerRow, provider: maskReference.dataProvider!, decode: nil, shouldInterpolate: true)!
        
        
        let maskedReference = imageReference.masking(imageMask)
        
        let maskedImage = UIImage(cgImage:maskedReference!)
        
        return maskedImage
    }
    open class func balloonImage(withPosition position:CellPosition? = nil, cellVPos:CellTypePosition? = nil)->UIImage?{
        var balloonEdgeInset = UIEdgeInsetsMake(13, 13, 13, 13)
        var balloonImage = Qiscus.image(named:"text_balloon_left")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
        if position != nil {
            if position == .left {
                balloonEdgeInset = UIEdgeInsetsMake(13, 28, 13, 13)
                if cellVPos != nil {
                    if cellVPos == .last {
                        balloonImage = Qiscus.image(named:"text_balloon_last_l")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
                    }else{
                        balloonImage = Qiscus.image(named:"text_balloon_left")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
                    }
                }else{
                    balloonImage = Qiscus.image(named:"text_balloon_left")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
                }
            }else{
                balloonEdgeInset = UIEdgeInsetsMake(13, 13, 13, 28)
                if cellVPos != nil {
                    if cellVPos == .last {
                        balloonImage = Qiscus.image(named:"text_balloon_last_r")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
                    }else{
                        balloonImage = Qiscus.image(named:"text_balloon_right")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
                    }
                }else{
                    balloonImage = Qiscus.image(named:"text_balloon_right")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
                }
            }
        }else{
            if cellVPos != nil{
                if cellVPos == .first{
                    balloonImage = Qiscus.image(named:"text_balloon_first")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
                }else if cellVPos == .middle{
                    balloonImage = Qiscus.image(named:"text_balloon_mid")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
                }
            }else{
                balloonImage = Qiscus.image(named:"text_balloon")?.resizableImage(withCapInsets: balloonEdgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
            }
            
        }
        return balloonImage
    }
    open class func getFormattedStringFromInt(_ number: Int) -> String{
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .none
        return numberFormatter.string(from: NSNumber(integerLiteral:number))!
    }
}
