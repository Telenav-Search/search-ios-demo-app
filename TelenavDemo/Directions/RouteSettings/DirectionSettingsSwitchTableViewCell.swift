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
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupView()
    }
    
    func setupView() {
        
        label.accessibilityIdentifier = "directionSettingsSwitchTableViewCellLabel"
        switchControl.accessibilityIdentifier = "directionSettingsSwitchTableViewCellControlSwitch"
    }
}
