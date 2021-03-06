//
//  StaticCategoryDisplayModel.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 13.11.2020.
//

import Foundation
import TelenavEntitySDK

enum StaticCategoryCellType {
    case categoryItem
    case moreItem
}

protocol StaticCategoryCellItem {
    var cellType: StaticCategoryCellType { get }
}

struct StaticCategoryDisplayModel: StaticCategoryCellItem {
    
    var cellType: StaticCategoryCellType {
        return .categoryItem
    }
    
    var staticCategory: TNEntityStaticCategory
    
    init(staticCategory: TNEntityStaticCategory) {
        self.staticCategory = staticCategory
    }
}

struct StaticCategoryMoreItem: StaticCategoryCellItem {
    
    var cellType: StaticCategoryCellType {
        return .moreItem
    }
}
