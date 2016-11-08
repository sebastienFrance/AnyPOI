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
    fileprivate struct entitiesCste {
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
    
    fileprivate struct defaultContactGroupCste {
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
    
    func isMandatoryGroup(_ group:GroupOfInterest) -> Bool {
        return isDefaultGroup(group) || isDefaultContactGroup(group)
    }
    
    // get the defaul GroupOfInterest (if it doesn't exist, it's automatically created)
    @discardableResult
    func getDefaultGroup() -> GroupOfInterest {
        if let defaultGroup = findGroup(groupId: defaultGroupCste.groupId) {
            return defaultGroup
        } else {
            return addGroup(groupId: defaultGroupCste.groupId, groupName: defaultGroupCste.displayName,
                            groupDescription: defaultGroupCste.groupDescription, groupColor: defaultGroupCste.groupColor)
        }
    }
    
    func isDefaultGroup(_ group:GroupOfInterest) -> Bool {
        let groupId = Int(group.groupId)
        if groupId == defaultGroupCste.groupId {
            return true
        } else {
            return false
        }
    }
    
    @discardableResult
    func getDefaultContactGroup() -> GroupOfInterest! {
        if let defaultGroup = findGroup(groupId: defaultContactGroupCste.groupId) {
            return defaultGroup
        } else {
            return addGroup(groupId: defaultContactGroupCste.groupId, groupName: defaultContactGroupCste.displayName,
                            groupDescription: defaultContactGroupCste.groupDescription, groupColor: defaultContactGroupCste.groupColor)
        }
    }

    func isDefaultContactGroup(_ group:GroupOfInterest) -> Bool {
        let groupId = Int(group.groupId)
        if groupId == defaultContactGroupCste.groupId {
            return true
        } else {
            return false
        }
    }
    
    
    //MARK: find Group
    func getGroups(_ searchFilter:String = "") -> [GroupOfInterest] {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest<GroupOfInterest>(entityName: entitiesCste.groupOfInterest)
        
        if !searchFilter.isEmpty {
            fetchRequest.predicate = NSPredicate(format: "groupDisplayName CONTAINS[cd] %@", argumentArray: [searchFilter])
        }
        
        let sortDescriptor = NSSortDescriptor(key: "groupDisplayName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            return try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("\(#function) GroupOfInterests could not be extracted from DB \(error), \(error.userInfo)")
            return [GroupOfInterest]()
        }
    }
    
    func findGroup(groupId:Int) -> GroupOfInterest? {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest<GroupOfInterest>(entityName: entitiesCste.groupOfInterest)
        fetchRequest.predicate = NSPredicate(format: "groupId = %@", argumentArray: [groupId])
        
        do {
            let matchingGroups = try managedContext.fetch(fetchRequest)
            
            if matchingGroups.count >= 1 {
                return matchingGroups[0]
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
        let fetchRequest = NSFetchRequest<GroupOfInterest>(entityName: entitiesCste.groupOfInterest)
        fetchRequest.predicate = NSPredicate(format: "isGroupDisplayed = %@", argumentArray: [true])
        
        let sortDescriptor = NSSortDescriptor(key: "groupDisplayName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            return try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("\(#function) DisplayableGroups could not be fetch \(error), \(error.userInfo)")
            return [GroupOfInterest]()
        }
        
    }
    
    func findGroups(_ searchText:String) -> [GroupOfInterest] {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest<GroupOfInterest>(entityName: entitiesCste.groupOfInterest)
        if !searchText.isEmpty {
            fetchRequest.predicate = NSPredicate(format: "groupDisplayName BEGINSWITH[cd] %@", searchText)
        } else {
            fetchRequest.predicate = NSPredicate(format: "isGroupDisplayed == TRUE")
        }
        let sortDescriptor = NSSortDescriptor(key: "groupDisplayName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        
        do {
            return try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("\(#function) could not be fetch \(error), \(error.userInfo)")
            return []
        }
    }

    // MARK: Group
    func addGroup(groupName:String, groupDescription:String, groupColor:UIColor) -> GroupOfInterest {
        let groupId = Int(Date.timeIntervalSinceReferenceDate)
        return addGroup(groupId: groupId, groupName: groupName, groupDescription: groupDescription, groupColor: groupColor)
    }
    
    fileprivate func addGroup(groupId: Int, groupName:String, groupDescription:String, groupColor:UIColor) -> GroupOfInterest {
        let group = getEmptyGroup()
        group.initializeWith(groupId, name: groupName, description: groupDescription, color: groupColor)
        return group
    }
    
    func getEmptyGroup() -> GroupOfInterest {
        
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let entity = NSEntityDescription.entity(forEntityName: entitiesCste.groupOfInterest, in:managedContext)
       // return GroupOfInterest(context: managedContext)
        return GroupOfInterest(entity: entity!, insertInto: managedContext)
    }

    func deleteGroup(group:GroupOfInterest) {
        

        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext

        managedContext.delete(group)

        if let pois = group.listOfPOIs {
            for currentPOI in pois {
                managedContext.delete(currentPOI as! NSManagedObject)
            }
        }
    }

    func updatePOIGroup(_ poiGroup: GroupOfInterest) {
    }

    //MARK: Find POI
    func getAllCities() -> [String] {
        return getUniqueStringFromPOI("poiCity", withSorting:true)
    }
    
    func getAllCitiesFromCountry(_ isoCountryCode:String, filter:String = "") -> [String] {
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
            if let countryName = (Locale.current as NSLocale).displayName(forKey: NSLocale.Key.countryCode, value: currentISOCountry) {
                let newCountryNameToISO = CountryDescription(countryName: countryName, ISOCountryCode: currentISOCountry)
                countries.append(newCountryNameToISO)
            } else {
                print("\(#function) cannot find translation for ISOCountry \(currentISOCountry), it's ignored")
            }
        }
        countries = countries.sorted() {
            $0.countryName < $1.countryName
        }
        return countries
    }
    
    fileprivate func getAllISOCountryCode() -> [String] {
        return getUniqueStringFromPOI("poiISOCountryCode")
    }
    
    fileprivate func getUniqueStringFromPOI(_ propertyName:String, withSorting:Bool = false, withPredicate:NSPredicate? = nil, withCountryNameFilter:String = "") -> [String] {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: entitiesCste.pointOfInterest)
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.returnsDistinctResults = true
        fetchRequest.propertiesToFetch = [propertyName]
        if let andPredicate = withPredicate {
            fetchRequest.predicate = andPredicate
        }
        
        if withSorting {
            let sortDescriptor = NSSortDescriptor(key: propertyName, ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
            fetchRequest.sortDescriptors = [sortDescriptor]
        }
       
        do {
            let propertiesResults = try managedContext.fetch(fetchRequest)
            // CitiesResults is an Array where each value is a Dictionary which contains the key ("poiCity" attribute) and the unique value
            // We must iterate each Dictionary and concat the values
            var properties = [String]()
            
            let withCountryNameLowerCase = withCountryNameFilter.lowercased()
            
            for currentPropertyDictionary in propertiesResults {
                if let values = currentPropertyDictionary.allValues as? [String] {
                    if withCountryNameFilter.isEmpty {
                        properties.append(contentsOf: values)
                    } else {
                        if values[0].lowercased().contains(withCountryNameLowerCase) {
                            properties.append(contentsOf: values)
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


    func getAllPOISortedByGroup(_ searchFilter:String = "", withEmptyGroup:Bool = false) -> [GroupOfInterest:[PointOfInterest]] {
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
        let fetchRequest = NSFetchRequest<PointOfInterest>(entityName: entitiesCste.pointOfInterest)

        let sortDescriptor = NSSortDescriptor(key: "poiDisplayName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortDescriptor]
     
        do {
            return try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("\(#function) could not be fetch \(error), \(error.userInfo)")
            return []
        }
    }
    
    func getAllPOIFromCity(_ cityName:String, searchFilter:String = "") -> [PointOfInterest] {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest<PointOfInterest>(entityName: entitiesCste.pointOfInterest)
        
        let basicPredicate = NSPredicate(format: "poiCity == %@", cityName)

        if !searchFilter.isEmpty {
            let searchPredicate = NSPredicate(format: "poiDisplayName CONTAINS[cd] %@", searchFilter)
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[searchPredicate, basicPredicate])
        } else {
            fetchRequest.predicate = basicPredicate
        }
        
        let sortDescriptor = NSSortDescriptor(key: "poiDisplayName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            return try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("\(#function) could not be fetch \(error), \(error.userInfo)")
            return []
        }
    }
    
    func getAllPOIFromCountry(_ ISOCountryCode:String, searchFilter:String = "") -> [PointOfInterest] {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest<PointOfInterest>(entityName: entitiesCste.pointOfInterest)
        
        let basicPredicate = NSPredicate(format: "poiISOCountryCode == %@", ISOCountryCode)
        
        if !searchFilter.isEmpty {
            let searchPredicate = NSPredicate(format: "poiDisplayName CONTAINS[cd] %@", searchFilter)
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[searchPredicate, basicPredicate])
        } else {
            fetchRequest.predicate = basicPredicate
        }
        
        let sortDescriptor = NSSortDescriptor(key: "poiDisplayName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            return try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("\(#function) could not be fetch \(error), \(error.userInfo)")
            return []
        }
    }



    func getAllMonitoredPOI(_ searchFilter:String = "") -> [PointOfInterest] {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest<PointOfInterest>(entityName: entitiesCste.pointOfInterest)
        
        let basicPredicate = NSPredicate(format: "(poiRegionNotifyEnter == TRUE) OR (poiRegionNotifyExit == TRUE)")
       
        if !searchFilter.isEmpty {
            let searchPredicate = NSPredicate(format: "poiDisplayName CONTAINS[cd] %@", searchFilter)
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[searchPredicate, basicPredicate])
        } else {
            fetchRequest.predicate = basicPredicate
        }

        let sortDescriptor = NSSortDescriptor(key: "poiDisplayName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortDescriptor]

        do {
            return try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("\(#function) could not be fetch \(error), \(error.userInfo)")
            return []
        }

    }
    
    func getPOIsFromGroup(_ group:GroupOfInterest, searchFilter:String = "") -> [PointOfInterest] {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest<PointOfInterest>(entityName: entitiesCste.pointOfInterest)
        
        let basicPredicate = NSPredicate(format: "parentGroup = %@", group)
        
        if !searchFilter.isEmpty {
            let searchPredicate = NSPredicate(format: "poiDisplayName CONTAINS[cd] %@", searchFilter)
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[searchPredicate, basicPredicate])
        } else {
            fetchRequest.predicate = basicPredicate
        }
        
        let sortDescriptor = NSSortDescriptor(key: "poiDisplayName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            return try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("\(#function) could not be fetch \(error), \(error.userInfo)")
            return []
        }
    }
    
    func getPOIWithURI(_ URI:URL) -> PointOfInterest? {
        return getObjectWithURI(URI) as? PointOfInterest ?? nil
    }
    
    func getRouteWithURI(_ URI:URL) -> Route? {
        return getObjectWithURI(URI) as? Route ?? nil
    }
    
    fileprivate func getObjectWithURI(_ URI:URL) -> NSManagedObject? {
        
        
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        if let managedObjectId = DatabaseAccess.sharedInstance.persistentStoreCoordinator.managedObjectID(forURIRepresentation: URI) {
            do {
                return try managedContext.existingObject(with: managedObjectId)
            } catch let error as NSError {
                print("\(#function) could not be fetch \(error), \(error.userInfo)")
            }
        }
        return nil
    }


    
    func findPOI(_ searchText:String, category:Int) -> [PointOfInterest] {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest<PointOfInterest>(entityName: entitiesCste.pointOfInterest)
        
        if category == CategoryUtils.EmptyCategoryIndex {
            fetchRequest.predicate = NSPredicate(format: "poiDisplayName CONTAINS[cd] %@", searchText)
        } else {
            fetchRequest.predicate = NSPredicate(format: "poiDisplayName CONTAINS[cd] %@ AND poiCategory == %d", searchText, category)
        }
        
        let sortDescriptor = NSSortDescriptor(key: "poiDisplayName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            return try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("\(#function) could not be fetch \(error), \(error.userInfo)")
            return []
        }
    }
    
    func findPOIWith(_ name:String, coordinates:CLLocationCoordinate2D) -> [PointOfInterest] {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest<PointOfInterest>(entityName: entitiesCste.pointOfInterest)
        fetchRequest.predicate = NSPredicate(format: "(poiDisplayName == %@) AND (poiLatitude == %@) AND (poiLongitude == %@)", name, NSNumber(value: coordinates.latitude as Double), NSNumber(value: coordinates.longitude as Double))
        do {
            return try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("\(#function) could not be fetch \(error), \(error.userInfo)")
            return []
        }
    }
    
    func findContact(_ contactIdentifier:String) -> [PointOfInterest] {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest<PointOfInterest>(entityName: entitiesCste.pointOfInterest)
        fetchRequest.predicate = NSPredicate(format: "(poiContactIdentifier == %@) AND (poiIsContact == TRUE)", contactIdentifier)
        
        do {
            return try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("\(#function) could not be fetch \(error), \(error.userInfo)")
            return []
        }
    }

    func findPOIWithRegiondId(_ regionId:String) -> PointOfInterest? {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest<PointOfInterest>(entityName: entitiesCste.pointOfInterest)
        fetchRequest.predicate = NSPredicate(format: "(poiRegionId == %@)", regionId)
        do {
            let matchingPOI = try managedContext.fetch(fetchRequest)
            if matchingPOI.count > 1 {
                print("\(#function): Error, found more than one POI")
            }
            return matchingPOI.first
        } catch let error as NSError {
            print("\(#function) could not be fetch \(error), \(error.userInfo)")
            return nil
        }
    }

    
    func findPOIWith(_ wikipedia:Wikipedia) -> PointOfInterest? {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest<PointOfInterest>(entityName: entitiesCste.pointOfInterest)
        fetchRequest.predicate = NSPredicate(format: "poiWikipediaPageId = %d", wikipedia.pageId)
        
        do {
            let matchingPOI = try managedContext.fetch(fetchRequest)
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
    func addPOI(_ coordinates: CLLocationCoordinate2D, camera:MKMapCamera) -> PointOfInterest {
        let poi = getEmptyPoi()
        poi.initializeWith(coordinates, camera:camera)
        commitDatabase()
        return poi
    }
    
    func addPOI(_ contact:CNContact, placemark:CLPlacemark) -> PointOfInterest {
        let poi = getEmptyPoi()
        poi.initializeWith(contact, placemark: placemark)
        commitDatabase()
        return poi
    }
    
    func addPOI(_ wikipedia: Wikipedia, group:GroupOfInterest) -> PointOfInterest {
        let poi = getEmptyPoi()
        poi.initializeWith(wikipedia, group: group)
        commitDatabase()
        return poi
    }
    
    func addPOI(_ mapItem: MKMapItem, categoryIndex:Int) -> PointOfInterest {
        let poi = getEmptyPoi()
        poi.initializeWith(mapItem, categoryIndex:categoryIndex)
        commitDatabase()
        return poi
    }
    
    fileprivate func getEmptyPoi() -> PointOfInterest {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let entity = NSEntityDescription.entity(forEntityName: entitiesCste.pointOfInterest, in:managedContext)
        return PointOfInterest(entity: entity!, insertInto: managedContext)
    }

    func deletePOI(POI:PointOfInterest) {
        if POI.isMonitored {
            _ = LocationManager.sharedInstance.stopMonitoringRegion(poi: POI)
        }
        deleteObject(POI)
    }
    
    func deleteCityPOIs(_ cityName:String, fromISOCountryCode:String) {
        let pois = getAllPOIFromCity(cityName)
        for currentPOI in pois {
            deletePOI(POI: currentPOI)
        }
    }
    
    func deleteCountryPOIs(_ isoCountryCode:String) {
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

    
    func deleteContacts(_ contactsToBeDeleted:Set<String>) {
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
    
    func updatePOI(_ poi: PointOfInterest) {
    }
    

    
    //MARK: find Route
    func getAllRoutes() -> [Route] {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest<Route>(entityName: entitiesCste.route)
 
        let sortDescriptor = NSSortDescriptor(key: "routeName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortDescriptor]

        do {
            return try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("getAllRoutes could not be fetch \(error), \(error.userInfo)")
            return []
        }
    }
    
    func findRoute(_ searchText:String) -> [Route] {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest<Route>(entityName: entitiesCste.route)
        fetchRequest.predicate = NSPredicate(format: "routeName BEGINSWITH[cd] %@", searchText)
        
        let sortDescriptor = NSSortDescriptor(key: "routeName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            return try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("findRoute could not be fetch: \(error), \(error.userInfo)")
            return []
        }
    }

    
    //MARK: Route
   func addRoute(_ routeName:String, routePath:[PointOfInterest]) -> Route {
        
        let wayPoints = NSMutableOrderedSet()
        
        for currentRouteEntry in routePath {
            let newRouteEntry = addWayPoint(currentRouteEntry)
            wayPoints.add(newRouteEntry)
        }
        
        let route = getEmptyRoute()
        route.initializeRoute(routeName, wayPoints: wayPoints)
        return route
    }
    
    fileprivate func getEmptyRoute() -> Route {
        
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let entity = NSEntityDescription.entity(forEntityName: entitiesCste.route, in:managedContext)
        return Route(entity: entity!, insertInto: managedContext)
    }


    func addWayPointToRoute(_ route:Route, pois:[PointOfInterest]) {
        let wayPoints = NSMutableOrderedSet(orderedSet: route.routeWayPoints!)

        for currentPOI in pois {
            let newWayPoint = addWayPoint(currentPOI)
            wayPoints.add(newWayPoint)
        }

        route.routeWayPoints = wayPoints
    }
    
    func insertWayPointTo(_ route: Route, poi:PointOfInterest, index:Int) {
        let wayPoints = NSMutableOrderedSet(orderedSet: route.routeWayPoints!)
        
        let newWayPoint = addWayPoint(poi)
        wayPoints.insert(newWayPoint, at: index)
        
        if index > 0 {
            let previousWayPoint = wayPoints.object(at: index - 1) as! WayPoint
            newWayPoint.transportType = previousWayPoint.transportType
            previousWayPoint.transportType = UserPreferences.sharedInstance.routeDefaultTransportType
            previousWayPoint.routeInfos = nil
        }
        
        route.routeWayPoints = wayPoints
    }
    
    func insertWayPointTo(_ route: Route, poi:PointOfInterest, index:Int, transportType:MKDirectionsTransportType) {
        let wayPoints = NSMutableOrderedSet(orderedSet: route.routeWayPoints!)
    
        if index == 0 {
            let newWayPoint = addWayPoint(poi, transportType: transportType)
            wayPoints.insert(newWayPoint, at: index)
        } else {
            let newWayPoint = addWayPoint(poi)
            wayPoints.insert(newWayPoint, at: index)
            
            let previousWayPoint = wayPoints.object(at: index - 1) as! WayPoint
            newWayPoint.transportType = previousWayPoint.transportType
            previousWayPoint.transportType = transportType
            previousWayPoint.routeInfos = nil
        }
        
        route.routeWayPoints = wayPoints
    }


    
    func updateRoute(route:Route) {
    }

    func deleteRoute(_ route:Route) {
        deleteObject(route)
    }

    // MARK: WayPoint
    func addWayPoint(_ poi: PointOfInterest) -> WayPoint {
        return addWayPoint(poi, transportType: UserPreferences.sharedInstance.routeDefaultTransportType)
    }

    func addWayPoint(_ poi: PointOfInterest, transportType:MKDirectionsTransportType) -> WayPoint {
        let wayPoint = getEmptyWayPoint()
        wayPoint.transportType = transportType
        wayPoint.wayPointPoi = poi
        return wayPoint
    }

    
    fileprivate func getEmptyWayPoint() -> WayPoint {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        let entity = NSEntityDescription.entity(forEntityName: entitiesCste.wayPoint, in:managedContext)
        return WayPoint(entity: entity!, insertInto: managedContext)
    }
    
    func deleteWayPoint(_ wayPoint:WayPoint) {
        wayPoint.wayPointParent!.willRemoveWayPoint(wayPoint)
        deleteObject(wayPoint)
    }
    
    func updateWayPoint(_ wayPoint:WayPoint) {
    }

    //MARK: Generic methods
    fileprivate func deleteObject(_ dataBaseObject:NSManagedObject) {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        managedContext.delete(dataBaseObject)
    }
    
    func commitDatabase() {
        
        DatabaseAccess.sharedInstance.saveContext()
    }
    
    func rollback() {
        let managedContext = DatabaseAccess.sharedInstance.managedObjectContext
        managedContext.rollback()
    }

}
