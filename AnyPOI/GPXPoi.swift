//
//  GPXPoi.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 30/11/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import MapKit
import Contacts

class GPXPoi {
    var wptAttributes:[String : String]? = nil
    var poiAttributes:[String : String]? = nil
    var groupAttributes:[String : String]? = nil
    var regionMonitoringAttributes:[String : String]? = nil
    var poiDescription = ""
    var poiLink = ""
    var poiName = ""
    var poiSym = ""
    
    var poiCategory:CategoryUtils.Category {
        get {
            if let poiAttr = poiAttributes, poiAttr.count > 0 {
                if let categoryString = poiAttr[GPXParser.poiCategoryIdAttr],
                    let groupCategoryString = poiAttr[GPXParser.poiGroupIdAttr],
                    let categoryId = Int16(categoryString),
                    let groupCategoryId = Int16(groupCategoryString){
                    
                    if let category = CategoryUtils.findCategory(groupCategory:groupCategoryId,
                                                                 categoryId:categoryId,
                                                                 inCategories: CategoryUtils.localSearchCategories) {
                        return category
                    }
                }
            }
            
            return CategoryUtils.defaultGroupCategory
            
        }
    }
    
    var poiCoordinates:CLLocationCoordinate2D? {
        get {
            if let wptAttr = wptAttributes,
                let latitudeString = wptAttr[GPXParser.wptLatitudeAttr],
                let longitudeString = wptAttr[GPXParser.wptLongitudeAttr],
                let latitude = Double(latitudeString), let longitude = Double(longitudeString) {
                
                return CLLocationCoordinate2DMake(latitude, longitude)
            }
            return nil
        }
    }
    
    var poiIsContact: Bool {
        get {
            if let poiAttr = poiAttributes,
                let isContactString = poiAttr[GPXParser.poiIsContactAttr],
                let isContact = Bool(isContactString) {
                return isContact
            } else {
                return false
            }
            
        }
    }
    
    var poiContactId:String? {
        get {
            if let poiAttr = poiAttributes,
                let contactIdString = poiAttr[GPXParser.poiContactIdAttr] {
                if ContactsUtilities.isContactExist(contactIdentifier: contactIdString) {
                    return contactIdString
                }
            }
            return nil
            
        }
    }
    
    var poiAddress:String? {
        get {
            if let poiAttr = poiAttributes {
                return poiAttr[GPXParser.poiAddressAttr]
            } else {
                return nil
            }
        }
    }
    
