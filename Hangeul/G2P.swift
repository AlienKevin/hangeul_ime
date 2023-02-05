//
//  G2P.swift
//  Hangeul
//
//  Created by Kevin Li on 2/3/23.
//

import Foundation

func applyRules(rules: [(String, String, String)], s: String) -> (String, [String]) {
    var result = s
    var appliedRules: [String] = []
    for (pattern, template, rule) in rules {
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let oldResult = result
            result = regex.stringByReplacingMatches(in: result, range: NSRange(result.startIndex..., in: result), withTemplate: template)
            if result != oldResult {
                appliedRules.append(rule)
            }
        }
    }
    return (result, appliedRules)
}

func syllableFinalNeutralization(s: String) -> (String, [String]) {
    let rules = [
        ("(ᆿ|ᆩ)", "ᆨ", "ᆿ and ᆩ are neutralized to ᆨ at the end of a syllable"),
        ("(ᇀ|ᆺ|ᆻ|ᆽ|ᆾ|ᇂ)", "ᆮ", "ᇀ, ᆺ, ᆻ, ᆽ, ᆾ, and ᇂ are neutralized to ᆮ at the end of a syllable"),
        ("ᇁ", "ᆸ", "ᇁ is neutralized to ᆸ at the end of a syllable"),
        ("ᆪ", "ᆨ", "ᆪ is neutralized to ᆨ at the end of a syllable"),
        ("ᆬ", "ᆫ", "ᆬ is neutralized to ᆫ at the end of a syllable"),
        ("ᆭ", "ᆫ", "ᆭ is neutralized to ᆫ at the end of a syllable"),
        ("ᆰ", "ᆨ", "ᆰ is neutralized to ᆨ at the end of a syllable"),
        ("ᆱ", "ᆷ", "ᆱ is neutralized to ᆷ at the end of a syllable"),
        ("ᆲ", "ᆯ", "ᆲ is neutralized to ᆯ at the end of a syllable"),  // may also be neutralized to ᆸ in Seoul Korean
        ("ᆳ", "ᆯ", "ᆳ is neutralized to ᆯ at the end of a syllable"),
        ("ᆴ", "ᆯ", "ᆴ is neutralized to ᆯ at the end of a syllable"),
        ("ᆵ", "ᆸ", "ᆵ is neutralized to ᆸ at the end of a syllable"),
        ("ᆶ", "ᆯ", "ᆶ is neutralized to ᆯ at the end of a syllable"),
        ("ᆹ", "ᆸ", "ᆹ is neutralized to ᆸ at the end of a syllable"),
    ]
    return applyRules(rules: rules, s: s)
}

