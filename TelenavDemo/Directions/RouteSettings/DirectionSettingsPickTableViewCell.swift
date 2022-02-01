//
//  DirectionSettingsPickTableViewCell.swift
//  TelenavDemo
//
//  Created by Olesya Slepchenko on 26.07.2021.
//

import UIKit

class DirectionSettingsPickTableViewCell: UITableViewCell {
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var intValue: Int = 0
    
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
        
        textField.accessibilityIdentifier = "directionSettingsPickTableViewCellTextField"
        label.accessibilityIdentifier = "directionSettingsPickTableViewCellLabel"
        descriptionLabel.accessibilityIdentifier = "directionSettingsPickTableViewCellDescriptionLabel"
    }
}
