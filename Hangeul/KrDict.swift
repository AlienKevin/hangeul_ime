//
//  Dictionary.swift
//  Hangeul
//
//  Created by Kevin Li on 10/22/22.
//

import Foundation
import OrderedCollections
import NaturalLanguage
import Cocoa

struct Entry : Decodable {
    var origin: String
    var vocabularyLevel: String
    var prs: [String]
    var equivalentEnglishWords: [[String]]
}

struct RawEntries : Decodable {
    var word: String
    var entries: [Entry]
}

typealias RawDict = [RawEntries]
typealias KrDict = OrderedDictionary<String, [Entry]>

// Value should be a list of list of two Ints
// First Int is the wordIndex
// Second Int is the entryIndex
typealias RawEnglishLookupTable = [String: [[Int]]]
struct EntryLocation {
    var wordIndex: Int
    var entryIndex: Int
}
typealias EnglishLookupTable = [String: [EntryLocation]]


extension KrDict {
    // Asynchronously load dictionary JSON to prevent blocking the main thread
    static func loadDictionaryFromJson() -> KrDict? {
        guard let jsonPath = Bundle.main.path(forResource: "KrDict", ofType: "json") else { return nil }
        guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonPath), options: .mappedIfSafe) else { return nil }
        let decoder = JSONDecoder()
        guard let rawDict = try? decoder.decode(RawDict.self, from: jsonData) else { return nil }
        var dict = KrDict();
        for rawEntries in rawDict {
            dict[rawEntries.word] = rawEntries.entries
        }
        dlog("KrDict loaded!")
        return dict
    }
    
    static func loadEnglishLookupTableFromJson() -> EnglishLookupTable? {
        guard let jsonPath = Bundle.main.path(forResource: "KrDictEnglishLookupTable", ofType: "json") else { return nil }
        dlog("Found english lookup table json in bundle")
        guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonPath), options: .mappedIfSafe) else { return nil }
        let decoder = JSONDecoder()
        guard let rawTable = try? decoder.decode(RawEnglishLookupTable.self, from: jsonData) else { return nil }
        dlog("successfully decoded english lookup table")
        var table = EnglishLookupTable();
        for (englishWord, entryLocations) in rawTable {
            table[englishWord] = entryLocations.map({
                EntryLocation(wordIndex: $0[0], entryIndex: $0[1])})
        }
        return table
    }
}

