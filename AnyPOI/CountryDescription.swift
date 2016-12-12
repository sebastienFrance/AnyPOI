//
//  CountryDescription.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 12/12/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation

struct CountryDescription : Equatable {
    let countryName:String
    let ISOCountryCode:String
    
    func getAllCities(filter:String = "") -> [String] {
        return POIDataManager.sharedInstance.getAllCitiesFromCountry(ISOCountryCode, filter: filter)
    }
    
    static func isoCountryNamesToCountryDescription(isoCountryNames:[String]) -> [CountryDescription] {
        var countries = [CountryDescription]()
        
        for currentISOCountry in isoCountryNames {
            if let countryName = (Locale.current as NSLocale).displayName(forKey: NSLocale.Key.countryCode, value: currentISOCountry) {
                let newCountryNameToISO = CountryDescription(countryName: countryName, ISOCountryCode: currentISOCountry)
                countries.append(newCountryNameToISO)
            } else {
                print("\(#function) cannot find translation for ISOCountry \(currentISOCountry), it's ignored")
            }
        }
        countries = countries.sorted() {
            $0.countryName < $1.countryName
        }
        return countries
    }
    
    
    static func ==(lhs:CountryDescription, rhs:CountryDescription) -> Bool {
        return lhs.ISOCountryCode == rhs.ISOCountryCode
    }
}