func liaison(s: String) -> (String, [String]) {
    let rules = [
        ("ᆨᄋ", "ᄀ", "The final consonant ᆨ shifts over to the beginning of the next syllable when there is a placeholder ᄋ"),
        ("ᆫᄋ", "ᄂ", "The final consonant ᆫ shifts over to the beginning of the next syllable when there is a placeholder ᄋ"),
        ("ᆮᄋ", "ᄃ", "The final consonant ᆮ shifts over to the beginning of the next syllable when there is a placeholder ᄋ"),
        ("ᆯᄋ", "ᄅ", "The final consonant ᆯ shifts over to the beginning of the next syllable when there is a placeholder ᄋ"),
        ("ᆷᄋ", "ᄆ", "The final consonant ᆷ shifts over to the beginning of the next syllable when there is a placeholder ᄋ"),
        ("ᆸᄋ", "ᄇ", "The final consonant ᆸ shifts over to the beginning of the next syllable when there is a placeholder ᄋ"),
        ("ᆺᄋ", "ᄉ", "The final consonant ᆺ shifts over to the beginning of the next syllable when there is a placeholder ᄋ"),
        ("ᆽᄋ", "ᄌ", "The final consonant ᆽ shifts over to the beginning of the next syllable when there is a placeholder ᄋ"),
        ("ᆾᄋ", "ᄎ", "The final consonant ᆾ shifts over to the beginning of the next syllable when there is a placeholder ᄋ"),
        ("ᆿᄋ", "ᄏ", "The final consonant ᆿ shifts over to the beginning of the next syllable when there is a placeholder ᄋ"),
        ("ᇀᄋ", "ᄐ", "The final consonant ᇀ shifts over to the beginning of the next syllable when there is a placeholder ᄋ"),
        ("ᇁᄋ", "ᄑ", "The final consonant ᇁ shifts over to the beginning of the next syllable when there is a placeholder ᄋ"),
        ("ᇂᄋ", "ᄒ", "The final consonant ᇂ shifts over to the beginning of the next syllable when there is a placeholder ᄋ"),
        ("ᆪᄋ", "ᆨᄉ", "The final consonant ᆪ shifts over to the beginning of the next syllable when there is a placeholder ᄋ"),
        ("ᆬᄋ", "ᆫᄌ", "The final consonant ᆬ shifts over to the beginning of the next syllable when there is a placeholder ᄋ"),
        ("ᆭᄋ", "ᆫᄒ", "The final consonant ᆭ shifts over to the beginning of the next syllable when there is a placeholder ᄋ"),
        ("ᆰᄋ", "ᆯᄀ", "The final consonant ᆰ shifts over to the beginning of the next syllable when there is a placeholder ᄋ"),
        ("ᆱᄋ", "ᆯᄆ", "The final consonant ᆱ shifts over to the beginning of the next syllable when there is a placeholder ᄋ"),
        ("ᆲᄋ", "ᆯᄇ", "The final consonant ᆲ shifts over to the beginning of the next syllable when there is a placeholder ᄋ"),
        ("ᆳᄋ", "ᆯᄉ", "The final consonant ᆳ shifts over to the beginning of the next syllable when there is a placeholder ᄋ"),
        ("ᆴᄋ", "ᆯᄐ", "The final consonant ᆴ shifts over to the beginning of the next syllable when there is a placeholder ᄋ"),
        ("ᆵᄋ", "ᆸᄑ", "The final consonant ᆵ shifts over to the beginning of the next syllable when there is a placeholder ᄋ"),
        ("ᆶᄋ", "ᆯᄒ", "The final consonant ᆶ shifts over to the beginning of the next syllable when there is a placeholder ᄋ"),
        ("ᆹᄋ", "ᆸᄉ", "The final consonant ᆹ shifts over to the beginning of the next syllable when there is a placeholder ᄋ"),
    ]
    return applyRules(rules: rules, s: s)
}

func nasalization(s: String) -> (String, [String]) {
    let rules = [
        // Obstruent Nasalization
        ("ᆸ(ᄆ|ᄂ)", "ᆷ$1", "The obstruent ᆸ is nasalized to ᆷ before the nasals ᄆ and ᄂ"),
        ("ᆮ(ᄆ|ᄂ)", "ᆫ$1", "The obstruent ᆮ is nasalized to ᆫ before the nasals ᄆ and ᄂ"),
        ("ᆨ(ᄆ|ᄂ)", "ᆼ$1", "The obstruent ᆨ is nasalized to ᆼ before the nasals ᄆ and ᄂ"),
        ("ᆸᄅ", "ᆷᄂ", "The obstruent ᆸ is nasalized to ᆷ before the liquid ᄅ and ᄅ is nasalized to ᄂ"),
        ("ᆨᄅ", "ᆼᄂ", "The obstruent ᆨ is nasalized to ᆼ before the liquid ᄅ and ᄅ is nasalized to ᄂ"),
        // Liquid Nasalization
        // /m/ + /l/ → [m] + [n]
        // /ŋ/ + /l/ → [ŋ] + [n]
        ("(ᆷ|ᆼ)ᄅ", "$1ᄂ", "The liquid ᄅ is nasalized to ᄂ after the nasals ᆷ and ᆼ"),
    ]
    return applyRules(rules: rules, s: s)
}

func palatalization(s: String) -> (String, [String]) {
    let rules = [
        ("ᆮ이", "지", "The consonant ᆮ is palatalized to ᄌ before the vowel 이"),
        ("ᆮ히", "치", "The consonant ᆮ is palatalized to ᄎ before the sound 히"),
        ("ᇀ(히|이)", "치", "The consonant ᇀ is palatalized to ᄎ before the sounds 히 and 이"),
    ]
    return applyRules(rules: rules, s: s)
}

func lateralization(s: String) -> (String, [String]) {
    let rules = [
        ("ᆫᄅ|ᆯᄂ", "ᆯᄅ", "The nasal ᄂ is lateralized to the liquid ᆯ before or after the liquid ᆯ"),
    ]
    return applyRules(rules: rules, s: s)
}

