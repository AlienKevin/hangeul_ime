import Cocoa
import InputMethodKit

@objc(HangeulInputController)
class InputController: IMKInputController {
    private var _isSyllableStart = true
    private var _prevSelectedLocation: Int? = nil
    
    private var _originalString = "" {
        didSet {
            dlog("[InputController] original changed: \(self._originalString)")
            let syllables = Syllable.syllabify(_originalString)
            if syllables.count >= 2 {
                //                dlog(syllables.map({ $0.description }).joined(separator: " "))
                //                dlog(syllables.dropFirst().map({ $0.description }).joined(separator: " "))
                self.replaceText(jamos2Hangul(syllables.first!.toJamos()), doClean: false)
                _originalString = String(_originalString.dropFirst(syllables.first!.count()))
                self.insertText(jamos2Hangul(syllables.dropFirst().map({ $0.toJamos() }).joined()), doClean: false)
                dlog("[InputController] syllables.count >= 2 originalString: \(self._originalString)")
            } else if _isSyllableStart {
                dlog("SyllableStart")
                self.insertText(jamos2Hangul(syllables.map({ $0.toJamos() }).joined()), doClean: false)
                _isSyllableStart = false
            } else {
                self.replaceText(jamos2Hangul(syllables.map({ $0.toJamos() }).joined()), doClean: false)
            }
        }
    }
    
    override func deactivateServer(_ sender: Any!) {
        clean()
        super.deactivateServer(sender)
    }
    
    @objc override func commitComposition(_ sender: Any!) {
        clean()
    }

    @objc override func cancelComposition() {
        clean()
        super.cancelComposition()
    }

    private func deleteKeyHandler(event: NSEvent) -> Bool? {
        let keyCode = event.keyCode
        // Delete key deletes the last letter
        if keyCode == kVK_Delete {
//            dlog("Delete")
            if _originalString.count > 0 {
//                dlog("Delete when _originalString is empty")
                _originalString = String(_originalString.dropLast(getLastJaso(_originalString)?.count ?? 1))
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
//            dlog("Punctuation " + punc)
            insertText(punc, doClean: true)
            return true
        }
        return nil
    }

    func clean() {
        dlog("[InputController] clean")
        _originalString = ""
        _isSyllableStart = true
    }

    func insertText(_ text: String, doClean: Bool) {
//        dlog("insertText: %@", text)
        let value = NSAttributedString(string: text)
        client()?.insertText(value, replacementRange: replacementRange())
//        dlog("insertText: " + text)
        if doClean { clean() }
    }
    
    func replaceText(_ text: String, doClean: Bool) {
        let value = NSAttributedString(string: text)
        let client = client()!
        let selectedRange = client.selectedRange()
        dlog("client.selectedRange before replaceText(): " + selectedRange.description)
        if selectedRange != NSRange(location: NSNotFound, length: NSNotFound) && selectedRange.location > 0 {
            let replacementLength = selectedRange.length == 0 ? 1 : selectedRange.length + 1
            let replacementRange = NSRange(location: selectedRange.location - 1, length: replacementLength)
            client.insertText(value, replacementRange: replacementRange)
        } else {
            client.insertText(value, replacementRange: replacementRange())
        }
        if doClean { clean() }
        dlog("client.selectedRange after replaceText(): " + client.selectedRange().description)
    }

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
//        dlog("[InputController] handle: \(event.debugDescription)")
        let currSelectedLocation = client()!.selectedRange().location
//        dlog("_prevSelectedLocation: " + (_prevSelectedLocation?.description ?? "nil"))
//        dlog("currSelectedLocation: " + currSelectedLocation.description)
        if _prevSelectedLocation != nil && _prevSelectedLocation != currSelectedLocation {
//            dlog("Cursor Moved")
            clean()
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
//        dlog("updated _prevSelectedLocation: " + (_prevSelectedLocation?.description ?? "nil"))
        
//        dlog("stopPropagation: " + String(stopPropagation == true))
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
