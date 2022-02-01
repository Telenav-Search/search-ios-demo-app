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
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupView()
    }
    
    func setupView() {
        
        textField.accessibilityIdentifier = "directionSettingsTextTableViewCellTextField"
        label.accessibilityIdentifier = "directionSettingsTextTableViewCellLabel"
        descriptionLabel.accessibilityIdentifier = "directionSettingsTextTableViewCellDescriptionLabel"
    }
}
