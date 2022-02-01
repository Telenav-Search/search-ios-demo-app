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
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupView()
    }
    
    func setupView() {
        
        label.accessibilityIdentifier = "directionSettingsDateTableViewCellLabel"
        descriptionLabel.accessibilityIdentifier = "directionSettingsDateTableViewCellDescriptionLabel"
        datePicker.accessibilityIdentifier = "directionSettingsDateTableViewCellDatePicker"
    }
}
