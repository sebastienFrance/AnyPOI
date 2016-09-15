//
//  DrawingUtils.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 11/01/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import CoreData

class DrawingUtils {
    
    struct layersName {
        static let circleForGroup = "CircleForGroup"
    }
    
    static func insertCircleForGroup(view:UIView, fillColor:UIColor, withStroke:Bool = false) {
        insertCircleInWithStroke(view, fillColor: fillColor, strokeColor: UIColor.blackColor(), lineWidth: withStroke ? 5 : 1)
    }
    
    static func insertCircleIn(view:UIView, fillColor:UIColor) {
        if let subLayers = view.layer.sublayers {
            if subLayers.count > 0 && subLayers[subLayers.count - 1].name == layersName.circleForGroup {
                subLayers[subLayers.count - 1].removeFromSuperlayer()
            }
        }
        
        let background = CAShapeLayer()
        view.layer.addSublayer(background)
        let rect = view.bounds
        let path = UIBezierPath(ovalInRect: rect)
        background.path = path.CGPath
        background.frame = view.layer.bounds
        background.fillColor = fillColor.CGColor
        background.name = layersName.circleForGroup
    }
    
    static func insertCircleInWithStroke(view:UIView, fillColor:UIColor, strokeColor:UIColor, lineWidth:CGFloat) {
        if let subLayers = view.layer.sublayers {
            if subLayers.count > 0 && subLayers[subLayers.count - 1].name == layersName.circleForGroup {
                subLayers[subLayers.count - 1].removeFromSuperlayer()
            }
        }

        let background = CAShapeLayer()
        view.layer.addSublayer(background)
        let rect = view.bounds
        let path = UIBezierPath(ovalInRect: rect)
        background.path = path.CGPath
        background.frame = view.layer.bounds
        background.fillColor = fillColor.CGColor
        background.strokeColor = strokeColor.CGColor
        background.lineWidth = lineWidth
        background.name = layersName.circleForGroup
    }



}