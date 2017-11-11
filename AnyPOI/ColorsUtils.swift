//
//  ColorsUtils.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 05/05/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class ColorsUtils {
    static func defaultGroupColor() -> UIColor {
        return UIColor.purple
    }
    
    static func contactsGroupColor() -> UIColor {
        return UIColor.blue
    }
    
    static var importedGroupColor:UIColor {
        get {
            return UIColor.orange
        }
    }
    
    static func getColor(color:UIColor) -> String? {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        if color.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return String(format: "#%02X%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255), Int(a * 255))
        } else {
            return nil
        }
    }
    
    static func getColor(rgba:String) -> UIColor? {
        guard rgba.hasPrefix("#") else {
            return nil
        }
        
        let index = rgba.index(rgba.startIndex, offsetBy: 1)
        let hexString = String(rgba[index...])
 
        var hexValue:  UInt32 = 0
        
        guard Scanner(string: hexString).scanHexInt32(&hexValue) else {
            return nil
        }
        
        let divisor = CGFloat(255)
        var red     = CGFloat((hexValue & 0xFF000000) >> 24) / divisor
        var green   = CGFloat((hexValue & 0x00FF0000) >> 16) / divisor
        var blue    = CGFloat((hexValue & 0x0000FF00) >>  8) / divisor
        var alpha   = CGFloat( hexValue & 0x000000FF       ) / divisor
        
        // Get the values on 2 digits
        red = CGFloat(round(100 * Double(red)) / 100)
        green = CGFloat(round(100 * Double(green)) / 100)
        blue = CGFloat(round(100 * Double(blue)) / 100)
        alpha = CGFloat(round(100 * Double(alpha)) / 100)
       
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    static func initColors() -> [UIColor] {
        
        var colors = [UIColor]()
        // 0.91, 1.1... to make sure the last value will be included
        for hue in stride(from: (0.0), through: 0.91, by: 0.1){
            for saturation in stride(from: (0.6), to: 1.1, by: 0.2) {
                for brightness in stride(from: (0.6), through: 1.1, by: 0.2) {
                    colors.append(UIColor(hue: CGFloat(hue), saturation: CGFloat(saturation), brightness: CGFloat(brightness), alpha: 1.0))
                }
            }
        }
        
        return colors
    }

    // Returns the index of the given color in the colors array. When the color is not in the array
    // then the returned value is -1
    static func findColorIndex(_ color:UIColor, inColors:[UIColor]) -> Int {
        for i in 0..<inColors.count {
            let currentColor = inColors[i]
            if color.description == currentColor.description {
                return i
            }
        }
        return -1
    }

}
