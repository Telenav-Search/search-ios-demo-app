//
//  Double + Utils.swift
//  TelenavDemo
//
//  Created by Anatol Uarmolovich on 12.11.21.
//

import Foundation

extension Double {
    func secondsToHoursMinutesSeconds() -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        let formattedString = formatter.string(from: TimeInterval(self))
        return formattedString
    }
}
