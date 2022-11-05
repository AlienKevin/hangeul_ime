//
//  KrDictEmbeddingsGenerator.swift
//  KrDictEmbeddingsGenerator
//
//  Created by Kevin Li on 10/29/22.
//

@testable import Hangeul
import XCTest
import NaturalLanguage
import CreateML

final class KrDictEmbeddingsGenerator: XCTestCase {
    func testGenerateKrDictEmbeddings() throws {
        if let sentenceEmbedding = NLEmbedding.sentenceEmbedding(for: .english) {
            let dict = KrDict.loadDictionaryFromJson(filename: "KrDict.json")!
            var vectors: [String: [Double]] = [:]
            for (wordIndex, (_, entries)) in dict.enumerated() {
                if wordIndex % 100 == 0 {
                    print("Finished processing \(wordIndex) entries")
                }
                for (entryIndex, entry) in entries.enumerated() {
                    for (englishWordGroupIndex, englishWordGroup) in entry.equivalentEnglishWords.enumerated() {
                        for (englishWordIndex, englishWord) in englishWordGroup.enumerated() {
                            guard let vector = sentenceEmbedding.vector(for: englishWord) else {
                                print("No embedding found for english word: \(englishWord)")
                                continue
                            }
                            let indexName = "\(wordIndex)_\(entryIndex)_\(englishWordGroupIndex)_\(englishWordIndex)"
                            vectors[indexName] = vector
                        }
                    }
                }
            }
            let outputUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("KrDictEmbeddings.mlmodel")
            let embedding = try! MLWordEmbedding(dictionary: vectors)
            try! embedding.write(to: outputUrl)
            print("KrDictEmbeddings.mlmodle written to \(outputUrl)")
        }
        XCTAssertTrue(true)
    }
}
