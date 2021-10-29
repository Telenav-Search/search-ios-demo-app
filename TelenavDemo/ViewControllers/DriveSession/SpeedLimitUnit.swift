//
//  SpeedLimitUnit.swift
//  TelenavDemo
//
//  Created by Anatol Uarmolovich on 28.10.21.
//

import Foundation

enum SpeedLimitUnit: Int {
    case mph = 0
    case kph = 1
}

extension SpeedLimitUnit {
    var unitStringRepresentation: String {
        switch self {
        case .mph:
            return "M/PH"
        case .kph:
            return "K/PH"
        }
    }
}
