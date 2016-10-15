//
//  Route+CoreDataProperties.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 15/10/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import CoreData


extension Route {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Route> {
        return NSFetchRequest<Route>(entityName: "Route");
    }

    @NSManaged public var isPrivate: Bool
    @NSManaged public var latestTotalDistance: Double
    @NSManaged public var latestTotalDuration: Double
    @NSManaged public var routeName: String?
    @NSManaged public var routeWayPoints: NSOrderedSet?

}

// MARK: Generated accessors for routeWayPoints
extension Route {

    @objc(insertObject:inRouteWayPointsAtIndex:)
    @NSManaged public func insertIntoRouteWayPoints(_ value: WayPoint, at idx: Int)

    @objc(removeObjectFromRouteWayPointsAtIndex:)
    @NSManaged public func removeFromRouteWayPoints(at idx: Int)

    @objc(insertRouteWayPoints:atIndexes:)
    @NSManaged public func insertIntoRouteWayPoints(_ values: [WayPoint], at indexes: NSIndexSet)

    @objc(removeRouteWayPointsAtIndexes:)
    @NSManaged public func removeFromRouteWayPoints(at indexes: NSIndexSet)

    @objc(replaceObjectInRouteWayPointsAtIndex:withObject:)
    @NSManaged public func replaceRouteWayPoints(at idx: Int, with value: WayPoint)

    @objc(replaceRouteWayPointsAtIndexes:withRouteWayPoints:)
    @NSManaged public func replaceRouteWayPoints(at indexes: NSIndexSet, with values: [WayPoint])

    @objc(addRouteWayPointsObject:)
    @NSManaged public func addToRouteWayPoints(_ value: WayPoint)

    @objc(removeRouteWayPointsObject:)
    @NSManaged public func removeFromRouteWayPoints(_ value: WayPoint)

    @objc(addRouteWayPoints:)
    @NSManaged public func addToRouteWayPoints(_ values: NSOrderedSet)

    @objc(removeRouteWayPoints:)
    @NSManaged public func removeFromRouteWayPoints(_ values: NSOrderedSet)

}
