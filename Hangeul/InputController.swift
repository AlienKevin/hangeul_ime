import Cocoa
import InputMethodKit

@objc(HangeulInputController)
class InputController: IMKInputController {
    private var _isSyllableStart = true
    private var _prevSelectedLocation: Int? = nil
    private var _supportsTSM = false
    
    private var _originalString = "" {
        didSet {
            dlog("[InputController] original changed: \(self._originalString)")
            let syllables = Syllable.syllabify(_originalString)
            if _supportsTSM {
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
            } else {
                if syllables.count >= 2 {
                    dlog(syllables.map({ $0.description }).joined(separator: " "))
                    dlog(syllables.dropFirst().map({ $0.description }).joined(separator: " "))
                    self.insertText(jamos2Hangul(syllables.first!.toJamos()), doClean: false)
                    _originalString = String(_originalString.dropFirst(syllables.first!.count()))
                    dlog("_originalSTring after dropFirst: " + _originalString)
                    self.markText(jamos2Hangul(syllables.dropFirst().map({ $0.toJamos() }).joined()))
                } else {
                    self.markText(jamos2Hangul(syllables.map({ $0.toJamos() }).joined()))
                }
            }
        }
    }
    
    override func activateServer(_ sender: Any!) {
        /*_supportsTSM = client()!.supportsProperty(TSMDocumentPropertyTag(kTSMDocumentSupportDocumentAccessPropertyTag))*/
        /* &&
            client()!.supportsProperty(TSMDocumentPropertyTag(kTSMDocumentTextServicePropertyTag))*/
        // Explicit whitelist of apps working with replaceText
        // TODO: find a TSMDocument property that specifies whether the client supports replaceText
        let clientId = client()!.bundleIdentifier()!
        let clientsSupportingReplaceText: Set = ["com.apple.Spotlight", "com.apple.finder", "com.apple.TextEdit", "com.apple.Dictionary", "com.apple.dt.Xcode", "com.apple.Safari", "com.apple.AppStore", "com.microsoft.VSCode", "com.microsoft.Word", "com.tinyspeck.slackmacgap", "com.google.Chrome", "com.tencent.xinWeChat", "us.zoom.xos", "ru.keepcoder.Telegram"]
        _supportsTSM = clientsSupportingReplaceText.contains(clientId)
        dlog("client.bundleIdentifier: " + clientId)
        dlog("_supportsTSM: " + String(_supportsTSM))
        super.activateServer(sender)
    }
    
    override func deactivateServer(_ sender: Any!) {
        if _supportsTSM {
            clean()
        } else {
            self.insertText(ascii2Hanguls(_originalString), doClean: true)
        }
        super.deactivateServer(sender)
    }
    
    @objc override func commitComposition(_ sender: Any!) {
        if _supportsTSM {
            clean()
        } else {
            self.insertText(ascii2Hanguls(_originalString), doClean: true)
        }
    }

    @objc override func cancelComposition() {
        clean()
        super.cancelComposition()
    }
    
    private func markText(_ text: String) {
        let attributedString = NSAttributedString(string: text, attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
        client()?.setMarkedText(attributedString,
                                selectionRange: NSRange(location: text.utf16.count, length: 0),
                                replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
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
            if _supportsTSM {
                insertText(" ", doClean: true)
            } else {
                insertText(ascii2Hanguls(_originalString) + " ", doClean: true)
            }
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
            if _supportsTSM {
                clean()
            } else {
                insertText(ascii2Hanguls(_originalString), doClean: true)
            }
            return false
        }
        return nil
    }

    private func punctutionKeyHandler(event: NSEvent) -> Bool? {
        let key = event.characters!
        if let punc = punctuations[key] {
//            dlog("Punctuation " + punc)
            if _supportsTSM {
                insertText(punc, doClean: true)
            } else {
                insertText(ascii2Hanguls(_originalString) + punc, doClean: true)
            }
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
        if _supportsTSM {
            let currSelectedLocation = client()!.selectedRange().location
            //        dlog("_prevSelectedLocation: " + (_prevSelectedLocation?.description ?? "nil"))
            //        dlog("currSelectedLocation: " + currSelectedLocation.description)
            if _prevSelectedLocation != nil && _prevSelectedLocation != currSelectedLocation {
                //            dlog("Cursor Moved")
                clean()
                _isSyllableStart = true
            }
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
        
        if _supportsTSM {
            _prevSelectedLocation = client()!.selectedRange().location
            //        dlog("updated _prevSelectedLocation: " + (_prevSelectedLocation?.description ?? "nil"))
        }
        
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
