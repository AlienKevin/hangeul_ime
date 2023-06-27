//
//  G2P.swift
//  Hangeul
//
//  Created by Kevin Li on 2/3/23.
//

import Foundation

public struct Explanation {
    let rule: String;
    let result: String;
}

func applyRules(rules: [(String, String, String)], s: String) -> (String, [Explanation]) {
    var result = s
    var appliedRules: [Explanation] = []
    for (pattern, template, rule) in rules {
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let oldResult = result
            result = regex.stringByReplacingMatches(in: result, range: NSRange(result.startIndex..., in: result), withTemplate: template)
            if result != oldResult {
                appliedRules.append(Explanation(rule: rule, result: result))
            }
        }
    }
    return (result, appliedRules)
}

func syllableFinalNeutralization(s: String) -> (String, [Explanation]) {
    let rules = [
        ("ᆿ", "ᆨ", "ᆿ is neutralized to ᆨ at the end of a syllable"),
        ("ᆩ", "ᆨ", "ᆩ is neutralized to ᆨ at the end of a syllable"),
        
        ("ᇀ", "ᆮ", "ᇀ is neutralized to ᆮ at the end of a syllable"),
        ("ᆺ", "ᆮ", "ᆺ is neutralized to ᆮ at the end of a syllable"),
        ("ᆻ", "ᆮ", "ᆻ is neutralized to ᆮ at the end of a syllable"),
        ("ᆽ", "ᆮ", "ᆽ is neutralized to ᆮ at the end of a syllable"),
        ("ᆾ", "ᆮ", "ᆾ is neutralized to ᆮ at the end of a syllable"),
        ("ᇂ", "ᆮ", "ᇂ is neutralized to ᆮ at the end of a syllable"),
        
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

func liaison(s: String) -> (String, [Explanation]) {
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

func nasalization(s: String) -> (String, [Explanation]) {
    let rules = [
        // Obstruent Nasalization
        ("ᆸᄆ", "ᆷᄆ", "The obstruent ᆸ is nasalized to ᆷ before the nasal ᄆ"),
        ("ᆸᄂ", "ᆷᄂ", "The obstruent ᆸ is nasalized to ᆷ before the nasal ᄂ"),
        
        ("ᆮᄆ", "ᆫᄆ", "The obstruent ᆮ is nasalized to ᆫ before the nasal ᄆ"),
        ("ᆮᄂ", "ᆫᄂ", "The obstruent ᆮ is nasalized to ᆫ before the nasal ᄂ"),
        
        ("ᆨᄆ", "ᆼᄆ", "The obstruent ᆨ is nasalized to ᆼ before the nasal ᄆ"),
        ("ᆨᄂ", "ᆼᄂ", "The obstruent ᆨ is nasalized to ᆼ before the nasal ᄂ"),
        
        ("ᆸᄅ", "ᆷᄂ", "The obstruent ᆸ is nasalized to ᆷ before the liquid ᄅ and ᄅ is nasalized to ᄂ"),
        ("ᆨᄅ", "ᆼᄂ", "The obstruent ᆨ is nasalized to ᆼ before the liquid ᄅ and ᄅ is nasalized to ᄂ"),
        
        // Liquid Nasalization
        // /m/ + /l/ → [m] + [n]
        // /ŋ/ + /l/ → [ŋ] + [n]
        ("ᆷᄅ", "ᆷᄂ", "The liquid ᄅ is nasalized to ᄂ after the nasal ᆷ"),
        ("ᆼᄅ", "ᆼᄂ", "The liquid ᄅ is nasalized to ᄂ after the nasal ᆼ"),
    ]
    return applyRules(rules: rules, s: s)
}

func palatalization(s: String) -> (String, [Explanation]) {
    let rules = [
        ("ᆮ이", "지", "The consonant ᆮ is palatalized to ᄌ before the vowel 이"),
        ("ᆮ히", "치", "The consonant ᆮ is palatalized to ᄎ before the sound 히"),
        ("ᇀ히", "치", "The consonant ᇀ is palatalized to ᄎ before the sound 히"),
        ("ᇀ이", "치", "The consonant ᇀ is palatalized to ᄎ before the sound 이"),
    ]
    return applyRules(rules: rules, s: s)
}

func lateralization(s: String) -> (String, [Explanation]) {
    let rules = [
        ("ᆫᄅ", "ᆯᄅ", "The nasal ᄂ is lateralized to the liquid ᆯ before the liquid ᆯ"),
        ("ᆯᄂ", "ᆯᄅ", "The nasal ᄂ is lateralized to the liquid ᆯ after the liquid ᆯ"),
    ]
    return applyRules(rules: rules, s: s)
}

func aspiration(s: String) -> (String, [Explanation]) {
    let rules = [
        ("ᆸᄒ", "ᄑ", "The obstruent ᆸ is aspirated to ᄑ before ᇂ"),
        ("ᇂᄇ", "ᄑ", "The obstruent ᆸ is aspirated to ᄑ after ᇂ"),
        
        ("ᆮᄒ", "ᄐ", "The obstruent ᆮ is aspirated to ᄐ before ᇂ"),
        ("ᇂᄃ", "ᄐ", "The obstruent ᆮ is aspirated to ᄐ after ᇂ"),
        
        ("ᆨᄒ", "ᄏ", "The obstruent ᆨ is aspirated to ᄏ before ᇂ"),
        ("ᇂᄀ", "ᄏ", "The obstruent ᆨ is aspirated to ᄏ after ᇂ"),
        
        ("ᆽᄒ", "ᄎ", "The obstruent ᆽ is aspirated to ᄎ before ᇂ"),
        ("ᇂᄌ", "ᄎ", "The obstruent ᆽ is aspirated to ᄎ after ᇂ"),

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

func fortis(s: String) -> (String, [Explanation]) {
    let rules = [
        ("ᆸᄇ", "ᆸᄈ", "The obstruent ᄇ is tensified after the obstruent ᆸ"),
        ("ᆮᄇ", "ᆮᄈ", "The obstruent ᄇ is tensified after the obstruent ᆮ"),
        ("ᆨᄇ", "ᆨᄈ", "The obstruent ᄇ is tensified after the obstruent ᆨ"),
        
        ("ᆸᄃ", "ᆸᄄ", "The obstruent ᄃ is tensified after the obstruents ᆸ"),
        ("ᆮᄃ", "ᆮᄄ", "The obstruent ᄃ is tensified after the obstruents ᆮ"),
        ("ᆨᄃ", "ᆨᄄ", "The obstruent ᄃ is tensified after the obstruents ᆨ"),
        
        ("ᆸᄀ", "ᆸᄁ", "The obstruent ᄀ is tensified after the obstruent ᆸ"),
        ("ᆮᄀ", "ᆮᄁ", "The obstruent ᄀ is tensified after the obstruent ᆮ"),
        ("ᆨᄀ", "ᆨᄁ", "The obstruent ᄀ is tensified after the obstruent ᆨ"),
        
        ("ᆸᄉ", "ᆸᄊ", "The obstruent ᄉ is tensified after the obstruents ᆸ"),
        ("ᆮᄉ", "ᆮᄊ", "The obstruent ᄉ is tensified after the obstruents ᆮ"),
        ("ᆨᄉ", "ᆨᄊ", "The obstruent ᄉ is tensified after the obstruents ᆨ"),
        
        ("ᆸᄌ", "ᆸᄍ", "The obstruent ᄌ is tensified after the obstruents ᆸ"),
        ("ᆮᄌ", "ᆮᄍ", "The obstruent ᄌ is tensified after the obstruents ᆮ"),
        ("ᆨᄌ", "ᆨᄍ", "The obstruent ᄌ is tensified after the obstruents ᆨ"),
        
        ("ᆰᄀ", "ᆯᄁ", "The plosive ᄀ is tensified after the consonant cluster ᆰ"),
    ]
    return applyRules(rules: rules, s: s)
}

func specialCases(s: String) -> (String, [Explanation]) {
    let rules = [
        ("희", "히", "Special case: 희 is pronounced as 히"),
        ("쳐", "처", "Special case: 쳐 is pronounced as 처"),
    ]
    return applyRules(rules: rules, s: s)
}

public func g2p(word: String) -> (String, [Explanation]) {
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
    return (jamos2Hangul(resultWord), appliedRules) as! (String, [Explanation])
}
