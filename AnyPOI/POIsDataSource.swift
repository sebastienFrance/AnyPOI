//
//  POIsDataSource.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 19/09/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import Foundation

class POIsDataSource {
    
    private enum DisplayMode {
        case simpleGroup, monitoredPois, cityPois, countryPois, poisWithoutAddress
    }
    
    private var displayMode = DisplayMode.simpleGroup
    private var displayModeFilter = ""
    var areaName = ""
    private var POIGroup:GroupOfInterest!

    // Datasource
     var pois:[PointOfInterest]? = nil
     var poisWithFilters:[PointOfInterest]? = nil

     var searchFilter = "" // Use to perform filtering on list of groups
    
    init() {
    }
    
    func showCityPoi(_ cityName: String) {
        displayMode = .cityPois
        displayModeFilter = cityName
        areaName = cityName
    }
    
    func showCountryPoi(country:CountryDescription) {
        displayMode = .countryPois
        displayModeFilter = country.ISOCountryCode
        areaName = "\(country.countryFlag) \(country.countryName)"
    }
    
    func showMonitoredPois() {
        displayMode = .monitoredPois
        areaName = NSLocalizedString("MonitoredPOIs", comment: "")
    }
    
    func showPoisWithoutAddress() {
        displayMode = .poisWithoutAddress
        areaName = "POIs without address"
    }
    
    func showGroup(_ group:GroupOfInterest) {
        POIGroup = group
        displayMode = .simpleGroup
        areaName = group.groupDisplayName!
    }
    
    func resetPOIs() {
        pois = nil // Reset the data
        poisWithFilters = nil
    }
    
    func resetPOisWithFilter(filter:String) {
        poisWithFilters = nil
        searchFilter = filter
    }
    
    //MARK: Utils
     func getPois(withFilter:Bool) -> [PointOfInterest] {
        if !withFilter {
            if pois == nil {
                pois = extractPOIsFromDatabase(withFilter:false)
            }
            return pois!
        } else {
            if poisWithFilters == nil {
                poisWithFilters = extractPOIsFromDatabase(withFilter:true)
            }
            return poisWithFilters!
        }
    }
    
     private func extractPOIsFromDatabase(withFilter:Bool) -> [PointOfInterest] {
        let filter = withFilter ? searchFilter : ""
        switch displayMode {
        case .monitoredPois:
            return POIDataManager.sharedInstance.getAllMonitoredPOI(filter)
        case .simpleGroup:
            return POIDataManager.sharedInstance.getPOIsFromGroup(POIGroup, searchFilter: filter)
        case .cityPois:
            return POIDataManager.sharedInstance.getAllPOIFromCity(displayModeFilter, searchFilter: filter)
        case .countryPois:
            return POIDataManager.sharedInstance.getAllPOIFromCountry(displayModeFilter, searchFilter: filter)
        case .poisWithoutAddress:
            return POIDataManager.sharedInstance.getPoisWithoutPlacemark(searchFilter: filter)
        }
    }

}
