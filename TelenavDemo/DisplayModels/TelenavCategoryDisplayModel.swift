//
//  TelenavCategoryDisplayModel.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 12.11.2020.
//

import UIKit
import TelenavSDK

class TelenavCategoryDisplayModel {

    var category: TelenavCategory
    var catLevel: Int = 0
    var isExpanded: Bool = false
    
    init(category: TelenavCategory, catLevel: Int) {
        self.category = category
        self.catLevel = catLevel
    }
}
