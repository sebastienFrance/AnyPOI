//
//  CommonProps.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 14/10/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import Foundation
import UIKit

struct CommonProps {
    
    struct userLocation {
        static let latitude = "lat"
        static let longitude = "long"
    }
    
    static let listOfPOIs = "pois"
    static let maxRadius = "maxRadius"
    static let maxResults = "maxRes"
    
    struct POI {
        static let title = "title"
        static let address = "address"
        static let categoryId = "catId"
        static let groupCategory = "group"
        static let color = "color"
        static let distance = "dist"
        static let latitude = "lat"
        static let longitude = "long"
    }
    
    static func categoryFrom(props:[String:String]) -> CategoryUtils.Category? {
        if let groupCategory = props[CommonProps.POI.groupCategory], let categoryId = props[CommonProps.POI.categoryId] {
            if let groupCategoryInt = Int16(groupCategory),
                let categoryIdInt = Int16(categoryId) {
                return CategoryUtils.findCategory(groupCategory: groupCategoryInt, categoryId: categoryIdInt, inCategories: CategoryUtils.localSearchCategories)
            }
        }
        
        return nil
    }
    
    static func poiColorFrom(props:[String:String]) -> UIColor? {
        if let colorString = props[CommonProps.POI.color] {
            return  ColorsUtils.getColor(rgba: colorString)
        }
        return nil
    }

}