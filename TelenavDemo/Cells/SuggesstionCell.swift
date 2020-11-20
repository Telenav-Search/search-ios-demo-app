//
//  SuggesstionCell.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 12.11.2020.
//

import UIKit
import TelenavSDK

class SuggesstionCell: UITableViewCell {

    @IBOutlet weak var suggestionTitleLabel: UILabel!
        
    @IBOutlet weak var distanceLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        contentView.layoutIfNeeded()
    }

    func fillSuggestion(_ suggestion: TelenavSuggestionResult) {
        self.suggestionTitleLabel.text = suggestion.formattedLabel
        self.distanceLabel.text = suggestion.entity?.formattedDistance
    }
}
