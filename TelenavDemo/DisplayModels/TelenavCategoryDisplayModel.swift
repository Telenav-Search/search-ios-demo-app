//
//  TelenavCategoryDisplayModel.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 12.11.2020.
//

import UIKit
import TelenavEntitySDK

class TelenavCategoryDisplayModel {

    var category: TNEntityCategory
    var catLevel: Int = 0
    var isExpanded: Bool = false
    var imgName: String {
        
        let image: String
        
        if let childNodes = category.childNodes, childNodes.count > 0 {
            
            if isExpanded {
                image = "ArrowDown"
            } else {
                image = "ArrowRight"
            }
        } else {
            image = "magnifyingglass"
        }
        
        return image
    }
    
    init(category: TNEntityCategory, catLevel: Int) {
        self.category = category
        self.catLevel = catLevel
    }
}


