//
//  CategoryUtils.swift
//  SimplePOI
//
//  Created by Sébastien Brugalières on 12/04/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import UIKit

class CategoryUtils {
    
     static let defaultGroupCategory = Category(groupCategory: GroupId.defaultGroupId, categoryId: CategoryId.defaultGroup.questionMarkId, icon: #imageLiteral(resourceName: "Question Mark-30"), localizedString: NSLocalizedString("CategoryLabelUnknown", comment: ""))
     static let contactCategory = Category(groupCategory: GroupId.defaultGroupId, categoryId: CategoryId.defaultGroup.contactId, icon: #imageLiteral(resourceName: "Contacts-30"), localizedString: "Contact")
     static let wikipediaCategory = Category(groupCategory: GroupId.defaultGroupId, categoryId: CategoryId.defaultGroup.wikipediaId, icon: #imageLiteral(resourceName: "Wikipedia-30"), localizedString: "Wikipedia")
    
    static func isWikipediaCategory(category:Category) -> Bool {
        return category.groupCategory == GroupId.defaultGroupId && category.categoryId == CategoryId.defaultGroup.wikipediaId
    }
    
    fileprivate struct GroupId {
        static let defaultGroupId = Int16(0)
        static let cultureId = Int16(1)
        static let dailyLifeId = Int16(2)
        static let nightLifeId = Int16(3)
        static let transportationId = Int16(4)
        static let shoppingId = Int16(5)
        static let othersId = Int16(6)
    }
    
    fileprivate struct CategoryId {
        struct defaultGroup {
            static let questionMarkId = Int16(0)
            static let wikipediaId = Int16(1)
            static let contactId = Int16(2)
        }
        struct culture {
            static let movieId = Int16(100)
            static let museumId = Int16(101)
            static let theatreId = Int16(102)
            static let opera = Int16(103)
            static let concertHallId = Int16(104)
        }
        
        struct dailyLife {
            static let coffeeId = Int16(200)
            static let restaurantId = Int16(201)
            static let pizzaId = Int16(202)
            static let barId = Int16(203)
            static let pubId = Int16(204)
            static let wineBarId = Int16(205)
            static let fastfood = Int16(206)
        }
        
        struct nightLife {
            static let dancingId = Int16(300)
        }
        
        struct transportation {
            static let parkingId = Int16(400)
            static let railwayStationId = Int16(401)
            static let airportId = Int16(402)
            static let gasStationId = Int16(403)
        }
        
        struct shopping {
            static let aTMId = Int16(500)
            static let bankId = Int16(501)
            static let shoppingCenterId = Int16(502)
            
        }
        
        struct others {
            static let cathedralId = Int16(600)
            static let courtHouseId = Int16(601)
            static let caduceusId = Int16(602)
            static let hospitalId = Int16(603)
            static let hotelId = Int16(604)
            static let parkBenchId = Int16(605)
            static let stadiumId = Int16(606)
        }
    }
    
     struct GroupCategory {
        let groupId:Int16
        let localizedString:String
    }

    
     struct Category : Hashable {
        let groupCategory:Int16
        let categoryId:Int16
        let icon:UIImage
        let localizedString:String
        
        var hashValue: Int {
            return groupCategory.hashValue ^ categoryId.hashValue
        }
        
        static func ==(lhs: Category, rhs: Category) -> Bool {
            return lhs.groupCategory == rhs.groupCategory && lhs.categoryId == rhs.categoryId
        }
    }
    

    
    static let localSearchCategories = [
        contactCategory,
        defaultGroupCategory,
        wikipediaCategory,
        Category(groupCategory: GroupId.cultureId, categoryId: CategoryId.culture.movieId, icon: #imageLiteral(resourceName: "Movie-30"), localizedString:  NSLocalizedString("CategoryLabelTheater", comment: "")),
        Category(groupCategory: GroupId.cultureId, categoryId: CategoryId.culture.museumId, icon: #imageLiteral(resourceName: "Museum-30"), localizedString:  NSLocalizedString("CategoryLabelMuseum", comment: "")),
        Category(groupCategory: GroupId.cultureId, categoryId: CategoryId.culture.opera, icon: #imageLiteral(resourceName: "Music Conductor-30"), localizedString:  NSLocalizedString("CategoryLabelOpera", comment: "")),
        Category(groupCategory: GroupId.cultureId, categoryId: CategoryId.culture.concertHallId, icon: #imageLiteral(resourceName: "Rock Music-30"), localizedString:  NSLocalizedString("CategoryLabelConcertHall", comment: "")),
        Category(groupCategory: GroupId.othersId, categoryId: CategoryId.others.stadiumId, icon: #imageLiteral(resourceName: "Stadium-30"), localizedString:  NSLocalizedString("CategoryLabelStadium", comment: "")),
        Category(groupCategory: GroupId.dailyLifeId, categoryId: CategoryId.dailyLife.coffeeId, icon: #imageLiteral(resourceName: "Cup-30"), localizedString:  NSLocalizedString("CategoryLabelCoffee", comment: "")),
        Category(groupCategory: GroupId.dailyLifeId, categoryId: CategoryId.dailyLife.restaurantId, icon: #imageLiteral(resourceName: "Restaurant-30"), localizedString:  NSLocalizedString("CategoryLabelRestaurant", comment: "")),
        Category(groupCategory: GroupId.dailyLifeId, categoryId: CategoryId.dailyLife.pizzaId, icon: #imageLiteral(resourceName: "Pizza-30"), localizedString:  NSLocalizedString("CategoryLabelPizzeria", comment: "")),
        Category(groupCategory: GroupId.dailyLifeId, categoryId: CategoryId.dailyLife.fastfood, icon: #imageLiteral(resourceName: "Hamburger-30"), localizedString:  NSLocalizedString("CategoryLabelFastfood", comment: "")),
        Category(groupCategory: GroupId.dailyLifeId, categoryId: CategoryId.dailyLife.wineBarId, icon: #imageLiteral(resourceName: "Bar-30"), localizedString:  NSLocalizedString("CategoryLabelWineBar", comment: "")),
        Category(groupCategory: GroupId.dailyLifeId, categoryId: CategoryId.dailyLife.pubId, icon: #imageLiteral(resourceName: "Bavarian Beer Mug-30"), localizedString:  NSLocalizedString("CategoryLabelBar", comment: "")),
        Category(groupCategory: GroupId.nightLifeId, categoryId: CategoryId.nightLife.dancingId, icon: #imageLiteral(resourceName: "Dancing-30"), localizedString:  NSLocalizedString("CategoryLabelNightClub", comment: "")),
        Category(groupCategory: GroupId.othersId, categoryId: CategoryId.others.hotelId, icon: #imageLiteral(resourceName: "Bed-30"), localizedString:  NSLocalizedString("CategoryLabelHotel", comment: "")),
        Category(groupCategory: GroupId.othersId, categoryId: CategoryId.others.parkBenchId, icon: #imageLiteral(resourceName: "Park Bench-30"), localizedString:  NSLocalizedString("CategoryLabelPark", comment: "")),
        Category(groupCategory: GroupId.transportationId, categoryId: CategoryId.transportation.airportId, icon: #imageLiteral(resourceName: "Airport-30"), localizedString:  NSLocalizedString("CategoryLabelAirport", comment: "")),
        Category(groupCategory: GroupId.transportationId, categoryId: CategoryId.transportation.railwayStationId, icon: #imageLiteral(resourceName: "City Railway Station-30"), localizedString:  NSLocalizedString("CategoryLabelStation", comment: "")),
        Category(groupCategory: GroupId.transportationId, categoryId: CategoryId.transportation.gasStationId, icon: #imageLiteral(resourceName: "Gas Station-30"), localizedString:  NSLocalizedString("CategoryLabelGasStation", comment: "")),
        Category(groupCategory: GroupId.transportationId, categoryId: CategoryId.transportation.parkingId, icon: #imageLiteral(resourceName: "Parking-30"), localizedString:  NSLocalizedString("CategoryLabelParking", comment: "")),
        Category(groupCategory: GroupId.shoppingId, categoryId: CategoryId.shopping.aTMId, icon: #imageLiteral(resourceName: "ATM-30"), localizedString:  NSLocalizedString("CategoryLabelATM", comment: "")),
        Category(groupCategory: GroupId.shoppingId, categoryId: CategoryId.shopping.bankId, icon: #imageLiteral(resourceName: "Bank-30"), localizedString:  NSLocalizedString("CategoryLabelBank", comment: "")),
        Category(groupCategory: GroupId.shoppingId, categoryId: CategoryId.shopping.shoppingCenterId, icon: #imageLiteral(resourceName: "Shopping Bag-30"), localizedString:  NSLocalizedString("CategoryLabelShopping", comment: "")),
        Category(groupCategory: GroupId.othersId, categoryId: CategoryId.others.caduceusId, icon: #imageLiteral(resourceName: "Caduceus-30"), localizedString:  NSLocalizedString("CategoryLabelPharmacy", comment: "")),
        Category(groupCategory: GroupId.othersId, categoryId: CategoryId.others.hospitalId, icon: #imageLiteral(resourceName: "Hospital 3-30"), localizedString:  NSLocalizedString("CategoryLabelHospital", comment: "")),
 //       Category(groupCategory: GroupId.othersId, categoryId: CategoryId.others.cathedralId, icon: #imageLiteral(resourceName: "Cathedral-30"), localizedString:  NSLocalizedString("CategoryLabelChurch", comment: "")),
        Category(groupCategory: GroupId.othersId, categoryId: CategoryId.others.courtHouseId, icon: #imageLiteral(resourceName: "Courthouse-30"), localizedString:  NSLocalizedString("CategoryLabelCourtHouse", comment: "")),
   ]
    
    fileprivate static let groups = [GroupCategory(groupId: GroupId.defaultGroupId, localizedString: "Default"),
                                     GroupCategory(groupId: GroupId.cultureId, localizedString: "culture"),
                                     GroupCategory(groupId: GroupId.dailyLifeId, localizedString: "Daily life"),
                                     GroupCategory(groupId: GroupId.nightLifeId, localizedString: "Night life"),
                                     GroupCategory(groupId: GroupId.othersId, localizedString: "Others"),
                                     GroupCategory(groupId: GroupId.shoppingId, localizedString: "Shopping"),
                                     GroupCategory(groupId: GroupId.transportationId, localizedString: "Transportation")]
    
    
    static func getCategory(poi:PointOfInterest) -> Category {
        for currentCategory in localSearchCategories {
            if currentCategory.categoryId == poi.poiCategory && currentCategory.groupCategory == poi.poiGroupCategory {
                return currentCategory
            }
        }
        
        return defaultGroupCategory
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
