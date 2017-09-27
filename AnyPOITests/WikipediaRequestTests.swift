//
//  WikipediaRequestTests.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 29/07/2017.
//  Copyright © 2017 Sébastien Brugalières. All rights reserved.
//

import XCTest
import CoreLocation
@testable import AnyPOI

class WikipediaRequestTests: XCTestCase {
    
    class WikiTestDelegate: WikipediaRequestDelegate {
        
        var promise:XCTestExpectation!
        private(set) var wikipediaArticles:[Wikipedia]!
        private(set) var isSuccess:Bool!
        
        func wikipediaLoadingDidFinished(_ wikipedias:[Wikipedia]) {
            isSuccess = true
            wikipediaArticles = wikipedias
            promise.fulfill()
        }
        func wikipediaLoadingDidFailed() {
            wikipediaArticles = [Wikipedia]()
            isSuccess = false
            promise.fulfill()
        }

    }
    
    let testDelegate = WikiTestDelegate()
    var request:WikipediaRequest!
    
    @objc override func setUp() {
        super.setUp()
        request = WikipediaRequest(delegate: testDelegate)
    }
    
    @objc override func tearDown() {
        request = nil
        super.tearDown()
    }
    
    @objc func testWikiSuccess() {
        testDelegate.promise = expectation(description: "Completion handler invoked")
        
        // Search wiki around Paris location
        request.searchAround(CLLocationCoordinate2D(latitude:48.8534, longitude:2.3488))
        
        waitForExpectations(timeout: 5.0, handler: nil)
        
        XCTAssertTrue(testDelegate.isSuccess, "Wikiepdia is not a success")
        XCTAssertTrue(testDelegate.wikipediaArticles.count > 0, "Wikipedia article is empty")
        
        
    }
    
    @objc func testWikiFailure() {
        testDelegate.promise = expectation(description: "Completion handler invoked")
        request.searchAround(CLLocationCoordinate2D(latitude:500, longitude:500))

        waitForExpectations(timeout: 5.0, handler: nil)
        
        XCTAssertFalse(testDelegate.isSuccess, "Wikiepdia should not be a success")
        XCTAssertTrue(testDelegate.wikipediaArticles.count == 0, "Wikipedia article is not empty")
    }
    
    @objc func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
