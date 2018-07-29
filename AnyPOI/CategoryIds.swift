//
//  CategoryIds.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 29/07/2018.
//  Copyright © 2018 Sébastien Brugalières. All rights reserved.
//

import Foundation

struct CategoryIds {
    
    struct GroupId {
        static let defaultGroupId = Int16(0)
        static let cultureId = Int16(1)
        static let dailyLifeId = Int16(2)
        static let nightLifeId = Int16(3)
        static let transportationId = Int16(4)
        static let shoppingId = Int16(5)
        static let othersId = Int16(6)
    }
    
    struct CategoryId {
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
}
