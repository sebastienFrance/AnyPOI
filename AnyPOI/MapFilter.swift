//
//  MapFilter.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 13/11/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class MapFilter {
    
    
    var filter = Set<Int16>()
    
    func add(category:Int16) {
        if !filter.contains(category) {
            filter.insert(category)
        }
    }
    
    func remove(category:Int16) {
        filter.remove(category)
    }
    
    func isFiletered(category:Int16) -> Bool {
        return filter.contains(category)
    }
    
}
