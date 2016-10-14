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
    
    static func getImageForColor(_ fillColor:UIColor, imageSize:CGFloat = 25.0, lineWidth:CGFloat = 1.0) -> UIImage {
        let size = CGSize(width: imageSize, height: imageSize)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let background = CAShapeLayer()
        let rect = CGRect(x: lineWidth / 2.0,
                              y: lineWidth / 2.0,
                              width: imageSize - (lineWidth),height: imageSize - (lineWidth))
        let path = UIBezierPath(ovalIn: rect)
        background.path = path.cgPath
        background.fillColor = fillColor.cgColor
        background.strokeColor = UIColor.black.cgColor
        background.lineWidth = lineWidth
        background.setNeedsDisplay()
        background.render(in: UIGraphicsGetCurrentContext()!)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }

}
