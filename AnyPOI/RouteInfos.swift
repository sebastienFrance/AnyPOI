//
//  RouteInfos.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 12/10/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import MapKit

class RouteInfos : NSCoding {
    var polyline: MKPolyline?
    var name: String
    var distance: CLLocationDistance
    var expectedTravelTime: TimeInterval
    var transportType: MKDirectionsTransportType
    
    fileprivate struct Keys {
        static let Polyline = "RouteInfosPolyLine"
        static let Name = "RouteInfosName"
        static let Distance = "RouteInfosDistance"
        static let ExpectedTravelTime = "RouteInfosExpectedTravelTime"
        static let TransportType = "RouteInfosTransportType"
    }
    
    fileprivate struct TransportTypeInt {
        static let Automobile = 0
        static let Transit = 10
        static let Walking = 20
        static let AnyTransport = 30
    }
    
    @objc required init?(coder aDecoder: NSCoder) {
        
        let polyLineObject = aDecoder.decodeObject(forKey: Keys.Polyline) as? NSObject
        if let object = polyLineObject {
            polyline = RouteInfos.polylineUnarchive(object)
        }
        
        name = aDecoder.decodeObject(forKey: Keys.Name) as! String
        distance = aDecoder.decodeDouble(forKey: Keys.Distance)
        expectedTravelTime = aDecoder.decodeDouble(forKey: Keys.ExpectedTravelTime)
        let transportTypeInt = aDecoder.decodeInteger(forKey: Keys.TransportType)
        switch transportTypeInt {
        case TransportTypeInt.Automobile:
            transportType = .automobile
        case TransportTypeInt.Transit:
            transportType = .transit
        case TransportTypeInt.Walking:
            transportType = .walking
        case TransportTypeInt.AnyTransport:
            transportType = .any
        default:
            transportType = .automobile
        }
        
    }
    
    @objc func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: Keys.Name)
        aCoder.encode(distance, forKey: Keys.Distance)
        aCoder.encode(expectedTravelTime, forKey: Keys.ExpectedTravelTime)
        var transportTypeInt = TransportTypeInt.Automobile
        switch transportType {
        case MKDirectionsTransportType.automobile:
            transportTypeInt = TransportTypeInt.Automobile
        case MKDirectionsTransportType.transit:
            transportTypeInt = TransportTypeInt.Transit
        case MKDirectionsTransportType.walking:
            transportTypeInt = TransportTypeInt.Walking
        case MKDirectionsTransportType.any:
            transportTypeInt = TransportTypeInt.AnyTransport
        default:
            transportTypeInt = TransportTypeInt.Automobile
        }
        
        aCoder.encode(transportTypeInt, forKey: Keys.TransportType)
        
//        var coords: [CLLocationCoordinate2D] = []
//        coords.reserveCapacity(polyline.pointCount)
//        polyline.getCoordinates(&coords, range: NSMakeRange(0, polyline.pointCount))
        
        let polyLineData = RouteInfos.polylineToArchive(polyline!)
        aCoder.encode(polyLineData, forKey: Keys.Polyline)
    }
    
//    func polylineUnarchive(polylineArchive: NSData) -> MKPolyline? {
//        guard let data = NSKeyedUnarchiver.unarchiveObjectWithData(polylineArchive),
//            let polyline = data as? [Dictionary<String, AnyObject>] else {
//                return nil
//        }
//        var locations: [CLLocation] = []
//        for item in polyline {
//            if let latitude = item["latitude"]?.doubleValue,
//                let longitude = item["longitude"]?.doubleValue {
//                let location = CLLocation(latitude: latitude, longitude: longitude)
//                locations.append(location)
//            }
//        }
//        var coordinates = locations.map({(location: CLLocation) -> CLLocationCoordinate2D in return location.coordinate})
//        let result = MKPolyline(coordinates: &coordinates, count: locations.count)
//        return result
//    }
    
    fileprivate static func polylineUnarchive(_ polylineArchive: NSObject) -> MKPolyline? {
        guard let polyline = polylineArchive as? [Dictionary<String, AnyObject>] else {
                return nil
        }
        var locations: [CLLocation] = []
        for item in polyline {
            if let latitude = item["latitude"]?.doubleValue,
                let longitude = item["longitude"]?.doubleValue {
                let location = CLLocation(latitude: latitude, longitude: longitude)
                locations.append(location)
            }
        }
        var coordinates = locations.map({(location: CLLocation) -> CLLocationCoordinate2D in return location.coordinate})
        let result = MKPolyline(coordinates: &coordinates, count: locations.count)
        return result
    }

    
//    func polylineToArchive(polyline: MKPolyline) -> NSData {
//        let coordsPointer = UnsafeMutablePointer<CLLocationCoordinate2D>.alloc(polyline.pointCount)
//        polyline.getCoordinates(coordsPointer, range: NSMakeRange(0, polyline.pointCount))
//        var coords: [Dictionary<String, AnyObject>] = []
//        for i in 0..<polyline.pointCount {
//            let latitude = NSNumber(double: coordsPointer[i].latitude)
//            let longitude = NSNumber(double: coordsPointer[i].longitude)
//            let coord = ["latitude" : latitude, "longitude" : longitude]
//            coords.append(coord)
//        }
//        let polylineData = NSKeyedArchiver.archivedDataWithRootObject(coords)
//        return polylineData
//    }
    
    fileprivate static func polylineToArchive(_ polyline: MKPolyline) -> [Dictionary<String, AnyObject>] {
        //SEB : Swift3 to be checked
        let coordsPointer = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: polyline.pointCount)
//        let coordsPointer = UnsafeMutablePointer<CLLocationCoordinate2D>(allocatingCapacity: polyline.pointCount)
        polyline.getCoordinates(coordsPointer, range: NSMakeRange(0, polyline.pointCount))
        var coords: [Dictionary<String, AnyObject>] = []
        for i in 0..<polyline.pointCount {
            let latitude = NSNumber(value: coordsPointer[i].latitude as Double)
            let longitude = NSNumber(value: coordsPointer[i].longitude as Double)
            let coord = ["latitude" : latitude, "longitude" : longitude]
            coords.append(coord)
        }
        return coords
    }

}

