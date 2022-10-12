//
//  InputControllerTest.swift
//  InputControllerTests
//
//  Created by Kevin Li on 10/8/22.
//
@testable import Hangeul

import XCTest

final class InputControllerTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSyllableSegmentation() throws {
        XCTAssertEqual(Syllable.syllabify("a"), [Syllable(nucleus: "a")])
        XCTAssertEqual(Syllable.syllabify("eo"), [Syllable(nucleus: "eo")])
        XCTAssertEqual(Syllable.syllabify("yeo"), [Syllable(nucleus: "ieo")])
        XCTAssertEqual(Syllable.syllabify("A"), [Syllable(nucleus: "a")])
        XCTAssertEqual(Syllable.syllabify("Eo"), [Syllable(nucleus: "eo")])
        XCTAssertEqual(Syllable.syllabify("Yeo"), [Syllable(nucleus: "ieo")])
        
        XCTAssertEqual(Syllable.syllabify("yeaoa"), [Syllable(nucleus: "ie"), Syllable(nucleus: "a"), Syllable(nucleus: "o"), Syllable(nucleus: "a")])
        
        XCTAssertEqual(Syllable.syllabify("nyeo"), [Syllable(initial: "n", nucleus: "ieo")])
        XCTAssertEqual(Syllable.syllabify("myeo"), [Syllable(initial: "m", nucleus: "ieo")])
        XCTAssertEqual(Syllable.syllabify("kkyeo"), [Syllable(initial: "kk", nucleus: "ieo")])
        
        XCTAssertEqual(Syllable.syllabify("nyeong"), [Syllable(initial: "n", nucleus: "ieo", final: "ng")])
        XCTAssertEqual(Syllable.syllabify("myeom"), [Syllable(initial: "m", nucleus: "ieo", final: "m")])
        XCTAssertEqual(Syllable.syllabify("kkyeonj"), [Syllable(initial: "kk", nucleus: "ieo", final: "nj")])
        
        XCTAssertEqual(Syllable.syllabify("gb"), [Syllable(initial: "g"), Syllable(initial: "b")])
        XCTAssertEqual(Syllable.syllabify("kl"), [Syllable(initial: "k"), Syllable(initial: "l")])
        
        XCTAssertEqual(Syllable.syllabify("kkyeongang"), [Syllable(initial: "kk", nucleus: "ieo", final: "n"), Syllable(initial: "g", nucleus: "a", final: "ng")])
        XCTAssertEqual(Syllable.syllabify("kkyeolbang"), [Syllable(initial: "kk", nucleus: "ieo", final: "l"), Syllable(initial: "b", nucleus: "a", final: "ng")])
        XCTAssertEqual(Syllable.syllabify("kkyeokkang"), [Syllable(initial: "kk", nucleus: "ieo", final: "k"), Syllable(initial: "k", nucleus: "a", final: "ng")])
        XCTAssertEqual(Syllable.syllabify("heojang"), [Syllable(initial: "h", nucleus: "eo"), Syllable(initial: "j", nucleus: "a", final: "ng")])
        XCTAssertEqual(Syllable.syllabify("heojan"), [Syllable(initial: "h", nucleus: "eo"), Syllable(initial: "j", nucleus: "a", final: "n")])
        
        XCTAssertEqual(Syllable.syllabify("bbb"), [Syllable(initial: "b"), Syllable(initial: "b"), Syllable(initial: "b")])
        XCTAssertEqual(Syllable.syllabify("kkk"), [Syllable(initial: "kk"), Syllable(initial: "k")])
        XCTAssertEqual(Syllable.syllabify("ggg"), [Syllable(initial: "g"), Syllable(initial: "g"), Syllable(initial: "g")])
        
        XCTAssertEqual(Syllable.syllabify("babwaebeo"), [Syllable(initial: "b", nucleus: "a"), Syllable(initial: "b", nucleus: "uae"), Syllable(initial: "b", nucleus: "eo")])
        
        // With capital letters
        XCTAssertEqual(Syllable.syllabify("kkyeonGang"), [Syllable(initial: "kk", nucleus: "ieo", final: "n"), Syllable(initial: "g", nucleus: "a", final: "ng")])
        XCTAssertEqual(Syllable.syllabify("kkyeolBang"), [Syllable(initial: "kk", nucleus: "ieo", final: "l"), Syllable(initial: "b", nucleus: "a", final: "ng")])
        XCTAssertEqual(Syllable.syllabify("kkyeokKang"), [Syllable(initial: "kk", nucleus: "ieo", final: "k"), Syllable(initial: "k", nucleus: "a", final: "ng")])
        XCTAssertEqual(Syllable.syllabify("kkyeongAng"), [Syllable(initial: "kk", nucleus: "ieo", final: "ng"), Syllable(nucleus: "a", final: "ng")])
        XCTAssertEqual(Syllable.syllabify("kkyeolbAng"), [Syllable(initial: "kk", nucleus: "ieo", final: "lb"), Syllable(nucleus: "a", final: "ng")])
        XCTAssertEqual(Syllable.syllabify("kkyeokkAng"), [Syllable(initial: "kk", nucleus: "ieo", final: "kk"), Syllable(nucleus: "a", final: "ng")])
    }

}
