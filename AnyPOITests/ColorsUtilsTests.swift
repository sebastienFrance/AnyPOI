//
//  ColorsUtilsTests.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 26/07/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import XCTest
@testable import AnyPOI

class ColorsUtilsTests: XCTestCase {
    
    @objc override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    @objc override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    @objc func testColors() {
        let colors = ColorsUtils.initColors()
        
        XCTAssertTrue(colors.count > 0, "Error colors is empty")
        
        let firstColor = colors[0]
        let lastColor = colors.last!
        
        let firstColorIndex = ColorsUtils.findColorIndex(firstColor, inColors: colors)
        XCTAssertNotEqual(firstColorIndex, -1, "Cannot find index of the first color")

        let lastColorIndex = ColorsUtils.findColorIndex(lastColor, inColors: colors)
        XCTAssertNotEqual(lastColorIndex, -1, "Cannot find index of the last color")
        
        XCTAssertNotEqual(firstColorIndex, lastColorIndex, "Error first color and last color cannot have the same index")
        
        let stringFirstColor = ColorsUtils.getColor(color: firstColor)
        XCTAssertNotNil(stringFirstColor, "First color not converted to a string")
        
        let colorFromString = ColorsUtils.getColor(rgba: stringFirstColor!)
        XCTAssertNotNil(colorFromString, "String cannot be converted to a color")
        XCTAssertEqual(firstColor, colorFromString!, "Cannot find the right color from the string for the first color")

        let stringLastColor = ColorsUtils.getColor(color: lastColor)
        XCTAssertNotNil(stringLastColor, "Last color not converted to a string")

        let lastColorFromString = ColorsUtils.getColor(rgba: stringLastColor!)
        XCTAssertNotNil(lastColorFromString, "String cannot be converted to a color for last color")
//        XCTAssertEqual(lastColor, lastColorFromString!, "Cannot find the right color from the string for the last color")
     }
    
    
}