    var isPoiAlreadyExist:Bool {
        get {
            if let url = poiURL,
                let coordinates = poiCoordinates,
                !poiName.isEmpty {
                if let _ = POIDataManager.sharedInstance.findPOI(url:url, poiName: poiName, coordinates: coordinates) {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        }
    }
    
    fileprivate var poiURL:URL? {
        get {
            if let poiAttr = poiAttributes, let urlString = poiAttr[GPXParser.poiInternalUrlAttr] {
                return URL(string: urlString)
            } else {
                return nil
            }
        }
    }
    

    
    fileprivate var groupURL:URL? {
        get {
            if let groupAttr = groupAttributes, let urlString = groupAttr[GPXParser.groupInternalUrlAttr] {
                return URL(string: urlString)
            } else {
                return nil
            }
        }
        
    }
    
    fileprivate var isPoiFromAnyPoi:Bool {
        get {
            if let poiAttr = poiAttributes, poiAttr.count > 0 {
                return true
            } else {
                return false
            }
        }
    }
    
    
    func importIt(options:GPXImportOptions) -> PointOfInterest? {
        return isPoiFromAnyPoi ? restorePoi(options:options) : importPoi(options:options)
    }
    
    
    /// Import a GPXPoi that has been exported by AnyPoi
    ///
    /// - Parameter options: import options configured by the user
    fileprivate func restorePoi(options:GPXImportOptions) -> PointOfInterest? {
        if let poiAttr = poiAttributes, let wptAttr = wptAttributes, poiAttr.count > 0, wptAttr.count > 0,
            !poiName.isEmpty,
            let url = poiURL,
            let coordinate = poiCoordinates {
            
            var restorePoi:PointOfInterest!
            if !options.poiOptions.importAsNew {
                if let poi = POIDataManager.sharedInstance.findPOI(url: url, poiName: poiName, coordinates: coordinate) {
                    if options.poiOptions.importUpdate {
                        // update the existing poi
                        restorePoi = poi
                        
                        // If it's already monitored, we stop it and it will be restarted if needed
                        restorePoi.stopMonitoring()
                    }
                } else if options.poiOptions.importNew {
                    // create a new Poi
                    restorePoi = POIDataManager.sharedInstance.getEmptyPoi()
                    restorePoi.importWith(coordinates: coordinate)
                }
            } else {
                // create a new Poi
                restorePoi = POIDataManager.sharedInstance.getEmptyPoi()
                restorePoi.importWith(coordinates: coordinate)
            }
            
            // Group may have changed, even if the POI was already existing in the database
            restorePoi.parentGroup = getGroup()

            // Set POI mandatory parameters with imported values
            restorePoi.category = poiCategory
            restorePoi.poiIsContact = poiIsContact
            restorePoi.poiContactIdentifier = poiContactId
            restorePoi.poiAddress = poiAddress
            restorePoi.poiDisplayName = poiName
            restorePoi.poiDescription = poiDescription
            
            
            // Set POI optional parameters with imported values
            if let city = poiAttr[GPXParser.poiCityAttr] {
                restorePoi.poiCity = city
            }
            
            if let ISOCountryCode = poiAttr[GPXParser.poiISOCountryCodeAttr] {
                restorePoi.poiISOCountryCode = ISOCountryCode
            }
            
            if let phoneNumber = poiAttr[GPXParser.poiPhoneNumberAttr] {
                restorePoi.poiPhoneNumber = phoneNumber
            }
            
            if let wikipediaIdString = poiAttr[GPXParser.poiWikipediaIdAttr],
                let wikipediaId = Int64(wikipediaIdString) {
                restorePoi.poiWikipediaPageId = wikipediaId
            }
            
            // Configure the Region monitoring of the imported POI
            configureRegionMonitoring(poi: restorePoi)
            
            POIDataManager.sharedInstance.commitDatabase()
            
            return restorePoi
        } else {
            print("\(#function) Poi is ignored because some mandatory data are missing")
            return nil
        }
    }
    
    
    /// Configure the Region Monitoring for the given POI with the imported data
    ///
    /// - Parameter poi: Poi related to the GPXPoi that must be configured for region monitoring
    fileprivate func configureRegionMonitoring(poi:PointOfInterest) {
        if let regionMonitoringAttr = regionMonitoringAttributes, regionMonitoringAttr.count > 0 {
            
            // Get parameters from imported values (notifyEnter, notifyExit and radius) and update the POI
            var notifyEnter = false
            if let notifyEnterString = regionMonitoringAttr[GPXParser.regionMonitoringNotifyEnterAttr],
                let notifyEnterBool = Bool(notifyEnterString) {
                notifyEnter = notifyEnterBool
            }
            
            var notifyExit = false
            if let notifyExitString = regionMonitoringAttr[GPXParser.regionMonitoringNotifyExitAttr],
                let notifyExitBool = Bool(notifyExitString) {
                notifyExit = notifyExitBool
            }
            
            if let radiusString = regionMonitoringAttr[GPXParser.regionMonitoringRadiusAttr],
                let radius = Double(radiusString) {
                poi.poiRegionRadius = radius
            }
            
            // enable the monitoring if at least the notifyExit or notifyEnter are enabled
            if notifyExit || notifyEnter {
                let result = poi.startMonitoring(radius: poi.poiRegionRadius, notifyEnterRegion: notifyEnter, notifyExitRegion: notifyExit)
                switch result {
                case .deviceNotSupported:
                    print("\(#function) Device doesn't suppport region monitoring")
                case .internalError:
                    print("\(#function) internal error")
                case .maxMonitoredRegionAlreadyReached:
                    print("\(#function) max monitored region already reached")
                case .noError:
                    print("\(#function) poi monitoring started for \(poi.poiDisplayName!)")
                }
            }
        }
    }
    
    
    
    /// Get a group for the GPXPoi
    ///  1) Look if the Group already exists, if it exists it's updated with the imported values
    ///  2) If the Group doesn't exist then it's created with the imported values
    ///  3) If the group doesn't exist and some values are missing in the imported values then the default Group is used
    ///
    /// - Returns: the Group in which the POI should be added
    fileprivate func getGroup() -> GroupOfInterest {
        if let attributes = groupAttributes, attributes.count > 0 {
            if let groupIdString = attributes[GPXParser.groupGroupIdAttr],
                let url = poiURL,
                let groupId = Int64(groupIdString),
                let groupName = attributes[GPXParser.groupNameAttr],
                let groupDescription = attributes[GPXParser.groupDescriptionAttr],
                let isDisplayedString = attributes[GPXParser.groupIsDisplayedAttr],
                let isDisplayed = Bool(isDisplayedString) {
                
             
                if let group = POIDataManager.sharedInstance.findGroup(url: url, groupId: Int(groupId), groupName: groupName) {
                    // The group already exists in Database, we update it with the imported values
                    var isGroupUpdated = false
                    if group.groupDisplayName != groupName {
                        group.groupDisplayName = groupName
                        isGroupUpdated = true
                    }
                    
                    if group.groupDescription != groupDescription {
                        group.groupDescription = groupDescription
                        isGroupUpdated = true
                    }
                    
                    if group.isGroupDisplayed != isDisplayed {
                        group.isGroupDisplayed = isDisplayed
                        isGroupUpdated = true
                    }
                    
                    
                    if let groupColorString = attributes[GPXParser.groupColorAttr],
                        let newColor = ColorsUtils.getColor(rgba: groupColorString){
                        // Compare color description because doesn't really work when comparing 2 UIColors (if not default colors)
                        if newColor.description != group.color.description {
                            group.color = newColor
                            isGroupUpdated = true
                        }
                    }
                    
                    if isGroupUpdated {
                        POIDataManager.sharedInstance.updatePOIGroup(group)
                        POIDataManager.sharedInstance.commitDatabase()
                    }
                   return group
                } else  {
                    // The group doesn't exist, we create a new one with the imported values
                    var groupColor = ColorsUtils.importedGroupColor
                    if let groupColorString = attributes[GPXParser.groupColorAttr],
                        let newColor = ColorsUtils.getColor(rgba: groupColorString){
                        groupColor = newColor
                    }
                    return POIDataManager.sharedInstance.addGroup(groupName: groupName,
                                                                  groupDescription: groupDescription,
                                                                  groupColor: groupColor,
                                                                  isDisplayed: isDisplayed)
                }
            }
        }
        
        // When the group doesn't already exist and some values are missing in the imported values 
        // the default group is returned. Warning, it should never happend (except if the GPX file is corrupted)
        return POIDataManager.sharedInstance.getDefaultGroup()
    }
    
    ///FIXEDME: To be completed
    fileprivate func importPoi(options:GPXImportOptions) -> PointOfInterest? {
        if let wptAttr = wptAttributes, wptAttr.count > 0, !poiName.isEmpty {
            // check mandatory parameters to create a POI
            if let coordinate = poiCoordinates {
                
                let importPoi = POIDataManager.sharedInstance.getEmptyPoi()
                importPoi.importWith(coordinates: coordinate)
                
                importPoi.poiDisplayName = poiName
                importPoi.poiDescription = poiDescription
                
                POIDataManager.sharedInstance.commitDatabase()
                return importPoi
            }
        }
        print("\(#function) Poi is ignored because some mandatory data are missing")
        return nil
    }
}
