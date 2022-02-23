//
//  DirectionSettingsTextTableViewCell.swift
//  TelenavDemo
//
//  Created by Olesya Slepchenko on 22.07.2021.
//

import UIKit

class DirectionSettingsTextTableViewCell: UITableViewCell {
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupView()
    }
    
    func setupView() {
        accessibilityIdentifier = label.text
        textField.accessibilityIdentifier = "directionSettingsTextTableViewCellTextField"
        label.accessibilityIdentifier = "directionSettingsTextTableViewCellLabel"
        descriptionLabel.accessibilityIdentifier = "directionSettingsTextTableViewCellDescriptionLabel"
    }
}
