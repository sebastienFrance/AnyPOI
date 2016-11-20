//
//  MapFilter.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 13/11/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class MapFilter {
    
    
    fileprivate var filter:Set<CategoryUtils.Category>!
    
    init(initialFilter:Set<CategoryUtils.Category>) {
        filter = initialFilter
    }
    
    func add(category:CategoryUtils.Category) {
        if !filter.contains(category) {
            filter.insert(category)
        }
    }
    
    func remove(category:CategoryUtils.Category) {
        filter.remove(category)
    }
    
    func isFiletered(category:CategoryUtils.Category) -> Bool {
        return filter.contains(category)
    }
    
}
