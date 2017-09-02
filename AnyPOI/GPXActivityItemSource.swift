//
//  GPXActivityItemSource.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 27/11/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class GPXActivityItemSource: NSObject, UIActivityItemSource {
    
    
    let gpxExportData:String
    
    init(pois:[PointOfInterest]) {
        let gpxExport = ExportGPX(pois: pois)
        gpxExportData = gpxExport.getGPX()
    }
    
    init(route:[Route]) {
        let gpxExport = ExportGPX(routes: route)
        gpxExportData = gpxExport.getGPX()
    }
    
    override init() {
        let gpxExport = ExportGPX()
        gpxExportData = gpxExport.getGPX()
    }
    
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return Data()
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType?) -> Any? {
        if let theActivityType = activityType, theActivityType == UIActivityType.mail || theActivityType.rawValue == HTMLAnyPoi.readdleSparkActivity  {
            return gpxExportData.data(using: .utf8)
        } else {
            return nil
        }
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivityType?) -> String {
        if activityType == UIActivityType.mail  {
            return "com.sebastien.AnyPOI.GPX"
        } else {
            return ""
        }
    }
    
}
