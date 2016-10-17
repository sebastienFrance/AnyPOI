//
//  RouteUtilties.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 19/04/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit
import MapKit

class RouteUtilities {
    
    
    static let wazeProductId = 323229106
    static let cityMapperProductId = 469463298
    static let googleMapsProductId = 585027354

    
    static func getDirectionRequestFor(_ source:WayPoint, destination:WayPoint) -> MKDirections? {

        // get the 2 waypoints
        source.routeInfos = nil // Reset the calculated route
        
        // Build the request to get the route for the 2 waypoints
        let routeRequest = MKDirectionsRequest()
        routeRequest.requestsAlternateRoutes = true
        routeRequest.transportType = source.transportType!

        if let sourcePoi = source.wayPointPoi, let destinationPoi = destination.wayPointPoi {
            routeRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: sourcePoi.coordinate, addressDictionary: nil))
            routeRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationPoi.coordinate, addressDictionary: nil))
            return MKDirections(request: routeRequest)
        } else {
            return nil
        }
    }

    
    fileprivate static let GoogleURL = "comgooglemaps://"
    fileprivate static let WazeURL = "waze://"
    fileprivate static let CityMapperURL = "citymapper://"
    
    static func startAppleMap(_ sourceCoordinate:CLLocationCoordinate2D,
                              sourceName:String,
                              destinationCoordinate:CLLocationCoordinate2D,
                              destinationName:String,
                              transportType:MKDirectionsTransportType) {
        var items = [MKMapItem]()
        
        let mapAppOptions:[String : AnyObject] = [MKLaunchOptionsMapTypeKey : MKMapType.standard.rawValue as AnyObject,
                                                  MKLaunchOptionsShowsTrafficKey: true as AnyObject,
                                                  // SEB: Swift3 Force to convert to AnyObject, why?
                                                  MKLaunchOptionsDirectionsModeKey :  MapUtils.convertToLaunchOptionsDirection(transportType) as AnyObject]
        let source = MKMapItem(placemark: MKPlacemark(coordinate: sourceCoordinate, addressDictionary: nil))
        source.name = sourceName
        items.append(source)
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil))
        destination.name = destinationName
        items.append(destination)
        
        MKMapItem.openMaps(with: items, launchOptions: mapAppOptions)
    }
    
    static func startGoogleMap(_ sourceCoordinate:CLLocationCoordinate2D, destinationCoordinate:CLLocationCoordinate2D, transportType:String) {
        if RouteUtilities.hasGoogleMap() {
            UIApplication.shared.openURL(URL(string:
                "\(GoogleURL)?saddr=\(sourceCoordinate.latitude),\(sourceCoordinate.longitude)&daddr=\(destinationCoordinate.latitude),\(destinationCoordinate.longitude)&directionsmode=\(transportType)")!)
        } else {
            print("\(#function) Can't use \(GoogleURL)");
        }
    }
    
    static func hasGoogleMap() -> Bool {
        return UIApplication.shared.canOpenURL(URL(string:GoogleURL)!)
    }
    
    static func startWaze(_ sourceCoordinate:CLLocationCoordinate2D, destinationCoordinate:CLLocationCoordinate2D) {
        if RouteUtilities.hasWaze() {
            UIApplication.shared.openURL(URL(string:
                "\(WazeURL)?ll=\(destinationCoordinate.latitude),\(destinationCoordinate.longitude)&navigate=yes")!)
        } else {
            print("\(#function) Can't use \(WazeURL)");
        }
    }
    
    static func hasWaze() -> Bool {
        return UIApplication.shared.canOpenURL(URL(string:WazeURL)!)
    }
    
    static func startCityMapper(_ sourceCoordinate:CLLocationCoordinate2D, destinationCoordinate:CLLocationCoordinate2D) {
        if RouteUtilities.hasCityMapper() {
            let myURL = URL(string: "\(CityMapperURL)directions?startcoord=\(sourceCoordinate.latitude),\(sourceCoordinate.longitude)&endcoord=\(destinationCoordinate.latitude),\(destinationCoordinate.longitude)")
            UIApplication.shared.openURL(myURL!)
        } else {
            print("\(#function) Can't use \(CityMapperURL)");
        }

    }
    
    static func hasCityMapper() -> Bool {
        return UIApplication.shared.canOpenURL(URL(string:CityMapperURL)!)
    }
    

}
