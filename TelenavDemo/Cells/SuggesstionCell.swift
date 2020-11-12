//
//  SuggesstionCell.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 12.11.2020.
//

import UIKit

class SuggesstionCell: UITableViewCell {

    @IBOutlet weak var suggestionTitleLabel: UILabel!
        
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        contentView.layoutIfNeeded()
    }

    func fillTitle(_ title: String) {
        self.suggestionTitleLabel.text = title
    }
}
