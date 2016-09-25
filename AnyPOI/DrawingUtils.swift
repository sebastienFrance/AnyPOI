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
    
    static func getImageForColor(fillColor:UIColor, imageSize:CGFloat = 25.0, lineWidth:CGFloat = 1.0) -> UIImage {
        let size = CGSizeMake(imageSize, imageSize)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let background = CAShapeLayer()
        let rect = CGRectMake(lineWidth / 2.0,
                              lineWidth / 2.0,
                              imageSize - (lineWidth),imageSize - (lineWidth))
        let path = UIBezierPath(ovalInRect: rect)
        background.path = path.CGPath
        background.fillColor = fillColor.CGColor
        background.strokeColor = UIColor.blackColor().CGColor
        background.lineWidth = lineWidth
        background.setNeedsDisplay()
        background.renderInContext(UIGraphicsGetCurrentContext()!)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }

}
