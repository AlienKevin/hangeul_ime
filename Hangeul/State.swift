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
    // SwiftUI 界面事件
    static let candidateSelected = Notification.Name("State.candidateSelected")
    static let candidateListUpdated = Notification.Name("State.candidateListUpdated")
    static let nextPageBtnTapped = Notification.Name("State.nextPageBtnTapped")
    static let prevPageBtnTapped = Notification.Name("State.prevPageBtnTapped")

    // 逻辑
    static let candidateInserted = Notification.Name("State.candidateInserted")
    static let inputModeChanged = Notification.Name("State.inputModeChanged")

    var inputMode: InputMode = .hangeul
    var krDict: Dictionary = loadJson(filename: "KrDict.json")!
    var server = IMKServer(name: Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String, bundleIdentifier: Bundle.main.bundleIdentifier)

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

private func loadJson(filename fileName: String) -> Dictionary? {
    guard let asset = NSDataAsset(name: fileName) else {
        fatalError("Missing data asset: \(fileName)")
    }
    let decoder = JSONDecoder()
    let jsonData = try! decoder.decode(Dictionary.self, from: asset.data)
    return jsonData
}
