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
        NSLog("\(#function)")
        switch complication.family {
        case .circularSmall:
            let template = CLKComplicationTemplateCircularSmallSimpleImage()
            if let poi = WatchDataSource.sharedInstance.nearestPOI {
                template.imageProvider = poi.complicationGlyph
            }
            let timeLine = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(timeLine)
        case .extraLarge:
            break
        case .modularLarge:
            let template = CLKComplicationTemplateModularLargeStandardBody()
            if let poi = WatchDataSource.sharedInstance.nearestPOI {
                template.headerImageProvider = poi.complicationGlyph
                template.headerTextProvider = poi.complicationCategory
                template.body1TextProvider = poi.complicationTitle
                template.body2TextProvider = poi.complicationDistance

             } else {
                template.headerTextProvider = CLKTextProvider.localizableTextProvider(withStringsFileTextKey: NSLocalizedString("Complication_NoPOI", comment: ""))
                template.body1TextProvider = CLKTextProvider.localizableTextProvider(withStringsFileTextKey: NSLocalizedString("Complication_AroundYourLocation", comment: ""))
                template.body2TextProvider = CLKTextProvider.localizableTextProvider(withStringsFileTextKey: "")
             }
            
            let timeLine = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(timeLine)
        case .modularSmall:
            let template = CLKComplicationTemplateModularSmallSimpleImage()
            if let poi = WatchDataSource.sharedInstance.nearestPOI {
                template.imageProvider = poi.complicationGlyph
            }
            let timeLine = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(timeLine)
        case .utilitarianLarge:
            let template = CLKComplicationTemplateUtilitarianLargeFlat()
            if let poi = WatchDataSource.sharedInstance.nearestPOI {
                template.imageProvider = poi.complicationGlyph
                template.textProvider = poi.complicationTitle
            } else {
                template.textProvider = CLKTextProvider.localizableTextProvider(withStringsFileTextKey: NSLocalizedString("Complication_NoPOILargeFlat", comment: ""))
            }
            let timeLine = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(timeLine)
        case .utilitarianSmall:
            let template = CLKComplicationTemplateUtilitarianSmallSquare()
            if let poi = WatchDataSource.sharedInstance.nearestPOI {
                template.imageProvider = poi.complicationGlyph
            }
            let timeLine = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(timeLine)
        case .utilitarianSmallFlat:
            let template = CLKComplicationTemplateUtilitarianSmallFlat()
            if let poi = WatchDataSource.sharedInstance.nearestPOI {
                template.imageProvider = poi.complicationGlyph
                template.textProvider = CLKTextProvider.localizableTextProvider(withStringsFileTextKey: "")
            }
            let timeLine = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(timeLine)
        }

    }
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        switch complication.family {
        case .circularSmall:
            let template = CLKComplicationTemplateCircularSmallSimpleImage()
            template.imageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "Museum Filled-80"))
            handler(template)
        case .extraLarge:
            break
        case .modularLarge:
            let template = CLKComplicationTemplateModularLargeStandardBody()
            template.headerImageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "Museum Filled-80"))
            template.headerTextProvider = CLKTextProvider.localizableTextProvider(withStringsFileTextKey: "Musée")
            template.body1TextProvider = CLKTextProvider.localizableTextProvider(withStringsFileTextKey: "Le Louvre")
            template.body2TextProvider = CLKTextProvider.localizableTextProvider(withStringsFileTextKey: "800m")
            handler(template)
        case .modularSmall:
            let template = CLKComplicationTemplateModularSmallSimpleImage()
            template.imageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "Museum Filled-80"))
            handler(template)
        case .utilitarianLarge:
            let template = CLKComplicationTemplateUtilitarianLargeFlat()
            template.imageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "Museum Filled-80"))
            template.textProvider = CLKTextProvider.localizableTextProvider(withStringsFileTextKey: "Le Louvre")
            handler(template)
        case .utilitarianSmall:
            let template = CLKComplicationTemplateUtilitarianSmallSquare()
            template.imageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "Museum Filled-80"))
            handler(template)
        case .utilitarianSmallFlat:
            let template = CLKComplicationTemplateUtilitarianSmallFlat()
            template.imageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "Museum Filled-80"))
            template.textProvider = CLKTextProvider.localizableTextProvider(withStringsFileTextKey: "")
            handler(template)
        }
   }
}
