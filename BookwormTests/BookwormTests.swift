//
//  BookwormTests.swift
//  BookwormTests
//
//  Created by Philippe Marissal on 18.06.20.
//  Copyright © 2020 Philippe Marissal. All rights reserved.
//

import XCTest
@testable import Bookworm

class BookwormTests: XCTestCase {

    var libraryView: LibraryViewController!
    override func setUpWithError() throws {
        super.setUp()
        libraryView = LibraryViewController()
        
    }

    override func tearDownWithError() throws {
        libraryView = nil
        super.tearDown()
        
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
