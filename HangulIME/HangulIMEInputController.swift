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

let hangulCompatabilityJamos: [Int] = [
    0x3131,     /* 0x1100 */
    0x3132,     /* 0x1101 */
    0x3134,     /* 0x1102 */
    0x3137,     /* 0x1103 */
    0x3138,     /* 0x1104 */
    0x3139,     /* 0x1105 */
    0x3141,     /* 0x1106 */
    0x3142,     /* 0x1107 */
    0x3143,     /* 0x1108 */
    0x3145,     /* 0x1109 */
    0x3146,     /* 0x110a */
    0x3147,     /* 0x110b */
    0x3148,     /* 0x110c */
    0x3149,     /* 0x110d */
    0x314a,     /* 0x110e */
    0x314b,     /* 0x110f */
    0x314c,     /* 0x1110 */
    0x314d,     /* 0x1111 */
    0x314e,     /* 0x1112 */
    0x0000,     /* 0x1113 */
    0x3165,     /* 0x1114 */
    0x3166,     /* 0x1115 */
    0x0000,     /* 0x1116 */
    0x0000,     /* 0x1117 */
    0x0000,     /* 0x1118 */
    0x0000,     /* 0x1119 */
    0x3140,     /* 0x111a */
    0x0000,     /* 0x111b */
    0x316e,     /* 0x111c */
    0x3171,     /* 0x111d */
    0x3172,     /* 0x111e */
    0x0000,     /* 0x111f */
    0x3173,     /* 0x1120 */
    0x3144,     /* 0x1121 */
    0x3174,     /* 0x1122 */
    0x3175,     /* 0x1123 */
    0x0000,     /* 0x1124 */
    0x0000,     /* 0x1125 */
    0x0000,     /* 0x1126 */
    0x3176,     /* 0x1127 */
    0x0000,     /* 0x1128 */
    0x3177,     /* 0x1129 */
    0x0000,     /* 0x112a */
    0x3178,     /* 0x112b */
    0x3179,     /* 0x112c */
    0x317a,     /* 0x112d */
    0x317b,     /* 0x112e */
    0x317c,     /* 0x112f */
    0x0000,     /* 0x1130 */
    0x0000,     /* 0x1131 */
    0x317d,     /* 0x1132 */
    0x0000,     /* 0x1133 */
    0x0000,     /* 0x1134 */
    0x0000,     /* 0x1135 */
    0x317e,     /* 0x1136 */
    0x0000,     /* 0x1137 */
    0x0000,     /* 0x1138 */
    0x0000,     /* 0x1139 */
    0x0000,     /* 0x113a */
    0x0000,     /* 0x113b */
    0x0000,     /* 0x113c */
    0x0000,     /* 0x113d */
    0x0000,     /* 0x113e */
    0x0000,     /* 0x113f */
    0x317f,     /* 0x1140 */
    0x0000,     /* 0x1141 */
    0x0000,     /* 0x1142 */
    0x0000,     /* 0x1143 */
    0x0000,     /* 0x1144 */
    0x0000,     /* 0x1145 */
    0x0000,     /* 0x1146 */
    0x3180,     /* 0x1147 */
    0x0000,     /* 0x1148 */
    0x0000,     /* 0x1149 */
    0x0000,     /* 0x114a */
    0x0000,     /* 0x114b */
    0x3181,     /* 0x114c */
    0x0000,     /* 0x114d */
    0x0000,     /* 0x114e */
    0x0000,     /* 0x114f */
    0x0000,     /* 0x1150 */
    0x0000,     /* 0x1151 */
    0x0000,     /* 0x1152 */
    0x0000,     /* 0x1153 */
    0x0000,     /* 0x1154 */
    0x0000,     /* 0x1155 */
    0x0000,     /* 0x1156 */
    0x3184,     /* 0x1157 */
    0x3185,     /* 0x1158 */
    0x3186,     /* 0x1159 */
    0x0000,     /* 0x115a */
    0x0000,     /* 0x115b */
    0x0000,     /* 0x115c */
    0x0000,     /* 0x115d */
    0x0000,     /* 0x115e */
    0x0000,     /* 0x115f */
    0x3164,     /* 0x1160 */
    0x314f,     /* 0x1161 */
    0x3150,     /* 0x1162 */
    0x3151,     /* 0x1163 */
    0x3152,     /* 0x1164 */
    0x3153,     /* 0x1165 */
    0x3154,     /* 0x1166 */
    0x3155,     /* 0x1167 */
    0x3156,     /* 0x1168 */
    0x3157,     /* 0x1169 */
    0x3158,     /* 0x116a */
    0x3159,     /* 0x116b */
    0x315a,     /* 0x116c */
    0x315b,     /* 0x116d */
    0x315c,     /* 0x116e */
    0x315d,     /* 0x116f */
    0x315e,     /* 0x1170 */
    0x315f,     /* 0x1171 */
    0x3160,     /* 0x1172 */
    0x3161,     /* 0x1173 */
    0x3162,     /* 0x1174 */
    0x3163,     /* 0x1175 */
    0x0000,     /* 0x1176 */
    0x0000,     /* 0x1177 */
    0x0000,     /* 0x1178 */
    0x0000,     /* 0x1179 */
    0x0000,     /* 0x117a */
    0x0000,     /* 0x117b */
    0x0000,     /* 0x117c */
    0x0000,     /* 0x117d */
    0x0000,     /* 0x117e */
    0x0000,     /* 0x117f */
    0x0000,     /* 0x1180 */
    0x0000,     /* 0x1181 */
    0x0000,     /* 0x1182 */
    0x0000,     /* 0x1183 */
    0x3187,     /* 0x1184 */
    0x3188,     /* 0x1185 */
    0x0000,     /* 0x1186 */
    0x0000,     /* 0x1187 */
    0x3189,     /* 0x1188 */
    0x0000,     /* 0x1189 */
    0x0000,     /* 0x118a */
    0x0000,     /* 0x118b */
    0x0000,     /* 0x118c */
    0x0000,     /* 0x118d */
    0x0000,     /* 0x118e */
    0x0000,     /* 0x118f */
    0x0000,     /* 0x1190 */
    0x318a,     /* 0x1191 */
    0x318b,     /* 0x1192 */
    0x0000,     /* 0x1193 */
    0x318c,     /* 0x1194 */
    0x0000,     /* 0x1195 */
    0x0000,     /* 0x1196 */
    0x0000,     /* 0x1197 */
    0x0000,     /* 0x1198 */
    0x0000,     /* 0x1199 */
    0x0000,     /* 0x119a */
    0x0000,     /* 0x119b */
    0x0000,     /* 0x119c */
    0x0000,     /* 0x119d */
    0x318d,     /* 0x119e */
    0x0000,     /* 0x119f */
    0x0000,     /* 0x11a0 */
    0x318e,     /* 0x11a1 */
    0x0000,     /* 0x11a2 */
    0x0000,     /* 0x11a3 */
    0x0000,     /* 0x11a4 */
    0x0000,     /* 0x11a5 */
    0x0000,     /* 0x11a6 */
    0x0000,     /* 0x11a7 */
    0x3131,     /* 0x11a8 */
    0x3132,     /* 0x11a9 */
    0x3133,     /* 0x11aa */
    0x3134,     /* 0x11ab */
    0x3135,     /* 0x11ac */
    0x3136,     /* 0x11ad */
    0x3137,     /* 0x11ae */
    0x3139,     /* 0x11af */
    0x313a,     /* 0x11b0 */
    0x313b,     /* 0x11b1 */
    0x313c,     /* 0x11b2 */
    0x313d,     /* 0x11b3 */
    0x313e,     /* 0x11b4 */
    0x313f,     /* 0x11b5 */
    0x3140,     /* 0x11b6 */
    0x3141,     /* 0x11b7 */
    0x3142,     /* 0x11b8 */
    0x3144,     /* 0x11b9 */
    0x3145,     /* 0x11ba */
    0x3146,     /* 0x11bb */
    0x3147,     /* 0x11bc */
    0x3148,     /* 0x11bd */
    0x314a,     /* 0x11be */
    0x314b,     /* 0x11bf */
    0x314c,     /* 0x11c0 */
    0x314d,     /* 0x11c1 */
    0x314e,     /* 0x11c2 */
    0x0000,     /* 0x11c3 */
    0x0000,     /* 0x11c4 */
    0x0000,     /* 0x11c5 */
    0x0000,     /* 0x11c6 */
    0x3167,     /* 0x11c7 */
    0x3168,     /* 0x11c8 */
    0x0000,     /* 0x11c9 */
    0x0000,     /* 0x11ca */
    0x0000,     /* 0x11cb */
    0x3169,     /* 0x11cc */
    0x0000,     /* 0x11cd */
    0x316a,     /* 0x11ce */
    0x0000,     /* 0x11cf */
    0x0000,     /* 0x11d0 */
    0x0000,     /* 0x11d1 */
    0x0000,     /* 0x11d2 */
    0x316b,     /* 0x11d3 */
    0x0000,     /* 0x11d4 */
    0x0000,     /* 0x11d5 */
    0x0000,     /* 0x11d6 */
    0x316c,     /* 0x11d7 */
    0x0000,     /* 0x11d8 */
    0x316d,     /* 0x11d9 */
    0x0000,     /* 0x11da */
    0x0000,     /* 0x11db */
    0x0000,     /* 0x11dc */
    0x316f,     /* 0x11dd */
    0x0000,     /* 0x11de */
    0x3170,     /* 0x11df */
    0x0000,     /* 0x11e0 */
    0x0000,     /* 0x11e1 */
    0x0000,     /* 0x11e2 */
    0x0000,     /* 0x11e3 */
    0x0000,     /* 0x11e4 */
    0x0000,     /* 0x11e5 */
    0x0000,     /* 0x11e6 */
    0x0000,     /* 0x11e7 */
    0x0000,     /* 0x11e8 */
    0x0000,     /* 0x11e9 */
    0x0000,     /* 0x11ea */
    0x0000,     /* 0x11eb */
    0x0000,     /* 0x11ec */
    0x0000,     /* 0x11ed */
    0x0000,     /* 0x11ee */
    0x0000,     /* 0x11ef */
    0x0000,     /* 0x11f0 */
    0x3182,     /* 0x11f1 */
    0x3183,     /* 0x11f2 */
    0x0000,     /* 0x11f3 */
    0x0000,     /* 0x11f4 */
    0x0000,     /* 0x11f5 */
    0x0000,     /* 0x11f6 */
    0x0000,     /* 0x11f7 */
    0x0000,     /* 0x11f8 */
    0x0000,     /* 0x11f9 */
    0x0000,     /* 0x11fa */
    0x0000,     /* 0x11fb */
    0x0000,     /* 0x11fc */
    0x0000,     /* 0x11fd */
    0x0000,     /* 0x11fe */
    0x0000,     /* 0x11ff */
]

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
    ("wi", "ᅱ"),
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
    
    ("c", "ᆾ"),
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
