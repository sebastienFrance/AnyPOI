//
//  AnyPOITests.swift
//  AnyPOITests
//
//  Created by Sébastien Brugalières on 15/09/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import XCTest
@testable import AnyPOI

@objcMembers
class CountryDescriptionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
   func testISOCountryToCountryDescription() {
        
        let countryNames = ["fr","us"]
        let countries = CountryDescription.isoCountryNamesToCountryDescription(isoCountryNames: countryNames)
    
    
        
        XCTAssertEqual(countries.count, countryNames.count, "More fr countries than expected")
    var france:CountryDescription
    var usa:CountryDescription
    if countries[0].ISOCountryCode == "fr" {
        france = countries[0]
        usa = countries[1]
    } else {
        france = countries[1]
        usa = countries[0]
    }
    
        XCTAssertEqual(france.countryName, "France", "France country name is incorrect")
        XCTAssertEqual(france.ISOCountryCode, "fr", "Invalid ISOCountry name for France")
        XCTAssertEqual(france.countryFlag, "🇫🇷", "Invalid Flag for France")
      
        XCTAssertEqual(usa.countryName, "États-Unis", "USA country name is incorrect")
        XCTAssertEqual(usa.ISOCountryCode, "us", "Invalid ISOCountry name for USA")
        XCTAssertEqual(usa.countryFlag, "🇺🇸", "Invalid Flag for USA")
        
        XCTAssertNotEqual(countries[0], countries[1], "Countries should not be equals!")
        XCTAssertEqual(countries[0],countries[0], "Countries should be equals")

        let emptyCountries = CountryDescription.isoCountryNamesToCountryDescription(isoCountryNames: [])
        XCTAssertEqual(emptyCountries.count, 0, "Not an empty countries")
    }
    
    func testEmojiFlag() {
        let france = CountryDescription.emoji(countryCode: "fr")
        let germany = CountryDescription.emoji(countryCode: "de")
        let usa = CountryDescription.emoji(countryCode: "us")
        
        XCTAssertEqual(france, "🇫🇷", "Flag from France is wrong")
        XCTAssertEqual(germany, "🇩🇪", "Flag from germany is wrong")
        XCTAssertEqual(usa, "🇺🇸", "Flag from usa is wrong")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        
        var countryCodes = [String]()
        for _ in 0..<10000 {
            countryCodes.append("fr")
        }
        
        self.measure {
            _ = CountryDescription.isoCountryNamesToCountryDescription(isoCountryNames: countryCodes)
        }
    }
    
}
