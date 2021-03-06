//
//  BrandFilterCell.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 26.11.2020.
//

import UIKit

class BrandFilterCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBOutlet weak var brandLabel: UILabel!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if selected {
            accessoryType = .checkmark
        } else {
            accessoryType = .none
        }
    }

    func fillBrand(_ brand: BrandDisplayModel) {
        self.brandLabel.text = brand.brand.brandName
    }
}
