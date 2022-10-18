import Cocoa
import InputMethodKit

@objc(HangeulInputController)
class InputController: IMKInputController {
    private var _isSyllableStart = true
    private var _prevSelectedLocation: Int? = nil
    
    private var _originalString = "" {
        didSet {
            NSLog("[InputController] original changed: \(self._originalString)")
            let syllables = Syllable.syllabify(_originalString)
            if syllables.count >= 2 {
                //                NSLog(syllables.map({ $0.description }).joined(separator: " "))
                //                NSLog(syllables.dropFirst().map({ $0.description }).joined(separator: " "))
                self.replaceText(jamos2Hangul(syllables.first!.toJamos()), doClean: false)
                _originalString = String(_originalString.dropFirst(syllables.first!.count()))
                self.insertText(jamos2Hangul(syllables.dropFirst().map({ $0.toJamos() }).joined()), doClean: false)
                NSLog("[InputController] syllables.count >= 2 originalString: \(self._originalString)")
            } else if _isSyllableStart {
                NSLog("SyllableStart")
                self.insertText(jamos2Hangul(syllables.map({ $0.toJamos() }).joined()), doClean: false)
                _isSyllableStart = false
            } else {
                self.replaceText(jamos2Hangul(syllables.map({ $0.toJamos() }).joined()), doClean: false)
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

    private func deleteKeyHandler(event: NSEvent) -> Bool? {
        let keyCode = event.keyCode
        // Delete key deletes the last letter
        if keyCode == kVK_Delete {
//            NSLog("Delete")
            if _originalString.count > 0 {
//                NSLog("Delete when _originalString is empty")
                _originalString = String(_originalString.dropLast())
                return !_originalString.isEmpty
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
        } else {
            self.commitComposition(client())
            return nil
        }
    }

    private func spaceKeyHandler(event: NSEvent) -> Bool? {
        if event.keyCode == kVK_Space && _originalString.count > 0 {
            insertText(" ", doClean: true)
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
            clean()
            return false
        }
        return nil
    }

    private func punctutionKeyHandler(event: NSEvent) -> Bool? {
        let key = event.characters!
        if let punc = punctuations[key] {
//            NSLog("Punctuation " + punc)
            insertText(punc, doClean: true)
            return true
        }
        return nil
    }

    func clean() {
        NSLog("[InputController] clean")
        _originalString = ""
        _isSyllableStart = true
    }

    func insertText(_ text: String, doClean: Bool) {
//        NSLog("insertText: %@", text)
        let value = NSAttributedString(string: text)
        client()?.insertText(value, replacementRange: replacementRange())
        if doClean { clean() }
    }
    
    func replaceText(_ text: String, doClean: Bool) {
        let value = NSAttributedString(string: text)
        let client = client()!
        NSLog(client.selectedRange().description)
        if client.selectedRange().location > 0 {
            let length = client.selectedRange().length == 0 ? 1 : client.selectedRange().length
            let range = NSRange(location: client.selectedRange().location - length, length: length)
            client.insertText(value, replacementRange: range)
        } else {
            client.insertText(value, replacementRange: replacementRange())
        }
        if doClean { clean() }
    }

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
//        NSLog("[InputController] handle: \(event.debugDescription)")
        let currSelectedLocation = client()!.selectedRange().location
        if _prevSelectedLocation != nil && _prevSelectedLocation != currSelectedLocation {
//            NSLog("Cursor Moved")
            _isSyllableStart = true
        }

        let handler = processHandlers(handlers: [
            deleteKeyHandler,
            escKeyHandler,
            enterKeyHandler,
            spaceKeyHandler,
            punctutionKeyHandler,
            charKeyHandler,
            ])
        let stopPropagation = handler(event)
        
        _prevSelectedLocation = client()!.selectedRange().location
        
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

func ascii2Hanguls(_ s: String) -> String {
    let syllables = Syllable.syllabify(s)
    let jamos = syllables.map({ $0.toJamos() }).joined()
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
