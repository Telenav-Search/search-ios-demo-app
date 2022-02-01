//
//  ToggleableTableViewCell.swift
//  TelenavDemo
//
//  Created by Sergey Zubkov on 18.08.2021.
//

import UIKit

class ToggleableTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var `switch`: UISwitch!
    
    var isOn: Bool = false {
        didSet {
            `switch`.isOn = isOn
        }
    }
    
    var switchChanged: ((_ isOn: Bool) -> Void)?
    
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
        `switch`.addTarget(self, action: #selector(switchValueDidChange(_:)), for: .valueChanged)
        
        setupView()
    }
    
    func setupView() {
        titleLabel.accessibilityIdentifier = "toggleableTableViewCellLabel"
        `switch`.accessibilityIdentifier = "toggleableTableViewCellSwitch"
    }
    
    @objc func switchValueDidChange(_ sender: UISwitch) {
        switchChanged?(sender.isOn)
    }
}
