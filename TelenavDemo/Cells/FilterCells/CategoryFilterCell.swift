//
//  CategoryFilterCell.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 26.11.2020.
//

import UIKit

class CategoryFilterCell: UITableViewCell {

    @IBOutlet weak var stateImgView: UIImageView!
    
    @IBOutlet weak var categoryLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if selected {
            accessoryType = .checkmark
        } else {
            accessoryType = .none
        }
    }
    
    func fillCategory(_ category: TelenavCategoryDisplayModel) {
        categoryLabel.text = category.category.name
    }
    
    @IBAction func didChangeExpandedState(_ sender: Any) {
        
    }
}
