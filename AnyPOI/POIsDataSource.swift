//
//  POIsDataSource.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 19/09/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import Foundation

class POIsDataSource {
    

    // Datasource cache
    private var pois:[PointOfInterest]? = nil
    private var poisWithFilters:[PointOfInterest]? = nil

    fileprivate(set) var poisDescription = ""
    private(set) var searchFilter = "" // Use to perform filtering on list of groups
    
    init() {
    }
    
    func reset() {
        pois = nil // Reset the data
        poisWithFilters = nil
    }
    
    func update(filter:String) {
        poisWithFilters = nil
        searchFilter = filter
    }
    
    //MARK: Utils
     func getPois(withFilter:Bool) -> [PointOfInterest] {
        if !withFilter {
            if pois == nil {
                pois = extractPOIsFromDatabase(withFilter:"")
            }
            return pois!
        } else {
            if poisWithFilters == nil {
                poisWithFilters = extractPOIsFromDatabase(withFilter:searchFilter)
            }
            return poisWithFilters!
        }
    }
    
     fileprivate func extractPOIsFromDatabase(withFilter:String) -> [PointOfInterest] {
        return []
    }

}

class POIsCityDataSource: POIsDataSource {
    
    private var city = ""
    
    init(cityName:String) {
        city = cityName
        super.init()
        poisDescription = cityName
    }
    
    override func extractPOIsFromDatabase(withFilter:String) -> [PointOfInterest] {
        return POIDataManager.sharedInstance.getAllPOIFromCity(city, searchFilter: withFilter)
     }
}

class POIsCountryDataSource: POIsDataSource {
    
    private var ISOCountryCode = ""

    init(country:CountryDescription) {
        ISOCountryCode = country.ISOCountryCode
        super.init()
        poisDescription = "\(country.countryFlag) \(country.countryName)"
    }
    
    
    override func extractPOIsFromDatabase(withFilter:String) -> [PointOfInterest] {
        return POIDataManager.sharedInstance.getAllPOIFromCountry(ISOCountryCode, searchFilter: withFilter)
    }
}

class POIsMonitoredDataSource: POIsDataSource {
    
    override init() {
        super.init()
        poisDescription = NSLocalizedString("MonitoredPOIs", comment: "")
    }
    
    
    override func extractPOIsFromDatabase(withFilter:String) -> [PointOfInterest] {
        return POIDataManager.sharedInstance.getAllMonitoredPOI(withFilter)
    }
}

class POIsNoAddressDataSource: POIsDataSource {
    
    override init() {
        super.init()
        poisDescription = "POIs without address"
    }
    
    
    override func extractPOIsFromDatabase(withFilter:String) -> [PointOfInterest] {
        return POIDataManager.sharedInstance.getPoisWithoutPlacemark(searchFilter: withFilter)
    }
}

class POIsGroupDataSource: POIsDataSource {
    
    fileprivate var POIGroup:GroupOfInterest

    init(group:GroupOfInterest) {
        POIGroup = group
        super.init()
        poisDescription = group.groupDisplayName!
    }
    
    
    override func extractPOIsFromDatabase(withFilter:String) -> [PointOfInterest] {
        return POIDataManager.sharedInstance.getPOIsFromGroup(POIGroup, searchFilter: withFilter)
    }
}

