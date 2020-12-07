//
//  TelenavStaticCategory.swift
//  TelenavEntitySDK
//
//  Created by Lera Mozgovaya on 13.11.2020.
//

import Foundation

@objcMembers open class TNEntityStaticCategory: NSObject, Codable {
    public var id: String = UUID().uuidString
    public var name: String?
    public var img: String? {
        let imgName = name?.replacingOccurrences(of: "/", with: "", options: .caseInsensitive)
        return imgName
    }
    
    public init(name: String) {
        self.name = name
    }
}
