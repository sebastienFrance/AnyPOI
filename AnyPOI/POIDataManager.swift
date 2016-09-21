//
//  POIDataManager.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 12/12/2015.
//  Copyright © 2015 Sébastien Brugalières. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MapKit
import Contacts

class POIDataManager {
    

    // Initialize the Singleton
    class var sharedInstance: POIDataManager {
        struct Singleton {
            static let instance = POIDataManager()
        }
        return Singleton.instance
    }

    // Name of entities
    private struct entitiesCste {
        static let groupOfInterest = "GroupOfInterest"
        static let pointOfInterest = "PointOfInterest"
        static let route = "Route"
        static let wayPoint = "WayPoint"
        static let monitoredRegion = "MonitoredRegion"
    }
    
    struct defaultGroupCste {
        static let groupId = 0
        static let displayName = NSLocalizedString("DefaultGroupName", comment: "")
        static let groupDescription = NSLocalizedString("DefaultGroupDescription", comment: "")
        static let groupColor = ColorsUtils.defaultGroupColor()
    }
    
    private struct defaultContactGroupCste {
        static let groupId = 1
        static let displayName = NSLocalizedString("ContactsGroupName", comment: "")
        static let groupDescription = NSLocalizedString("ContactsGroupDescription", comment: "")
        static let groupColor = ColorsUtils.contactsGroupColor()
    }

    // MARK: Default Groups
    func initDefaultGroups() {
        getDefaultGroup()
        getDefaultContactGroup()
    }
    
    func isMandatoryGroup(group:GroupOfInterest) -> Bool {
        return isDefaultGroup(group) || isDefaultContactGroup(group)
    }
    
    // get the defaul GroupOfInterest (if it doesn't exist, it's automatically created)
    func getDefaultGroup() -> GroupOfInterest! {
        if let defaultGroup = findGroup(groupId: defaultGroupCste.groupId) {
            return defaultGroup
        } else {
            return addGroup(groupId: defaultGroupCste.groupId, groupName: defaultGroupCste.displayName,
                            groupDescription: defaultGroupCste.groupDescription, groupColor: defaultGroupCste.groupColor)
        }
    }
    
    func isDefaultGroup(group:GroupOfInterest) -> Bool {
        let groupId = Int(group.groupId)
        if groupId == defaultGroupCste.groupId {
            return true
        } else {
            return false
        }
    }
    
    func getDefaultContactGroup() -> GroupOfInterest! {
        if let defaultGroup = findGroup(groupId: defaultContactGroupCste.groupId) {
            return defaultGroup
        } else {
            return addGroup(groupId: defaultContactGroupCste.groupId, groupName: defaultContactGroupCste.displayName,
                            groupDescription: defaultContactGroupCste.groupDescription, groupColor: defaultContactGroupCste.groupColor)
        }
    }

    func isDefaultContactGroup(group:GroupOfInterest) -> Bool {
        let groupId = Int(group.groupId)
        if groupId == defaultContactGroupCste.groupId {
            return true
        } else {
            return false
        }
    }
    
    
    //MARK: find Group
    func getGroups(searchFilter:String = "") -> [GroupOfInterest] {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: entitiesCste.groupOfInterest)
        
        if !searchFilter.isEmpty {
            fetchRequest.predicate = NSPredicate(format: "groupDisplayName CONTAINS[cd] %@", argumentArray: [searchFilter])
        }
        
