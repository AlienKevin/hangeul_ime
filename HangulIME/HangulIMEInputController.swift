//
//  HangulIMEInputController.swift
//  HangulIMEInputController
//
//  Created by ensan on 2021/09/07.
//

import Cocoa
import InputMethodKit

@objc(HangulIMEInputController)
class HangulIMEInputController: IMKInputController {
    private var _originalString = "" {
        didSet {
            NSLog("[InputController] original changed: \(self._originalString), refresh window")
            self.markText(ascii2Hanguls(_originalString))
        }
    }

    private func markText(_ text: String) {
        client()?.setMarkedText(text, selectionRange: NSRange(location: text.count, length: 0), replacementRange: replacementRange())
    }

    private func deleteKeyHandler(event: NSEvent) -> Bool? {
        let keyCode = event.keyCode
        // 删除键删除字符
        if keyCode == kVK_Delete {
            if _originalString.count > 0 {
                _originalString = String(_originalString.dropLast())
                return true
            }
            return false
        }
        return nil
    }

    private func charKeyHandler(event: NSEvent) -> Bool? {
        // 获取输入的字符
        let string = event.characters!

        guard let reg = try? NSRegularExpression(pattern: "^[a-zA-Z]+$") else {
            return nil
        }
        let match = reg.firstMatch(
            in: string,
            options: [],
            range: NSRange(location: 0, length: string.count)
        )

        // 当前没有输入非字符并且之前没有输入字符,不做处理
        if _originalString.count <= 0 && match == nil {
            NSLog("非字符,不做处理")
            return nil
        }
        // 当前输入的是英文字符,附加到之前
        if match != nil {
            _originalString += string
            return true
        }
        return nil
    }

    private func spaceKeyHandler(event: NSEvent) -> Bool? {
        if event.keyCode == kVK_Space && _originalString.count > 0 {
            insertText(ascii2Hanguls(_originalString))
            return true
        }
        return nil
    }

    private func enterKeyHandler(event: NSEvent) -> Bool? {
        // 回车键输入原字符
        if event.keyCode == kVK_Return && _originalString.count > 0 {
            // 插入原字符
            insertText(_originalString)
            return true
        }
        return nil
    }

    private func punctutionKeyHandler(event: NSEvent) -> Bool? {
        // 获取输入的字符
        let key = event.characters!
        if let punc = punctuations[key] {
            print("Punctuation " + punc)
            insertText(ascii2Hanguls(_originalString) + punc)
            return true
        }
        return nil
    }

    func clean() {
        NSLog("[InputController] clean")
        _originalString = ""
    }

    func insertText(_ text: String) {
        NSLog("insertText: %@", text)
        let value = NSAttributedString(string: text)
        client()?.insertText(value, replacementRange: replacementRange())
        clean()
    }

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        NSLog("[InputController] handle: \(event.debugDescription)")

        let handler = processHandlers(handlers: [
            deleteKeyHandler,
            charKeyHandler,
            punctutionKeyHandler,
            enterKeyHandler,
            spaceKeyHandler,
            ])
        return handler(event) ?? false
    }
}

func processHandlers<T>(
    handlers: [(NSEvent) -> T?]
) -> ((NSEvent) -> T?) {
    func handleFn(event: NSEvent) -> T? {
        for handler in handlers {
            if let result = handler(event) {
                return result
            }
        }
        return nil
    }
    return handleFn
}

struct Syllable: Equatable {
    var initial: String? = nil
    var nucleus: String? = nil
    var final: String? = nil
    
    func isEmpty() -> Bool {
        return initial == nil && nucleus == nil && final == nil
    }
}

