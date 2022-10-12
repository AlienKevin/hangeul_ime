import Cocoa
import InputMethodKit

@objc(HangulIMEInputController)
class HangulIMEInputController: IMKInputController {
    private var _originalString = "" {
        didSet {
//            NSLog("[InputController] original changed: \(self._originalString), refresh window")
            let syllables = syllableSegmentation(_originalString)
            if syllables.count >= 2 {
//                NSLog(syllables.map({ $0.description }).joined(separator: " "))
//                NSLog(syllables.dropFirst().map({ $0.description }).joined(separator: " "))
                self.insertText(jamos2Hangul(syllable2Jamos(syllables.first!)), doClean: false)
                _originalString = String(_originalString.dropFirst(syllables.first!.count()))
                self.markText(jamos2Hangul(syllables.dropFirst().map(syllable2Jamos).joined()))
            } else {
                self.markText(jamos2Hangul(syllables.map(syllable2Jamos).joined()))
            }
        }
    }
    
    override func deactivateServer(_ sender: Any!) {
        self.insertText(ascii2Hanguls(_originalString), doClean: true)
        super.deactivateServer(sender)
    }
    
    @objc override func commitComposition(_ sender: Any!) {
        insertText(ascii2Hanguls(_originalString), doClean: true)
    }

    @objc override func cancelComposition() {
        clean()
        super.cancelComposition()
    }

    private func markText(_ text: String) {
        client()?.setMarkedText(text, selectionRange: selectionRange(), replacementRange: replacementRange())
    }

    private func deleteKeyHandler(event: NSEvent) -> Bool? {
        let keyCode = event.keyCode
        // Delete key deletes the last letter
        if keyCode == kVK_Delete {
//            NSLog("Delete")
            if _originalString.count > 0 {
//                NSLog("Delete when _originalString is empty")
                _originalString = String(_originalString.dropLast())
                return true
            }
            return false
        }
        return nil
    }

    private func charKeyHandler(event: NSEvent) -> Bool? {
        let string = event.characters!

        guard let reg = try? NSRegularExpression(pattern: "^[a-zA-Z]+$") else {
            return nil
        }
        let match = reg.firstMatch(
            in: string,
            options: [],
            range: NSRange(location: 0, length: string.count)
        )

        // Found English letter, add them to the string
        if match != nil {
            _originalString += string
            return true
        }
        return nil
    }

    private func spaceKeyHandler(event: NSEvent) -> Bool? {
        if event.keyCode == kVK_Space && _originalString.count > 0 {
            insertText(ascii2Hanguls(_originalString) + " ", doClean: true)
            return true
        }
        return nil
    }
    
    private func escKeyHandler(event: NSEvent) -> Bool? {
        if event.keyCode == kVK_Escape && _originalString.count > 0 {
            clean()
            return true
        }
        return nil
    }
    
    private func enterKeyHandler(event: NSEvent) -> Bool? {
        if event.keyCode == kVK_Return && _originalString.count > 0 {
            // commit the actively edited string
            insertText(ascii2Hanguls(_originalString), doClean: true)
            return false
        }
        return nil
    }

    private func punctutionKeyHandler(event: NSEvent) -> Bool? {
        let key = event.characters!
        if let punc = punctuations[key] {
//            NSLog("Punctuation " + punc)
            insertText(ascii2Hanguls(_originalString) + punc, doClean: true)
            return true
        }
        return nil
    }

    func clean() {
//        NSLog("[InputController] clean")
        _originalString = ""
    }

    func insertText(_ text: String, doClean: Bool) {
//        NSLog("insertText: %@", text)
        let value = NSAttributedString(string: text)
        client()?.insertText(value, replacementRange: replacementRange())
        if doClean { clean() }
    }

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
//        NSLog("[InputController] handle: \(event.debugDescription)")

        let handler = processHandlers(handlers: [
            deleteKeyHandler,
            charKeyHandler,
            punctutionKeyHandler,
            escKeyHandler,
            enterKeyHandler,
            spaceKeyHandler,
            ])
        let stopPropagation = handler(event)
//        NSLog("stopPropagation: " + String(stopPropagation == true))
        return stopPropagation ?? false
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
    
    func count() -> Int {
        return (initial.map { $0.count } ?? 0) + (nucleus.map { $0.count } ?? 0)
            + (final.map { $0.count } ?? 0)
    }
    
    public var description: String { (initial ?? "") + (nucleus ?? "") + (final ?? "") }
}

func syllableSegmentation(_ s: String) -> [Syllable] {
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

func jamo2HangulCompatabilityJamo(_ jamo: Int) -> Int {
    if jamo >= 0x1100 && jamo <= 0x11ff {
        let result = hangulCompatabilityJamos[jamo - 0x1100]
        if result != 0x0000 {
            return result
        } else {
            return jamo
        }
    } else {
        return jamo
    }
}

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
    
    func part2String(_ part: Int) -> String {
        return String(UnicodeScalar(jamo2HangulCompatabilityJamo(part))!)
    }

    for part in inp.unicodeScalars {
        let part = Int(part.value)
        if partState == lState { // lpart state
            if isLPartJamo(part) {
                LVIndex = (part - LBase) * NCount
                partState = vState
            } else {
                hangul.append(part2String(part))
            }
        } else if partState == vState { // vpart state
            if isVPartJamo(part) {
                LVIndex = LVIndex + (part - VBase) * TCount
                partState = tState
            } else {
                let prevLPart = LVIndex / NCount + LBase
                if isLPartJamo(part) {
                    hangul.append(part2String(prevLPart))
                    LVIndex = (part - LBase) * NCount
                } else {
                    hangul.append(part2String(prevLPart))
                    hangul.append(part2String(part))
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
                appendHangul = part2String(part)
                partState = lState
            }
            hangul.append(part2String(s) + appendHangul)
        }
    }

    if partState == vState {
        let prevLPart = LVIndex / NCount + LBase
        hangul.append(part2String(prevLPart))
    } else if partState == tState {
        let s = SBase + LVIndex
        hangul.append(part2String(s))
    }

    return hangul
}
