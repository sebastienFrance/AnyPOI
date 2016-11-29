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

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

@objc(GroupOfInterest)
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
            return NSKeyedUnarchiver.unarchiveObject(with: groupColor as! Data) as! UIColor
        }
        set {
            groupColor = NSKeyedArchiver.archivedData(withRootObject: newValue) as NSObject?
            GroupOfInterest.resetImageForGroup(self)
        }
    }

    var pois: [PointOfInterest] {
        get {
            if let allPois = listOfPOIs {
                let pois = allPois.allObjects as! [PointOfInterest]
                return pois.sorted { $0.poiDisplayName < $1.poiDisplayName }
            } else {
                return [PointOfInterest]()
            }
        }
    }
    
    func initializeWith(_ id: Int, name:String, description:String, color newColor:UIColor, isDisplayed:Bool = true) {
        isPrivate = false
        groupId = Int64(id)
        groupDisplayName = name
        groupDescription = description
        isGroupDisplayed = isDisplayed
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
    
    fileprivate static var imagesCacheForGroup = [NSManagedObjectID:UIImage]()
    fileprivate static var pinImagesCacheForGroup = [NSManagedObjectID:UIImage?]()
    
    fileprivate static func resetImageForGroup(_ group:GroupOfInterest, imageSize:CGFloat = 25.0) {
        imagesCacheForGroup[group.objectID] = createImageForGroup(group, imageSize: imageSize)
    }
    
    fileprivate static func getImageForGroup(_ group:GroupOfInterest, imageSize:CGFloat = 25.0) -> UIImage {
        if let image = imagesCacheForGroup[group.objectID] {
            return image
        } else {
            imagesCacheForGroup[group.objectID] = createImageForGroup(group, imageSize: imageSize)
            return imagesCacheForGroup[group.objectID]!
        }
    }
    
    
    fileprivate static func getPinImageForGroup(_ group:GroupOfInterest, imageSize:CGFloat = 25.0) -> UIImage? {
        if let image = pinImagesCacheForGroup[group.objectID] {
            return image
        } else {
            pinImagesCacheForGroup[group.objectID] = createPinImageForGroup(group, imageSize: imageSize)
            return pinImagesCacheForGroup[group.objectID]!
        }
    }

    
    fileprivate static func createImageForGroup(_ group:GroupOfInterest, imageSize:CGFloat = 25.0, lineWidth:CGFloat = 1.0) -> UIImage {
        let size = CGSize(width: imageSize, height: imageSize)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let background = CAShapeLayer()
        let rect = CGRect(x: lineWidth / 2.0,
                              y: lineWidth / 2.0,
                              width: imageSize - (lineWidth),height: imageSize - (lineWidth))
        let path = UIBezierPath(ovalIn: rect)
        background.path = path.cgPath
        background.fillColor = group.color.cgColor
        background.strokeColor = UIColor.black.cgColor
        background.lineWidth = lineWidth
        background.setNeedsDisplay()
        background.render(in: UIGraphicsGetCurrentContext()!)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    fileprivate static func createPinImageForGroup(_ group:GroupOfInterest, imageSize:CGFloat = 25.0) -> UIImage? {
        let annotationView = MKPinAnnotationView(frame: CGRect(x: 0, y: 0, width: imageSize, height: imageSize))
        annotationView.pinTintColor = group.color
        return annotationView.image
    }
 }

