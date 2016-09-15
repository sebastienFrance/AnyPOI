//
//  CategoryUtils.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 12/04/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class CategoryUtils {
    
     private static let categoryIcons = ["Question Mark-40", "Cup-40", "Restaurant-40", "Bar-40", "Bavarian Beer Mug-40", "Museum-40", "Dancing-40", "City Railway Station-40", "Theatre Mask-40",
                         "Hospital 3-40", "Caduceus-40", "Cathedral-40", "Stadium-40", "Gas Station-40", "Courthouse-40", "Airport-40", "Movie-40", "Park Bench-40",
                         "Parking-40", "Pizza-40", "ATM-40", "Bank-40", "Shopping Bag-40", "Hotel Information-40"]
     private static let categoryLabel = ["Inconnue", "Café", "Restaurant", "Bar à vin", "Bar", "Musée", "Night club", "Gare", "Theatre",
                         "Hopital", "Pharmacie", "Eglise", "Stade", "Station essence", "Palais de justice", "Aéroport", "Cinémas", "Parc",
                         "Parking", "Pizzeria", "Distributeur", "Banque", "Shopping", "Hotel"]

    
    static let EmptyCategoryIndex = 0
    static let WikipediaCategoryIndex = 10000
    
    static func getCategoryCount() -> Int {
        return CategoryUtils.categoryIcons.count
    }
    
    static func getCategoryForIndex(index:Int) -> (icon:UIImage?, label:String?) {
        if case 0 ..< getCategoryCount() = index {
            return (UIImage(named: CategoryUtils.categoryIcons[index]), CategoryUtils.categoryLabel[index])
        } else {
            return (nil,"")
        }
    }
    
    static func getIconCategoryForIndex(index:Int) -> UIImage? {
        if case 0 ..< getCategoryCount() = index {
            return UIImage(named: CategoryUtils.categoryIcons[index])
        } else {
            return nil
        }
    }
    
    static func getLabelCategoryForIndex(index:Int) -> String {
        if case 0 ..< getCategoryCount() = index {
            return CategoryUtils.categoryLabel[index]
        } else {
            return ""
        }
    }
    
    static func getAllCategoriesLabel() -> [String] {
        return CategoryUtils.categoryLabel
    }

    static func isEmptyCategory(categoryIndex:Int) -> Bool {
        return categoryIndex == EmptyCategoryIndex ? true : false
    }
    
    static func isWikipediaCategory(categoryIndex:Int) -> Bool {
        return categoryIndex == WikipediaCategoryIndex ? true : false 
    }
    
    static func getWikipediaCategory() -> (icon:UIImage?, label:String?) {
        return (UIImage(named: "Wikipedia-40") , "Wikipedia")
    }
    
}
