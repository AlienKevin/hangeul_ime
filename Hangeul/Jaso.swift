//
//  Jaso.swift
//  Hangeul
//
//  Created by Kevin Li on 10/18/22.
//

import Foundation

let vowelJaso = try! NSRegularExpression(pattern: "([iy]ae|[iy]eo|ae|[iy]e|[iy]a|[iy]o|oe|[iy][uw]|e[uw]|eo|a|e|[iy]|o|[uw])$", options: [NSRegularExpression.Options.caseInsensitive])
let consonantJaso = try! NSRegularExpression(pattern: "(ch|ng|ch|p|t|k|b|d|g|j|c|s|h|n|m|l|r)$", options: [NSRegularExpression.Options.caseInsensitive])

func getLastJaso(_ s: String) -> String? {
    assert(!s.isEmpty)
    if let match = vowelJaso.matches(in: s, range: NSRange(location: 0, length: s.utf16.count)).first {
        if let swiftRange = Range(match.range, in: s) {
            return String(s[swiftRange])
        }
    }
    if let match = consonantJaso.matches(in: s, range: NSRange(location: 0, length: s.utf16.count)).first {
        if let swiftRange = Range(match.range, in: s) {
            return String(s[swiftRange])
        }
    }
    return nil
}
