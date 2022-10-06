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

            // 建议mark originalString, 否则在某些APP中会有问题
            let jamos = ascii2Jamos(_originalString)
            var hanguls = jamos2Hangul(jamos)
            let vowels = CharacterSet.init(charactersIn: "aeiouw");
            
            if hanguls.unicodeScalars.count == 2 {
                NSLog("Found 2 hanguls")
                NSLog(String(hanguls.unicodeScalars.last!))
                if isJamo(Int(hanguls.unicodeScalars.first!.value)) &&
                    isJamo(Int(hanguls.unicodeScalars.last!.value)) {
                    let first_hangul = String(hanguls.unicodeScalars.prefix(hanguls.unicodeScalars.count - 1))
                    NSLog("First hangul: " + first_hangul)
                    client()?.insertText(first_hangul, replacementRange: replacementRange())
                    NSLog("Second jamo: " + String(_originalString.unicodeScalars.last!))
                    _originalString = String(_originalString.unicodeScalars.last!)
                    self.markText(String(hanguls.unicodeScalars.last!))
                } else {
                    let nextStart = hanguls.removeLast()
                    let value = NSAttributedString(string: hanguls)
                    client()?.insertText(value, replacementRange: replacementRange())
                    var lastConsonantOffset = _originalString.unicodeScalars.count - 1;
                    for (i, char) in _originalString.unicodeScalars.reversed().enumerated()  {
                        NSLog(String(i))
                        if !vowels.contains(char) {
                            NSLog(String(char))
                            lastConsonantOffset = i
                            break
                        }
                    }
                    NSLog(String(lastConsonantOffset))
                    if lastConsonantOffset == _originalString.unicodeScalars.count - 1 {
                        _originalString = String(_originalString.last!)
                    } else {
                        NSLog("found nextstartIndex")
                        let start = _originalString.index(_originalString.endIndex, offsetBy: -lastConsonantOffset-1)
                        _originalString = String(_originalString[start...])
                    }
                    self.markText(String(nextStart))
                }
            } else {
                self.markText(hanguls)
            }
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
            if  _originalString.count <= 0 && match == nil {
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
            insertText(jamos2Hangul(ascii2Jamos(_originalString)))
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
            insertText(jamos2Hangul(ascii2Jamos(_originalString)) + punc)
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
    
//    override func inputText(_ string: String!, client sender: Any!) -> Bool {
//        NSLog(string)
//        // get client to insert
//        guard let client = sender as? IMKTextInput else {
//            return false
//        }
//        _originalString += string
//        client.setMarkedText(_originalString, selectionRange: NSRange(location: NSNotFound, length: NSNotFound), replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
//        return true
//    }
    
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

extension String {
    mutating func replacingRegexMatches(pattern: String, with: String) {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: self.count)
            self = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: with)
        } catch { return }
    }
    
    mutating func replacingWrappedMatches(pattern: String, with: String) {
        self.replacingRegexMatches(pattern: "([aeiouw])" + pattern + "$", with: "$1" + with)
        self.replacingRegexMatches(pattern: "([aeiouw])" + pattern + "([^aeiouw])", with: "$1" + with + "$2")
    }
    
    mutating func replacingRightBoundMatches(pattern: String, with: String) {
        self.replacingRegexMatches(pattern: pattern + "([^aeiouw]|'|$)", with: with + "$1")
    }
}

