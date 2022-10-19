//
//  Debug.swift
//  Hangeul
//
//  Created by Kevin Li on 10/19/22.
//

import Foundation

#if DEBUG
    func dlog(_ msg: String) {
        NSLog(msg)
    }

#else
    func dlog(_: CVarArg...) {
        // do nothing in release mode
    }
#endif
