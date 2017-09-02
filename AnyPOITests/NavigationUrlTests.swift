//
//  NavigationUrlTests.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 29/07/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import XCTest
@testable import AnyPOI

class NavigationUrlTests: XCTestCase {
    
    var navUrlWithoutPoiId: NavigationURL!
    var navUrlWithPoiId: NavigationURL!
    var invalidURL: NavigationURL!
    var emptyURL: NavigationURL!
    
    override func setUp() {
        super.setUp()
        
        navUrlWithoutPoiId = NavigationURL(openURL: URL(string: "https://apple.com?value1=1&value2=2&value3=3")!)
        navUrlWithPoiId = NavigationURL(openURL: URL(string: "https://apple.com?value1=1&poiId=poiIdValue&value3=3")!)
        invalidURL = NavigationURL(openURL: URL(string: "https://apple.com?value1=1&poiId&value3=3")!)
        emptyURL = NavigationURL(openURL: URL(string: "https://apple.com")!)
    }
    
    override func tearDown() {
        navUrlWithoutPoiId = nil
        navUrlWithPoiId = nil
        invalidURL = nil
        emptyURL = nil
        super.tearDown()
    }
    
    func testExample() {
        XCTAssertTrue(navUrlWithoutPoiId.isValidURL, "Error navUrlWithoutPoiId is not a valid URL")
        XCTAssertTrue(navUrlWithPoiId.isValidURL, "Error navUrlWithPoiId is not a valid URL")
        XCTAssertFalse(invalidURL.isValidURL, "Error invalidURL is a valid URL")
        XCTAssertFalse(emptyURL.isValidURL, "Error emptyURL is a valid URL")
        XCTAssertNil(invalidURL.getPoi(), "Error poiId found in this URL")
        XCTAssertNil(navUrlWithoutPoiId.getPoi(), "Error poiId found in this URL")
        XCTAssertNotNil(navUrlWithPoiId.getPoi(), "Error cannot find a poiId in this URL")
        XCTAssertEqual(navUrlWithPoiId.getPoi(), "poiIdValue", "Error invalid value for poiId")
    }
    
    
}
