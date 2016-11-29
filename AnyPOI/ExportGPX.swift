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
    
    init(pois:[PointOfInterest]) {
        self.pois = pois
    }
    
    func getGPX() -> String {
        /*
         <?xml version="1.0" encoding="ISO-8859-2"?>
         <gpx xmlns="http://www.topografix.com/GPX/1/1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd" version="1.1" creator="POIPlaza (http://www.poiplaza.com)">
         */
        
        var xml = "<?xml version=\"1.0\" encoding=\"ISO-8859-2\"?>"
        xml += "<gpx xmlns=\"http://www.topografix.com/GPX/1/1\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd\" version=\"1.1\""
        xml += " creator=\"AnyPOI\">"
        
        for currentPoi in pois {
            xml += currentPoi.toGPX()
        }
        
        xml += "</gpx>"
        
        return xml
    }
}
