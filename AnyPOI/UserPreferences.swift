//
//  UserPreferences.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 06/01/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation

import MapKit


class UserPreferences {
    
    class var sharedInstance: UserPreferences {
        struct Singleton {
            static let instance = UserPreferences()
        }
        return Singleton.instance
    }
    
    private struct keys {
        static let MapMode = "MapMode"
        static let MapShowTraffic = "MapShowTraffic"
        static let MapShowPointsOfInterest = "MapShowPointsOfInterest"
    
    
        static let MapLatestLatitude = "MapLatestLatitude"
        static let MapLatestLongitude = "MapLatestLongitude"
        static let MapLatestSpanLatitude = "MapLatestSpanLatitude"
        static let MapLatestSpanLongitude = "MapLatestSpanLongitude"

        static let WikipediaNearByDistance = "WikipediaNearByDistance"
        static let WikipediaMaxResults = "WikipediaMaxResults"
        
        static let RouteDefaultTransportType = "RouteDefaultTransportType"

        static let AuthenticationTouchIdEnabled = "AuthenticationTouchIdEnabled"
        static let AuthenticationPasswordEnabled = "AuthenticationPasswordEnabled"
        static let AuthenticationPassword = "AuthenticationPassword"
        
        static let TestParameter = "Test"
    }
    
    private let defaultCamera = MKMapCamera(lookingAtCenterCoordinate: CLLocationCoordinate2DMake(0.0, 0.0), fromDistance: 38814229, pitch:0, heading: 0)
    private let defaultRegion = MKCoordinateRegion(center: CLLocationCoordinate2DMake(0.0, 0.0), span: MKCoordinateSpanMake(1.0, 1.0))
    private let defaultMapCoordinate = CLLocationCoordinate2DMake(0.0, 0.0)
    
    init() {
        if NSUserDefaults.standardUserDefaults().stringForKey(keys.TestParameter) == nil {
            let userDefaults = NSUserDefaults.standardUserDefaults()
            
            userDefaults.setValue("test", forKey: keys.TestParameter)
            mapMode = .Standard
            mapShowTraffic = true
            mapShowPointsOfInterest = false
            
            mapLatestMapRegion = defaultRegion
            
            wikipediaNearByDistance = 10000
            wikipediaMaxResults = 10
            
            routeDefaultTransportType = .Automobile

            authenticationPasswordEnabled = false
            authenticationTouchIdEnabled = false
            authenticationPassword = ""
        }
    }
    
    var mapMode:MKMapType {
        get {
            let mapModeValue = UInt(NSUserDefaults.standardUserDefaults().integerForKey(keys.MapMode))
            return MKMapType(rawValue: mapModeValue)!
        }
        set {
            NSUserDefaults.standardUserDefaults().setInteger(Int(newValue.rawValue), forKey: keys.MapMode)
        }
    }
    

    var mapShowPointsOfInterest: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey(keys.MapShowPointsOfInterest)
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: keys.MapShowPointsOfInterest)
        }
    }

    var mapShowTraffic: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey(keys.MapShowTraffic)
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: keys.MapShowTraffic)
        }
    }
    
    var mapLatestMapRegion : MKCoordinateRegion {
        get {
            let mapLatitude = NSUserDefaults.standardUserDefaults().doubleForKey(keys.MapLatestLatitude)
            let mapLongitude = NSUserDefaults.standardUserDefaults().doubleForKey(keys.MapLatestLongitude)
            let mapSpanLatitude = NSUserDefaults.standardUserDefaults().doubleForKey(keys.MapLatestSpanLatitude)
            let mapSpanLongitude = NSUserDefaults.standardUserDefaults().doubleForKey(keys.MapLatestSpanLongitude)

            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: mapLatitude, longitude: mapLongitude),
                                      span: MKCoordinateSpanMake(mapSpanLatitude, mapSpanLongitude))
        }
        set {
            NSUserDefaults.standardUserDefaults().setDouble(newValue.center.latitude, forKey: keys.MapLatestLatitude)
            NSUserDefaults.standardUserDefaults().setDouble(newValue.center.longitude, forKey: keys.MapLatestLongitude)
            NSUserDefaults.standardUserDefaults().setDouble(newValue.span.latitudeDelta, forKey: keys.MapLatestSpanLatitude)
            NSUserDefaults.standardUserDefaults().setDouble(newValue.span.longitudeDelta, forKey: keys.MapLatestSpanLongitude)
        }
    }

    
    var wikipediaNearByDistance: Int {
        get {
            return NSUserDefaults.standardUserDefaults().integerForKey(keys.WikipediaNearByDistance)
        }
        set {
            NSUserDefaults.standardUserDefaults().setInteger(newValue, forKey: keys.WikipediaNearByDistance)
        }
    }
    
    var wikipediaMaxResults: Int {
        get {
            return NSUserDefaults.standardUserDefaults().integerForKey(keys.WikipediaMaxResults)
        }
        set {
            NSUserDefaults.standardUserDefaults().setInteger(newValue, forKey: keys.WikipediaMaxResults)
        }
    }
    
    var routeDefaultTransportType: MKDirectionsTransportType {
        get {
            let value = NSUserDefaults.standardUserDefaults().integerForKey(keys.RouteDefaultTransportType)
            return MKDirectionsTransportType(rawValue:UInt(value))
        }
        set {
            NSUserDefaults.standardUserDefaults().setInteger(Int(newValue.rawValue), forKey: keys.RouteDefaultTransportType)
        }
    }

    var authenticationPasswordEnabled: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey(keys.AuthenticationPasswordEnabled)
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: keys.AuthenticationPasswordEnabled)
        }
    }

    var authenticationTouchIdEnabled: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey(keys.AuthenticationTouchIdEnabled)
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: keys.AuthenticationTouchIdEnabled)
        }
    }
    
    var authenticationPassword: String {
        get {
            return NSUserDefaults.standardUserDefaults().objectForKey(keys.AuthenticationPassword) as! String
        }
        set {
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey:keys.AuthenticationPassword)
        }
    }



}