func ascii2Jamos(_ inp: String) -> String {
    if inp == "" {
        return ""
    }
    
    var inp = inp.replacingOccurrences(of: " ", with: "'")
    inp = inp.replacingOccurrences(of: "wa", with: "oa")
    inp.replacingRegexMatches(pattern: "w[eo]", with: "ue")
    inp = inp.replacingOccurrences(of: "f", with: "x")
    inp = inp.replacingOccurrences(of: "r", with: "l")
    
    // double final consonants
    inp.replacingWrappedMatches(pattern: "gs", with: "ᆪ")
    inp.replacingWrappedMatches(pattern: "nj", with: "ᆬ")
    inp.replacingWrappedMatches(pattern: "nh", with: "ᆭ")
    inp.replacingWrappedMatches(pattern: "lg", with: "ᆰ")
    inp.replacingWrappedMatches(pattern: "lm", with: "ᆱ")
    inp.replacingWrappedMatches(pattern: "lb", with: "ᆲ")
    inp.replacingWrappedMatches(pattern: "ls", with: "ᆳ")
    inp.replacingWrappedMatches(pattern: "lt", with: "ᆴ")
    inp.replacingWrappedMatches(pattern: "lp", with: "ᆵ")
    inp.replacingWrappedMatches(pattern: "lh", with: "ᆶ")
    inp.replacingWrappedMatches(pattern: "bs", with: "ᆹ")
    
    // tense and lax consonant pairs
    inp.replacingRightBoundMatches(pattern: "G", with: "ᆩ")
    inp = inp.replacingOccurrences(of: "G", with: "ᄁ")
    inp.replacingWrappedMatches(pattern: "g", with: "ᆨ")
    inp = inp.replacingOccurrences(of: "g", with: "ᄀ")
    
    inp.replacingRightBoundMatches(pattern: "S", with: "ᆻ")
    inp = inp.replacingOccurrences(of: "S", with: "ᄊ")
    inp.replacingWrappedMatches(pattern: "s", with: "ᆺ")
    inp = inp.replacingOccurrences(of: "s", with: "ᄉ")
    
    inp = inp.replacingOccurrences(of: "B", with: "ᄈ")
    inp.replacingWrappedMatches(pattern: "b", with: "ᆸ")
    inp = inp.replacingOccurrences(of: "b", with: "ᄇ")
    
    inp = inp.replacingOccurrences(of: "D", with: "ᄄ")
    inp.replacingWrappedMatches(pattern: "d", with: "ᆮ")
    inp = inp.replacingOccurrences(of: "d", with: "ᄃ")
    
    inp = inp.replacingOccurrences(of: "J", with: "ᄍ")
    inp.replacingWrappedMatches(pattern: "j", with: "ᆽ")
    inp = inp.replacingOccurrences(of: "j", with: "ᄌ")
    
    // Rest of the consonants
    inp.replacingWrappedMatches(pattern: "l", with: "ᆯ")
    inp = inp.replacingOccurrences(of: "l", with: "ᄅ")
    
    inp.replacingWrappedMatches(pattern: "m", with: "ᆷ")
    inp = inp.replacingOccurrences(of: "m", with: "ᄆ")
    
    inp.replacingWrappedMatches(pattern: "h", with: "ᇂ")
    inp = inp.replacingOccurrences(of: "h", with: "ᄒ")
    
    inp.replacingWrappedMatches(pattern: "n", with: "ᆫ")
    inp = inp.replacingOccurrences(of: "n", with: "ᄂ")
    
    inp.replacingWrappedMatches(pattern: "c", with: "ᆾ")
    inp = inp.replacingOccurrences(of: "c", with: "ᄎ")
    
    inp.replacingWrappedMatches(pattern: "p", with: "ᇁ")
    inp = inp.replacingOccurrences(of: "p", with: "ᄑ")
    
    inp.replacingWrappedMatches(pattern: "t", with: "ᇀ")
    inp = inp.replacingOccurrences(of: "t", with: "ᄐ")
    
    inp.replacingWrappedMatches(pattern: "k", with: "ᆿ")
    inp = inp.replacingOccurrences(of: "k", with: "ᄏ")
    
    inp.replacingRegexMatches(pattern: "([^aeiouw])x", with: "$1ᄋ")
    inp.replacingRegexMatches(pattern: "x([aeiouw])", with: "ᄋ$1")
    inp = inp.replacingOccurrences(of: "x", with: "ᆼ")
    
    inp = inp.replacingOccurrences(of: "iai", with: "ᅤ")
    inp = inp.replacingOccurrences(of: "iei", with: "ᅨ")
    inp = inp.replacingOccurrences(of: "uei", with: "ᅰ")
    inp = inp.replacingOccurrences(of: "oai", with: "ᅫ")
    inp = inp.replacingOccurrences(of: "ai", with: "ᅢ")
    inp = inp.replacingOccurrences(of: "ei", with: "ᅦ")
    inp = inp.replacingOccurrences(of: "ia", with: "ᅣ")
    inp = inp.replacingOccurrences(of: "ie", with: "ᅧ")
    inp = inp.replacingOccurrences(of: "io", with: "ᅭ")
    inp = inp.replacingOccurrences(of: "iu", with: "ᅲ")
    inp = inp.replacingOccurrences(of: "ue", with: "ᅯ")
    inp = inp.replacingOccurrences(of: "ui", with: "ᅱ")
    inp = inp.replacingOccurrences(of: "wi", with: "ᅴ")
    inp = inp.replacingOccurrences(of: "oa", with: "ᅪ")
    inp = inp.replacingOccurrences(of: "o", with: "ᅩ")
    inp = inp.replacingOccurrences(of: "e", with: "ᅥ")
    inp = inp.replacingOccurrences(of: "a", with: "ᅡ")
    inp = inp.replacingOccurrences(of: "i", with: "ᅵ")
    inp = inp.replacingOccurrences(of: "u", with: "ᅮ")
    inp = inp.replacingOccurrences(of: "w", with: "ᅳ")
    
    inp = inp.replacingOccurrences(of: "'", with: "")
    return inp
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
    let NCount = 588    // VCount * TCount
    
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
                } else{
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
    "`" : "₩",
    "," : ",",
    "." : ".",
    "<" : "<",
    ">" : ">",
    "/" : "/",
    "?" : "?",
    ";" : ";",
    ":" : ":",
    "'" : "'",
    "\"" : "\"",
    "\\" : "\\",
    "|" : "|",
    "~" : "~",
    "!" : "!",
    "@" : "@",
    "#" : "#",
    "%" : "%",
    "^" : "^",
    "&" : "&",
    "*" : "*",
    "(" : "(",
    ")" : ")",
    "-" : "-",
    "_" : "_",
    "+" : "+",
    "=" : "=",
    "[" : "[",
    "]" : "]",
    "{" : "{",
    "}" : "}",
]
