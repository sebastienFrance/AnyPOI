//
//  ExportGPX.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 27/11/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation

class ExportGPX {
    
    fileprivate let pois:[PointOfInterest]
    fileprivate let routes:[Route]
    
    init(pois:[PointOfInterest]) {
        self.pois = pois
        self.routes = [Route]()
    }
    
    init(routes:[Route]) {
        self.routes = routes
        
        var uniquePois = [PointOfInterest]()
        for currentRoute in routes {
            for currentPoi in currentRoute.pois {
                if !uniquePois.contains(currentPoi) {
                    uniquePois.append(currentPoi)
                }
            }
        }
        
        self.pois = uniquePois
    }
    
    func getGPX() -> String {
        let gpxAttributes = [ "xmlns" : "http://www.topografix.com/GPX/1/1",
                              "xmlns:xsi" : "http://www.w3.org/2001/XMLSchema-instance",
                              "xsi:schemaLocation" : "http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd",
                              "version" : "1.1",
                              "creator" : "AnyPOI"]
        
        var gpxElement = XMLElement(elementName: GPXParser.XSD.GPX.name, attributes: gpxAttributes)
        for currentPoi in pois {
            gpxElement.addSub(element: currentPoi.toGPXElement())
        }
        for currentRoute in routes {
            gpxElement.addSub(element: currentRoute.toGPXElement())
        }

        let rootAttributes = [ "version" : "1.0", "encoding" : "UTF-8" ]
        let rootXMLElement = XMLRoot(attributes: rootAttributes, xmlContent:gpxElement)
        return rootXMLElement.toString
    }
}
