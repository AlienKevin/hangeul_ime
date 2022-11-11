//
//  State.swift
//  Hangeul
//
//  Created by Kevin Li on 10/23/22.
//

import Foundation

import Cocoa
import InputMethodKit
import NaturalLanguage

let candidateCount = 5

class State: NSObject {
    // SwiftUI interface events
    static let candidateSelected = Notification.Name("State.candidateSelected")
    static let candidateListUpdated = Notification.Name("State.candidateListUpdated")
    static let nextPageBtnTapped = Notification.Name("State.nextPageBtnTapped")
    static let prevPageBtnTapped = Notification.Name("State.prevPageBtnTapped")

    // Logic related events
    static let candidateInserted = Notification.Name("State.candidateInserted")
    static let inputModeChanged = Notification.Name("State.inputModeChanged")

    var inputMode: InputMode = .hangeul
    var krDict: KrDict = KrDict()
    var krDictEnglishLookupTable: EnglishLookupTable = EnglishLookupTable()
    var server = IMKServer(name: Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String, bundleIdentifier: Bundle.main.bundleIdentifier)
    var krDictEmbeddings: NLEmbedding = NLEmbedding()
    var freqDict: FreqDict = FreqDict()
    
    override init() {
        super.init()
        Task.init(priority: TaskPriority.medium) {
            self.krDict = KrDict.loadDictionaryFromJson() ?? self.krDict
        }
        Task.init(priority: TaskPriority.medium) {
            self.krDictEnglishLookupTable = KrDict.loadEnglishLookupTableFromJson() ?? self.krDictEnglishLookupTable
            if !self.krDictEnglishLookupTable.isEmpty {
                dlog("krDictEnglishLookupTable loaded!")
                if let _ = self.krDictEnglishLookupTable["united states"] {
                    dlog("The word \"united states\" is found in the lookup table")
                }
            }
            self.freqDict = FreqDict.loadDictionaryFromJson() ?? self.freqDict
        }
        Task.init(priority: TaskPriority.low) {
            self.krDictEmbeddings = try! NLEmbedding.init(contentsOf: Bundle.main.url(forResource: "KrDictEmbeddings", withExtension:"mlmodelc")!)
            dlog("krDictEmbeddings loaded!")
        }
    }

    func toggleInputMode(_ nextInputMode: InputMode? = nil) {
        if nextInputMode != nil, self.inputMode == nextInputMode {
            return
        }
        let oldVal = self.inputMode
        if let nextInputMode = nextInputMode, nextInputMode != self.inputMode {
            self.inputMode = nextInputMode
        } else {
            self.inputMode = inputMode == .english ? .hangeul : .english
            dlog("new inputMode: " + self.inputMode.rawValue)
        }
        NotificationCenter.default.post(name: State.inputModeChanged, object: nil, userInfo: [
            "oldVal": oldVal,
            "val": self.inputMode,
            "label": self.inputMode == .english ? "english" : "hangeul"
        ])
    }

    func getCandidates(origin: String = String(), page: Int = 1) -> (candidates: [Candidate], hasNext: Bool) {
        if origin.count <= 0 {
            return ([], false)
        }
        let candidates = reverseLookupByEnglish(word: origin, dict: krDict, englishLookupTable: krDictEnglishLookupTable, freqDict: freqDict, embedding: krDictEmbeddings)
        if (page - 1) * candidateCount < candidates.count {
            let candidatesInPage = Array(candidates[((page - 1) * candidateCount)..<min(page * candidateCount, candidates.count)])
            let hasNext = page * candidateCount < candidates.count
            return (candidatesInPage, hasNext)
        } else {
            return ([], false)
        }
    }

    static let shared = State()
}
