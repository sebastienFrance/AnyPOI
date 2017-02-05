//
//  WayPoint+CoreDataProperties.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 05/02/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import Foundation
import CoreData


extension WayPoint {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WayPoint> {
        return NSFetchRequest<WayPoint>(entityName: "WayPoint");
    }

    @NSManaged public var wayPointRouteInfos: NSObject?
    @NSManaged public var wayPointTransportType: Int64
    @NSManaged public var wayPointDistance: Double
    @NSManaged public var wayPointDuration: Double
    @NSManaged public var wayPointParent: Route?
    @NSManaged public var wayPointPoi: PointOfInterest?

}
