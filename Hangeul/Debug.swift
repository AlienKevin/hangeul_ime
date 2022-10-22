//
//  Debug.swift
//  Hangeul
//
//  Created by Kevin Li on 10/19/22.
//

import Foundation

#if DEBUG
    func dlog(_ format: String, _ args: CVarArg...) {
        NSLogv(format, getVaList(args))
    }

#else
    func dlog(_: CVarArg...) {
        // do nothing in release mode
    }
#endif