func reverseLookupByEnglish(word: String, dict: KrDict, englishLookupTable: EnglishLookupTable, freqDict: FreqDict, embedding: NLEmbedding) -> [Candidate] {
    var resultDict = KrDict()
    func searchDict(word: String) {
        if let entryLocations = englishLookupTable[word] {
            for entryLocation in entryLocations {
                let (entryWord, entries) = dict.elements[entryLocation.wordIndex]
                let entry = entries[entryLocation.entryIndex]
                let equivalentEnglishWords = entry.equivalentEnglishWords.filter({
                    $0.map({removeStopwords($0.lowercased())}).contains(removeStopwords(word.lowercased()))
                })
                if !equivalentEnglishWords.isEmpty {
                    var resultEntries = resultDict[entryWord] ?? []
                    var resultEntry = entry
                    resultEntry.equivalentEnglishWords = equivalentEnglishWords
                    resultEntries.append(resultEntry)
                    resultDict[entryWord] = resultEntries
                }
            }
        }
    }
    searchDict(word: word)
    if resultDict.isEmpty {
        // embedding not loaded yet
        // fallback to nearest neighbor for word queries
        if embedding.vocabularySize == 0 {
            dlog("krDictEmbeddings is empty")
            if containsOnlyLetters(word) {
                guard let wordEmbedding = NLEmbedding.wordEmbedding(for: .english) else { return [] }
                wordEmbedding.enumerateNeighbors(for: word, maximumCount: 5) { neighborWord, distance in
                    if distance < 1 {
                        searchDict(word: neighborWord)
                        if !resultDict.isEmpty {
                            return false
                        }
                    }
                    return true
                }
            }
        } else {
            dlog("Searching nearest neighbors in krDictEmbeddings")
            guard let sentenceEmbedding = NLEmbedding.sentenceEmbedding(for: .english) else { return [] }
            guard let queryVector = sentenceEmbedding.vector(for: word) else { return [] }
            let nearestDictKeys = embedding.neighbors(for: queryVector, maximumCount: 5)
            dlog("Number of nearest neighbors: \(nearestDictKeys.count)")
            for (nearestDictKey, distance) in nearestDictKeys {
                let (entryWord, resultEntry) = getEntryWithEmbeddingKey(key: nearestDictKey, dict: dict)
                dlog("Found nearest entry word: \(entryWord) with distance \(distance)")
                if distance < 0.9 * sigmoid(coefficient: 0.4, input: (Double)(word.count)) {
                    var resultEntries = resultDict[entryWord] ?? []
                    resultEntries.append(resultEntry)
                    resultDict[entryWord] = resultEntries
                }
            }
        }
    }
    var resultKeyValuePairs: [(String, [Entry])] = []
    for (entryWord, entries) in resultDict {
        let sortedEntries = entries.sorted(by: { $0.equivalentEnglishWords.count > $1.equivalentEnglishWords.count })
        resultKeyValuePairs.append((entryWord, sortedEntries))
    }
    func countEnglishWordOccurrences(entries: [Entry]) -> Int {
        return entries.map({return $0.equivalentEnglishWords.count}).reduce(0, +)
    }
    let sortedResultKeyValuePairs = resultKeyValuePairs.sorted(by: {
        let leftWordRanking = freqDict.getRanking(word: $0.0)
        let rightWordRanking = freqDict.getRanking(word: $1.0)
        if leftWordRanking == rightWordRanking {
            return countEnglishWordOccurrences(entries: $0.1) > countEnglishWordOccurrences(entries: $1.1)
        } else {
            return leftWordRanking < rightWordRanking
        }
    })
    return sortedResultKeyValuePairs.map({
        let koreanWord = $0.0
        let firstEntry = $0.1.first!
        let englishWords = NSOrderedSet(array: firstEntry.equivalentEnglishWords).map({ $0 as! [String] })
        return Candidate(koreanWord: koreanWord, englishWords: englishWords.first!)
    })
}

private func sigmoid(coefficient: Double, input: Double) -> Double {
    return 1 / (1.0 + exp(-coefficient * input))
}

private func getEntryWithEmbeddingKey(key: String, dict: KrDict) -> (String, Entry) {
    let indices = key.split(separator: "_")
    let wordIndex = Int(indices[0])!
    let entryIndex = Int(indices[1])!
    let englishWordGroupIndex = Int(indices[2])!
    
    let (entryWord, entries) = dict.elements[wordIndex]
    var resultEntry = entries[entryIndex]
    resultEntry.equivalentEnglishWords = [entries[entryIndex].equivalentEnglishWords[englishWordGroupIndex]]
    return (entryWord, resultEntry)
}

private func containsOnlyLetters(_ input: String) -> Bool {
   for chr in input {
      if (!(chr >= "a" && chr <= "z") && !(chr >= "A" && chr <= "Z") ) {
         return false
      }
   }
   return true
}

private func removeStopwords(_ input: String) -> String {
    let stopwords: Set = ["a", "an", "the"]
    
    for stopword in stopwords {
        if input.starts(with: stopword + " ") {
            var result = input
            result.removeFirst(stopword.count + 1)
            return result
        }
    }
    return input
    
//    let range = input.startIndex ..< input.endIndex
//    let tagger = NLTagger(tagSchemes: [.tokenType])
//    tagger.string = input
//    var output = ""
//    tagger.enumerateTags(in: range, unit: .word, scheme: .tokenType) { (tag, range) -> Bool in
//        if !stopwords.contains(String(input[range])) {
//            output += input[range]
//        }
//      return true
//    }
//    return output.isEmpty ? input : output
}
