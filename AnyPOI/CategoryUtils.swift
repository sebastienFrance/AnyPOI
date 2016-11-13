//
//  CategoryUtils.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 12/04/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class CategoryUtils {
    
     fileprivate static let categoryIcons = ["Question Mark-40",
                                         "Cup-40",
                                         "Restaurant-40",
                                         "Pizza-40",
                                         "Bar-40",
                                         "Bavarian Beer Mug-40",
                                         "Movie-40",
                                         "Museum-40",
                                         "Dancing-40",
                                         "Theatre Mask-40",
                                         "Stadium-40",
                                         "Park Bench-40",
                                         "Hotel Information-40",
                                         "City Railway Station-40",
                                         "Airport-40",
                                         "Hospital 3-40",
                                         "Caduceus-40",
                                         "Cathedral-40",
                                         "Gas Station-40",
                                         "Courthouse-40",
                                         "Parking-40",
                                         "ATM-40",
                                         "Bank-40",
                                         "Shopping Bag-40"]

    fileprivate static let categoryFromIcons = ["Question Mark-40" : NSLocalizedString("CategoryLabelUnknown", comment: ""),
                                            "Cup-40" : NSLocalizedString("CategoryLabelCoffee", comment: ""),
                                            "Restaurant-40" : NSLocalizedString("CategoryLabelRestaurant", comment: ""),
                                            "Bar-40" : NSLocalizedString("CategoryLabelWineBar", comment: ""),
                                            "Bavarian Beer Mug-40" : NSLocalizedString("CategoryLabelBar", comment: ""),
                                            "Museum-40" : NSLocalizedString("CategoryLabelMuseum", comment: ""),
                                            "Dancing-40":  NSLocalizedString("CategoryLabelNightClub", comment: ""),
                                            "City Railway Station-40" : NSLocalizedString("CategoryLabelStation", comment: ""),
                                            "Theatre Mask-40" : NSLocalizedString("CategoryLabelOpera", comment: ""),
                                            "Hospital 3-40" : NSLocalizedString("CategoryLabelHospital", comment: ""),
                                            "Caduceus-40" : NSLocalizedString("CategoryLabelPharmacy", comment: ""),
                                            "Cathedral-40" : NSLocalizedString("CategoryLabelChurch", comment: ""),
                                            "Stadium-40" : NSLocalizedString("CategoryLabelStadium", comment: ""),
                                            "Gas Station-40" : NSLocalizedString("CategoryLabelGasStation", comment: ""),
                                            "Courthouse-40" : NSLocalizedString("CategoryLabelCourtHouse", comment: ""),
                                            "Airport-40" : NSLocalizedString("CategoryLabelAirport", comment: ""),
                                            "Movie-40" : NSLocalizedString("CategoryLabelTheater", comment: ""),
                                            "Park Bench-40" : NSLocalizedString("CategoryLabelPark", comment: ""),
                                            "Parking-40" : NSLocalizedString("CategoryLabelParking", comment: ""),
                                            "Pizza-40" : NSLocalizedString("CategoryLabelPizzeria", comment: ""),
                                            "ATM-40" : NSLocalizedString("CategoryLabelATM", comment: ""),
                                            "Bank-40" : NSLocalizedString("CategoryLabelBank", comment: ""),
                                            "Shopping Bag-40" : NSLocalizedString("CategoryLabelShopping", comment: ""),
                                            "Hotel Information-40" : NSLocalizedString("CategoryLabelHotel", comment: "")]
    
    static let EmptyCategoryIndex = 0
    
    struct Wikipedia {
        static let categoryIndex = 10000
        fileprivate static let label = "Wikipedia"
        fileprivate static let image = UIImage(named: "Wikipedia-40")
    }
    
    static func getCount() -> Int {
        return CategoryUtils.categoryIcons.count
    }
    
    static func getIconAndLabel(index:Int) -> (icon:UIImage?, label:String?) {
        if case 0 ..< getCount() = index {
            return (UIImage(named: CategoryUtils.categoryIcons[index]), CategoryUtils.categoryFromIcons[CategoryUtils.categoryIcons[index]])
        } else {
            if index == Wikipedia.categoryIndex {
                return getWikipediaCategory()
            } else {
                return (nil,"")
            }
        }
    }
    
    static func getIcon(index:Int) -> UIImage? {
        if case 0 ..< getCount() = index {
            return UIImage(named: CategoryUtils.categoryIcons[index])
        } else  if index == Wikipedia.categoryIndex {
            return Wikipedia.image
        } else {
            return nil
        }
    }
    
    static func getLabel(index:Int) -> String {
        if case 0 ..< getCount() = index {
            return CategoryUtils.categoryFromIcons[CategoryUtils.categoryIcons[index]]!
        } else if index == Wikipedia.categoryIndex {
            return Wikipedia.label
        } else {
            return ""
        }
    }
    
    static func getAllLabels() -> [String] {
        var categories = [String]()
        for category in categoryIcons {
            categories.append(CategoryUtils.categoryFromIcons[category]!)
        }
        
        return categories
    }

    static func isEmptyCategory(_ categoryIndex:Int) -> Bool {
        return categoryIndex == EmptyCategoryIndex ? true : false
    }
    
    static func isWikipediaCategory(_ categoryIndex:Int) -> Bool {
        return categoryIndex == Wikipedia.categoryIndex ? true : false
    }
    
    static func getWikipediaCategory() -> (icon:UIImage?, label:String?) {
        return (Wikipedia.image, Wikipedia.label)
    }
    
}
