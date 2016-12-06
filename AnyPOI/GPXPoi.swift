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
                if let categoryString = poiAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.categoryId],
                    let groupCategoryString = poiAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.groupId],
                    let categoryId = Int16(categoryString),
                    let groupCategoryId = Int16(groupCategoryString){
                    
                    if let category = CategoryUtils.findCategory(groupCategory:groupCategoryId, categoryId:categoryId, inCategories: CategoryUtils.localSearchCategories) {
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
                let latitudeString = wptAttr[GPXParser.XSD.GPX.Elements.WPT.Attributes.latitude],
                let longitudeString = wptAttr[GPXParser.XSD.GPX.Elements.WPT.Attributes.longitude],
                let latitude = Double(latitudeString), let longitude = Double(longitudeString) {
                
                return CLLocationCoordinate2DMake(latitude, longitude)
            }
            return nil
        }
    }
    
    var poiIsContact: Bool {
        get {
            if let poiAttr = poiAttributes,
                let isContactString = poiAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.isContact],
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
                let contactIdString = poiAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.contactId] {
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
                return poiAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.address]
            } else {
                return nil
            }
        }
    }
    
    fileprivate var poiURL:URL? {
        get {
            if let poiAttr = poiAttributes, let urlString = poiAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.internalUrl] {
                return URL(string: urlString)
            } else {
                return nil
            }
        }
    }
    
    
    func importGPXPoi() {
        if poiAttributes != nil {
            restorePoi()
        } else {
            importPoi()
        }
    }
    
    fileprivate func restorePoi() {
        if let poiAttr = poiAttributes, let wptAttr = wptAttributes, poiAttr.count > 0, wptAttr.count > 0,
            !poiName.isEmpty,
            let url = poiURL,
            let group = findGroup(),
            let coordinate = poiCoordinates {
            
            var restorePoi:PointOfInterest!
            if let poi = POIDataManager.sharedInstance.getPOIWithURI(url), poi.poiDisplayName == poiName {
                print("\(#function) update an existing Poi")
                restorePoi = poi
                
                //FIXEDME: Warning if the updated POI is monitored and the imported is not
                // the old one will stay monitored!
            } else {
                print("\(#function) create a new Poi")
                restorePoi = POIDataManager.sharedInstance.getEmptyPoi()
            }
            
            restorePoi.importWith(coordinates: coordinate)
            
            restorePoi.category = poiCategory
            restorePoi.poiIsContact = poiIsContact
            restorePoi.poiContactIdentifier = poiContactId
            restorePoi.poiAddress = poiAddress
            restorePoi.poiDisplayName = poiName
            restorePoi.poiDescription = poiDescription
            restorePoi.parentGroup = group
            
            if let city = poiAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.city] {
                restorePoi.poiCity = city
            }
            
            if let ISOCountryCode = poiAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.ISOCountryCode] {
                restorePoi.poiISOCountryCode = ISOCountryCode
            }
            
            if let phoneNumber = poiAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.phoneNumber] {
                restorePoi.poiPhoneNumber = phoneNumber
            }
            
            if let wikipediaIdString = poiAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Attributes.wikipediaId],
                let wikipediaId = Int64(wikipediaIdString) {
                restorePoi.poiWikipediaPageId = wikipediaId
            }
            
            if let regionMonitoringAttr = regionMonitoringAttributes, regionMonitoringAttr.count > 0 {
                
                var notifyEnter = false
                if let notifyEnterString = regionMonitoringAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.regionMonitoring.Attributes.notifyEnter], let notifyEnterBool = Bool(notifyEnterString) {
                    notifyEnter = notifyEnterBool
                }
                
                var notifyExit = false
                if let notifyExitString = regionMonitoringAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.regionMonitoring.Attributes.notifyExit],
                    let notifyExitBool = Bool(notifyExitString) {
                    notifyExit = notifyExitBool
                }
                
                if let radiusString = regionMonitoringAttr[GPXParser.XSD.GPX.Elements.WPT.Elements.customExtension.Elements.poi.Elements.regionMonitoring.Attributes.regionRadius],
                    let radius = Double(radiusString) {
                    restorePoi.poiRegionRadius = radius
                }
                
                if notifyExit || notifyEnter {
                    let result = restorePoi.startMonitoring(radius: restorePoi.poiRegionRadius, notifyEnterRegion: notifyEnter, notifyExitRegion: notifyExit)
                    switch result {
                    case .deviceNotSupported:
                        print("\(#function) Device doesn't suppport region monitoring")
                    case .internalError:
                        print("\(#function) internal error")
                    case .maxMonitoredRegionAlreadyReached:
                        print("\(#function) max monitored region already reached")
                    case .noError:
                        print("\(#function) poi monitoring started for \(restorePoi.poiDisplayName!)")
                    }
                }
            }
            
            
            POIDataManager.sharedInstance.commitDatabase()
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
        if let wptAttr = wptAttributes, wptAttr.count > 0, !poiName.isEmpty {
            // check mandatory parameters to create a POI
            if let coordinate = poiCoordinates {
                
                let importPoi = POIDataManager.sharedInstance.getEmptyPoi()
                importPoi.importWith(coordinates: coordinate)
                
                importPoi.poiDisplayName = poiName
                importPoi.poiDescription = poiDescription
                
                POIDataManager.sharedInstance.commitDatabase()
            }
        } else {
            print("\(#function) Poi is ignored because some mandatory data are missing")
        }
    }
}
