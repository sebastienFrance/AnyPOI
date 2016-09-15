//
//  PoiNotificationUserInfo.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 12/03/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import CoreData

class PoiNotificationUserInfo {
    
    var updatedPois = [PointOfInterest]()
    var updatedGroupOfInterest = [GroupOfInterest]()
    var updatedWayPoints = [WayPoint]()
    var updatedRoutes = [Route]()
 
    var deletedPois = [PointOfInterest]()
    var deletedGroupOfInterest = [GroupOfInterest]()
    var deletedWayPoints = [WayPoint]()
    var deletedRoutes = [Route]()

    var insertedPois = [PointOfInterest]()
    var insertedGroupOfInterest = [GroupOfInterest]()
    var insertedWayPoints = [WayPoint]()
    var insertedRoutes = [Route]()

    
    init(userInfo: [NSObject : AnyObject]?) {
        if let theUserInfo = userInfo {
            processInsertedObjects(theUserInfo)
            processDeletedObjects(theUserInfo)
            processUpdatedObjects(theUserInfo)
        }
    }
    
    func processInsertedObjects(userInfo:[NSObject : AnyObject]) {
        if let insertedValues = userInfo[NSInsertedObjectsKey] as? NSSet  {
            for currentObject in insertedValues {
                if currentObject is PointOfInterest {
                    insertedPois.append(currentObject as! PointOfInterest)
                } else if currentObject is GroupOfInterest {
                    insertedGroupOfInterest.append(currentObject as! GroupOfInterest)
                } else if currentObject is WayPoint {
                    insertedWayPoints.append(currentObject as! WayPoint)
                } else if currentObject is Route {
                    insertedRoutes.append(currentObject as! Route)
                }
            }
        }
     
    }
    
    func processDeletedObjects(userInfo:[NSObject : AnyObject]) {
        if let insertedValues = userInfo[NSDeletedObjectsKey] as? NSSet  {
            for currentObject in insertedValues {
                if currentObject is PointOfInterest {
                    deletedPois.append(currentObject as! PointOfInterest)
                } else if currentObject is GroupOfInterest {
                    deletedGroupOfInterest.append(currentObject as! GroupOfInterest)
                } else if currentObject is WayPoint {
                    deletedWayPoints.append(currentObject as! WayPoint)
                } else if currentObject is Route {
                    deletedRoutes.append(currentObject as! Route)
                }
            }
        }
    }
    
    func processUpdatedObjects(userInfo:[NSObject : AnyObject]) {
        if let insertedValues = userInfo[NSUpdatedObjectsKey] as? NSSet  {
            for currentObject in insertedValues {
                if currentObject is PointOfInterest {
                    updatedPois.append(currentObject as! PointOfInterest)
                } else if currentObject is GroupOfInterest {
                    updatedGroupOfInterest.append(currentObject as! GroupOfInterest)
                } else if currentObject is WayPoint {
                    updatedWayPoints.append(currentObject as! WayPoint)
                } else if currentObject is Route {
                    updatedRoutes.append(currentObject as! Route)
                }
            }
        }
    }

    static func dumpUserInfo(title:String, userInfo: [NSObject : AnyObject]?) {
        print("============> \(title)")
        if let theUserInfo = userInfo {
            if let insertedValues = theUserInfo[NSInsertedObjectsKey] as? NSSet  {
                dumpObjects(insertedValues, title: "Inserted")
            }
            if let deletedValues = theUserInfo[NSDeletedObjectsKey] as? NSSet {
                dumpObjects(deletedValues, title: "Deleted")
            }
            if let updatedValues = theUserInfo[NSUpdatedObjectsKey] as? NSSet {
                dumpObjects(updatedValues, title: "Updated")
            }
        }
    }
    
    private static func dumpObjects(objects: NSSet, title:String) {
        if objects.count > 0 {
            print("\(title) has count(\(objects.count)) objects")
            for currentObject in objects {
                print("\(title): \(getObjectClass(currentObject))")
            }
        }
    }
    
    private static func getObjectClass(theObject:AnyObject) -> String {
        if theObject is PointOfInterest {
            return "PoinfOfInterest \((theObject as! PointOfInterest).poiDisplayName)"
        } else if theObject is WayPoint {
            return "WayPoint \((theObject as! WayPoint).wayPointPoi?.poiDisplayName) from route \((theObject as! WayPoint).wayPointParent?.routeName) "
        } else if theObject is GroupOfInterest {
            return "GroupOfInterest \((theObject as! GroupOfInterest).groupDisplayName)"
        } else if theObject is Route {
            return "Route \((theObject as! Route).routeName)"
        } else {
            return "unknown object"
        }
        
    }


}