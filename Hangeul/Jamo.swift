//
//  Jamo.swift
//  Hangeul
//
//  Created by Kevin Li on 10/18/22.
//

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

