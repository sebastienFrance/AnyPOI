//
//  PointOfInterest+CoreDataProperties.swift
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

extension PointOfInterest {

    @NSManaged var isPrivate: Bool
    @NSManaged var poiCamera: NSObject?
    @NSManaged var poiCategory: Int16
    @NSManaged var poiCity: String?
    @NSManaged var poiContactIdentifier: String?
    @NSManaged var poiContactLatestAddress: String?
    @NSManaged var poiDescription: String?
    @NSManaged var poiDisplayName: String?
    @NSManaged var poiIsContact: Bool
    @NSManaged var poiISOCountryCode: String?
    @NSManaged var poiLatitude: Double
    @NSManaged var poiLongitude: Double
    @NSManaged var poiPhoneNumber: String?
    @NSManaged var poiPlacemark: NSObject?
    @NSManaged var poiRegionId: String?
    @NSManaged var poiRegionNotifyEnter: Bool
    @NSManaged var poiRegionNotifyExit: Bool
    @NSManaged var poiRegionRadius: Double
    @NSManaged var poiURL: String?
    @NSManaged var poiWikipediaPageId: Int64
    @NSManaged var parentGroup: GroupOfInterest?
    @NSManaged var poiWayPoints: NSSet?

}
