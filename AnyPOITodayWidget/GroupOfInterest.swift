//
//  GroupOfInterest.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 17/09/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import UIKit

import CoreData
@objc(GroupOfInterest)
class GroupOfInterest : NSManagedObject {
    
    var color: UIColor {
        return NSKeyedUnarchiver.unarchiveObject(with: groupColor as! Data) as! UIColor
    }

}
