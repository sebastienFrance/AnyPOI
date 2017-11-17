//
//  WatchPointOfInterest.swift
//  AnyPOIWatch Extension
//
//  Created by Sébastien Brugalières on 14/10/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import UIKit
import ClockKit

class WatchPointOfInterest : BasicPointOfInterest {
    
    var complicationTitle:CLKTextProvider {
        return CLKTextProvider.localizableTextProvider(withStringsFileTextKey: poiTitle)
    }
    
    var complicationGlyph:CLKImageProvider {
        if let theCatgory = category {
            return CLKImageProvider(onePieceImage: theCatgory.glyph)
        } else {
            return CLKImageProvider(onePieceImage: CategoryUtils.defaultGroupCategory.glyph)
        }
    }
    
    var complicationCategory: CLKTextProvider {
        if let theCatgory = category {
            return CLKTextProvider.localizableTextProvider(withStringsFileTextKey: theCatgory.localizedString)
        } else {
            return CLKTextProvider.localizableTextProvider(withStringsFileTextKey: "?")
        }
    }
    
    var complicationDistance: CLKTextProvider {
        return CLKTextProvider.localizableTextProvider(withStringsFileTextKey: distance)
    }
}
