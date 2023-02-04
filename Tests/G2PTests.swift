//
//  G2PTest.swift
//  Hangeul
//
//  Created by Kevin Li on 2/4/23.
//

@testable import Hangeul

import XCTest

final class G2PTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testG2P() throws {
        XCTAssertEqual(g2p(word: "압력").0, "암녁")
    }
}
