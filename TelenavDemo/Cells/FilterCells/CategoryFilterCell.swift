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
    
    @IBOutlet weak var mainImageLeadingConstraint: NSLayoutConstraint!
    var expandedStateChanged: ((TelenavCategoryDisplayModel) -> Void)?
    
    private var category: TelenavCategoryDisplayModel?
    
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
        self.category = category
        
        if let img = UIImage(named: category.imgName) {
            stateImgView.image = img
        } else if let img = UIImage(systemName: category.imgName) {
            stateImgView.image = img
        }
        
        if category.catLevel > 0 {
            mainImageLeadingConstraint.constant = CGFloat(15 * category.catLevel)
        } else {
            mainImageLeadingConstraint.constant = 10
        }
    }
    
    @IBAction func didChangeExpandedState(_ sender: Any) {
        
        guard let category = self.category else {
            return
        }
        
        expandedStateChanged?(category)
    }
}
