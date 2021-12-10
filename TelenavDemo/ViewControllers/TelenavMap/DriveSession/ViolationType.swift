//
//  ViolationType.swift
//  TelenavDemo
//
//  Created by Anatol Uarmolovich on 23.11.21.
//

import Foundation

enum ViolationType: Int {
    case invalidAttention = 0
    case overSpeedAttention = 1
}

extension ViolationType {
    var violationTypeStringRepresentation: String {
        switch self {
        case .invalidAttention:
            return "UNKNOWN ATTENTION!"
        case .overSpeedAttention:
            return "SPEED LIMIT ATTENTION!"
        }
    }
}
