//
//  PointOfInterest.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 17/09/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(PointOfInterest)
class PointOfInterest : NSManagedObject {
    
    
    var category:CategoryUtils.Category! {
        get {
            return CategoryUtils.Category(groupCategory: CategoryUtils.GroupId.othersId, categoryId: CategoryUtils.CategoryId.others.courtHouseId, icon: #imageLiteral(resourceName: "Courthouse-30"),  glyph: #imageLiteral(resourceName: "Courthouse Filled-80"), localizedString:  NSLocalizedString("CategoryLabelCourtHouse", tableName: "Categories", comment: ""))
            //return CategoryUtils.getCategory(groupCategory: poiGroupCategory, categoryId: poiCategory)
        }
        set {
            poiGroupCategory = newValue.groupCategory
            poiCategory = newValue.categoryId
        }
    }
    
    
    var glyphImage:UIImage {
        return category.glyph
    }

}
