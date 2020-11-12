//
//  CatalogBaseCell.swift
//  TelenavDemo
//
//  Created by ezaderiy on 30.10.2020.
//

import UIKit
import TelenavSDK

class CatalogBaseCell: UITableViewCell {

    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var mainLabel: UILabel!
    
    @IBOutlet weak var mainImageLeadingConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }

    func fillCategory(_ category: TelenavCategoryDisplayModel) {
        mainLabel.text = category.category.name
//        mainImageView.image =
        if category.catLevel > 0 {
            mainImageLeadingConstraint.constant = CGFloat(15 * category.catLevel)
        } else {
            mainImageLeadingConstraint.constant = 10
        }
    }
}
