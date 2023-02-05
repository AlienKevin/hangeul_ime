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
    
    func check(_ input: String, _ expected: String) {
        XCTAssertEqual(g2p(word: input).0, expected)
    }

    func testG2P() throws {
        // Obstruent Nasalization
        check("압력", "암녁")
        check("악력", "앙녁")
        // Liquid Nasalization
        check("금리", "금니")
        check("담론", "담논")
        check("공리", "공니")
        check("등록", "등녹")
        // Special cases
        check("희다", "히다")
        // Consonant cluster tensification
        check("초읽기", "초일끼")
        // Aspiration
        check("어떻다", "어떠타")
        check("엇비슷하다", "얻삐스타다")
        check("열어젖히다", "여러저치다")
        check("어쭙잖다", "어쭙짠타")
        // Palatalization
        check("여닫이", "여다지")
    }
}