func syllableSegmentation(_ s: String) -> [Syllable] {
    var syllables: [Syllable] = []
    let vowel = try! NSRegularExpression(pattern: "^([iy]ae|[uw]ae|[iy]eo|ae|[iy]e|[uw]e|[iy]a|[iy]o|oe|[iy][uw]|[uw]o|[uw][iy]|[uw]a|e[uw]|eo|a|e|[iy]|o|[uw])", options: [NSRegularExpression.Options.caseInsensitive])
    let initial_consonant = try! NSRegularExpression(pattern: "^(jj|ch|ss|pp|tt|kk|p|t|k|b|d|g|j|c|s|h|n|m|l)", options: [NSRegularExpression.Options.caseInsensitive])
    let final_consonant = try! NSRegularExpression(pattern: "^(kk|ss|ng|ch|gs|nj|nh|lg|lm|lb|ls|lt|lp|lh|bs|g|k|d|t|b|p|j|c|s|h|n|m|l)", options: [NSRegularExpression.Options.caseInsensitive])
    
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
                    syllable.initial = String(s[swiftRange]).lowercased()
                    start = s.index(start, offsetBy: match.range.length)
                }
            }
            
            let vowel_match = vowel.matches(in: s, range: NSRange(start..<end, in: s))
            if let match = vowel_match.first {
                if let swiftRange = Range(match.range, in: s) {
                    syllable.nucleus = String(s[swiftRange]).lowercased().replacingOccurrences(of: "w", with: "u").replacingOccurrences(of: "y", with: "i")
                    start = s.index(start, offsetBy: match.range.length)
                }
                
                let final_match = final_consonant.matches(in: s, range: NSRange(start..<end, in: s))
                if let final_match = final_match.first {
                    let next_start = s.index(start, offsetBy: final_match.range.length)
                    if vowel.matches(in: s, range: NSRange(next_start..<end, in: s)).isEmpty {
                        if let swiftRange = Range(final_match.range, in: s) {
                            syllable.final = String(s[swiftRange]).lowercased()
                            start = s.index(start, offsetBy: final_match.range.length)
                        }
                    } else {
                        let shrinked_range = NSRange(final_match.range.lowerBound..<final_match.range.upperBound - 1)
                        if shrinked_range.length > 0 {
                            if let swiftRange = Range(shrinked_range, in: s) {
                                syllable.final = String(s[swiftRange]).lowercased()
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

let initial2Jamo: [(initial: String, jamo: String)] = [
    ("pp", "ᄈ"),
    ("tt", "ᄄ"),
    ("kk", "ᄁ"),
    ("jj", "ᄍ"),
    ("ch", "ᄎ"),
    ("ss", "ᄊ"),
    ("g", "ᄀ"),
    ("k", "ᄏ"),
    ("n", "ᄂ"),
    ("d", "ᄃ"),
    ("l", "ᄅ"),
    ("m", "ᄆ"),
    ("b", "ᄇ"),
    ("s", "ᄉ"),
    ("j", "ᄌ"),
    ("c", "ᄎ"),
    ("t", "ᄐ"),
    ("p", "ᄑ"),
    ("h", "ᄒ"),
]

let nucleus2Jamo: [(nucleus: String, jamo: String)] = [
    ("iae", "ᅤ"),
    ("uae", "ᅫ"),
    ("ieo", "ᅧ"),
    ("ae", "ᅢ"),
    ("ie", "ᅨ"),
    ("ue", "ᅰ"),
    ("ia", "ᅣ"),
    ("io", "ᅭ"),
    ("oe", "ᅬ"),
    ("iu", "ᅲ"),
    ("uo", "ᅯ"),
    ("ui", "ᅴ"),
    ("ua", "ᅪ"),
    ("eu", "ᅳ"),
    ("eo", "ᅥ"),
    ("a", "ᅡ"),
    ("e", "ᅦ"),
    ("i", "ᅵ"),
    ("o", "ᅩ"),
    ("u", "ᅮ"),
]

let final2Jamo: [(final: String, jamo: String)] = [
    ("kk", "ᆩ"),
    ("ch", "ᆾ"),
    ("ss", "ᆻ"),
    ("ng", "ᆼ"),
    
    ("gs", "ᆪ"),
    ("nj", "ᆬ"),
    ("nh", "ᆭ"),
    ("lg", "ᆰ"),
    ("lm", "ᆱ"),
    ("lb", "ᆲ"),
    ("ls", "ᆳ"),
    ("lt", "ᆴ"),
    ("lp", "ᆵ"),
    ("lh", "ᆶ"),
    ("bs", "ᆹ"),
    
    ("g", "ᆨ"),
    ("n", "ᆫ"),
    ("d", "ᆮ"),
    ("l", "ᆯ"),
    ("m", "ᆷ"),
    ("b", "ᆸ"),
    
    ("s", "ᆺ"),
    ("j", "ᆽ"),
    ("k", "ᆿ"),
    ("t", "ᇀ"),
    ("p", "ᇁ"),
    ("h", "ᇂ"),
]

func syllable2Jamos(_ syllable: Syllable) -> String {
    if syllable.isEmpty() {
        return ""
    }
    
    var res = ""

    if var initial = syllable.initial {
        for (ascii, jamo) in initial2Jamo {
            initial = initial.replacingOccurrences(of: ascii, with: jamo)
        }
        res = res + initial
    }
    
    if var nucleus = syllable.nucleus {
        for (ascii, jamo) in nucleus2Jamo {
            nucleus = nucleus.replacingOccurrences(of: ascii, with: jamo)
        }
        if syllable.initial == nil {
            nucleus = "ᄋ" + nucleus
        }
        res = res + nucleus
    }
    
    if var final = syllable.final {
        for (ascii, jamo) in final2Jamo {
            final = final.replacingOccurrences(of: ascii, with: jamo)
        }
        res = res + final;
    }

    return res
}

func ascii2Hanguls(_ s: String) -> String {
    let syllables = syllableSegmentation(s)
    let jamos = syllables.map(syllable2Jamos).joined()
    let hanguls = jamos2Hangul(jamos)
    return hanguls
}

private func isLPartJamo(_ c: Int) -> Bool {
    return 0x1100 <= c && c <= 0x1112
}

private func isVPartJamo(_ c: Int) -> Bool {
    return 0x1161 <= c && c <= 0x1175
}

private func isTPartJamo(_ c: Int) -> Bool {
    return 0x11A8 <= c && c <= 0x11C2
}

private func isJamo(_ c: Int) -> Bool {
    return isLPartJamo(c) || isVPartJamo(c) || isTPartJamo(c)
}

func jamos2Hangul(_ inp: String) -> String {
    let SBase = 0xAC00
    let LBase = 0x1100
    let VBase = 0x1161
    let TBase = 0x11A7
    let TCount = 28
    let NCount = 588 // VCount * TCount

    let lState = 0
    let vState = 1
    let tState = 2

    var partState = lState
    var LVIndex = 0

    var hangul = ""

    for part in inp.unicodeScalars {
        let part = Int(part.value)
        if partState == lState { // lpart state
            if isLPartJamo(part) {
                LVIndex = (part - LBase) * NCount
                partState = vState
            } else {
                hangul.append(String(UnicodeScalar(part)!))
            }
        } else if partState == vState { // vpart state
            if isVPartJamo(part) {
                LVIndex = LVIndex + (part - VBase) * TCount
                partState = tState
            } else {
                let prevLPart = LVIndex / NCount + LBase
                if isLPartJamo(part) {
                    hangul.append(String(UnicodeScalar(prevLPart)!))
                    LVIndex = (part - LBase) * NCount
                } else {
                    hangul.append(String(UnicodeScalar(prevLPart)!))
                    hangul.append(String(UnicodeScalar(part)!))
                    partState = lState
                }
            }
        }
        else if partState == 2 { // tpart state
            var s = 0
            var appendHangul = ""
            if isTPartJamo(part) {
                let TIndex = part - TBase
                s = SBase + LVIndex + TIndex
                partState = lState
            } else if isLPartJamo(part) {
                s = SBase + LVIndex
                LVIndex = (part - LBase) * NCount
                partState = vState
            } else {
                s = SBase + LVIndex
                appendHangul = String(UnicodeScalar(part)!)
                partState = lState
            }
            print(s)
            hangul.append(String(UnicodeScalar(s)!) + appendHangul)
        }
    }

    if partState == vState {
        let prevLPart = LVIndex / NCount + LBase
        hangul.append(String(UnicodeScalar(prevLPart)!))
    } else if partState == tState {
        let s = SBase + LVIndex
        hangul.append(String(UnicodeScalar(s)!))
    }

    return hangul
}

let punctuations: [String: String] = [
    "`": "₩",
    ",": ",",
    ".": ".",
    "<": "<",
    ">": ">",
    "/": "/",
    "?": "?",
    ";": ";",
    ":": ":",
    "'": "'",
    "\"": "\"",
    "\\": "\\",
    "|": "|",
    "~": "~",
    "!": "!",
    "@": "@",
    "#": "#",
    "%": "%",
    "^": "^",
    "&": "&",
    "*": "*",
    "(": "(",
    ")": ")",
    "-": "-",
    "_": "_",
    "+": "+",
    "=": "=",
    "[": "[",
    "]": "]",
    "{": "{",
    "}": "}",
]
