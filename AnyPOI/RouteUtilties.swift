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
    static let hereMapProductId = 955837609

    
    static func getDirectionRequestFor(_ source:WayPoint, destination:WayPoint) -> MKDirections? {

        // get the 2 waypoints
        //source.routeInfos = nil // Reset the calculated route
        
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

    private struct URLs {
        static let Google = "comgooglemaps://"
        static let HereRoute = "here-route://"
        static let Waze = "waze://"
        static let CityMapper = "citymapper://"
    }
    
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
            let googleParameters = "saddr=\(sourceCoordinate.latitude),\(sourceCoordinate.longitude)&daddr=\(destinationCoordinate.latitude),\(destinationCoordinate.longitude)&directionsmode=\(transportType)"
            if let googleURL = URL(string:"\(URLs.Google)?\(googleParameters)"){
                UIApplication.shared.open(googleURL, options:[ : ], completionHandler: nil)
            } else {
                NSLog("\(#function) Can't configure the URL");
            }
        } else {
            NSLog("\(#function) Can't use \(URLs.Google)");
        }
    }
    
    static func hasGoogleMap() -> Bool {
        return UIApplication.shared.canOpenURL(URL(string:URLs.Google)!)
    }
    
    
    static func startHereMap(_ sourceCoordinate:CLLocationCoordinate2D, destinationCoordinate:CLLocationCoordinate2D, transportType:String) {
        if RouteUtilities.hasHereMap {
            let hereParameters = "\(sourceCoordinate.latitude),\(sourceCoordinate.longitude),Start/\(destinationCoordinate.latitude),\(destinationCoordinate.longitude),End?ref=AnyPOI&m=\(transportType)"
            if let hereURL = URL(string:"\(URLs.HereRoute)\(hereParameters)"){
                UIApplication.shared.open(hereURL, options:[ : ], completionHandler: nil)
            } else {
                NSLog("\(#function) Can't configure the URL");
            }
        } else {
            NSLog("\(#function) Can't use \(URLs.HereRoute)");
        }
    }
    
    static var hasHereMap:Bool {
        return UIApplication.shared.canOpenURL(URL(string:URLs.HereRoute)!)
    }

    static func startWaze(_ sourceCoordinate:CLLocationCoordinate2D, destinationCoordinate:CLLocationCoordinate2D) {
        if RouteUtilities.hasWaze() {
            let wazeParameters = "ll=\(destinationCoordinate.latitude),\(destinationCoordinate.longitude)&navigate=yes"
            if let wazeURL = URL(string:"\(URLs.Waze)?\(wazeParameters)"){
                UIApplication.shared.open(wazeURL, options:[ : ], completionHandler: nil)
            } else {
                NSLog("\(#function) Can't configure the URL");
            }
        } else {
            NSLog("\(#function) Can't use \(URLs.Waze)");
        }
    }
    
    static func hasWaze() -> Bool {
        return UIApplication.shared.canOpenURL(URL(string:URLs.Waze)!)
    }
    
    static func startCityMapper(_ sourceCoordinate:CLLocationCoordinate2D, destinationCoordinate:CLLocationCoordinate2D) {
        if RouteUtilities.hasCityMapper() {
            let cityMapperParameters = "startcoord=\(sourceCoordinate.latitude),\(sourceCoordinate.longitude)&endcoord=\(destinationCoordinate.latitude),\(destinationCoordinate.longitude)"
            if let cityMapperURL = URL(string: "\(URLs.CityMapper)directions?\(cityMapperParameters)") {
                UIApplication.shared.open(cityMapperURL, options:[ : ], completionHandler: nil)
            } else {
                NSLog("\(#function) Can't configure the URL");
            }
        } else {
            NSLog("\(#function) Can't use \(URLs.CityMapper)");
        }
        
    }
    
    static func hasCityMapper() -> Bool {
        return UIApplication.shared.canOpenURL(URL(string:URLs.CityMapper)!)
    }
    

}
