//
//  CategoryUtils.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 12/04/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class CategoryUtils {
    
     static let defaultGroupCategory = Category(groupCategory: CategoryIds.GroupId.defaultGroupId,
                                                categoryId: CategoryIds.CategoryId.defaultGroup.questionMarkId,
                                                icon: #imageLiteral(resourceName: "Question Mark-30"),
                                                glyph: #imageLiteral(resourceName: "Question Mark Filled-80"),
                                                localizedString: NSLocalizedString("CategoryLabelUnknown", tableName: "Categories", comment: ""))
    
     static let contactCategory = Category(groupCategory: CategoryIds.GroupId.defaultGroupId,
                                           categoryId: CategoryIds.CategoryId.defaultGroup.contactId,
                                           icon: #imageLiteral(resourceName: "Contacts-30"),
                                           glyph: #imageLiteral(resourceName: "Contacts Filled-80"),
                                           localizedString: NSLocalizedString("CategoryContacts", tableName: "Categories", comment: ""))
    
     static let wikipediaCategory = Category(groupCategory: CategoryIds.GroupId.defaultGroupId,
                                             categoryId: CategoryIds.CategoryId.defaultGroup.wikipediaId,
                                             icon: #imageLiteral(resourceName: "Wikipedia-30"),
                                             glyph: #imageLiteral(resourceName: "Wikipedia Filled-80"),
                                             localizedString: NSLocalizedString("CategoryWikipedia", tableName: "Categories", comment: ""))
    
    static func isWikipediaCategory(category:Category) -> Bool {
        return category.groupCategory == CategoryIds.GroupId.defaultGroupId && category.categoryId == CategoryIds.CategoryId.defaultGroup.wikipediaId
    }

     struct GroupCategory {
        let groupId:Int16
        let localizedString:String
    }

    struct categoryKey: Hashable {
        let groupCategory:Int16
        let categoryId:Int16
        
        var hashValue: Int {
            return groupCategory.hashValue ^ categoryId.hashValue
        }
        
        static func ==(lhs: categoryKey, rhs: categoryKey) -> Bool {
            return lhs.groupCategory == rhs.groupCategory && lhs.categoryId == rhs.categoryId
        }
    }
    
     struct Category : Hashable {
        let groupCategory:Int16
        let categoryId:Int16
        let icon:UIImage
        let glyph:UIImage
        let localizedString:String
        
        var key:categoryKey {
            return categoryKey(groupCategory:groupCategory, categoryId:categoryId)
        }

        
        var hashValue: Int {
            return groupCategory.hashValue ^ categoryId.hashValue
        }
        
        static func ==(lhs: Category, rhs: Category) -> Bool {
            return lhs.key == rhs.key
        }
    }
    
    private static var categoriesDictionary = [categoryKey:Category]()

    
    static let localSearchCategories = [
        contactCategory,
        defaultGroupCategory,
        wikipediaCategory,
        Category(groupCategory: CategoryIds.GroupId.cultureId, categoryId: CategoryIds.CategoryId.culture.movieId, icon: #imageLiteral(resourceName: "Movie-30"), glyph: #imageLiteral(resourceName: "Movie Filled-80"), localizedString:  NSLocalizedString("CategoryLabelTheater", tableName: "Categories", comment: "")),
        Category(groupCategory: CategoryIds.GroupId.cultureId, categoryId: CategoryIds.CategoryId.culture.museumId, icon: #imageLiteral(resourceName: "Museum-30"),  glyph: #imageLiteral(resourceName: "Museum Filled-80"),localizedString:  NSLocalizedString("CategoryLabelMuseum", tableName: "Categories", comment: "")),
        Category(groupCategory: CategoryIds.GroupId.cultureId, categoryId: CategoryIds.CategoryId.culture.opera, icon: #imageLiteral(resourceName: "Music Conductor-30"), glyph: #imageLiteral(resourceName: "Music Conductor Filled-80"), localizedString:  NSLocalizedString("CategoryLabelOpera", tableName: "Categories", comment: "")),
        Category(groupCategory: CategoryIds.GroupId.cultureId, categoryId: CategoryIds.CategoryId.culture.concertHallId, icon: #imageLiteral(resourceName: "Rock Music-30"), glyph: #imageLiteral(resourceName: "Rock Music Filled-80"), localizedString:  NSLocalizedString("CategoryLabelConcertHall", tableName: "Categories", comment: "")),
        Category(groupCategory: CategoryIds.GroupId.othersId, categoryId: CategoryIds.CategoryId.others.stadiumId, icon: #imageLiteral(resourceName: "Stadium-30"),  glyph: #imageLiteral(resourceName: "Stadium Filled-80") ,localizedString:  NSLocalizedString("CategoryLabelStadium", tableName: "Categories", comment: "")),
        Category(groupCategory: CategoryIds.GroupId.dailyLifeId, categoryId: CategoryIds.CategoryId.dailyLife.coffeeId, icon: #imageLiteral(resourceName: "Cup-30"),  glyph: #imageLiteral(resourceName: "Cup Filled-80"), localizedString:  NSLocalizedString("CategoryLabelCoffee", tableName: "Categories", comment: "")),
        Category(groupCategory: CategoryIds.GroupId.dailyLifeId, categoryId: CategoryIds.CategoryId.dailyLife.restaurantId, icon: #imageLiteral(resourceName: "Restaurant-30"),  glyph: #imageLiteral(resourceName: "Restaurant Filled-80"), localizedString:  NSLocalizedString("CategoryLabelRestaurant", tableName: "Categories", comment: "")),
        Category(groupCategory: CategoryIds.GroupId.dailyLifeId, categoryId: CategoryIds.CategoryId.dailyLife.pizzaId, icon: #imageLiteral(resourceName: "Pizza-30"),  glyph: #imageLiteral(resourceName: "Pizza Filled-80"), localizedString:  NSLocalizedString("CategoryLabelPizzeria", tableName: "Categories", comment: "")),
        Category(groupCategory: CategoryIds.GroupId.dailyLifeId, categoryId: CategoryIds.CategoryId.dailyLife.fastfood, icon: #imageLiteral(resourceName: "Hamburger-30"),  glyph: #imageLiteral(resourceName: "Hamburger Filled-80"), localizedString:  NSLocalizedString("CategoryLabelFastfood", tableName: "Categories", comment: "")),
        Category(groupCategory: CategoryIds.GroupId.dailyLifeId, categoryId: CategoryIds.CategoryId.dailyLife.wineBarId, icon: #imageLiteral(resourceName: "Bar-30"),  glyph: #imageLiteral(resourceName: "Bar Filled-80"), localizedString:  NSLocalizedString("CategoryLabelWineBar", tableName: "Categories", comment: "")),
        Category(groupCategory: CategoryIds.GroupId.dailyLifeId, categoryId: CategoryIds.CategoryId.dailyLife.pubId, icon: #imageLiteral(resourceName: "Bavarian Beer Mug-30"),  glyph: #imageLiteral(resourceName: "Bavarian Beer Mug Filled-80"), localizedString:  NSLocalizedString("CategoryLabelBar", tableName: "Categories", comment: "")),
        Category(groupCategory: CategoryIds.GroupId.nightLifeId, categoryId: CategoryIds.CategoryId.nightLife.dancingId, icon: #imageLiteral(resourceName: "Dancing-30"),  glyph: #imageLiteral(resourceName: "Dancing Filled-80"), localizedString:  NSLocalizedString("CategoryLabelNightClub", tableName: "Categories", comment: "")),
        Category(groupCategory: CategoryIds.GroupId.othersId, categoryId: CategoryIds.CategoryId.others.hotelId, icon: #imageLiteral(resourceName: "Bed-30"),  glyph: #imageLiteral(resourceName: "Bed Filled-80"), localizedString:  NSLocalizedString("CategoryLabelHotel", tableName: "Categories", comment: "")),
        Category(groupCategory: CategoryIds.GroupId.othersId, categoryId: CategoryIds.CategoryId.others.parkBenchId, icon: #imageLiteral(resourceName: "Park Bench-30"),  glyph: #imageLiteral(resourceName: "Park Bench Filled-80"), localizedString:  NSLocalizedString("CategoryLabelPark", tableName: "Categories", comment: "")),
        Category(groupCategory: CategoryIds.GroupId.transportationId, categoryId: CategoryIds.CategoryId.transportation.airportId, icon: #imageLiteral(resourceName: "Airport-30"),  glyph: #imageLiteral(resourceName: "Airport Filled-80"), localizedString:  NSLocalizedString("CategoryLabelAirport", tableName: "Categories", comment: "")),
        Category(groupCategory: CategoryIds.GroupId.transportationId, categoryId: CategoryIds.CategoryId.transportation.railwayStationId, icon: #imageLiteral(resourceName: "City Railway Station-30"),  glyph: #imageLiteral(resourceName: "City Railway Station Filled-80"), localizedString:  NSLocalizedString("CategoryLabelStation", tableName: "Categories", comment: "")),
        Category(groupCategory: CategoryIds.GroupId.transportationId, categoryId: CategoryIds.CategoryId.transportation.gasStationId, icon: #imageLiteral(resourceName: "Gas Station-30"), glyph: #imageLiteral(resourceName: "Gas Station Filled-80"), localizedString:  NSLocalizedString("CategoryLabelGasStation", tableName: "Categories", comment: "")),
        Category(groupCategory: CategoryIds.GroupId.transportationId, categoryId: CategoryIds.CategoryId.transportation.parkingId, icon: #imageLiteral(resourceName: "Parking-30"),  glyph: #imageLiteral(resourceName: "Parking Filled-80"), localizedString:  NSLocalizedString("CategoryLabelParking", tableName: "Categories", comment: "")),
        Category(groupCategory: CategoryIds.GroupId.shoppingId, categoryId: CategoryIds.CategoryId.shopping.aTMId, icon: #imageLiteral(resourceName: "ATM-30"),  glyph: #imageLiteral(resourceName: "ATM Filled-80"), localizedString:  NSLocalizedString("CategoryLabelATM", tableName: "Categories", comment: "")),
        Category(groupCategory: CategoryIds.GroupId.shoppingId, categoryId: CategoryIds.CategoryId.shopping.bankId, icon: #imageLiteral(resourceName: "Bank-30"),  glyph: #imageLiteral(resourceName: "Bank Filled-80"), localizedString:  NSLocalizedString("CategoryLabelBank", tableName: "Categories", comment: "")),
        Category(groupCategory: CategoryIds.GroupId.shoppingId, categoryId: CategoryIds.CategoryId.shopping.shoppingCenterId, icon: #imageLiteral(resourceName: "Shopping Bag-30"),  glyph: #imageLiteral(resourceName: "Shopping Bag Filled-80"), localizedString:  NSLocalizedString("CategoryLabelShopping", tableName: "Categories", comment: "")),
        Category(groupCategory: CategoryIds.GroupId.othersId, categoryId: CategoryIds.CategoryId.others.caduceusId, icon: #imageLiteral(resourceName: "Caduceus-30"),  glyph: #imageLiteral(resourceName: "Caduceus Filled-80"), localizedString:  NSLocalizedString("CategoryLabelPharmacy", tableName: "Categories", comment: "")),
        Category(groupCategory: CategoryIds.GroupId.othersId, categoryId: CategoryIds.CategoryId.others.hospitalId, icon: #imageLiteral(resourceName: "Hospital 3-30"),  glyph: #imageLiteral(resourceName: "Hospital 3 Filled-80"), localizedString:  NSLocalizedString("CategoryLabelHospital", tableName: "Categories", comment: "")),
        Category(groupCategory: CategoryIds.GroupId.othersId, categoryId: CategoryIds.CategoryId.others.courtHouseId, icon: #imageLiteral(resourceName: "Courthouse-30"),  glyph: #imageLiteral(resourceName: "Courthouse Filled-80"), localizedString:  NSLocalizedString("CategoryLabelCourtHouse", tableName: "Categories", comment: "")),
   ]
    
    fileprivate static let groups = [GroupCategory(groupId: CategoryIds.GroupId.defaultGroupId, localizedString: "Default"),
                                     GroupCategory(groupId: CategoryIds.GroupId.cultureId, localizedString: "culture"),
                                     GroupCategory(groupId: CategoryIds.GroupId.dailyLifeId, localizedString: "Daily life"),
                                     GroupCategory(groupId: CategoryIds.GroupId.nightLifeId, localizedString: "Night life"),
                                     GroupCategory(groupId: CategoryIds.GroupId.othersId, localizedString: "Others"),
                                     GroupCategory(groupId: CategoryIds.GroupId.shoppingId, localizedString: "Shopping"),
                                     GroupCategory(groupId: CategoryIds.GroupId.transportationId, localizedString: "Transportation")]
    
    

    
    
    static func findCategory(groupCategory:Int16, categoryId:Int16) -> Category? {
        if categoriesDictionary.isEmpty {
            for currentCategory in localSearchCategories {
                categoriesDictionary[currentCategory.key] = currentCategory
            }
        }
        return categoriesDictionary[categoryKey(groupCategory: groupCategory, categoryId: categoryId)]
    }
    
    static func getCategory(groupCategory:Int16, categoryId:Int16) -> Category {
        if let category = findCategory(groupCategory: groupCategory, categoryId: categoryId) {
            return category
        } else {
            return defaultGroupCategory
        }
    }

    
    static func getIndex(category:Category, inCategories:[Category]) -> Int? {
        var index = 0
        for currentCategory in inCategories {
            if currentCategory == category {
                return index
            }
            index += 1
        }
        return nil
    }
    
    static func findCategory(groupCategory:Int16, categoryId:Int16, inCategories:[Category]) -> Category? {
        for currentCategory in inCategories {
            if currentCategory.groupCategory == groupCategory && currentCategory.categoryId == categoryId {
                return currentCategory
            }
        }

        return nil
    }
}
