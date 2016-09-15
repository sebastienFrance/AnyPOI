//
//  Route+CoreDataProperties.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 15/09/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Route {

    @NSManaged var isPrivate: Bool
    @NSManaged var latestTotalDistance: Double
    @NSManaged var latestTotalDuration: Double
    @NSManaged var routeName: String?
    @NSManaged var routeWayPoints: NSOrderedSet?

}
