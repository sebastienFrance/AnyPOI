//
//  GPXPoi.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 30/11/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import MapKit

class GPXPoi {
     var wptAttributes:[String : String]? = nil
     var poiAttributes:[String : String]? = nil
     var groupAttributes:[String : String]? = nil
     var regionMonitoringAttributes:[String : String]? = nil
     var poiDescription = ""
     var poiLink = ""
     var poiName = ""
     var poiSym = ""
    
    
    func importGPXPoi() {
        if poiAttributes != nil {
            restorePoi()
        } else {
            importPoi()
        }
    }
    
    fileprivate func restorePoi() {
        // let emptyPoi = POIDataManager.sharedInstance.getEmptyPoi()
        print("Create POI from restore")
        if let poiAttr = poiAttributes, let wptAttr = wptAttributes, poiAttr.count > 0, wptAttr.count > 0, !poiName.isEmpty {
            if let group = findGroup() {
                // check mandatory parameters to create a POI
                if let latitudeString = wptAttr[GPXParser.XSD.GPX.Elements.WPT.Attributes.latitude], let longitudeString = wptAttr[GPXParser.XSD.GPX.Elements.WPT.Attributes.longitude],
                    let latitude = Double(latitudeString), let longitude = Double(longitudeString),
                    let categoryString = poiAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.categoryId],
                    let groupCategoryString = poiAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.categoryId],
                    let categoryId = Int16(categoryString), let groupCategoryId = Int16(groupCategoryString){
                    
                    let emptyPoi = POIDataManager.sharedInstance.getEmptyPoi()
                    emptyPoi.initializeWith(coordinates: CLLocationCoordinate2DMake(latitude, longitude))
                    
                    if let category = CategoryUtils.findCategory(groupCategory:groupCategoryId, categoryId:categoryId, inCategories: CategoryUtils.localSearchCategories) {
                        emptyPoi.category = category
                    } else {
                        emptyPoi.category = CategoryUtils.defaultGroupCategory
                    }
                    
                    if let isContactString = poiAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.isContact],
                        let isContact = Bool(isContactString),
                        isContact {
                        emptyPoi.poiIsContact = true
                        if let contactIdString = poiAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.contactId] {
                            if ContactsUtilities.isContactExist(contactIdentifier: contactIdString) {
                                emptyPoi.poiContactIdentifier = contactIdString
                            }
                        }
                        
                        if let latestAddress = poiAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.contactLatestAddress] {
                            emptyPoi.poiContactLatestAddress = latestAddress
                        }
                    } else {
                        emptyPoi.poiIsContact = false
                    }
                    
                    if let city = poiAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.city] {
                        emptyPoi.poiCity = city
                    }
                    
                    if let ISOCountryCode = poiAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.ISOCountryCode] {
                        emptyPoi.poiISOCountryCode = ISOCountryCode
                    }
                    
                    if let phoneNumber = poiAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.phoneNumber] {
                        emptyPoi.poiPhoneNumber = phoneNumber
                    }
                    
                    if let wikipediaIdString = poiAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.wikipediaId],
                        let wikipediaId = Int64(wikipediaIdString) {
                        emptyPoi.poiWikipediaPageId = wikipediaId
                    }
                    
                    
                    emptyPoi.poiDisplayName = poiName
                    emptyPoi.poiDescription = poiDescription
                    
                    emptyPoi.parentGroup = group
                    
                    if let regionMonitoringAttr = regionMonitoringAttributes, regionMonitoringAttr.count > 0 {
                        
                        if let notifyEnterString = regionMonitoringAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.regionMonitoring.Attributes.notifyEnter],
                            let notifyEnter = Bool(notifyEnterString) {
                            emptyPoi.poiRegionNotifyEnter = notifyEnter
                        }
                        
                        if let notifyExitString = regionMonitoringAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.regionMonitoring.Attributes.notifyExit],
                            let notifyExit = Bool(notifyExitString) {
                            emptyPoi.poiRegionNotifyEnter = notifyExit
                        }
                        
                        if let radiusString = regionMonitoringAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.regionMonitoring.Attributes.regionRadius],
                            let radius = Double(radiusString) {
                            emptyPoi.poiRegionRadius = radius
                        }
                        
                        //FIXEDME: Most probably it's not required because the regionId will be different on imported device
                        //if let regionId = regionMonitoringAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.regionMonitoring.Attributes.regionId] {
                        // emptyPoi.poiRegionId = regionId
                        //}
                        
                    }
                    
                    
                    POIDataManager.sharedInstance.commitDatabase()
                }
            }
        } else {
            print("\(#function) Poi is ignored because some mandatory data are missing")
        }
    }
    
    fileprivate func findGroup() -> GroupOfInterest? {
        if let attributes = groupAttributes, attributes.count > 0 {
            if let groupIdString = attributes[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.group.Attributes.groupId],
                let groupId = Int(groupIdString)  {
                
                if let group = POIDataManager.sharedInstance.findGroup(groupId: groupId) {
                    //FIXEDME: Maybe the Group should be updated even if it already exists !
                    return group
                } else if let groupName = attributes[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.group.Attributes.name],
                    let groupDescription = attributes[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.group.Attributes.groupDescription],
                    let isDisplayedString = attributes[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.group.Attributes.isDisplayed],
                    let isDisplayed = Bool(isDisplayedString) {
                    
                    //FIXEDME: Color should be imported
                    return POIDataManager.sharedInstance.addGroup(groupId: groupId,
                                                                  groupName: groupName,
                                                                  groupDescription: groupDescription,
                                                                  groupColor: UIColor.blue,
                                                                  isDisplayed: isDisplayed)
                }
            }
        }
        
        return nil
    }
    
    fileprivate func importPoi() {
        print("Import a new POI")
        
    }
}