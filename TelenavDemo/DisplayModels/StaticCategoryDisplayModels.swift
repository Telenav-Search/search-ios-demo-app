//
//  StaticCategoryDisplayModel.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 13.11.2020.
//

import Foundation
import TelenavSDK

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
    
    var staticCategory: TelenavStaticCategory
    
    init(staticCategory: TelenavStaticCategory) {
        self.staticCategory = staticCategory
    }
}

struct StaticCategoryMoreItem: StaticCategoryCellItem {
    
    var cellType: StaticCategoryCellType {
        return .moreItem
    }
}
