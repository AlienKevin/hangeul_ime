//
//  FreqDict.swift
//  Hangeul
//
//  Created by Kevin Li on 11/11/22.
//

import Foundation

typealias FreqDict = [ String : Int ]

extension FreqDict {
    static func loadDictionaryFromJson() -> FreqDict? {
        guard let jsonPath = Bundle.main.path(forResource: "FreqDict", ofType: "json") else { return nil }
        guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonPath), options: .mappedIfSafe) else { return nil }
        let decoder = JSONDecoder()
        guard let dict = try? decoder.decode(FreqDict.self, from: jsonData) else { return nil }
        return dict
    }
    
    func getRanking(word: String) -> Int {
        return self[word] ?? self.count + 1
    }
}
