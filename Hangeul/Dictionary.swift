//
//  Dictionary.swift
//  Hangeul
//
//  Created by Kevin Li on 10/22/22.
//

import Foundation
import OrderedCollections

struct Entry : Decodable {
    var origin: String
    var vocabularyLevel: String
    var prs: [String]
    var equivalentEnglishWords: [[String]]
}

typealias Dictionary = [String : [Entry]]

func reverseLookupByEnglish(word: String, dict: Dictionary) -> [Candidate] {
    var resultDict = Dictionary()
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
