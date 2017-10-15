//
//  AnyPOIComplication.swift
//  AnyPOIWatch Extension
//
//  Created by Sébastien Brugalières on 15/10/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import WatchKit
import ClockKit

class AnyPOIComplicationController: NSObject, CLKComplicationDataSource {
    
    override init() {
        
    }
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        
        handler([])
    }
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        switch complication.family {
        case .circularSmall:
            break
        case .extraLarge:
            break
        case .modularLarge:
            let template = CLKComplicationTemplateModularLargeStandardBody()
            let myDelegate = WKExtension.shared().delegate as! ExtensionDelegate
             if let poi = myDelegate.nearestPOI() {
                template.headerImageProvider = CLKImageProvider(onePieceImage: poi.category!.glyph)
                template.headerTextProvider = CLKTextProvider.localizableTextProvider(withStringsFileTextKey: poi.title!)
                template.body1TextProvider = CLKTextProvider.localizableTextProvider(withStringsFileTextKey: poi.category!.localizedString)
                template.body2TextProvider = CLKTextProvider.localizableTextProvider(withStringsFileTextKey: poi.distance!)

             } else {
                template.headerTextProvider = CLKTextProvider.localizableTextProvider(withStringsFileTextKey: "No POI")
                template.body1TextProvider = CLKTextProvider.localizableTextProvider(withStringsFileTextKey: "")
                template.body2TextProvider = CLKTextProvider.localizableTextProvider(withStringsFileTextKey: "")
             }
            
            let timeLine = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(timeLine)
            break
        case .modularSmall:
            break
        case .utilitarianLarge:
            break
        case .utilitarianSmall:
            break
        case .utilitarianSmallFlat:
            break
        }

    }
    


}
