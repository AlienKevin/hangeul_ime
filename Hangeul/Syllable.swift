//
//  Syllable.swift
//  Hangeul
//
//  Created by Kevin Li on 10/12/22.
//

import Foundation

struct Syllable: Equatable {
    var initial: String? = nil
    var nucleus: String? = nil
    var final: String? = nil
    
    func isEmpty() -> Bool {
        return initial == nil && nucleus == nil && final == nil
    }
    
    func count() -> Int {
        return (initial.map { $0.count } ?? 0) + (nucleus.map { $0.count } ?? 0)
            + (final.map { $0.count } ?? 0)
    }
    
    public var description: String { (initial ?? "") + (nucleus ?? "") + (final ?? "") }
    
    public func toJamos() -> String {
        if self.isEmpty() {
            return ""
        }
        
        var res = ""

        if var initial = self.initial {
            for (ascii, jamo) in initial2Jamo {
                initial = initial.replacingOccurrences(of: ascii, with: jamo)
            }
            res = res + initial
        }
        
        if var nucleus = self.nucleus {
            for (ascii, jamo) in nucleus2Jamo {
                nucleus = nucleus.replacingOccurrences(of: ascii, with: jamo)
            }
            if self.initial == nil {
                nucleus = "ᄋ" + nucleus
            }
            res = res + nucleus
        }
        
        if var final = self.final {
            for (ascii, jamo) in final2Jamo {
                final = final.replacingOccurrences(of: ascii, with: jamo)
            }
            res = res + final;
        }

        return res
    }
    
    public static func syllabify(_ s: String) -> [Syllable] {
        var syllables: [Syllable] = []
        let vowel = try! NSRegularExpression(pattern: "^([iy]ae|[uw]ae|[iy]eo|ae|[iy]e|[uw]e|[iy]a|[iy]o|oe|[iy][uw]|[uw]o|[uw][iy]|[uw]a|e[uw]|eo|a|e|[iy]|o|[uw])", options: [NSRegularExpression.Options.caseInsensitive])
        let initial_consonant = try! NSRegularExpression(pattern: "^(jj|ch|ss|pp|tt|kk|p|t|k|b|d|g|j|c|s|h|n|m|l|r)", options: [NSRegularExpression.Options.caseInsensitive])
        let final_consonant = try! NSRegularExpression(pattern: "^(kk|ss|ng|ch|gs|nj|nh|lg|lm|lb|ls|lt|lp|lh|bs|g|k|d|t|b|p|j|c|s|h|n|m|l|r)", options: [NSRegularExpression.Options.caseInsensitive])
        
        var start = s.startIndex
        var end = start
        
        while start != s.endIndex {
            if end == s.endIndex {
                break
            }
            // Skip the first letter which can be lower or uppercase
            end = s.index(end, offsetBy: 1)
            // Move end to the next uppercase letter or end of string
            while end != s.endIndex && s[end].isLowercase {
                end = s.index(end, offsetBy: 1)
            }
            
            while start != end {
                var syllable = Syllable()
                
                let initial_match = initial_consonant.matches(in: s, range: NSRange(start..<end, in: s))
                if let match = initial_match.first {
                    if let swiftRange = Range(match.range, in: s) {
                        syllable.initial = String(s[swiftRange]).lowercased().replacingOccurrences(of: "r", with: "l")
                        start = s.index(start, offsetBy: match.range.length)
                    }
                }
                
                let vowel_match = vowel.matches(in: s, range: NSRange(start..<end, in: s))
                if let match = vowel_match.first {
                    if let swiftRange = Range(match.range, in: s) {
                        syllable.nucleus = String(s[swiftRange]).lowercased()
                            .replacingOccurrences(of: "y", with: "i")
                            .replacingOccurrences(of: "wi", with: "Wi")
                            .replacingOccurrences(of: "w", with: "u")
                            .replacingOccurrences(of: "Wi", with: "wi")
                        start = s.index(start, offsetBy: match.range.length)
                    }
                    
                    let final_match = final_consonant.matches(in: s, range: NSRange(start..<end, in: s))
                    if let final_match = final_match.first {
                        let next_start = s.index(start, offsetBy: final_match.range.length)
                        if vowel.matches(in: s, range: NSRange(next_start..<end, in: s)).isEmpty {
                            if let swiftRange = Range(final_match.range, in: s) {
                                syllable.final = String(s[swiftRange]).lowercased().replacingOccurrences(of: "r", with: "l")
                                start = s.index(start, offsetBy: final_match.range.length)
                            }
                        } else {
                            let shrinked_range = NSRange(final_match.range.lowerBound..<final_match.range.upperBound - 1)
                            if shrinked_range.length > 0 {
                                if let swiftRange = Range(shrinked_range, in: s) {
                                    syllable.final = String(s[swiftRange]).lowercased().replacingOccurrences(of: "r", with: "l")
                                    start = s.index(start, offsetBy: final_match.range.length - 1)
                                }
                            }
                        }
                    }
                }
                
                if !syllable.isEmpty() {
                    syllables.append(syllable)
                } else {
                    syllables.append(Syllable(initial: String(s[start])))
                    start = s.index(start, offsetBy: 1)
                }
            }
        }
        
        return syllables
    }

}
