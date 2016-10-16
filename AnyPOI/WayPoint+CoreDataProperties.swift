//
//  WayPoint+CoreDataProperties.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 16/10/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import CoreData


extension WayPoint {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WayPoint> {
        return NSFetchRequest<WayPoint>(entityName: "WayPoint");
    }

    @NSManaged public var wayPointRouteInfos: NSObject?
    @NSManaged public var wayPointTransportType: Int64
    @NSManaged public var wayPointParent: Route?
    @NSManaged public var wayPointPoi: PointOfInterest?

}
