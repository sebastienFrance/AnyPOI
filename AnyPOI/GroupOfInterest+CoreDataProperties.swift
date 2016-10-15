//
//  GroupOfInterest+CoreDataProperties.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 15/10/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import CoreData


extension GroupOfInterest {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GroupOfInterest> {
        return NSFetchRequest<GroupOfInterest>(entityName: "GroupOfInterest");
    }

    @NSManaged public var groupColor: NSObject?
    @NSManaged public var groupDescription: String?
    @NSManaged public var groupDisplayName: String?
    @NSManaged public var groupId: Int64
    @NSManaged public var isGroupDisplayed: Bool
    @NSManaged public var isPrivate: Bool
    @NSManaged public var listOfPOIs: NSSet?

}

// MARK: Generated accessors for listOfPOIs
extension GroupOfInterest {

    @objc(addListOfPOIsObject:)
    @NSManaged public func addToListOfPOIs(_ value: PointOfInterest)

    @objc(removeListOfPOIsObject:)
    @NSManaged public func removeFromListOfPOIs(_ value: PointOfInterest)

    @objc(addListOfPOIs:)
    @NSManaged public func addToListOfPOIs(_ values: NSSet)

    @objc(removeListOfPOIs:)
    @NSManaged public func removeFromListOfPOIs(_ values: NSSet)

}
