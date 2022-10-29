import Cocoa
import InputMethodKit

typealias NotificationObserver = (name: Notification.Name, callback: (_ notification: Notification) -> Void)

@objc(HangeulInputController)
class InputController: IMKInputController {
    private var _isSyllableStart = true
    private var _prevSelectedLocation: Int? = nil
    private var _supportsTSM = false
    private var _candidates: [Candidate] = []
    private var _hasNext: Bool = false
    internal var inputMode: InputMode {
        get { State.shared.inputMode }
        set(value) { State.shared.inputMode = value }
    }

    internal var temp: (
        observerList: [NSObjectProtocol],
        monitorList: [Any?]
    ) = (
        observerList: [],
        monitorList: []
    )
    
    private var _originalString = "" {
        didSet {
            dlog("[InputController] original changed: \(self._originalString)")
            if inputMode == InputMode.english {
                if self.curPage != 1 {
                    // after code is updated, reset curPage to 1
                    self.curPage = 1
                    self.markText(self._originalString)
                    return
                }
                self._originalString.count > 0 ? self.refreshCandidatesWindow() : CandidatesWindow.shared.close()
                self.markText(self._originalString)
            } else {
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
                        dlog("syllables.count: %d", syllables.count)
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
    }
    
    private var curPage: Int = 1 {
        didSet(old) {
            guard old == self.curPage else {
                NSLog("[InputHandler] page changed")
                self.refreshCandidatesWindow()
                return
            }
        }
    }
    
    private var _selectedIndex: Int = 0 {
        didSet(old) {
            guard old == self._selectedIndex else {
                NSLog("[InputHandler] selected candidate changed")
                self.refreshCandidatesWindow(doUpdateCandidates: false)
                return
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
//        dlog("kTSMDocumentTextServicePropertyTag: " + String(client()!.supportsProperty(TSMDocumentPropertyTag(kTSMDocumentTextServicePropertyTag))))
//        dlog("kTSMDocumentUnicodePropertyTag: " + String(client()!.supportsProperty(TSMDocumentPropertyTag(kTSMDocumentUnicodePropertyTag))))
//        dlog("kTSMDocumentTSMTEPropertyTag: " + String(client()!.supportsProperty(TSMDocumentPropertyTag(kTSMDocumentTSMTEPropertyTag))))
//        dlog("kTSMDocumentSupportGlyphInfoPropertyTag: " + String(client()!.supportsProperty(TSMDocumentPropertyTag(kTSMDocumentSupportGlyphInfoPropertyTag))))
//        dlog("kTSMDocumentUseFloatingWindowPropertyTag: " + String(client()!.supportsProperty(TSMDocumentPropertyTag(kTSMDocumentUseFloatingWindowPropertyTag))))
//        dlog("kTSMDocumentUnicodeInputWindowPropertyTag: " + String(client()!.supportsProperty(TSMDocumentPropertyTag(kTSMDocumentUnicodeInputWindowPropertyTag))))
//        dlog("kTSMDocumentSupportDocumentAccessPropertyTag: " + String(client()!.supportsProperty(TSMDocumentPropertyTag(kTSMDocumentSupportDocumentAccessPropertyTag))))
//        dlog("kTSMDocumentRefconPropertyTag: " + String(client()!.supportsProperty(TSMDocumentPropertyTag(kTSMDocumentRefconPropertyTag))))
//        dlog("kTSMDocumentInputModePropertyTag: " + String(client()!.supportsProperty(TSMDocumentPropertyTag(kTSMDocumentInputModePropertyTag))))
//        dlog("kTSMDocumentWindowLevelPropertyTag: " + String(client()!.supportsProperty(TSMDocumentPropertyTag(kTSMDocumentWindowLevelPropertyTag))))
//        dlog("kTSMDocumentInputSourceOverridePropertyTag: " + String(client()!.supportsProperty(TSMDocumentPropertyTag(kTSMDocumentInputSourceOverridePropertyTag))))
//        dlog("kTSMDocumentEnabledInputSourcesPropertyTag: " + String(client()!.supportsProperty(TSMDocumentPropertyTag(kTSMDocumentEnabledInputSourcesPropertyTag))))
        
        notificationList().forEach { (observer) in temp.observerList.append(NotificationCenter.default.addObserver(
          forName: observer.name, object: nil, queue: nil, using: observer.callback
        ))}
        
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
        if inputMode == .english {
            State.shared.toggleInputMode()
            self.markText("")
            CandidatesWindow.shared.close()
        } else {
            if _supportsTSM {
                clean()
            } else {
                self.insertText(ascii2Hanguls(_originalString), doClean: true)
            }
        }
    }

    @objc override func cancelComposition() {
        clean()
        super.cancelComposition()
    }
    
    private func markText(_ text: String, cursorLocation: Int? = nil) {
        let attributedString = NSAttributedString(string: text, attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
        client()?.setMarkedText(attributedString,
                                selectionRange: NSRange(location: cursorLocation ?? text.utf16.count, length: 0),
                                replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
    }
    
    private func pageKeyHandler(event: NSEvent) -> Bool? {
        // Go to previous page: - or arrow left
        // Go to next page: + or arrow right
        let keyCode = event.keyCode
        if inputMode == .english && _originalString.count > 0 {
            if keyCode == kVK_ANSI_Equal || keyCode == kVK_RightArrow {
                curPage = _hasNext ? curPage + 1 : curPage
                _selectedIndex = 0
                return true
            }
            if keyCode == kVK_ANSI_Minus || keyCode == kVK_LeftArrow {
                curPage = curPage > 1 ? curPage - 1 : 1
                _selectedIndex = 0
                return true
            }
        }
        return nil
    }
    
    private func nextCandidateKeyHandler(event: NSEvent) -> Bool? {
        // Select previous candidate: arrow up
        // Select next candidate: arrow down
        let keyCode = event.keyCode
        if inputMode == .english && _originalString.count > 0 {
            if keyCode == kVK_DownArrow {
                if _selectedIndex >= min(candidateCount, _candidates.count) - 1 {
                    if _hasNext {
                        dlog("go to next page")
                        _selectedIndex = 0
                        curPage += 1
                    }
                } else {
                    _selectedIndex += 1
                }
                return true
            }
            if keyCode == kVK_UpArrow {
                if _selectedIndex <= 0 {
                    if curPage > 1 {
                        curPage -= 1
                        _selectedIndex = candidateCount - 1
                    }
                } else {
                    _selectedIndex -= 1
                }
                return true
            }
        }
        return nil
    }

    private func deleteKeyHandler(event: NSEvent) -> Bool? {
        let keyCode = event.keyCode
        // Delete key deletes the last letter
        if keyCode == kVK_Delete {
//            dlog("Delete")
            if _originalString.count > 0 {
//                dlog("Delete when _originalString is empty")
                if inputMode == .english {
                    _originalString = String(_originalString.dropLast(1))
                    if _originalString.isEmpty {
                        State.shared.toggleInputMode()
                    }
                    return true
                } else {
                    _originalString = String(_originalString.dropLast(getLastJaso(_originalString)?.count ?? 1))
                    return !_originalString.isEmpty
                }
            } else if inputMode == .english {
                State.shared.toggleInputMode()
                self.markText("")
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

        if inputMode == .hangeul && string == "q" {
            dlog("Pressed q, toggleInputMode")
            self.commitComposition(client()!)
            State.shared.toggleInputMode()
            self.markText("q[English]", cursorLocation: 1)
            return true
        }
        // Found English letter, add them to the string
        // english mode takes any string
        else if match != nil || inputMode == .english {
            _originalString += string
            return true
        }
        return nil
    }
    
    private func numberKeyHandler(event: NSEvent) -> Bool? {
        let string = event.characters!
        // When the inputed character is a digit, select the nth candidate on the page
        if inputMode == InputMode.english {
            if let pos = Int(string), _originalString.count > 0 {
                if pos >= 1 && pos <= _candidates.count {
                    let index = pos - 1
                    insertCandidate(_candidates[index])
                    return true
                }
            }
        }
        return nil
    }

    private func spaceKeyHandler(event: NSEvent) -> Bool? {
        if event.keyCode == kVK_Space && _originalString.count > 0 {
            if inputMode == InputMode.english {
                _originalString += " "
            } else if _supportsTSM {
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
            if inputMode == InputMode.english {
                if _candidates.isEmpty {
                    insertText(_originalString, doClean: true)
                } else {
                    insertCandidate(self._candidates[_selectedIndex])
                }
                return true
            } else if _supportsTSM {
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
        if inputMode == .hangeul, let punc = punctuations[key] {
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
        if inputMode == .hangeul && _supportsTSM {
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
            nextCandidateKeyHandler,
            pageKeyHandler,
            deleteKeyHandler,
            escKeyHandler,
            enterKeyHandler,
            numberKeyHandler,
            spaceKeyHandler,
            charKeyHandler,
            punctutionKeyHandler,
            ])
        let stopPropagation = handler(event)
        
        if inputMode == .hangeul && _supportsTSM {
            _prevSelectedLocation = client()!.selectedRange().location
            //        dlog("updated _prevSelectedLocation: " + (_prevSelectedLocation?.description ?? "nil"))
        }
        
//        dlog("stopPropagation: " + String(stopPropagation == true))
        return stopPropagation ?? false
    }
    
    func updateCandidates(_ sender: Any!) {
        let (candidates, hasNext) = State.shared.getCandidates(origin: self._originalString, page: curPage)
        _candidates = candidates
        _hasNext = hasNext
        _selectedIndex = 0
    }

    func refreshCandidatesWindow(doUpdateCandidates: Bool = true) {
        if doUpdateCandidates {
            updateCandidates(client())
        }
        if _candidates.count <= 0 {
            // If no candidates are found, close the candidates window
            CandidatesWindow.shared.close()
            return
        }
        let candidatesData = (list: _candidates, hasPrev: curPage > 1, hasNext: _hasNext, selectedIndex: _selectedIndex)
        CandidatesWindow.shared.setCandidates(
            candidatesData,
            originalString: _originalString,
            topLeft: getOriginPoint()
        )
    }
    
    func insertCandidate(_ candidate: Candidate) {
        insertText(candidate.koreanWord, doClean: true)
        let notification = Notification(
            name: State.candidateInserted,
            object: nil,
            userInfo: [ "candidate": candidate ]
        )
        // Asynchronously send out notification to prevent congestion of UI threads
        NotificationQueue.default.enqueue(notification, postingStyle: .whenIdle)
        State.shared.toggleInputMode()
    }
    
    // Get the mouse cursor's position
    private func getOriginPoint() -> NSPoint {
        let xd: CGFloat = 0
        let yd: CGFloat = 4
        var rect = NSRect()
        client()?.attributes(forCharacterIndex: 0, lineHeightRectangle: &rect)
        return NSPoint(x: rect.minX + xd, y: rect.minY - yd)
    }
    
    func notificationList() -> [NotificationObserver] {
        return [
            (State.candidateSelected, { notification in
                if let candidate = notification.userInfo?["candidate"] as? Candidate {
                    self.insertCandidate(candidate)
                }
            }),
            (State.prevPageBtnTapped, { _ in self.curPage = self.curPage > 1 ? self.curPage - 1 : 1 }),
            (State.nextPageBtnTapped, { _ in self.curPage = self._hasNext ? self.curPage + 1 : self.curPage }),
            (State.inputModeChanged, { notification in
                if self._originalString.count > 0, notification.userInfo?["val"] as? InputMode == InputMode.english {
                    self.commitComposition(self.client()!)
                }
            })
        ]
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