func aspiration(s: String) -> (String, [String]) {
    let rules = [
        ("ᆸᄒ|ᇂᄇ", "ᄑ", "The obstruent ᆸ is aspirated to ᄑ before or after ᇂ"),
        ("ᆮᄒ|ᇂᄃ", "ᄐ", "The obstruent ᆮ is aspirated to ᄐ before or after ᇂ"),
        ("ᆨᄒ|ᇂᄀ", "ᄏ", "The obstruent ᆨ is aspirated to ᄏ before or after ᇂ"),
        ("ᆽᄒ|ᇂᄌ", "ᄎ", "The obstruent ᆽ is aspirated to ᄎ before or after ᇂ"),

        ("ᆭᄇ", "ᆫᄑ", "The plosive ᄇ is aspirated to ᄑ after the consonant cluster ᆭ"),
        ("ᆭᄃ", "ᆫᄐ", "The plosive ᄃ is aspirated to ᄐ after the consonant cluster ᆭ"),
        ("ᆭᄀ", "ᆫᄏ", "The plosive ᄀ is aspirated to ᄏ after the consonant cluster ᆭ"),

        ("ᆶᄇ", "ᆯᄑ", "The plosive ᄇ is aspirated to ᄑ after the consonant cluster ᆶ"),
        ("ᆶᄃ", "ᆯᄐ", "The plosive ᄃ is aspirated to ᄐ after the consonant cluster ᆶ"),
        ("ᆶᄀ", "ᆯᄏ", "The plosive ᄀ is aspirated to ᄏ after the consonant cluster ᆶ"),

        ("ᆰᄒ", "ᆯᄏ", "The plosive ᄀ in the consonant cluster ᆰ is aspirated to ᄏ before ᄒ"),
    ]
    return applyRules(rules: rules, s: s)
}

func fortis(s: String) -> (String, [String]) {
    let rules = [
        ("(ᆸ|ᆮ|ᆨ)ᄇ", "$1ᄈ", "The obstruent ᄇ is tensified after the obstruents ᆸ, ᆮ, and ᆨ"),
        ("(ᆸ|ᆮ|ᆨ)ᄃ", "$1ᄄ", "The obstruent ᄃ is tensified after the obstruents ᆸ, ᆮ, and ᆨ"),
        ("(ᆸ|ᆮ|ᆨ)ᄀ", "$1ᄁ", "The obstruent ᄀ is tensified after the obstruents ᆸ, ᆮ, and ᆨ"),
        ("(ᆸ|ᆮ|ᆨ)ᄉ", "$1ᄊ", "The obstruent ᄉ is tensified after the obstruents ᆸ, ᆮ, and ᆨ"),
        ("(ᆸ|ᆮ|ᆨ)ᄌ", "$1ᄍ", "The obstruent ᄌ is tensified after the obstruents ᆸ, ᆮ, and ᆨ"),
        ("ᆰᄀ", "ᆯᄁ", "The plosive ᄀ is tensified after the consonant cluster ᆰ"),
    ]
    return applyRules(rules: rules, s: s)
}

func specialCases(s: String) -> (String, [String]) {
    let rules = [
        ("희", "히", "Special case: 희 is pronounced as 히"),
        ("쳐", "처", "Special case: 쳐 is pronounced as 처"),
    ]
    return applyRules(rules: rules, s: s)
}

public func g2p(word: String) -> (String, [String]) {
    // Remove whitespace between morphemes (only 5 words have whitespaces)
    let word = word.replacingOccurrences(of: " ", with: "")
    
    let surfacePhoneticRules = [
        specialCases,
        palatalization,
        liaison,
        lateralization,
        aspiration,
        fortis,
        syllableFinalNeutralization,
        aspiration,
        fortis,
        nasalization,
    ]
    
    let (resultWord, appliedRules) = surfacePhoneticRules.reduce((hanguls2Jamos(word), []), { result, rule in
        let (word, appliedRules) = result
        let (resultWord, newAppliedRules) = rule(word)
        return (resultWord, appliedRules + newAppliedRules)
    })
    return (jamos2Hangul(resultWord), appliedRules) as! (String, [String])
}
