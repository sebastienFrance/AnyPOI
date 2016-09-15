//
//  Wikipedia.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 24/01/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import MapKit

class Wikipedia {
    
    let title:String!
    let coordinates: CLLocationCoordinate2D!
    let pageId: Int!
    let distance:Float!
    
    var url:String {
        get {
            return WikipediaUtils.getMobileURLForPageId(pageId)
        }
    }
    
    var extract = "No description"
    
    init(title:String, latitude:Double, longitude:Double, pageId:Int, distance:Float) {
        self.title = title
        self.coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        self.pageId = pageId
        self.distance = distance
        
    }
    
    struct ArticleCste {
        static let title = "title"
        static let latitude = "lat"
        static let longitude = "lon"
        static let pageId = "pageid"
        static let distance = "dist"
    }
    
    convenience init(initialValues:Dictionary<String, AnyObject>) {
        let title = initialValues[ArticleCste.title] as! String
        let latitudeString = initialValues[ArticleCste.latitude] as! NSNumber
        let longitudeString = initialValues[ArticleCste.longitude] as! NSNumber
        let pageId = initialValues[ArticleCste.pageId] as! NSNumber
        let distance = initialValues[ArticleCste.distance] as! NSNumber
        
        self.init(title:title, latitude:Double(latitudeString), longitude: Double(longitudeString), pageId:Int(pageId), distance:Float(distance))
    }

    
}