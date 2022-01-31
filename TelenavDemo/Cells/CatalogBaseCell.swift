//
//  CatalogBaseCell.swift
//  TelenavDemo
//
//  Created by ezaderiy on 30.10.2020.
//

import UIKit
import TelenavEntitySDK

class CatalogBaseCell: UITableViewCell {

    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var mainLabel: UILabel!
    
    @IBOutlet weak var mainImageLeadingConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        mainImageView.accessibilityIdentifier = "catalogBaseCellMainImageView"
        mainLabel.accessibilityIdentifier = "catalogBaseCellMainLabel"
    }

    func fillCategory(_ category: TelenavCategoryDisplayModel) {
        mainLabel.text = category.category.name
        
        if let img = UIImage(named: category.imgName) {
            mainImageView.image = img
        } else if let img = UIImage(systemName: category.imgName) {
            mainImageView.image = img
        }
        
        if category.catLevel > 0 {
            mainImageLeadingConstraint.constant = CGFloat(15 * category.catLevel)
        } else {
            mainImageLeadingConstraint.constant = 10
        }
    }
}
