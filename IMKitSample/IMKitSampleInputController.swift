//
//  IMKitSampleInputController.swift
//  IMKitSampleInputController
//
//  Created by ensan on 2021/09/07.
//

import Cocoa
import InputMethodKit

@objc(IMKitSampleInputController)
class IMKitSampleInputController: IMKInputController {
    private var _originalString = "" {
        didSet {
            NSLog("[InputController] original changed: \(self._originalString), refresh window")

            // 建议mark originalString, 否则在某些APP中会有问题
            self.markText()
        }
    }
    
    private func markText() {
        client()?.setMarkedText(_originalString, selectionRange: NSRange(location: NSNotFound, length: NSNotFound), replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
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
            insertText(_originalString)
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
