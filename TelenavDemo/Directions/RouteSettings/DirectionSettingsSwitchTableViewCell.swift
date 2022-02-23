//
//  DirectionSettingsSwitchTableViewCell.swift
//  TelenavDemo
//
//  Created by Olesya Slepchenko on 26.07.2021.
//

import UIKit

class DirectionSettingsSwitchTableViewCell: UITableViewCell {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var switchControl: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupView()
    }
    
    func setupView() {
        accessibilityIdentifier = label.text
        label.accessibilityIdentifier = "directionSettingsSwitchTableViewCellLabel"
        switchControl.accessibilityIdentifier = "directionSettingsSwitchTableViewCellControlSwitch"
    }
}
