//
//  PointOfInterest+CoreDataProperties.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 10/09/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//
//

import Foundation
import CoreData


extension PointOfInterest {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PointOfInterest> {
        return NSFetchRequest<PointOfInterest>(entityName: "PointOfInterest")
    }

    @NSManaged public var poiAddress: String?
    @NSManaged public var poiCategory: Int16
    @NSManaged public var poiCity: String?
    @NSManaged public var poiContactIdentifier: String?
    @NSManaged public var poiDescription: String?
    @NSManaged public var poiDisplayName: String?
    @NSManaged public var poiGroupCategory: Int16
    @NSManaged public var poiIsContact: Bool
    @NSManaged public var poiISOCountryCode: String?
    @NSManaged public var poiLatitude: Double
    @NSManaged public var poiLongitude: Double
    @NSManaged public var poiPhoneNumber: String?
    @NSManaged public var poiRegionId: String?
    @NSManaged public var poiRegionNotifyEnter: Bool
    @NSManaged public var poiRegionNotifyExit: Bool
    @NSManaged public var poiRegionRadius: Double
    @NSManaged public var poiURL: String?
    @NSManaged public var poiWikipediaPageId: Int64
    @NSManaged public var parentGroup: GroupOfInterest?
    @NSManaged public var poiWayPoints: NSSet?

}

// MARK: Generated accessors for poiWayPoints
extension PointOfInterest {

    @objc(addPoiWayPointsObject:)
    @NSManaged public func addToPoiWayPoints(_ value: WayPoint)

    @objc(removePoiWayPointsObject:)
    @NSManaged public func removeFromPoiWayPoints(_ value: WayPoint)

    @objc(addPoiWayPoints:)
    @NSManaged public func addToPoiWayPoints(_ values: NSSet)

    @objc(removePoiWayPoints:)
    @NSManaged public func removeFromPoiWayPoints(_ values: NSSet)

}
