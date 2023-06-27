//
//  Candidates.swift
//  Hangeul
//
//  Created by Kevin Li on 10/23/22.
//  src: https://github.com/qwertyyb/Fire/blob/master/Fire/types.swift

import Foundation

enum CandidatesDirection: Int, Decodable, Encodable {
    case vertical
    case horizontal
}

struct Candidate: Hashable {
    let koreanWord: String
    let prs: [String]
    let englishWords: [String]
}

enum InputMode: String {
    case hangeul
    case english
}
