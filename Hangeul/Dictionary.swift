//
//  Dictionary.swift
//  Hangeul
//
//  Created by Kevin Li on 10/22/22.
//

import Foundation
import OrderedCollections
import NaturalLanguage

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

typealias RawDictionary = [RawEntries]
typealias Dictionary = OrderedDictionary<String, [Entry]>

func reverseLookupByEnglish(word: String, dict: Dictionary) -> [Candidate] {
    var resultDict = Dictionary()
    func searchDict(word: String) {
        for (entryWord, entries) in dict {
            for entry in entries {
                let equivalentEnglishWords = entry.equivalentEnglishWords.filter({$0.map({$0.lowercased()}).contains(word.lowercased())})
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
        if containsOnlyLetters(word) {
            if let wordEmbedding = NLEmbedding.wordEmbedding(for: .english) {
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
    let sortedResultKeyValuePairs = resultKeyValuePairs.sorted(by: { countEnglishWordOccurrences(entries: $0.1) > countEnglishWordOccurrences(entries: $1.1) })
    return sortedResultKeyValuePairs.map({
        let koreanWord = $0.0
        let firstEntry = $0.1.first!
        let englishWords = NSOrderedSet(array: firstEntry.equivalentEnglishWords).map({ $0 as! [String] })
        return Candidate(koreanWord: koreanWord, englishWords: englishWords.first!)
    })
}

private func containsOnlyLetters(_ input: String) -> Bool {
   for chr in input {
      if (!(chr >= "a" && chr <= "z") && !(chr >= "A" && chr <= "Z") ) {
         return false
      }
   }
   return true
}
