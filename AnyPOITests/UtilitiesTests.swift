//
//  UtilitiesTests.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 26/07/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import XCTest
@testable import AnyPOI

class UtilitiesTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTimeInterval() {
        let oneHourAndHalfAndTenSecondsInterval = Utilities.stringFromTimeInterval(5410)
        XCTAssertEqual(oneHourAndHalfAndTenSecondsInterval, "01:30:10.000", "Interval is wrong it should be 01:30:10.000")
        
        let zeroInterval = Utilities.stringFromTimeInterval(0)
        XCTAssertEqual(zeroInterval, "00:00:00.000", "Interval is wrong it should be 00:00:00.000")
        
        let negativeOneHourInterval = Utilities.stringFromTimeInterval(-3600)
        XCTAssertEqual(negativeOneHourInterval, "-01:00:00.000", "Interval is wrong it should be -01:00:00.000")
        
        let oneHourAndHalfShortInterval = Utilities.shortStringFromTimeInterval(5400)
        XCTAssertEqual(oneHourAndHalfShortInterval, "01:30", "Interval is wrong it should be 01:30")
    
        let zeroShotInterval = Utilities.shortStringFromTimeInterval(0)
        XCTAssertEqual(zeroShotInterval, "00:00", "Interval is wrong it should be 00:00")

        let negativeShortInterval = Utilities.shortStringFromTimeInterval(-3600)
        XCTAssertEqual(negativeShortInterval, "-01:00", "Interval is wrong it should be -01:00")
   }
    
}
