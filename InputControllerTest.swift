//
//  InputControllerTest.swift
//  HangulIMEInputControllerTests
//
//  Created by Kevin Li on 10/8/22.
//
@testable import HangulIME

import XCTest

final class InputControllerTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSyllableSegmentation() throws {
        XCTAssertEqual(syllableSegmentation("a"), [Syllable(nucleus: "a")])
        XCTAssertEqual(syllableSegmentation("eo"), [Syllable(nucleus: "eo")])
        XCTAssertEqual(syllableSegmentation("yeo"), [Syllable(nucleus: "yeo")])
        XCTAssertEqual(syllableSegmentation("A"), [Syllable(nucleus: "a")])
        XCTAssertEqual(syllableSegmentation("Eo"), [Syllable(nucleus: "eo")])
        XCTAssertEqual(syllableSegmentation("Yeo"), [Syllable(nucleus: "yeo")])
        
        XCTAssertEqual(syllableSegmentation("yeaoa"), [Syllable(nucleus: "ye"), Syllable(nucleus: "a"), Syllable(nucleus: "o"), Syllable(nucleus: "a")])
        
        XCTAssertEqual(syllableSegmentation("nyeo"), [Syllable(initial: "n", nucleus: "yeo")])
        XCTAssertEqual(syllableSegmentation("myeo"), [Syllable(initial: "m", nucleus: "yeo")])
        XCTAssertEqual(syllableSegmentation("kkyeo"), [Syllable(initial: "kk", nucleus: "yeo")])
        
        XCTAssertEqual(syllableSegmentation("nyeong"), [Syllable(initial: "n", nucleus: "yeo", final: "ng")])
        XCTAssertEqual(syllableSegmentation("myeom"), [Syllable(initial: "m", nucleus: "yeo", final: "m")])
        XCTAssertEqual(syllableSegmentation("kkyeonj"), [Syllable(initial: "kk", nucleus: "yeo", final: "nj")])
        
        XCTAssertEqual(syllableSegmentation("gb"), [Syllable(initial: "g"), Syllable(initial: "b")])
        XCTAssertEqual(syllableSegmentation("kl"), [Syllable(initial: "k"), Syllable(initial: "l")])
        
        XCTAssertEqual(syllableSegmentation("kkyeongang"), [Syllable(initial: "kk", nucleus: "yeo", final: "n"), Syllable(initial: "g", nucleus: "a", final: "ng")])
        XCTAssertEqual(syllableSegmentation("kkyeolbang"), [Syllable(initial: "kk", nucleus: "yeo", final: "l"), Syllable(initial: "b", nucleus: "a", final: "ng")])
        XCTAssertEqual(syllableSegmentation("kkyeokkang"), [Syllable(initial: "kk", nucleus: "yeo", final: "k"), Syllable(initial: "k", nucleus: "a", final: "ng")])
        
        XCTAssertEqual(syllableSegmentation("bbb"), [Syllable(initial: "b"), Syllable(initial: "b"), Syllable(initial: "b")])
        XCTAssertEqual(syllableSegmentation("kkk"), [Syllable(initial: "kk"), Syllable(initial: "k")])
        XCTAssertEqual(syllableSegmentation("ggg"), [Syllable(initial: "g"), Syllable(initial: "g"), Syllable(initial: "g")])
        
        XCTAssertEqual(syllableSegmentation("babwaebeo"), [Syllable(initial: "b", nucleus: "a"), Syllable(initial: "b", nucleus: "wae"), Syllable(initial: "b", nucleus: "eo")])
        
        // With capital letters
        XCTAssertEqual(syllableSegmentation("kkyeonGang"), [Syllable(initial: "kk", nucleus: "yeo", final: "n"), Syllable(initial: "g", nucleus: "a", final: "ng")])
        XCTAssertEqual(syllableSegmentation("kkyeolBang"), [Syllable(initial: "kk", nucleus: "yeo", final: "l"), Syllable(initial: "b", nucleus: "a", final: "ng")])
        XCTAssertEqual(syllableSegmentation("kkyeokKang"), [Syllable(initial: "kk", nucleus: "yeo", final: "k"), Syllable(initial: "k", nucleus: "a", final: "ng")])
        XCTAssertEqual(syllableSegmentation("kkyeongAng"), [Syllable(initial: "kk", nucleus: "yeo", final: "ng"), Syllable(nucleus: "a", final: "ng")])
        XCTAssertEqual(syllableSegmentation("kkyeolbAng"), [Syllable(initial: "kk", nucleus: "yeo", final: "lb"), Syllable(nucleus: "a", final: "ng")])
        XCTAssertEqual(syllableSegmentation("kkyeokkAng"), [Syllable(initial: "kk", nucleus: "yeo", final: "kk"), Syllable(nucleus: "a", final: "ng")])
    }

}
