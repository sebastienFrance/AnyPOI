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

    
    static func getDirectionRequestFor(source:WayPoint, destination:WayPoint) -> MKDirections? {

        // get the 2 waypoints
        source.calculatedRoute = nil // Reset the calculated route
        
        // Build the request to get the route for the 2 waypoints
        let routeRequest = MKDirectionsRequest()
        routeRequest.requestsAlternateRoutes = true
        routeRequest.transportType = source.transportType!

        if let sourcePoi = source.wayPointPoi, destinationPoi = destination.wayPointPoi {
            routeRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: sourcePoi.coordinate, addressDictionary: nil))
            routeRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationPoi.coordinate, addressDictionary: nil))
            return MKDirections(request: routeRequest)
        } else {
            return nil
        }
    }

    
    private static let GoogleURL = "comgooglemaps://"
    private static let WazeURL = "waze://"
    private static let CityMapperURL = "citymapper://"
    
    static func startAppleMap(sourceCoordinate:CLLocationCoordinate2D,
                              sourceName:String,
                              destinationCoordinate:CLLocationCoordinate2D,
                              destinationName:String,
                              transportType:MKDirectionsTransportType) {
        var items = [MKMapItem]()
        
        let mapAppOptions:[String : AnyObject] = [MKLaunchOptionsMapTypeKey : MKMapType.Standard.rawValue, MKLaunchOptionsShowsTrafficKey: true,
                                                  MKLaunchOptionsDirectionsModeKey :  MapUtils.convertToLaunchOptionsDirection(transportType)]
        let source = MKMapItem(placemark: MKPlacemark(coordinate: sourceCoordinate, addressDictionary: nil))
        source.name = sourceName
        items.append(source)
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil))
        destination.name = destinationName
        items.append(destination)
        
        MKMapItem.openMapsWithItems(items, launchOptions: mapAppOptions)
    }
    
    static func startGoogleMap(sourceCoordinate:CLLocationCoordinate2D, destinationCoordinate:CLLocationCoordinate2D, transportType:String) {
        if RouteUtilities.hasGoogleMap() {
            UIApplication.sharedApplication().openURL(NSURL(string:
                "\(GoogleURL)?saddr=\(sourceCoordinate.latitude),\(sourceCoordinate.longitude)&daddr=\(destinationCoordinate.latitude),\(destinationCoordinate.longitude)&directionsmode=\(transportType)")!)
        } else {
            print("\(#function) Can't use \(GoogleURL)");
        }
    }
    
    static func hasGoogleMap() -> Bool {
        return UIApplication.sharedApplication().canOpenURL(NSURL(string:GoogleURL)!)
    }
    
    static func startWaze(sourceCoordinate:CLLocationCoordinate2D, destinationCoordinate:CLLocationCoordinate2D) {
        if RouteUtilities.hasWaze() {
            UIApplication.sharedApplication().openURL(NSURL(string:
                "\(WazeURL)?ll=\(destinationCoordinate.latitude),\(destinationCoordinate.longitude)&navigate=yes")!)
        } else {
            print("\(#function) Can't use \(WazeURL)");
        }
    }
    
    static func hasWaze() -> Bool {
        return UIApplication.sharedApplication().canOpenURL(NSURL(string:WazeURL)!)
    }
    
    static func startCityMapper(sourceCoordinate:CLLocationCoordinate2D, destinationCoordinate:CLLocationCoordinate2D) {
        if RouteUtilities.hasCityMapper() {
            let myURL = NSURL(string: "\(CityMapperURL)directions?startcoord=\(sourceCoordinate.latitude),\(sourceCoordinate.longitude)&endcoord=\(destinationCoordinate.latitude),\(destinationCoordinate.longitude)")
            UIApplication.sharedApplication().openURL(myURL!)
        } else {
            print("\(#function) Can't use \(CityMapperURL)");
        }

    }
    
    static func hasCityMapper() -> Bool {
        return UIApplication.sharedApplication().canOpenURL(NSURL(string:CityMapperURL)!)
    }
    

}
