//
//  DirectionSettingsDateTableViewCell.swift
//  TelenavDemo
//
//  Created by Olesya Slepchenko on 26.07.2021.
//

import UIKit

class DirectionSettingsDateTableViewCell: UITableViewCell {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupView()
    }
    
    func setupView() {
        accessibilityIdentifier = label.text
        label.accessibilityIdentifier = "directionSettingsDateTableViewCellLabel"
//        descriptionLabel.accessibilityIdentifier = "directionSettingsDateTableViewCellDescriptionLabel"
        datePicker.accessibilityIdentifier = "directionSettingsDateTableViewCellDatePicker"
    }
}
