//
//  SuggesstionCell.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 12.11.2020.
//

import UIKit
import TelenavEntitySDK

class SuggesstionCell: UITableViewCell {

    @IBOutlet weak var suggestionTitleLabel: UILabel!
        
    @IBOutlet weak var distanceLabel: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupView()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        contentView.layoutIfNeeded()
        setupView()
    }
    
    func setupView() {
        suggestionTitleLabel.accessibilityIdentifier = "suggesstionCellTitleLabel"
        distanceLabel.accessibilityIdentifier = "suggesstionCellDistanceLabel"
    }
    

    func fillSuggestion(_ suggestion: TNEntitySuggestion) {
        self.suggestionTitleLabel.text = suggestion.formattedLabel
        self.distanceLabel.text = suggestion.entity?.formattedDistance
    }
}
