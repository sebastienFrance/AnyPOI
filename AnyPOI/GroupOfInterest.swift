//
//  GroupOfInterest.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 20/12/2015.
//  Copyright © 2015 Sébastien Brugalières. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import MapKit

class GroupOfInterest: NSManagedObject {

    struct properties {
        static let groupId = "groupId"
        static let groupDisplayName = "groupDisplayName"
        static let groupDescription = "groupDescription"
        static let isGroupDisplayed = "isGroupDisplayed"
        static let groupColor = "groupColor"
    }

    var color: UIColor {
        get {
            return NSKeyedUnarchiver.unarchiveObjectWithData(groupColor as! NSData) as! UIColor
        }
        set {
            groupColor = NSKeyedArchiver.archivedDataWithRootObject(newValue)
            GroupOfInterest.resetImageForGroup(self)
        }
    }

    var pois: [PointOfInterest] {
        get {
            if let allPois = listOfPOIs {
                let pois = allPois.allObjects as! [PointOfInterest]
                return pois.sort { $0.poiDisplayName < $1.poiDisplayName }
            } else {
                return [PointOfInterest]()
            }
        }
    }
    
    func initializeWith(id: Int, name:String, description:String, color newColor:UIColor) {
        isPrivate = false
        groupId = Int64(id)
        groupDisplayName = name
        groupDescription = description
        isGroupDisplayed = true
        self.color = newColor
    }
    
    var iconImage: UIImage {
        get {
             return GroupOfInterest.getImageForGroup(self)
        }
    }
    
    var pinImage: UIImage? {
        get {
            return GroupOfInterest.getPinImageForGroup(self)
        }
    }
    
    private static var imagesCacheForGroup = [NSManagedObjectID:UIImage]()
    private static var pinImagesCacheForGroup = [NSManagedObjectID:UIImage?]()
    
    private static func resetImageForGroup(group:GroupOfInterest, imageSize:CGFloat = 25.0) {
        imagesCacheForGroup[group.objectID] = createImageForGroup(group, imageSize: imageSize)
    }
    
    private static func getImageForGroup(group:GroupOfInterest, imageSize:CGFloat = 25.0) -> UIImage {
        if let image = imagesCacheForGroup[group.objectID] {
            return image
        } else {
            imagesCacheForGroup[group.objectID] = createImageForGroup(group, imageSize: imageSize)
            return imagesCacheForGroup[group.objectID]!
        }
    }
    
    private static func getPinImageForGroup(group:GroupOfInterest, imageSize:CGFloat = 25.0) -> UIImage? {
        if let image = pinImagesCacheForGroup[group.objectID] {
            return image
        } else {
            pinImagesCacheForGroup[group.objectID] = createPinImageForGroup(group, imageSize: imageSize)
            return pinImagesCacheForGroup[group.objectID]!
        }
    }

    
    private static func createImageForGroup(group:GroupOfInterest, imageSize:CGFloat = 25.0, lineWidth:CGFloat = 1.0) -> UIImage {
        let size = CGSizeMake(imageSize, imageSize)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let background = CAShapeLayer()
        let rect = CGRectMake(lineWidth / 2.0,
                              lineWidth / 2.0,
                              imageSize - (lineWidth),imageSize - (lineWidth))
        let path = UIBezierPath(ovalInRect: rect)
        background.path = path.CGPath
        background.fillColor = group.color.CGColor
        background.strokeColor = UIColor.blackColor().CGColor
        background.lineWidth = lineWidth
        background.setNeedsDisplay()
        background.renderInContext(UIGraphicsGetCurrentContext()!)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    private static func createPinImageForGroup(group:GroupOfInterest, imageSize:CGFloat = 25.0) -> UIImage? {
        let annotationView = MKPinAnnotationView(frame: CGRectMake(0, 0, imageSize, imageSize))
        annotationView.pinTintColor = group.color
        return annotationView.image
    }
 }

