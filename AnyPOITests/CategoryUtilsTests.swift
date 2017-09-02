//
//  CategoryUtilsTests.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 26/07/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import XCTest

@testable import AnyPOI

class CategoryUtilsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCategoryIndex() {
        
        let indexDefaultGroup = CategoryUtils.getIndex(category: CategoryUtils.defaultGroupCategory, inCategories: CategoryUtils.localSearchCategories)
        XCTAssertNotNil(indexDefaultGroup, "Cannot find index of default category")
 
        let indexContact = CategoryUtils.getIndex(category: CategoryUtils.contactCategory, inCategories: CategoryUtils.localSearchCategories)
        XCTAssertNotNil(indexContact, "Cannot find index of contact category")

        XCTAssertNotEqual(indexDefaultGroup!, indexContact!, "Error index of contact and default group must not be equals")
        
        let unknownCategory = CategoryUtils.Category(groupCategory: 9999, categoryId: 9999, icon: #imageLiteral(resourceName: "Bank-30"), localizedString: "unknown category")
        let indexUnknownCategory = CategoryUtils.getIndex(category: unknownCategory, inCategories: CategoryUtils.localSearchCategories)
        XCTAssertNil(indexUnknownCategory, "Warning found an unknown category in localSearchCategory")
        
    }
    
    func testCategoryFind() {
        let defaultCategory = CategoryUtils.findCategory(groupCategory: CategoryUtils.defaultGroupCategory.groupCategory,
                                                         categoryId: CategoryUtils.defaultGroupCategory.categoryId,
                                                         inCategories: CategoryUtils.localSearchCategories)
        
        XCTAssertNotNil(defaultCategory, "Cannot find default group category")

        let unknownCategory = CategoryUtils.findCategory(groupCategory: 9999,
                                                         categoryId: 9999,
                                                         inCategories: CategoryUtils.localSearchCategories)
        XCTAssertNil(unknownCategory, "Found an unknown category")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    
}
