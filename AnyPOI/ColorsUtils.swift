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
