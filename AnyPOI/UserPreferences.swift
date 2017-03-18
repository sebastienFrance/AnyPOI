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
    
    fileprivate struct keys {
        static let MapMode = "MapMode"
        static let MapShowTraffic = "MapShowTraffic"
        static let MapShowPointsOfInterest = "MapShowPointsOfInterest"
        static let Flyover360Enabled = "Flyover360Enabled"
    
    
        static let MapLatestLatitude = "MapLatestLatitude"
        static let MapLatestLongitude = "MapLatestLongitude"
        static let MapLatestSpanLatitude = "MapLatestSpanLatitude"
        static let MapLatestSpanLongitude = "MapLatestSpanLongitude"

        static let WikipediaNearByDistance = "WikipediaNearByDistance"
        static let WikipediaMaxResults = "WikipediaMaxResults"
        static let WikipediaLanguageISOcode = "WikipediaLanguageISOcode"
        
        static let RouteDefaultTransportType = "RouteDefaultTransportType"

        static let AuthenticationTouchIdEnabled = "AuthenticationTouchIdEnabled"
        static let AuthenticationPasswordEnabled = "AuthenticationPasswordEnabled"
        static let AuthenticationPassword = "AuthenticationPassword"
        
        static let AnyPoiUnlimited = "AnyPoiUnlimited"
        static let firstStartup = "firstStartup"
        
        static let TestParameter = "Test"
    }
    
    fileprivate let defaultCamera = MKMapCamera(lookingAtCenter: CLLocationCoordinate2DMake(0.0, 0.0), fromDistance: 38814229, pitch:0, heading: 0)
    fileprivate let defaultRegion = MKCoordinateRegion(center: CLLocationCoordinate2DMake(0.0, 0.0), span: MKCoordinateSpanMake(1.0, 1.0))
    fileprivate let defaultMapCoordinate = CLLocationCoordinate2DMake(0.0, 0.0)
    
    init() {
        if UserDefaults.standard.string(forKey: keys.TestParameter) == nil {
            let userDefaults = UserDefaults.standard
            
            userDefaults.setValue("test", forKey: keys.TestParameter)
            
            isFirstStartup = true
            isAnyPoiUnlimited = false
            
            mapMode = .standard
            mapShowTraffic = true
            flyover360Enabled = true
            mapShowPointsOfInterest = false
            
            mapLatestMapRegion = defaultRegion
            
            wikipediaNearByDistance = 10000
            wikipediaMaxResults = 10
            
            wikipediaLanguageISOcode = getDefaultWikipediaLanguageISOcode()
            routeDefaultTransportType = .automobile

            authenticationPasswordEnabled = false
            authenticationTouchIdEnabled = false
            authenticationPassword = ""
        }
    }
    
    fileprivate func getDefaultWikipediaLanguageISOcode() -> String {
        if let localLanguageCode = (Locale.current as NSLocale).object(forKey: NSLocale.Key.languageCode) as? String {
            if WikipediaLanguages.hasISOCodeLanguage(localLanguageCode) {
                return localLanguageCode
            }
        }
        return WikipediaLanguages.defaultWikipediaLanguageISOcode
    }
    
    var mapMode:MKMapType {
        get {
            let mapModeValue = UInt(UserDefaults.standard.integer(forKey: keys.MapMode))
            return MKMapType(rawValue: mapModeValue)!
        }
        set {
            UserDefaults.standard.set(Int(newValue.rawValue), forKey: keys.MapMode)
        }
    }
    
    var flyover360Enabled:Bool {
        get {
            return UserDefaults.standard.bool(forKey: keys.Flyover360Enabled)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keys.Flyover360Enabled)
        }
    }
    
    var isAnyPoiUnlimited:Bool {
        get {
            //return true
            return UserDefaults.standard.bool(forKey: keys.AnyPoiUnlimited)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keys.AnyPoiUnlimited)
        }
    }
    
    var isFirstStartup:Bool {
        get {
            return UserDefaults.standard.bool(forKey: keys.firstStartup)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keys.firstStartup)
        }
    }

    

    var mapShowPointsOfInterest: Bool {
        get {
            return UserDefaults.standard.bool(forKey: keys.MapShowPointsOfInterest)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keys.MapShowPointsOfInterest)
        }
    }

    var mapShowTraffic: Bool {
        get {
            return UserDefaults.standard.bool(forKey: keys.MapShowTraffic)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keys.MapShowTraffic)
        }
    }
    
    var mapLatestMapRegion : MKCoordinateRegion {
        get {
            let mapLatitude = UserDefaults.standard.double(forKey: keys.MapLatestLatitude)
            let mapLongitude = UserDefaults.standard.double(forKey: keys.MapLatestLongitude)
            let mapSpanLatitude = UserDefaults.standard.double(forKey: keys.MapLatestSpanLatitude)
            let mapSpanLongitude = UserDefaults.standard.double(forKey: keys.MapLatestSpanLongitude)

            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: mapLatitude, longitude: mapLongitude),
                                      span: MKCoordinateSpanMake(mapSpanLatitude, mapSpanLongitude))
        }
        set {
            UserDefaults.standard.set(newValue.center.latitude, forKey: keys.MapLatestLatitude)
            UserDefaults.standard.set(newValue.center.longitude, forKey: keys.MapLatestLongitude)
            UserDefaults.standard.set(newValue.span.latitudeDelta, forKey: keys.MapLatestSpanLatitude)
            UserDefaults.standard.set(newValue.span.longitudeDelta, forKey: keys.MapLatestSpanLongitude)
        }
    }

    
    var wikipediaNearByDistance: Int {
        get {
            return UserDefaults.standard.integer(forKey: keys.WikipediaNearByDistance)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keys.WikipediaNearByDistance)
        }
    }
    
    var wikipediaMaxResults: Int {
        get {
            return UserDefaults.standard.integer(forKey: keys.WikipediaMaxResults)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keys.WikipediaMaxResults)
        }
    }
    
    var wikipediaLanguageISOcode: String {
        get {
            if let defautLanguageISOCode = UserDefaults.standard.object(forKey: keys.WikipediaLanguageISOcode) as? String {
                return defautLanguageISOCode
            } else {
                let defaultLanguageISOcode = getDefaultWikipediaLanguageISOcode()
                self.wikipediaLanguageISOcode = defaultLanguageISOcode
                return defaultLanguageISOcode
            }
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: keys.WikipediaLanguageISOcode)
        }
    }

    
    var routeDefaultTransportType: MKDirectionsTransportType {
        get {
            let value = UserDefaults.standard.integer(forKey: keys.RouteDefaultTransportType)
            return MKDirectionsTransportType(rawValue:UInt(value))
        }
        set {
            UserDefaults.standard.set(Int(newValue.rawValue), forKey: keys.RouteDefaultTransportType)
        }
    }

    var authenticationPasswordEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: keys.AuthenticationPasswordEnabled)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keys.AuthenticationPasswordEnabled)
        }
    }

    var authenticationTouchIdEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: keys.AuthenticationTouchIdEnabled)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keys.AuthenticationTouchIdEnabled)
        }
    }
    
    var authenticationPassword: String {
        get {
            return UserDefaults.standard.object(forKey: keys.AuthenticationPassword) as! String
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey:keys.AuthenticationPassword)
        }
    }



}
