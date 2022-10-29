//
//  State.swift
//  Hangeul
//
//  Created by Kevin Li on 10/23/22.
//

import Foundation

import Cocoa
import InputMethodKit

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
    var krDict: Dictionary = Dictionary()
    var server = IMKServer(name: Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String, bundleIdentifier: Bundle.main.bundleIdentifier)
    
    override init() {
        super.init()
        Task.init(priority: TaskPriority.medium) {
            self.krDict = loadJson(filename: "KrDict.json")
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
        let candidates = reverseLookupByEnglish(word: origin, dict: krDict)
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

// Asynchronously load dictionary JSON to prevent blocking the main thread
func loadJson(filename fileName: String) -> Dictionary {
    guard let asset = NSDataAsset(name: fileName) else {
        fatalError("Missing data asset: \(fileName)")
    }
    let decoder = JSONDecoder()
    let rawDict = try! decoder.decode(RawDictionary.self, from: asset.data)
    var dict = Dictionary();
    for rawEntries in rawDict {
        dict[rawEntries.word] = rawEntries.entries
    }
    dlog("KrDict loaded!")
    return dict
}