        let sortDescriptor = NSSortDescriptor(key: "groupDisplayName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            let results = try managedContext.executeFetchRequest(fetchRequest)
            return results as! [GroupOfInterest]
        } catch let error as NSError {
            print("\(#function) GroupOfInterests could not be extracted from DB \(error), \(error.userInfo)")
            return [GroupOfInterest]()
        }
    }
    
    func findGroup(groupId groupId:Int) -> GroupOfInterest? {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: entitiesCste.groupOfInterest)
        fetchRequest.predicate = NSPredicate(format: "groupId = %@", argumentArray: [groupId])
        
        do {
            let matchingGroups = try managedContext.executeFetchRequest(fetchRequest)
            
            if matchingGroups.count >= 1 {
                return matchingGroups[0] as? GroupOfInterest
            } else {
                return nil
            }
            
        } catch let error as NSError {
            print("\(#function) GroupOfInterest could not be searched in DB \(error), \(error.userInfo)")
            return nil
        }
    }
    
    func findDisplayableGroups() -> [GroupOfInterest] {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: entitiesCste.groupOfInterest)
        fetchRequest.predicate = NSPredicate(format: "isGroupDisplayed = %@", argumentArray: [true])
        
        let sortDescriptor = NSSortDescriptor(key: "groupDisplayName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            let matchingGroups = try managedContext.executeFetchRequest(fetchRequest)
            return matchingGroups as! [GroupOfInterest]
        } catch let error as NSError {
            print("\(#function) DisplayableGroups could not be fetch \(error), \(error.userInfo)")
            return [GroupOfInterest]()
        }
        
    }
    
    func findGroups(searchText:String) -> [GroupOfInterest] {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: entitiesCste.groupOfInterest)
        if !searchText.isEmpty {
            fetchRequest.predicate = NSPredicate(format: "groupDisplayName BEGINSWITH[cd] %@", searchText)
        } else {
            fetchRequest.predicate = NSPredicate(format: "isGroupDisplayed == TRUE")
        }
        let sortDescriptor = NSSortDescriptor(key: "groupDisplayName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        
        do {
            let matchingGroup = try managedContext.executeFetchRequest(fetchRequest)
            return matchingGroup as! [GroupOfInterest]
        } catch let error as NSError {
            print("\(#function) could not be fetch \(error), \(error.userInfo)")
            return []
        }
    }

    // MARK: Group
    func addGroup(groupName groupName:String, groupDescription:String, groupColor:UIColor) -> GroupOfInterest {
        let groupId = Int(NSDate.timeIntervalSinceReferenceDate())
        return addGroup(groupId: groupId, groupName: groupName, groupDescription: groupDescription, groupColor: groupColor)
    }
    
    private func addGroup(groupId groupId: Int, groupName:String, groupDescription:String, groupColor:UIColor) -> GroupOfInterest {
        let group = getEmptyGroup()
        group.initializeWith(groupId, name: groupName, description: groupDescription, color: groupColor)
        return group
    }
    
    func getEmptyGroup() -> GroupOfInterest {
        
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let entity = NSEntityDescription.entityForName(entitiesCste.groupOfInterest, inManagedObjectContext:managedContext)
        return GroupOfInterest(entity: entity!, insertIntoManagedObjectContext: managedContext)
    }

    func deleteGroup(group group:GroupOfInterest) {
        

        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext

        managedContext.deleteObject(group)

        if let pois = group.listOfPOIs {
            for currentPOI in pois {
                managedContext.deleteObject(currentPOI as! NSManagedObject)
            }
        }
    }

    func updatePOIGroup(poiGroup: GroupOfInterest) {
    }
    

    func isUserAuthenticated() -> Bool {
        return UserAuthentication.isUserAuthenticated
    }


    //MARK: Find POI
    func getAllCities() -> [String] {
        return getUniqueStringFromPOI("poiCity", withSorting:true)
    }
    
    func getAllCitiesFromCountry(isoCountryCode:String, filter:String = "") -> [String] {
        return getUniqueStringFromPOI("poiCity", withSorting:true, withPredicate: NSPredicate(format: "poiISOCountryCode == %@",isoCountryCode), withCountryNameFilter:filter)
    }
    
    
    struct CountryDescription {
        let countryName:String
        let ISOCountryCode:String
    }
    
    func getAllCountriesOrderedByName() -> [CountryDescription] {
        let isoCountryNames = getAllISOCountryCode()
        
        var countries = [CountryDescription]()
        
        for currentISOCountry in isoCountryNames {
            if let countryName = NSLocale.currentLocale().displayNameForKey(NSLocaleCountryCode, value: currentISOCountry) {
                let newCountryNameToISO = CountryDescription(countryName: countryName, ISOCountryCode: currentISOCountry)
                countries.append(newCountryNameToISO)
            } else {
                print("\(#function) cannot find translation for ISOCountry \(currentISOCountry), it's ignored")
            }
        }
        countries = countries.sort() {
            $0.countryName < $1.countryName
        }
        return countries
    }
    
    private func getAllISOCountryCode() -> [String] {
        return getUniqueStringFromPOI("poiISOCountryCode")
    }
    
    private func getUniqueStringFromPOI(propertyName:String, withSorting:Bool = false, withPredicate:NSPredicate? = nil, withCountryNameFilter:String = "") -> [String] {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: entitiesCste.pointOfInterest)
        fetchRequest.resultType = .DictionaryResultType
        fetchRequest.returnsDistinctResults = true
        fetchRequest.propertiesToFetch = [propertyName]
        if !isUserAuthenticated() {
            if let andPredicate = withPredicate {
                fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[NSPredicate(format: "isPrivate == FALSE"), andPredicate])
            } else {
                fetchRequest.predicate = NSPredicate(format: "isPrivate == FALSE")
            }
        } else {
            if let andPredicate = withPredicate {
                fetchRequest.predicate = andPredicate
            }
        }
        
        if withSorting {
            let sortDescriptor = NSSortDescriptor(key: propertyName, ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
            fetchRequest.sortDescriptors = [sortDescriptor]
        }
       
        do {
            let propertiesResults = try managedContext.executeFetchRequest(fetchRequest)
            // CitiesResults is an Array where each value is a Dictionary which contains the key ("poiCity" attribute) and the unique value
            // We must iterate each Dictionary and concat the values
            var properties = [String]()
            
            let withCountryNameLowerCase = withCountryNameFilter.lowercaseString
            
            for currentPropertyDictionary in propertiesResults {
                if let values = (currentPropertyDictionary as? NSDictionary)?.allValues as? [String] {
                    if withCountryNameFilter.isEmpty {
                        properties.appendContentsOf(values)
                    } else {
                        if values[0].lowercaseString.containsString(withCountryNameLowerCase) {
                            properties.appendContentsOf(values)
                        }
                    }
                }
            }
            return properties
        } catch let error as NSError {
            print("\(#function) could not be fetch \(error), \(error.userInfo) for property \(propertyName)")
            return []
        }
    }

    func getAllContactsIdentifier() -> Set<String> {
        let result = getUniqueStringFromPOI(PointOfInterest.properties.poiContactIdentifier, withSorting:false, withPredicate: NSPredicate(format: "poiIsContact == TRUE"))
        return Set(result)
    }


    func getAllPOISortedByGroup(searchFilter:String = "", withEmptyGroup:Bool = false) -> [GroupOfInterest:[PointOfInterest]] {
        let groups = getGroups()
        var POIsPerGroup = [GroupOfInterest:[PointOfInterest]]()
        for currentGroup in groups {
            let POIs = getPOIsFromGroup(currentGroup, searchFilter: searchFilter)
            if POIs.count == 0 && !withEmptyGroup {
                continue
            }
            POIsPerGroup[currentGroup] = POIs
        }

        return POIsPerGroup
    }
    
    func getAllPOI() -> [PointOfInterest] {
        
        
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: entitiesCste.pointOfInterest)
        if !isUserAuthenticated() {
            fetchRequest.predicate = NSPredicate(format: "isPrivate == FALSE")
        }

        let sortDescriptor = NSSortDescriptor(key: "poiDisplayName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortDescriptor]
     
        do {
            let matchingPOI = try managedContext.executeFetchRequest(fetchRequest) as! [PointOfInterest]
            return matchingPOI
        } catch let error as NSError {
            print("\(#function) could not be fetch \(error), \(error.userInfo)")
            return []
        }
    }
    
    func getAllPOIFromCity(cityName:String, searchFilter:String = "") -> [PointOfInterest] {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: entitiesCste.pointOfInterest)
        
        let basicPredicate = !isUserAuthenticated() ?  NSPredicate(format: "isPrivate == FALSE AND poiCity == %@", cityName) : NSPredicate(format: "poiCity == %@", cityName)

        if !searchFilter.isEmpty {
            let searchPredicate = NSPredicate(format: "poiDisplayName CONTAINS[cd] %@", searchFilter)
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[searchPredicate, basicPredicate])
        } else {
            fetchRequest.predicate = basicPredicate
        }
        
        let sortDescriptor = NSSortDescriptor(key: "poiDisplayName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            let matchingPOI = try managedContext.executeFetchRequest(fetchRequest) as! [PointOfInterest]
            return matchingPOI
        } catch let error as NSError {
            print("\(#function) could not be fetch \(error), \(error.userInfo)")
            return []
        }
    }
    
    func getAllPOIFromCountry(ISOCountryCode:String, searchFilter:String = "") -> [PointOfInterest] {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: entitiesCste.pointOfInterest)
        
        let basicPredicate = !isUserAuthenticated() ? NSPredicate(format: "isPrivate == FALSE AND poiISOCountryCode == %@", ISOCountryCode) :  NSPredicate(format: "poiISOCountryCode == %@", ISOCountryCode)
        
        if !searchFilter.isEmpty {
            let searchPredicate = NSPredicate(format: "poiDisplayName CONTAINS[cd] %@", searchFilter)
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[searchPredicate, basicPredicate])
        } else {
            fetchRequest.predicate = basicPredicate
        }
        
        let sortDescriptor = NSSortDescriptor(key: "poiDisplayName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            let matchingPOI = try managedContext.executeFetchRequest(fetchRequest) as! [PointOfInterest]
            return matchingPOI
        } catch let error as NSError {
            print("\(#function) could not be fetch \(error), \(error.userInfo)")
            return []
        }
    }



    func getAllMonitoredPOI(searchFilter:String = "") -> [PointOfInterest] {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: entitiesCste.pointOfInterest)
        
        let basicPredicate = !isUserAuthenticated() ? NSPredicate(format: "isPrivate == FALSE AND ((poiRegionNotifyEnter == TRUE) OR (poiRegionNotifyExit == TRUE))") : NSPredicate(format: "(poiRegionNotifyEnter == TRUE) OR (poiRegionNotifyExit == TRUE)")
        
        if !searchFilter.isEmpty {
            let searchPredicate = NSPredicate(format: "poiDisplayName CONTAINS[cd] %@", searchFilter)
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[searchPredicate, basicPredicate])
        } else {
            fetchRequest.predicate = basicPredicate
        }

        let sortDescriptor = NSSortDescriptor(key: "poiDisplayName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortDescriptor]

        do {
            let matchingPOI = try managedContext.executeFetchRequest(fetchRequest) as! [PointOfInterest]
            return matchingPOI
        } catch let error as NSError {
            print("\(#function) could not be fetch \(error), \(error.userInfo)")
            return []
        }

    }
    
    func getPOIsFromGroup(group:GroupOfInterest, searchFilter:String = "") -> [PointOfInterest] {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: entitiesCste.pointOfInterest)
        
        let basicPredicate = !isUserAuthenticated() ? NSPredicate(format: "isPrivate == FALSE AND parentGroup = %@", group) : NSPredicate(format: "parentGroup = %@", group)
        
        if !searchFilter.isEmpty {
            let searchPredicate = NSPredicate(format: "poiDisplayName CONTAINS[cd] %@", searchFilter)
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[searchPredicate, basicPredicate])
        } else {
            fetchRequest.predicate = basicPredicate
        }
        
        let sortDescriptor = NSSortDescriptor(key: "poiDisplayName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            let matchingPOI = try managedContext.executeFetchRequest(fetchRequest) as! [PointOfInterest]
            return matchingPOI
        } catch let error as NSError {
            print("\(#function) could not be fetch \(error), \(error.userInfo)")
            return []
        }
    }
    
    func getPOIWithURI(URI:NSURL) -> PointOfInterest? {
        return getObjectWithURI(URI) as? PointOfInterest ?? nil
    }
    
    func getRouteWithURI(URI:NSURL) -> Route? {
        return getObjectWithURI(URI) as? Route ?? nil
    }
    
    private func getObjectWithURI(URI:NSURL) -> NSManagedObject? {
        
        
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        if let managedObjectId = DatabaseAccess.sharedInstance.persistentStoreCoordinator.managedObjectIDForURIRepresentation(URI) {
            do {
                return try managedContext.existingObjectWithID(managedObjectId)
            } catch let error as NSError {
                print("\(#function) could not be fetch \(error), \(error.userInfo)")
            }
        }
        return nil
    }


    
    func findPOI(searchText:String, category:Int) -> [PointOfInterest] {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: entitiesCste.pointOfInterest)
        
        if isUserAuthenticated() {
            if category == CategoryUtils.EmptyCategoryIndex {
                fetchRequest.predicate = NSPredicate(format: "poiDisplayName CONTAINS[cd] %@", searchText)
            } else {
                fetchRequest.predicate = NSPredicate(format: "poiDisplayName CONTAINS[cd] %@ AND poiCategory == %d", searchText, category)
            }
        } else {
            if category == CategoryUtils.EmptyCategoryIndex {
                fetchRequest.predicate = NSPredicate(format: "isPrivate == FALSE AND poiDisplayName CONTAINS[cd] %@", searchText) // BEGINSWITH
            } else {
                fetchRequest.predicate = NSPredicate(format: "isPrivate == FALSE AND poiDisplayName CONTAINS[cd] %@ AND poiCategory == %d", searchText, category)
            }
        }

        
        let sortDescriptor = NSSortDescriptor(key: "poiDisplayName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            let matchingPOI = try managedContext.executeFetchRequest(fetchRequest) as! [PointOfInterest]
            return matchingPOI
        } catch let error as NSError {
            print("\(#function) could not be fetch \(error), \(error.userInfo)")
            return []
        }
    }
    
    func findPOIWith(name:String, coordinates:CLLocationCoordinate2D) -> [PointOfInterest] {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: entitiesCste.pointOfInterest)
        if isUserAuthenticated() {
            fetchRequest.predicate = NSPredicate(format: "(poiDisplayName == %@) AND (poiLatitude == %@) AND (poiLongitude == %@)", name, NSNumber(double: coordinates.latitude), NSNumber(double:coordinates.longitude))
        } else {
            fetchRequest.predicate = NSPredicate(format: "isPrivate == FALSE AND (poiDisplayName == %@) AND (poiLatitude == %@) AND (poiLongitude == %@)", name, NSNumber(double: coordinates.latitude), NSNumber(double:coordinates.longitude))

        }
        do {
            let matchingPOI = try managedContext.executeFetchRequest(fetchRequest) as! [PointOfInterest]
            return matchingPOI
        } catch let error as NSError {
            print("\(#function) could not be fetch \(error), \(error.userInfo)")
            return []
        }
    }
    
    func findContact(contactIdentifier:String) -> [PointOfInterest] {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: entitiesCste.pointOfInterest)
        if isUserAuthenticated() {
            fetchRequest.predicate = NSPredicate(format: "(poiContactIdentifier == %@) AND (poiIsContact == TRUE)", contactIdentifier)
        } else {
            fetchRequest.predicate = NSPredicate(format: "isPrivate == FALSE AND (poiContactIdentifier == %@) AND (poiIsContact == true)", contactIdentifier)
        }
        
        do {
            let matchingPOI = try managedContext.executeFetchRequest(fetchRequest) as! [PointOfInterest]
            return matchingPOI
        } catch let error as NSError {
            print("\(#function) could not be fetch \(error), \(error.userInfo)")
            return []
        }
    }

    func findPOIWithRegiondId(regionId:String) -> PointOfInterest? {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: entitiesCste.pointOfInterest)
        fetchRequest.predicate = NSPredicate(format: "(poiRegionId == %@)", regionId)
        do {
            let matchingPOI = try managedContext.executeFetchRequest(fetchRequest) as! [PointOfInterest]
            if matchingPOI.count > 1 {
                print("\(#function): Error, found more than one POI")
            }
            return matchingPOI.first
        } catch let error as NSError {
            print("\(#function) could not be fetch \(error), \(error.userInfo)")
            return nil
        }
    }

    
    func findPOIWith(wikipedia:Wikipedia) -> PointOfInterest? {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: entitiesCste.pointOfInterest)
        if isUserAuthenticated() {
            fetchRequest.predicate = NSPredicate(format: "poiWikipediaPageId = %d", wikipedia.pageId)
        } else {
            fetchRequest.predicate = NSPredicate(format: "isPrivate == FALSE AND poiWikipediaPageId = %d", wikipedia.pageId)
        }
        
        do {
            let matchingPOI = try managedContext.executeFetchRequest(fetchRequest) as! [PointOfInterest]
            if matchingPOI.count > 0 {
                return matchingPOI[0]
            } else {
                return nil
            }
        } catch let error as NSError {
            print("\(#function) could not be fetch \(error), \(error.userInfo)")
            return nil
        }
        
    }

     //MARK: POI
    // Insert a new PointOfInterest in the database in the default GroupOfInterest
    func addPOI(coordinates: CLLocationCoordinate2D, camera:MKMapCamera) -> PointOfInterest {
        let poi = getEmptyPoi()
        poi.initializeWith(coordinates, camera:camera)
        commitDatabase()
//        poi.updateInSpotLight()
        return poi
    }
    
    func addPOI(contact:CNContact, placemark:CLPlacemark) -> PointOfInterest {
        let poi = getEmptyPoi()
        poi.initializeWith(contact, placemark: placemark)
        commitDatabase()
//        poi.updateInSpotLight()
        return poi
    }
    
    func addPOI(wikipedia: Wikipedia, group:GroupOfInterest) -> PointOfInterest {
        let poi = getEmptyPoi()
        poi.initializeWith(wikipedia, group: group)
        commitDatabase()
//        poi.updateInSpotLight()
        return poi
    }
    
    func addPOI(mapItem: MKMapItem, categoryIndex:Int) -> PointOfInterest {
        let poi = getEmptyPoi()
        poi.initializeWith(mapItem, categoryIndex:categoryIndex)
        commitDatabase()
//        poi.updateInSpotLight()
        return poi
    }
    
    private func getEmptyPoi() -> PointOfInterest {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let entity = NSEntityDescription.entityForName(entitiesCste.pointOfInterest, inManagedObjectContext:managedContext)
        return PointOfInterest(entity: entity!, insertIntoManagedObjectContext: managedContext)
    }

    func deletePOI(POI POI:PointOfInterest) {
        if POI.isMonitored {
            LocationManager.sharedInstance.stopMonitoringRegion(POI)
        }
        deleteObject(POI)
    }
    
    func deleteCityPOIs(cityName:String, fromISOCountryCode:String) {
        let pois = getAllPOIFromCity(cityName)
        for currentPOI in pois {
            deletePOI(POI: currentPOI)
        }
    }
    
    func deleteCountryPOIs(isoCountryCode:String) {
        let pois = getAllPOIFromCountry(isoCountryCode)
        for currentPOI in pois {
            deletePOI(POI: currentPOI)
        }        
    }
    
    func deleteMonitoredPOIs() {
        let pois = POIDataManager.sharedInstance.getAllMonitoredPOI()
        for currentPOI in pois {
            deletePOI(POI: currentPOI)
        }
    }

    
    func deleteContacts(contactsToBeDeleted:Set<String>) {
        for currentContactId in contactsToBeDeleted {
            let pois = findContact(currentContactId)
            if pois.count > 1 {
                print("\(#function) Warning, found \(pois.count) with the same contactIdentifier!")
            }
            for currentPoi in pois {
                deletePOI(POI: currentPoi)
            }
        }
    }
    
    func updatePOI(poi: PointOfInterest) {
    }
    

    
    //MARK: find Route
    func getAllRoutes() -> [Route] {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: entitiesCste.route)
 
        let sortDescriptor = NSSortDescriptor(key: "routeName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortDescriptor]

        do {
            let routes = try managedContext.executeFetchRequest(fetchRequest) as! [Route]
            return routes
        } catch let error as NSError {
            print("getAllRoutes could not be fetch \(error), \(error.userInfo)")
            return []
        }
    }
    
    func findRoute(searchText:String) -> [Route] {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: entitiesCste.route)
        fetchRequest.predicate = NSPredicate(format: "routeName BEGINSWITH[cd] %@", searchText)
        
        let sortDescriptor = NSSortDescriptor(key: "routeName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            let matchingRoute = try managedContext.executeFetchRequest(fetchRequest) as! [Route]
            return matchingRoute
        } catch let error as NSError {
            print("findRoute could not be fetch: \(error), \(error.userInfo)")
            return []
        }
    }

    
    //MARK: Route
   func addRoute(routeName:String, routePath:[PointOfInterest]) -> Route {
        
        let wayPoints = NSMutableOrderedSet()
        
        for currentRouteEntry in routePath {
            let newRouteEntry = addWayPoint(currentRouteEntry)
            wayPoints.addObject(newRouteEntry)
        }
        
        let route = getEmptyRoute()
        route.initializeRoute(routeName, wayPoints: wayPoints)
        return route
    }
    
    private func getEmptyRoute() -> Route {
        
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let entity = NSEntityDescription.entityForName(entitiesCste.route, inManagedObjectContext:managedContext)
        return Route(entity: entity!, insertIntoManagedObjectContext: managedContext)
    }


    func addWayPointToRoute(route:Route, pois:[PointOfInterest]) {
        let wayPoints = NSMutableOrderedSet(orderedSet: route.routeWayPoints!)

        for currentPOI in pois {
            let newWayPoint = addWayPoint(currentPOI)
            wayPoints.addObject(newWayPoint)
        }

        route.routeWayPoints = wayPoints
    }
    
    func insertWayPointTo(route: Route, poi:PointOfInterest, index:Int) {
        let wayPoints = NSMutableOrderedSet(orderedSet: route.routeWayPoints!)
        
        let newWayPoint = addWayPoint(poi)
        wayPoints.insertObject(newWayPoint, atIndex: index)
        
        if index > 0 {
            let previousWayPoint = wayPoints.objectAtIndex(index - 1) as! WayPoint
            newWayPoint.transportType = previousWayPoint.transportType
            previousWayPoint.transportType = UserPreferences.sharedInstance.routeDefaultTransportType
            previousWayPoint.calculatedRoute = nil
        }
        
        route.routeWayPoints = wayPoints
    }
    
    func insertWayPointTo(route: Route, poi:PointOfInterest, index:Int, transportType:MKDirectionsTransportType) {
        let wayPoints = NSMutableOrderedSet(orderedSet: route.routeWayPoints!)
    
        if index == 0 {
            let newWayPoint = addWayPoint(poi, transportType: transportType)
            wayPoints.insertObject(newWayPoint, atIndex: index)
        } else {
            let newWayPoint = addWayPoint(poi)
            wayPoints.insertObject(newWayPoint, atIndex: index)
            
            let previousWayPoint = wayPoints.objectAtIndex(index - 1) as! WayPoint
            newWayPoint.transportType = previousWayPoint.transportType
            previousWayPoint.transportType = transportType
            previousWayPoint.calculatedRoute = nil
        }
        
        route.routeWayPoints = wayPoints
    }


    
    func updateRoute(route:Route) {
    }

    func deleteRoute(route:Route) {
        deleteObject(route)
    }

    // MARK: WayPoint
    func addWayPoint(poi: PointOfInterest) -> WayPoint {
        return addWayPoint(poi, transportType: UserPreferences.sharedInstance.routeDefaultTransportType)
    }

    func addWayPoint(poi: PointOfInterest, transportType:MKDirectionsTransportType) -> WayPoint {
        let wayPoint = getEmptyWayPoint()
        wayPoint.transportType = transportType
        wayPoint.wayPointPoi = poi
        return wayPoint
    }

    
    private func getEmptyWayPoint() -> WayPoint {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let entity = NSEntityDescription.entityForName(entitiesCste.wayPoint, inManagedObjectContext:managedContext)
        return WayPoint(entity: entity!, insertIntoManagedObjectContext: managedContext)
    }
    
    func deleteWayPoint(wayPoint:WayPoint) {
        wayPoint.wayPointParent!.willRemoveWayPoint(wayPoint)
        deleteObject(wayPoint)
    }
    
    func updateWayPoint(wayPoint:WayPoint) {
    }

    //MARK: Generic methods
    private func deleteObject(dataBaseObject:NSManagedObject) {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        managedContext.deleteObject(dataBaseObject)
    }
    
    func commitDatabase() {
        
        DatabaseAccess.sharedInstance.saveContext()
    }
    
    func rollback() {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        managedContext.rollback()
    }

}
